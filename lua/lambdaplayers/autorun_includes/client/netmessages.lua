
local LambdaIsValid = LambdaIsValid
local table_insert = table.insert
local RealTime = RealTime
local IsValid = IsValid
local math_Clamp = math.Clamp
local cam = cam
local hook = hook
local surface = surface

local cleanupvar = GetConVar( "lambdaplayers_corpsecleanuptime" )

-- Net sent from ENT:OnKilled()
net.Receive( "lambdaplayers_becomeragdoll", function() 
    local ent = net.ReadEntity()
    local force = net.ReadVector()
    local offset = net.ReadVector()
    local colvec = net.ReadVector()

    if !IsValid( ent ) then return end

    local ragdoll = ent:BecomeRagdollOnClient()
    ragdoll:DrawShadow( true )
    ragdoll.GetPlayerColor = function() return col end

    ent.ragdoll = ragdoll

    local time = cleanupvar:GetInt()

    if time != 0 then timer.Simple( time , function() ragdoll:Remove() end ) end

    table_insert( _LAMBDAPLAYERSClientSideRagdolls, ragdoll )

    for i=1, 3 do
        local phys = ent.ragdoll:GetPhysicsObjectNum( i )

        if IsValid( phys ) then
            phys:ApplyForceOffset( force, offset )
        end

    end

end )


local volumeconvar = GetConVar( "lambdaplayers_voicevolume" )
local globalconvar = GetConVar( "lambdaplayers_globalvoice" )
local voiceicon = Material( "voice/icntlk_pl" )


-- Voice icons, voice positioning, all that stuff will be handled in here.
local function PlaySoundFile( ent, soundname, index, shouldstoponremove, is3d )

    if IsValid( ent.l_VoiceSnd ) then ent.l_VoiceSnd:Stop() end

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

        if IsValid( snd ) then

            local followEnt
            local id = ent:EntIndex()
            local length = snd:GetLength()

            hook.Add( "PreDrawEffects", "lambdavoiceicon" .. id,function()
                followEnt = LambdaIsValid( ent ) and ent or IsValid( ent.ragdoll ) and ent.ragdoll or followEnt

                if !IsValid( snd ) or snd:GetState() == GMOD_CHANNEL_STOPPED then hook.Remove( "PreDrawEffects", "zetavoiceicon" .. id ) return end
                if RealTime() > RealTime() + length then hook.Remove( "PreDrawEffects", "zetavoiceicon" .. id ) return end
                if !IsValid( followEnt ) then hook.Remove( "PreDrawEffects", "zetavoiceicon" .. id ) return end

                local ang = EyeAngles()
                local pos = followEnt:GetPos() + Vector( 0, 0, 80 )
                ang:RotateAroundAxis( ang:Up(), -90 )
                ang:RotateAroundAxis( ang:Forward(), 90 )
            
                cam.Start3D2D( pos, ang, 1 )
                    surface.SetMaterial( voiceicon )
                    surface.SetDrawColor( 255, 255, 255 )
                    surface.DrawTexturedRect( -8, -8, 16, 16 )
                cam.End3D2D()
            end)
            

            ent.l_VoiceSnd = snd

            snd:SetPlaybackRate( ent:GetVoicePitch() / 100 )

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
            local lastpos
            local tickent -- This variable is used so we don't redefine ent and can allow the sound to return to the Lambda when they respawn

            -- This has proved to be a bit of a challenge.
            -- There were issues with the sounds not going back the lambda player when they respawn and there were issues when the ragdoll gets removed.
            -- Right now this code seems to work just as I think I want it to. Unsure if it could be optimized better but to me it looks as good as it is gonna get

            hook.Add( "Tick", "lambdaplayersvoicetick" .. index, function()
                if !LambdaIsValid( ent ) and shouldstoponremove then snd:Stop() return end
                if !IsValid( snd ) or snd:GetState() == GMOD_CHANNEL_STOPPED then hook.Remove( "Tick", "lambdaplayersvoicetick" .. index ) return end
                if RealTime() > RealTime() + length then hook.Remove( "Tick", "lambdaplayersvoicetick" .. index ) return end

                tickent = LambdaIsValid( ent ) and ent or IsValid( ent.ragdoll ) and ent.ragdoll or tickent

                if !globalconvar:GetBool() and !is3d then
                    local ply = LocalPlayer()
                    lastpos = IsValid( tickent ) and tickent:GetPos() or lastpos

                    local dist = ply:GetPos():DistToSqr( lastpos )

                    if dist < ( 2000 * 2000 ) then
                        volume = math_Clamp( volumeconvar:GetFloat() / ( dist / ( 90 * 90 ) ), 0, volumeconvar:GetFloat() )
                    else
                        volume = 0
                    end
                else
                    lastpos = IsValid( tickent ) and tickent:GetPos() or lastpos
                    snd:SetPos( lastpos )
                    volume = volumeconvar:GetFloat()
                end

                snd:SetVolume( volume )


                if LambdaIsValid( tickent ) then 

                    local leftC, rightC = snd:GetLevel()
                    local voiceLvl = ((leftC + rightC) / 2)

                    snd:SetPos( tickent:GetPos() ) 

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
                    tickent:LambdaMoveMouth( num2 )
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


net.Receive( "lambdaplayers_setnodraw", function() 
    local ent = net.ReadEntity()
    local bool = net.ReadBool()
    if !IsValid( ent ) then return end
    ent:SetNoDraw( bool or false )
    ent:DrawShadow( !bool or true )
end )


