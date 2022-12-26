
local LambdaIsValid = LambdaIsValid
local table_insert = table.insert
local timer_Simple = timer.Simple
local RealTime = RealTime
local IsValid = IsValid
local math_Clamp = math.Clamp
local random = math.random
local sub = string.sub
local Left = string.Left
local cam = cam
local net = net
local hook = hook
local surface = surface
local LocalPlayer = LocalPlayer
local origin = Vector()
local cleanuptime = GetConVar( "lambdaplayers_corpsecleanuptime" )
local cleaneffect = GetConVar( "lambdaplayers_corpsecleanupeffect" )
local speaklimit = GetConVar( "lambdaplayers_voice_talklimit" )
local globalvoice = GetConVar(  "lambdaplayers_voice_globalvoice" )
local stereowarn = GetConVar( "lambdaplayers_voice_warnvoicestereo" )
local voicevolume = GetConVar( "lambdaplayers_voice_voicevolume" )
local usegmodpopups = GetConVar( "lambdaplayers_voice_usegmodvoicepopups" )

-- Net sent from ENT:OnKilled()
net.Receive( "lambdaplayers_becomeragdoll", function() 
    local ent = net.ReadEntity()
    if !IsValid( ent ) then return end
    
    local ragdoll = ent:BecomeRagdollOnClient()
    ragdoll:DrawShadow( true )
    
    local plyColor = net.ReadVector()
    ragdoll.GetPlayerColor = function() return plyColor end

    ragdoll.LambdaOwner = ent
    ent.ragdoll = ragdoll
    table_insert( _LAMBDAPLAYERS_ClientSideEnts, ragdoll )

    local force = net.ReadVector()
    local offset = net.ReadVector()
    for i = 1, 3 do
        local phys = ragdoll:GetPhysicsObjectNum( i )
        if IsValid( phys ) then phys:ApplyForceOffset( force, offset ) end
    end

    local time = cleanuptime:GetInt()
    if time != 0 then 
        timer_Simple( time, function()
            if !IsValid( ragdoll ) then return end
            if cleaneffect:GetBool() then ragdoll:LambdaDisintegrate() return end 
            ragdoll:Remove()
        end ) 
    end
end )

net.Receive( "lambdaplayers_createclientsidedroppedweapon", function()
    local ent = net.ReadEntity()
    if !IsValid( ent ) then return end

    local cs_prop = ents.CreateClientProp( ent:GetModel() )
    cs_prop:SetPos( ent:GetPos() )
    cs_prop:SetAngles( ent:GetAngles() )
    cs_prop:SetSkin( ent:GetSkin() )
    cs_prop:SetSubMaterial( 1, ent:GetSubMaterial( 1 ) )

    local colvec = net.ReadVector()
    cs_prop:SetNW2Vector( "lambda_weaponcolor", colvec )

    cs_prop:Spawn()

    table_insert( _LAMBDAPLAYERS_ClientSideEnts, cs_prop )

    local dropFunc = _LAMBDAPLAYERSWEAPONS[ net.ReadString() ].OnDrop
    if isfunction( dropFunc ) then dropFunc( cs_prop ) end

    local phys = cs_prop:GetPhysicsObject()
    if IsValid( phys ) then
        local force = net.ReadVector()
        force = force / 2

        phys:SetMass( 20 )
        phys:ApplyForceOffset( force, net.ReadVector() )
    end

    local time = cleanuptime:GetInt()
    if time != 0 then 
        timer_Simple( time, function()
            if !IsValid( cs_prop ) then return end
            if cleaneffect:GetBool() then cs_prop:LambdaDisintegrate() return end 
            cs_prop:Remove()
        end ) 
    end
end )

local Material = Material
local voiceicon = Material( "voice/icntlk_pl" )


local function CreateProfilePictureMat( ent )
    local pfp = ent:GetProfilePicture()

    local profilepicturematerial = Material( pfp )

    if profilepicturematerial:IsError() then
        local model = ent:GetModel()
        profilepicturematerial = Material( "spawnicons/" .. sub( model, 1, #model - 4 ) .. ".png" )
    end
    return profilepicturematerial
end

-- Voice icons, voice positioning, all that stuff will be handled in here.
local function PlaySoundFile( ent, soundname, index, shouldstoponremove, is3d )
    if speaklimit:GetInt() > 0 and #_LAMBDAPLAYERS_Voicechannels >= speaklimit:GetInt() or ent.l_ismuted then return end

    if IsValid( ent.l_VoiceSnd ) then if usegmodpopups:GetBool() then hook.Run( "PlayerEndVoice", ent ) end ent.l_VoiceSnd:Stop() end

    local flag = ( is3d and "3d mono noplay" or "mono noplay" )

    sound.PlayFile( "sound/" .. soundname, flag, function( snd, ID, errorname )
        if ID == 21 then
            if stereowarn:GetBool() then print( "Lambda Players Voice Chat Warning: Sound file " ..soundname .. " has a stereo track and won't be played in 3d. Sound will continue to play. You can disable these warnings in Lambda Player>Utilities" ) end
            PlaySoundFile( ent, soundname, index, shouldstoponremove, false )
            return
        elseif ID == 2 then
            print( "Lambda Players Voice Chat Error: Sound file " ..soundname .. " failed to open!" )
            return
        end

        if IsValid( snd ) then


            local volume
            local followEnt
            local id = ent:EntIndex()
            local length = snd:GetLength()
            local pitch = IsValid( ent ) and ent:GetVoicePitch() or 100


            local dist = LocalPlayer():GetPos():DistToSqr( IsValid( ent ) and ent:GetPos() or origin )
            if dist < ( 2000 * 2000 ) then
                volume = math_Clamp( voicevolume:GetFloat() / ( dist / ( 90 * 90 ) ), 0, voicevolume:GetFloat() )
            else
                volume = 0
            end

            snd:SetVolume( volume )
            snd:Play()
            if usegmodpopups:GetBool() then hook.Run( "PlayerStartVoice", ent ) end

            -- Render the voice icon
            hook.Add( "PreDrawEffects", "lambdavoiceicon" .. id,function()
                followEnt = LambdaIsValid( ent ) and ent or IsValid( ent.ragdoll ) and ent.ragdoll or followEnt

                if !IsValid( snd ) or snd:GetState() == GMOD_CHANNEL_STOPPED then hook.Remove( "PreDrawEffects", "lambdavoiceicon" .. id ) return end
                if RealTime() > RealTime() + length then hook.Remove( "PreDrawEffects", "lambdavoiceicon" .. id ) return end
                if !IsValid( followEnt ) then hook.Remove( "PreDrawEffects", "lambdavoiceicon" .. id ) return end

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

            snd:SetPlaybackRate( pitch / 100 )

            -- Tell the server the duration of this sound file
            -- See server/netmessages.lua
            net.Start( "lambdaplayers_server_sendsoundduration" )
            net.WriteEntity( ent )
            net.WriteFloat( ( length / ( pitch / 100 ) ) )
            net.SendToServer()

            if !globalvoice:GetBool() and is3d then
                snd:Set3DFadeDistance( 300, 0 )
                snd:Set3DEnabled( is3d )
            end

            local length = snd:GetLength()
            local replaced = false

            for k, v in ipairs( _LAMBDAPLAYERS_Voicechannels ) do
                if IsValid( ent ) and v[ 5 ] == ent:EntIndex() then
                    _LAMBDAPLAYERS_Voicechannels[ k ] = { snd, ent:GetLambdaName(), CreateProfilePictureMat( ent ), length, ent:EntIndex() }
                    replaced = true
                    break
                end
            end
            if !replaced and IsValid( ent ) then table_insert( _LAMBDAPLAYERS_Voicechannels, { snd, ent:GetLambdaName(), CreateProfilePictureMat( ent ), length, ent:EntIndex() } ) end

            local num
            local realtime
            local num2 
            local lastpos
            local tickent -- This variable is used so we don't redefine ent and can allow the sound to return to the Lambda when they respawn

            -- This has proved to be a bit of a challenge.
            -- There were issues with the sounds not going back the Lambda player when they respawn and there were issues when the ragdoll gets removed.
            -- Right now this code seems to work just as I think I want it to. Unsure if it could be optimized better but to me it looks as good as it is gonna get

            hook.Add( "Tick", "lambdaplayersvoicetick" .. index, function()
                if !LambdaIsValid( ent ) and shouldstoponremove then if usegmodpopups:GetBool() then hook.Run( "PlayerEndVoice", ent ) end snd:Stop() return end
                if !IsValid( snd ) or snd:GetState() == GMOD_CHANNEL_STOPPED then if usegmodpopups:GetBool() then hook.Run( "PlayerEndVoice", ent ) end hook.Remove( "Tick", "lambdaplayersvoicetick" .. index ) return end
                if RealTime() > RealTime() + length then if usegmodpopups:GetBool() then hook.Run( "PlayerEndVoice", ent ) end hook.Remove( "Tick", "lambdaplayersvoicetick" .. index ) return end

                tickent = LambdaIsValid( ent ) and ent or IsValid( ent.ragdoll ) and ent.ragdoll or tickent
                snd:Set3DEnabled( ( !globalvoice:GetBool() and is3d ) )

                if !globalvoice:GetBool() and !is3d then
                    local ply = LocalPlayer()
                    lastpos = IsValid( tickent ) and tickent:GetPos() or lastpos or origin

                    local dist = ply:GetPos():DistToSqr( lastpos )
                    if dist < ( 2000 * 2000 ) then
                        volume = math_Clamp( voicevolume:GetFloat() / ( dist / ( 90 * 90 ) ), 0, voicevolume:GetFloat() )
                    else
                        volume = 0
                    end
                else
                    lastpos = IsValid( tickent ) and tickent:GetPos() or lastpos or origin
                    snd:SetPos( lastpos )
                    volume = voicevolume:GetFloat()
                end

                snd:SetVolume( volume )


                if LambdaIsValid( tickent ) then 

                    local leftC, rightC = snd:GetLevel()
                    local voiceLvl = ((leftC + rightC) / 2)

                    local voicelvlent = tickent.IsLambdaPlayer and tickent or IsValid( tickent.LambdaOwner ) and tickent.LambdaOwner
                    if IsValid( voicelvlent ) then voicelvlent:SetVoiceLevel( voiceLvl ) end

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


net.Receive( "lambdaplayers_notification", function()
    local text = net.ReadString()
    local notify = net.ReadUInt( 3 )
    local snd = net.ReadString()

    notification.AddLegacy( text, notify, 3 )

    if snd then surface.PlaySound( snd ) end
end )

local unpack = unpack
local JSONToTable = util.JSONToTable
net.Receive( "lambdaplayers_chatadd", function()
    local args = net.ReadString()
    args = JSONToTable( args )

    chat.AddText( unpack( args ) )
end )

net.Receive( "lambdaplayers_addtokillfeed", function() 
    local attackername = net.ReadString()
    local attackerteam = net.ReadInt( 8 )
    local victimname = net.ReadString()
    local victimteam = net.ReadInt( 8 )
    local inflictorname = net.ReadString()

    GAMEMODE:AddDeathNotice( attackername, attackerteam, inflictorname, victimname, victimteam )
end )


local EndsWith = string.EndsWith
local CreateMaterial = CreateMaterial
local Material = Material
local color_white = color_white
local DecalEx = util.DecalEx


local function Spray( spraypath, tracehitpos, tracehitnormal, index, attemptedfallback )
    local isVTF = EndsWith( spraypath, ".vtf" ) -- If the file is a VTF
    local material

    -- The file is a Valve Texture Format ( VTF )
    if isVTF then
        material = CreateMaterial( "lambdasprayVTFmaterial" .. index, "LightmappedGeneric", {
            [ "$basetexture" ] = spraypath,
            [ "$translucent" ] = 1, -- Some VTFs are translucent
            [ "Proxies" ] = {
                [ "AnimatedTexture" ] = { -- Support for Animated VTFs
                    [ "animatedTextureVar" ] = "$basetexture",
                    [ "animatedTextureFrameNumVar" ] = "$frame",
                    [ "animatedTextureFrameRate" ] = 10
                }
            }
        })
    else -- The file is a PNG or JPG
        material = Material( spraypath )
    end

    -- If we failed to load the Server's spray, try one of our own sprays and hope it works. If it does not work, give up and don't spray anything.
    if material:IsError() and !attemptedfallback then Spray( LambdaPlayerSprays[ random( #LambdaPlayerSprays ) ], tracehitpos, tracehitnormal, index, true ) return elseif material:IsError() and attemptedfallback then return end

--[[     local texWidth = material:Width()
    local texHeight = material:Height()
    local widthPower = 256
    local heightPower = 256

    -- Sizing the Spray
    if texWidth > texHeight then heightPower = 128 elseif texHeight > texWidth then widthPower = 128 end
    if texWidth < 256 then texWidth = ( texWidth / 256 ) else texWidth = ( widthPower / ( texWidth * 4 ) ) end
    if texHeight < 256 then texHeight = ( texHeight / 256 ) else texHeight = ( heightPower / ( texHeight * 4) ) end ]]

    local texWidth = (material:Width() * 0.15) / material:Width()
    local texHeight = (material:Height() * 0.15) / material:Height() 

    -- Place the spray
    DecalEx( material, Entity( 0 ), tracehitpos, tracehitnormal, color_white, texWidth, texHeight)

end

net.Receive( "lambdaplayers_spray", function() 
    local spraypath = net.ReadString()
    local tracehitpos = net.ReadVector()
    local tracehitnormal = net.ReadNormal()
    local index = net.ReadUInt( 32 )
    Spray( spraypath, tracehitpos, tracehitnormal, index )
end )

net.Receive( "lambdaplayers_getplybirthday", function() 
    local birthdaydata = LAMBDAFS:ReadFile( "lambdaplayers/playerbirthday.json", "json" )

    net.Start( "lambdaplayers_returnplybirthday" )
    if birthdaydata then
        net.WriteString( birthdaydata.month )
        net.WriteUInt( birthdaydata.day, 5 )
    else
        net.WriteString( "NIL" )
        net.WriteUInt( 1, 5 )
    end
    net.SendToServer()
end )