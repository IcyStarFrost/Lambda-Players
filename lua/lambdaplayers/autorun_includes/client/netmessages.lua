
local LambdaIsValid = LambdaIsValid
local table_insert = table.insert
local RealTime = RealTime
local math_Clamp = math.Clamp

-- Net sent from ENT:OnKilled()
net.Receive( "lambdaplayers_becomeragdoll", function() 
    local ent = net.ReadEntity()
    local force = net.ReadVector()
    local offset = net.ReadVector()
    local colvec = net.ReadVector()

    if !IsValid( ent ) then return end

    ent.ragdoll = ent:BecomeRagdollOnClient()
    ent.ragdoll.GetPlayerColor = function() return col end

    table_insert( _LAMBDAPLAYERSClientSideRagdolls, ent.ragdoll )

    for i=1, 3 do
        local phys = ent.ragdoll:GetPhysicsObjectNum( i )

        if IsValid( phys ) then
            phys:ApplyForceOffset( force, offset )
        end

    end

end )


local volumeconvar = GetConVar( "lambdaplayers_voicevolume" )
local globalconvar = GetConVar( "lambdaplayers_globalvoice" )


local function PlaySoundFile( ent, soundname, index, shouldstoponremove, is3d )

    ent = LambdaIsValid( ent.ragdoll ) and ent.ragdoll or ent

    local flag = globalconvar:GetBool() and "" or is3d and "3d mono" or "mono"

    sound.PlayFile( "sound/" .. soundname, flag, function( snd, ID, errorname )
        if ID == 21 then
            print( "Lambda Players Voice Chat Warning: Sound file " ..soundname .. " has a stereo track and won't be played in 3d. Sound will continue to play" )
            PlaySoundFile( ent, soundname, index, shouldstoponremove, false )
            return
        elseif ID == 2 then
            print( "Lambda Players Voice Chat Error: Sound file " ..soundname .. " failed to open!" )
            return
        end

        if LambdaIsValid( snd ) then

            if !globalconvar:GetBool() and is3d then
                snd:Set3DFadeDistance( 300, 0 )
                snd:Set3DEnabled( is3d )
            end

            local length = snd:GetLength()
            table_insert( _LAMBDAPLAYERS_Voicechannels, { snd, lambda, length } )
        
            local volume
            local num
            local realtime
            local num2 

            hook.Add( "Tick", "lambdaplayersvoicetick" .. index, function()
                if !LambdaIsValid( snd ) or snd:GetState() == GMOD_CHANNEL_STOPPED then hook.Remove( "Tick", "lambdaplayersvoicetick" .. index ) return end
                if RealTime() > RealTime() + length then hook.Remove( "Tick", "lambdaplayersvoicetick" .. index ) return end
                if !LambdaIsValid( ent ) then if shouldstoponremove then snd:Stop() end hook.Remove( "Tick", "lambdaplayersvoicetick" .. index ) return end

                if !globalconvar:GetBool() and !is3d then
                    local ply = LocalPlayer()

                    local dist = ply:GetPos():DistToSqr( ent:GetPos() )

                    if dist < ( 2000 * 2000 ) then
                        volume = math_Clamp( volumeconvar:GetFloat() / ( dist / ( 90 * 90 ) ), 0, volumeconvar:GetFloat() )
                    else
                        volume = 0
                    end
                else
                    snd:SetPos( ent:GetPos() )
                    volume = volumeconvar:GetFloat()
                end

                snd:SetVolume( volume )

                local leftC, rightC = snd:GetLevel()
                local voiceLvl = ((leftC + rightC) / 2)


                if LambdaIsValid( ent ) then 
                    snd:SetPos( ent:GetPos() ) 

                    num = num or 0.0
                    realtime = realtime or RealTime()
                    num2 = num2 or 0.0
                    
                    if RealTime() <= realtime then
                        if voiceLvl > num then
                            num = voiceLvl 
                        end
                    else
                        num = 0.0
                        realtime = RealTime() + 1
                    end

                    num2 = ( num <= 0.2 and num2 or ( voiceLvl / num ) )
                    ent:LambdaMoveMouth( num2 )
                end

            end )    

        end
    end)
end

net.Receive("lambdaplayers_playsoundfile", function()
    local lambda = net.ReadEntity()
    local soundname = net.ReadString()
    local shouldstoponremove = net.ReadBool()
    local index = net.ReadUInt( 32 )

    if !IsValid(lambda) then return end

    PlaySoundFile( lambda, soundname, index, shouldstoponremove, true )
end)

net.Receive( "lambdaplayers_invalidateragdoll", function()
    local ent = net.ReadEntity()

    if !IsValid( ent ) then return end

    ent.ragdoll = nil
end )
