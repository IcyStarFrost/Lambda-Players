
local table_insert = table.insert
local table_Count = table.Count
local RealTime = RealTime
local IsValid = IsValid
local CurTime = CurTime
local math_Clamp = math.Clamp
local Start3D2D = cam.Start3D2D
local End3D2D = cam.End3D2D
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_PlaySound = surface.PlaySound
local notification_AddLegacy = notification.AddLegacy
local net = net
local pairs = pairs
local ipairs = ipairs
local CreateClientProp = ents.CreateClientProp
local EyeAngles = EyeAngles
local EyePos = EyePos
local istable = istable
local sound_PlayFile = sound.PlayFile
local coroutine_yield = coroutine.yield
local cleanuptime = GetConVar( "lambdaplayers_corpsecleanuptime" )
local cleaneffect = GetConVar( "lambdaplayers_corpsecleanupeffect" )
local speaklimit = GetConVar( "lambdaplayers_voice_talklimit" )
local globalvoice = GetConVar(  "lambdaplayers_voice_globalvoice" )
local stereowarn = GetConVar( "lambdaplayers_voice_warnvoicestereo" )
local voicevolume = GetConVar( "lambdaplayers_voice_voicevolume" )
local voicedistance = GetConVar( "lambdaplayers_voice_voicedistance" )
local removeCorpse = GetConVar( "lambdaplayers_removecorpseonrespawn" )
local dropWeapon = GetConVar( "lambdaplayers_dropweaponondeath" )
local voicePopupClrR = GetConVar( "lambdaplayers_voice_voicepopupcolor_r" )
local voicePopupClrG = GetConVar( "lambdaplayers_voice_voicepopupcolor_g" )
local voicePopupClrB = GetConVar( "lambdaplayers_voice_voicepopupcolor_b" )

net.Receive( "lambdaplayers_serversideragdollplycolor", function()
    local ragdoll = net.ReadEntity()
    if !IsValid( ragdoll ) then return end

    local color = net.ReadVector()
    ragdoll.GetPlayerColor = function() return color end
end )

net.Receive( "lambdaplayers_disintegrationeffect", function()
    local ent = net.ReadEntity()
    if IsValid( ent ) then ent:LambdaDisintegrate() end
end )

-- Net sent from ENT:OnKilled()
net.Receive( "lambdaplayers_becomeragdoll", function()
    local lambda = net.ReadEntity()
    if !IsValid( lambda ) then return end

    local overrideEnt = net.ReadEntity()
    local ragdoll = ( IsValid( overrideEnt ) and overrideEnt or lambda ):BecomeRagdollOnClient()
    if !IsValid( ragdoll ) then return end

    local dormPos = net.ReadVector()
    local dmgPos, dmgForce, forceDiv = net.ReadVector(), net.ReadVector(), net.ReadUInt( 7 )
    local isDorm = lambda:IsDormant()

    for i = 0, ( ragdoll:GetPhysicsObjectCount() - 1 ) do
        local phys = ragdoll:GetPhysicsObjectNum( i )
        if !IsValid( phys ) then continue end
        if isDorm then phys:SetPos( dormPos, true ) end

        local distDiff = ( phys:GetPos():Distance( dmgPos ) / forceDiv )
        local forceAdd = ( dmgForce / distDiff )
        phys:ApplyForceOffset( forceAdd, dmgPos )
    end

    ragdoll:SetNoDraw( false )
    ragdoll:DrawShadow( true )
    ragdoll.isclientside = true
    ragdoll.LambdaOwner = lambda

    local plyColor = net.ReadVector()
    ragdoll.GetPlayerColor = function() return plyColor end

    lambda.ragdoll = ragdoll
    table_insert( _LAMBDAPLAYERS_ClientSideEnts, ragdoll )

    local startTime = CurTime()
    LambdaCreateThread( function()
        while ( cleanuptime:GetInt() == 0 or CurTime() < ( startTime + cleanuptime:GetInt() ) or IsValid( lambda ) and ( !lambda.GetIsDead or lambda:GetIsDead() and lambda:IsSpeaking() ) ) do
            if !IsValid( ragdoll ) then return end
            coroutine_yield()
        end
        if !IsValid( ragdoll ) then return end

        if cleaneffect:GetBool() then ragdoll:LambdaDisintegrate() return end
        ragdoll:Remove()
    end )
end )

net.Receive( "lambdaplayers_createclientsidedroppedweapon", function()
    if !dropWeapon:GetBool() then return end

    local wepent = net.ReadEntity()
    if !IsValid( wepent ) then return end

    local cs_prop = CreateClientProp( net.ReadString() )
    cs_prop:SetPos( net.ReadVector() )
    cs_prop:SetAngles( wepent:GetAngles() )
    cs_prop:SetSkin( net.ReadUInt( 5 ) )
    cs_prop:SetSubMaterial( 1, net.ReadString() )
    cs_prop:SetModelScale( net.ReadFloat(), 0 )
    cs_prop:SetNW2Vector( "lambda_weaponcolor", net.ReadVector() )
    cs_prop:Spawn()

    local lambda = net.ReadEntity()
    if IsValid( lambda ) then lambda.cs_prop = cs_prop end

    table_insert( _LAMBDAPLAYERS_ClientSideEnts, cs_prop )
    cs_prop.isclientside = true

    local wpnData = _LAMBDAPLAYERSWEAPONS[ net.ReadString() ]
    if istable( wpnData ) then
        local dropFunc = wpnData.OnDrop
        if isfunction( dropFunc ) then dropFunc( lambda, wepent, cs_prop ) end
    end

    local phys = cs_prop:GetPhysicsObject()
    if IsValid( phys ) then
        local force = ( net.ReadVector() / 7 )
        phys:ApplyForceOffset( force, net.ReadVector() )
    end

    local startTime = CurTime()
    LambdaCreateThread( function()
        while ( cleanuptime:GetInt() == 0 or CurTime() < ( startTime + cleanuptime:GetInt() ) or IsValid( lambda ) and ( !lambda.GetIsDead or lambda:GetIsDead() and lambda:IsSpeaking() ) ) do
            if !IsValid( cs_prop ) then return end
            coroutine_yield()
        end
        if !IsValid( cs_prop ) then return end

        if cleaneffect:GetBool() then cs_prop:LambdaDisintegrate() return end
        cs_prop:Remove()
    end )
end )

-- Voice icons, voice positioning, all that stuff will be handled in here.

local Material = Material
local team_GetColor = team.GetColor
local Color = Color
local voiceicon = Material( "voice/icntlk_pl" )
local iconOffset = Vector( 0, 0, 80 )
local baseTeams = {
    [ TEAM_CONNECTING ] = true,
    [ TEAM_UNASSIGNED ] = true,
    [ TEAM_SPECTATOR ] = true
}

_LAMBDAPLAYERS_VoiceChannels = {}

local function PlaySoundFile( ent, soundName, index, origin, delay, is3d )
    if !IsValid( ent ) then return end

    local talkLimit = speaklimit:GetInt()
    if talkLimit > 0 and table_Count( _LAMBDAPLAYERS_VoiceChannels ) >= talkLimit then return end

    local sndData = _LAMBDAPLAYERS_VoiceChannels[ ent ]
    if sndData then
        local prevSnd = sndData.Sound
        if IsValid( prevSnd ) then prevSnd:Stop() end
    end
    if LambdaRunHook( "LambdaOnPlaySound", ent, soundName ) == true then return end

    sound_PlayFile( "sound/" .. soundName, "noplay " .. ( is3d and "3d" or "" ), function( snd, errorId, errorName )
        if errorId == 21 then
            if stereowarn:GetBool() then print( "Lambda Players Voice Chat Warning: Sound file " ..soundName .. " has a stereo track and won't be played in 3d. Sound will continue to play. You can disable these warnings in Lambda Player>Utilities" ) end
            PlaySoundFile( ent, soundName, index, origin, delay, false )
            return
        elseif !IsValid( snd ) then
            print( "Lambda Players Voice Chat Error: Sound file " .. soundName .. " failed to open!\nError Index: " .. errorName .. "#" .. errorId )
            return
        end

        local sndLength = snd:GetLength()
        if sndLength <= 0 or !IsValid( ent ) or !ent.GetVoicePitch then
            snd:Stop()
            snd = nil
            return
        end

        local playTime = ( RealTime() + delay )
        sndData = _LAMBDAPLAYERS_VoiceChannels[ ent ]
        if sndData then
            local prevSnd = sndData.Sound
            if IsValid( prevSnd ) then prevSnd:Stop() end

            sndData.Sound = snd
            sndData.LastSndPos = origin
            sndData.Is3D = is3d
            sndData.PlayTime = playTime
        else
            _LAMBDAPLAYERS_VoiceChannels[ ent ] = {
                Sound = snd,
                LastSrcEnt = ent,
                LastSndPos = origin,
                Is3D = is3d,
                PlayTime = playTime,
                MouthMoveData = { 0, 0, RealTime() },

                LastPlayTime = 0,
                AlphaRatio = 0,
                FirstDisplayTime = 0,
                VoiceVolume = 0
            }
        end

        local playRate = ( ent:GetVoicePitch() / 100 )
        snd:SetPlaybackRate( playRate )
        snd:Set3DFadeDistance( voicedistance:GetInt(), 0 )

        net.Start( "lambdaplayers_server_sendsoundduration" )
            net.WriteEntity( ent )
            net.WriteFloat( ( sndLength / playRate ) + delay )
        net.SendToServer()

        local lambdaTeam, popupClr = ent:Team()
        if !baseTeams[ lambdaTeam ] then
            popupClr = team_GetColor( lambdaTeam )
        else
            popupClr = Color( voicePopupClrR:GetInt(), voicePopupClrG:GetInt(), voicePopupClrB:GetInt() )
        end

        local sndPopup = _LAMBDAPLAYERS_VoicePopups[ ent ]
        if sndPopup then
            sndPopup.Sound = snd
            sndPopup.Color = popupClr
        else
            _LAMBDAPLAYERS_VoicePopups[ ent ] = {
                Sound = snd,
                VoiceVolume = 0,
                Nick = ent:GetLambdaName(),
                ProfilePicture = ent:GetPFPMat(),
                AlphaRatio = 0,
                PlayTime = playTime,
                LastPlayTime = 0,
                FirstDisplayTime = 0,
                Color = popupClr
            }
        end
    end )
end

hook.Add( "PreDrawEffects", "lambdavc_voiceicons", function()
    for _, sndData in pairs( _LAMBDAPLAYERS_VoiceChannels ) do
        if sndData.PlayTime then continue end

        local ang = EyeAngles()
        ang:RotateAroundAxis( ang:Up(), -90 )
        ang:RotateAroundAxis( ang:Forward(), 90 )

        Start3D2D( ( sndData.LastSndPos + iconOffset ), ang, 1.0 )
            surface_SetDrawColor( 255, 255, 255 )
            surface_SetMaterial( voiceicon )
            surface_DrawTexturedRect( -8, -8, 16, 16 )
        End3D2D()
    end
end)

hook.Add( "Tick", "lambdavc_updatesounds", function()
    local voiceVolume = voicevolume:GetFloat()
    local voiceDist = voicedistance:GetInt()
    local isGlobal = globalvoice:GetBool()
    local curPos = EyePos()
    local curTime = RealTime()

    for ent, sndData in pairs( _LAMBDAPLAYERS_VoiceChannels ) do
        local snd = sndData.Sound
        local lastSrcEnt = sndData.LastSrcEnt
        local playTime = sndData.PlayTime

        if !IsValid( ent ) or !IsValid( snd ) or !playTime and snd:GetState() == GMOD_CHANNEL_STOPPED then
            if IsValid( snd ) then snd:Stop() end
            if IsValid( lastSrcEnt ) then lastSrcEnt:LambdaMoveMouth( 0 ) end
            if IsValid( ent ) then ent:SetVoiceLevel( 0 ) end

            _LAMBDAPLAYERS_VoiceChannels[ ent ] = nil
            continue
        end

        local srcEnt
        if ent:GetNoDraw() then
            srcEnt = ent.ragdoll
            if !IsValid( srcEnt ) then srcEnt = ent:GetNW2Entity( "lambda_serversideragdoll" ) end
        end
        if !IsValid( srcEnt ) then srcEnt = ent end

        if srcEnt != lastSrcEnt and IsValid( lastSrcEnt ) then
            lastSrcEnt:LambdaMoveMouth( 0 )
        end
        sndData.LastSrcEnt = srcEnt

        local leftC, rightC = snd:GetLevel()
        local voiceLvl = ( ( leftC + rightC ) / 2 )
        ent:SetVoiceLevel( voiceLvl )

        local lastPos = sndData.LastSndPos
        if !srcEnt:IsDormant() then
            lastPos = srcEnt:GetPos()
            sndData.LastSndPos = lastPos

            local mouthData = sndData.MouthMoveData
            if curTime >= mouthData[ 3 ] then
                mouthData[ 1 ] = 0
                mouthData[ 3 ] = ( curTime + 1 )
            elseif voiceLvl > mouthData[ 1 ] then
                mouthData[ 1 ] = voiceLvl
            end
            mouthData[ 2 ] = ( mouthData[ 1 ] <= 0.2 and mouthData[ 2 ] or ( voiceLvl / mouthData[ 1 ] ) )
            srcEnt:LambdaMoveMouth( mouthData[ 2 ] )
        end

        if ent.l_ismuted then
            snd:SetVolume( 0 )
        elseif isGlobal then
            snd:SetVolume( voiceVolume )
            snd:Set3DEnabled( false )
        else
            local sndVol = voiceVolume
            if !sndData.Is3D then
                sndVol = math_Clamp( sndVol / ( curPos:DistToSqr( lastPos ) / ( voiceDist * voiceDist ) ), 0, 1 )
                snd:Set3DEnabled( false )
            else
                snd:Set3DEnabled( true )
                snd:Set3DFadeDistance( voiceDist, 0 )
                snd:SetPos( lastPos )
            end

            snd:SetVolume( sndVol )
        end

        if playTime and RealTime() >= playTime then
            sndData.PlayTime = false
            snd:Play()
        end
    end
end )

net.Receive( "lambdaplayers_updatedata", function()
    LambdaPlayerNames = LAMBDAFS:GetNameTable()
    LambdaPlayerProps = LAMBDAFS:GetPropTable()
    LambdaPlayerMaterials = LAMBDAFS:GetMaterialTable()
    Lambdaprofilepictures = LAMBDAFS:GetProfilePictures()
    LambdaVoiceLinesTable = LAMBDAFS:GetVoiceLinesTable()
    LambdaVoiceProfiles = LAMBDAFS:GetVoiceProfiles()
    LambdaPlayerSprays = LAMBDAFS:GetSprays()
    LambdaTextTable = LAMBDAFS:GetTextTable()
    LambdaTextProfiles = LAMBDAFS:GetTextProfiles()
    LambdaPersonalProfiles = file.Exists( "lambdaplayers/profiles.json", "DATA" ) and LAMBDAFS:ReadFile( "lambdaplayers/profiles.json", "json" ) or nil
    LambdaModelVoiceProfiles = LAMBDAFS:GetModelVoiceProfiles()
    LambdaPlayermodelBodySkinSets = LAMBDAFS:GetPlayermodelBodySkinSets()
    LambdaQuickNades = LAMBDAFS:GetQuickNadeWeapons()
    LambdaEntsToFearFrom = LAMBDAFS:GetEntsToFearFrom()

    chat.AddText( "Lambda Data was updated by the Server" )
end )

net.Receive( "lambdaplayers_playsoundfile", function()
    local lambda = net.ReadEntity()
    if !IsValid( lambda ) then return end

    local sendState = net.ReadBool()
    if !lambda.GetIsDead or !lambda:GetIsDead() != sendState then return end

    PlaySoundFile( lambda, net.ReadString(), net.ReadUInt( 32 ), net.ReadVector(), net.ReadFloat(), true )
end )

net.Receive( "lambdaplayers_stopcurrentsound", function()
    local ent = net.ReadEntity()
    if !IsValid( ent ) then return end

    local sndData = _LAMBDAPLAYERS_VoiceChannels[ ent ]
    if !sndData then return end

    local snd = sndData.Sound
    if IsValid( snd ) then snd:Stop() end
end )

-- Mfw networking:
local function SafelySetNetworkVar( ent, name, var )
    local func = ent[ "Set" .. name ]
    if func then func( ent, var ) end
end

net.Receive( "lambdaplayers_updatecsstatus", function()
    local lambda = net.ReadEntity()
    if !IsValid( lambda ) then return end

    local hasDied = net.ReadBool()
    if !hasDied then
        if removeCorpse:GetBool() then
            local ragdoll = lambda.ragdoll
            if IsValid( ragdoll ) then
                if cleaneffect:GetBool() then
                    ragdoll:LambdaDisintegrate()
                else
                    ragdoll:Remove()
                end
            end

            local cs_prop = lambda.cs_prop
            if IsValid( cs_prop ) then
                if cleaneffect:GetBool() then
                    cs_prop:LambdaDisintegrate()
                else
                    cs_prop:Remove()
                end
            end
        end

        lambda.ragdoll = nil
        lambda.cs_prop = nil
    end

    SafelySetNetworkVar( lambda, "IsDead", hasDied )
    SafelySetNetworkVar( lambda, "Frags", net.ReadInt( 11 ) )
    SafelySetNetworkVar( lambda, "Deaths", net.ReadInt( 11 ) )

    local sndData = _LAMBDAPLAYERS_VoiceChannels[ lambda ]
    if sndData then sndData.LastSndPos = net.ReadVector() end
end )

net.Receive( "lambdaplayers_setnodraw", function()
    local ent = net.ReadEntity()
    if !IsValid( ent ) then return end

    local bool = net.ReadBool()
    ent:SetNoDraw( bool or false )
    ent:DrawShadow( !bool or true )
end )


net.Receive( "lambdaplayers_notification", function()
    notification_AddLegacy( net.ReadString(), net.ReadUInt( 3 ), 3 )

    local snd = net.ReadString()
    if snd then surface_PlaySound( snd ) end
end )

-- Because JSON to table doesn't give colors their proper meta table for some reason, we must do this.
-- This fixes other chat addons not setting the Lambda's color properly
local function RestoreColorMetas( tbl )
    local clrMeta = FindMetaTable( "Color" )
    for _, v in ipairs( tbl ) do
        if !istable( v ) or !v.r or !v.g or !v.b then continue end
        setmetatable( v, clrMeta  )
    end
end

local unpack = unpack
local JSONToTable = util.JSONToTable
net.Receive( "lambdaplayers_chatadd", function()
    local args = net.ReadString()
    args = JSONToTable( args )
    RestoreColorMetas( args )

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
local framerateconvar = GetConVar( "lambdaplayers_animatedpfpsprayframerate" )
_LambdaMaterialSprayIndexes = ( _LambdaMaterialSprayIndexes or 0 )

local function Spray( spraypath, tracehitpos, tracehitnormal, attemptedfallback )
    local material

    -- The file is a Valve Texture Format ( VTF )
    if EndsWith( spraypath, ".vtf" ) then
        material = CreateMaterial( "lambdasprayVTFmaterial" .. _LambdaMaterialSprayIndexes, "LightmappedGeneric", {
            [ "$basetexture" ] = spraypath,
            [ "$translucent" ] = 1, -- Some VTFs are translucent
            [ "Proxies" ] = {
                [ "AnimatedTexture" ] = { -- Support for Animated VTFs
                    [ "animatedTextureVar" ] = "$basetexture",
                    [ "animatedTextureFrameNumVar" ] = "$frame",
                    [ "animatedTextureFrameRate" ] = framerateconvar:GetInt()
                }
            }
        })

        _LambdaMaterialSprayIndexes = ( _LambdaMaterialSprayIndexes + 1 )
    else -- The file is a PNG or JPG
        material = Material( spraypath )
    end

    -- If we failed to load the Server's spray, try one of our own sprays and hope it works. If it does not work, give up and don't spray anything.
    if !material or material:IsError() then
        if !attemptedfallback then
            Spray( LambdaPlayerSprays[ LambdaRNG( #LambdaPlayerSprays ) ], tracehitpos, tracehitnormal, true )
        end
        return
    end

    local texWidth = material:Width()
    local texHeight = material:Height()

    -- Sizing the Spray
    local widthPower = 256
    local heightPower = 256
    if texWidth > texHeight then
        heightPower = 128
    elseif texHeight > texWidth then
        widthPower = 128
    end
    if texWidth < 256 then
        texWidth = ( texWidth / 256 )
    else
        texWidth = ( widthPower / ( texWidth * 4 ) )
    end
    if texHeight < 256 then
        texHeight = ( texHeight / 256 )
    else
        texHeight = ( heightPower / ( texHeight * 4) )
    end

    -- Place the spray
    DecalEx( material, Entity( 0 ), tracehitpos, tracehitnormal, color_white, texWidth, texHeight)

end

net.Receive( "lambdaplayers_spray", function()
    local spraypath = net.ReadString()
    local tracehitpos = net.ReadVector()
    local tracehitnormal = net.ReadNormal()
    Spray( spraypath, tracehitpos, tracehitnormal )
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

local color_client = Color( 255, 145, 0 )
local RunConsoleCommand = RunConsoleCommand

net.Receive( "lambdaplayers_reloadaddon", function()
    LambdaReloadAddon()
    chat.AddText( color_client, "Reloaded all Lambda Lua Files for your Client" )
    RunConsoleCommand( "spawnmenu_reload" )
end )

net.Receive( "lambdaplayers_mergeweapons", function()
    LambdaMergeWeapons()
    chat.AddText( color_client, "Merged all Lambda Weapon Lua Files for your Client" )
    RunConsoleCommand( "spawnmenu_reload" )
end )

local render_Capture = render.Capture
local game_GetMap = game.GetMap
local os_date = os.date
local viewshotTbl = { drawviewer = true }
local captureTbl = { x = 0, y = 0, alpha = false }
local vector_fullscale = Vector( 1, 1, 1 )

local allowShots = GetConVar( "lambdaplayers_viewshots_allowforyou" )
local viewFOV = GetConVar( "lambdaplayers_viewshots_viewfov" )
local saveAsPng = GetConVar( "lambdaplayers_viewshots_saveaspng" )

_LambdaIsTakingViewShot = _LambdaIsTakingViewShot or false
file.CreateDir( "lambdaplayers/viewshots" )

local function DrawEntityBones( ent, parent, draw )
    ent:ManipulateBoneScale( parent, draw and vector_fullscale or vector_origin )

    for _, child in ipairs( ent:GetChildBones( parent ) ) do
        DrawEntityBones( ent, child, draw )
    end
end

net.Receive( "lambdaplayers_takeviewshot", function()
    if !allowShots:GetBool() then return end

    local lambda = net.ReadEntity()
    if !IsValid( lambda ) then return end

    local shotPos = net.ReadVector()
    local shotAng = net.ReadAngle()
    local lambdaCorpse = nil

    local headBone = lambda:LookupBone( "ValveBiped.Bip01_Head1" )
    if headBone then DrawEntityBones( lambda, headBone, false ) end

    _LambdaIsTakingViewShot = true

    lambda:Hook( "CalcView", "ViewShotCalcView", function()
        local origin = ( !shotPos:IsZero() and shotPos )
        local angles = ( !shotAng:IsZero() and shotAng )

        local ragdoll = lambda:GetRagdollEntity()
        if lambda:GetIsDead() and IsValid( ragdoll ) then
            local eyes = lambda:GetAttachmentPoint( "eyes", ragdoll )
            origin = ( origin or eyes.Pos )
            angles = ( angles or eyes.Ang )

            lambdaCorpse = ragdoll
            if headBone then DrawEntityBones( ragdoll, headBone, false ) end
        else
            lambdaCorpse = nil
            origin = ( origin or lambda:EyePos() )
            angles = ( angles or lambda:EyeAngles() )
        end

        viewshotTbl.origin = origin
        viewshotTbl.angles = angles
        viewshotTbl.fov = viewFOV:GetInt()
        return viewshotTbl
    end, true )

    local function EndViewShotting()
        _LambdaIsTakingViewShot = false
        lambda:RemoveHook( "CalcView", "ViewShotCalcView" )
        lambda:RemoveHook( "OnEntityRemoved", "ViewShotRemoveFailSafe" )
        return "end"
    end
    lambda:Hook( "OnEntityRemoved", "ViewShotRemoveFailSafe", EndViewShotting )

    lambda:Hook( "PreDrawHUD", "ViewShotRenderCapture", function()
        captureTbl.w = ScrW()
        captureTbl.h = ScrH()

        local format = ( saveAsPng:GetBool() and "png" or "jpg" )
        captureTbl.format = format

        local rndMiliSec = LambdaRNG( 1, 99 )
        if rndMiliSec < 10 then rndMiliSec = "0" .. rndMiliSec end

        local fileName = game_GetMap() .. "_" .. os_date( "%Y-%m-%d_%H-%M-%S" ) .. "-" .. rndMiliSec .. "." .. format
        LAMBDAFS:WriteFile( "lambdaplayers/viewshots/" .. fileName, render_Capture( captureTbl ), "binary" )

        if headBone then
            DrawEntityBones( lambda, headBone, true )
            if IsValid( lambdaCorpse ) then DrawEntityBones( lambdaCorpse, headBone, true ) end
        end
        return EndViewShotting()
    end, true )
end )