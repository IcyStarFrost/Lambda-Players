local CurTime = CurTime
local IsValid = IsValid
local ipairs = ipairs
local table_remove = table.remove
local RealTime = RealTime
local isnumber = isnumber
local isfunction = isfunction
local LambdaScreenScale = LambdaScreenScale
local Left = string.Left
local match = string.match
local gmatch = string.gmatch
local RunString = RunString
local ScrW = ScrW
local ScrH = ScrH
local IsValidRagdoll = util.IsValidRagdoll
local invisClr = Color( 0, 0, 0, 0 )

if SERVER then

    local wepDmgScalePlys = GetConVar( "lambdaplayers_combat_weapondmgmultiplier_players" )
    local wepDmgScaleLambdas = GetConVar( "lambdaplayers_combat_weapondmgmultiplier_lambdas" )
    local wepDmgScaleMisc = GetConVar( "lambdaplayers_combat_weapondmgmultiplier_misc" )

    function LambdaGetWeaponDamageScale( target )
        if target.IsLambdaPlayer then return wepDmgScaleLambdas:GetFloat() end
        if target:IsPlayer() then return wepDmgScalePlys:GetFloat() end
        return wepDmgScaleMisc:GetFloat()
    end

    -- God mode simple stuff
    hook.Add( "EntityTakeDamage", "LambdaMainDamageHook", function( ent, dmginfo )
        if ent.l_godmode then return true end
        
        if ent.IsLambdaPlayer then
            local lastDmg = ent.l_lastdamage
            if lastDmg and ( lastDmg / 4 ) == dmginfo:GetDamage() then
                dmginfo:ScaleDamage( 4 )
            end
        end

        local inflictor = dmginfo:GetInflictor()
        if IsValid( inflictor ) and ( inflictor.IsLambdaWeapon or inflictor.l_UseLambdaDmgModifier ) then
            dmginfo:ScaleDamage( LambdaGetWeaponDamageScale( ent ) )
        end
    end )

    -- Updates the map's spawn points when we clean the map
    hook.Add( "PostCleanupMap", "LambdaResetSpawnPoints", function()
        LambdaSpawnPoints = LambdaGetPossibleSpawns()
    end )

    -- So the client knows if the player is the host or not
    hook.Add("PlayerInitialSpawn", "Lambdasetserverhost", function( ply )
        if ply:IsListenServerHost() then ply:SetNW2Bool( "lambda_serverhost", true ) end
        
        LambdaGetPlayerBirthday( ply, function( ply, month, day )
            _LambdaPlayerBirthdays[ ply:SteamID() ] = { month = month, day = day } 
        end )
    end )
    
    -- Fixes ReAgdoll throwing errors when a ragdoll doesn't have bones it need to use (like head)
    hook.Add( "OnEntityCreated", "LambdaOnEntityCreated", function( ent )
        if !IsValid( ent ) then return end

        local class = ent:GetClass() 
        if class == "lua_run" then
            function ent:RunCode( activator, caller, code )
                self:SetupGlobals( activator, caller )
                    if activator.IsLambdaPlayer then
                        for funcName in gmatch( code, "[%TRIGGER_PLAYER%ACTIVATOR]:([%w_]+)" ) do
                            if !isfunction( activator[ funcName ] ) then self:KillGlobals() return end
                        end
                    end
                    if caller.IsLambdaPlayer then
                        for funcName in gmatch( code, "CALLER:([%w_]+)" ) do
                            if !isfunction( caller[ funcName ] ) then self:KillGlobals() return end
                        end
                    end

                    RunString( code, "lua_run#" .. self:EntIndex() )
                self:KillGlobals()
            end

            function ent:SetupGlobals( activator, caller )
                ACTIVATOR = activator
                CALLER = caller

                if IsValid( activator ) && ( activator.IsLambdaPlayer or activator:IsPlayer() ) then
                    TRIGGER_PLAYER = activator
                end
            end
        end
    end )

    local specialkeywords = { 
        "|birthday|", 
        "|christmas|",
        "|newyears|",
        "|addonbirthday|",
        "|thanksgiving|",
        "|4thjuly|",
        "|easter|"
    }

    local function GetSpecialDayLine()
        local tbl = LambdaTextTable[ "idle" ]
        if !tbl then return end
        local speciallines = {}

        for k, str in ipairs( tbl ) do
            for i = 1, #specialkeywords do 
                local keyword = specialkeywords[ i ]
                if string.find( str, keyword ) and LambdaConditionalKeyWordCheck( nil, str ) then 
                    speciallines[ #speciallines + 1 ] = str
                end
            end
        end
        return speciallines[ math.random( #speciallines ) ]
    end
    
    hook.Add( "LambdaOnStartTyping", "LambdaSpecialDaytext", function( lambda, text, texttype )
        if texttype != "idle" or math.random( 0, 100 ) > 10 then return end

        local line = GetSpecialDayLine()

        if !line then return end

        return line
    end )

elseif CLIENT then
    
    local DrawText = draw.DrawText
    local tostring = tostring
    local uiscale = GetConVar( "lambdaplayers_uiscale" )
    local IsSinglePlayer = game.SinglePlayer()
    local input_LookupBinding = input.LookupBinding
    local input_GetKeyCode = input.GetKeyCode
    local input_IsKeyDown = input.IsKeyDown

    local displayArmor = GetConVar( "lambdaplayers_displayarmor" )

    -- The little name and health display when you look at Lambdas
    hook.Add( "HUDPaint", "LambdaPlayers_NameDisplay", function()
        local sw, sh = ScrW(), ScrH()
        local traceent = LocalPlayer():GetEyeTrace().Entity

        if LambdaIsValid( traceent ) and traceent.IsLambdaPlayer then
            local result = LambdaRunHook( "LambdaShowNameDisplay", traceent )
            if result == false then return end

            local name = traceent:GetLambdaName()
            local color = traceent:GetDisplayColor()
            local hp = traceent:GetNW2Float( "lambda_health", "NAN" )
            local hpW = 2
            local armor = traceent:GetArmor()
            hp = hp == "NAN" and traceent:GetNWFloat( "lambda_health", "NAN" ) or hp

            if armor > 0 and displayArmor:GetBool() then
                hpW = 2.1
                DrawText( tostring( armor ) .. "%", "lambdaplayers_healthfont", ( sw / 1.9 ), ( sh / 1.87 ) + LambdaScreenScale( 1 + uiscale:GetFloat() ), color, TEXT_ALIGN_CENTER)
            end

            DrawText( name, "lambdaplayers_displayname", ( sw / 2 ), ( sh / 1.95 ) , color, TEXT_ALIGN_CENTER )
            DrawText( tostring( hp ) .. "%", "lambdaplayers_healthfont", ( sw / hpW ), ( sh / 1.87 ) + LambdaScreenScale( 1 + uiscale:GetFloat() ), color, TEXT_ALIGN_CENTER)
        end
    
    end )


    -- Since Singleplayer prevents normal use of the Voice Chat bind, we force it on with this
    if IsSinglePlayer then
        local limit = false -- This is important so code doesn't run constantly
        hook.Add( "Think", "lambdaplayers_forceenablevoicechat", function()
            local vcbind = input_LookupBinding( "+voicerecord" )
            local bindenum = vcbind and input_GetKeyCode( vcbind ) or KEY_X
        
            if input_IsKeyDown( bindenum ) and !limit then
                limit = true
                GAMEMODE:PlayerStartVoice( LocalPlayer() )
            elseif !input_IsKeyDown( bindenum ) and limit then
                limit = false
                GAMEMODE:PlayerEndVoice( LocalPlayer() )
                net.Start( "lambdaplayers_realplayerendvoice", true )
                net.SendToServer()
            end
        end )
    end

    local table_Empty = table.Empty
    local max = math.max
    local ispanel = ispanel
    local surface_SetFont = surface.SetFont
    local surface_GetTextSize = surface.GetTextSize
    local surface_SetDrawColor = surface.SetDrawColor
    local surface_SetMaterial = surface.SetMaterial
    local DrawTexturedRect = surface.DrawTexturedRect
    local sub = string.sub
    local SortedPairsByMemberValue = SortedPairsByMemberValue
    local allowpopups = GetConVar( "lambdaplayers_voice_voicepopups" )
    local voicepopupx = GetConVar( "lambdaplayers_voice_voicepopupoffset_x" )
    local voicepopupy = GetConVar( "lambdaplayers_voice_voicepopupoffset_y" )

    local popupBaseColor = Color( 255, 255, 255, 255 )
    local popupVolColor = Color( 0, 255, 0, 240 )
    local drawPopupIndexes = {}

    -- This handles the rendering of the Voice Popups to the right side 
    hook.Add( "HUDPaint", "LambdaPlayers_DrawVoicePopups", function()
        if !allowpopups:GetBool() then return end

        local realTime = RealTime()
        local timeOffset = 0
        local canDrawSomething = false
        table_Empty( drawPopupIndexes )

        for lambda, vcData in SortedPairsByMemberValue( _LAMBDAPLAYERS_VoicePopups, "FirstDisplayTime" ) do
            local playTime = vcData.PlayTime
            if playTime then
                if realTime >= playTime then
                    vcData.PlayTime = false
                else
                    continue
                end
            end
            
            local sndVol = 0
            local snd = vcData.Sound
            local lastPlayTime = vcData.LastPlayTime
            if IsValid( snd ) and snd:GetState() == GMOD_CHANNEL_PLAYING then
                local leftChan, rightChan = snd:GetLevel()
                sndVol = ( ( leftChan + rightChan ) * 0.5 )
    
                vcData.LastPlayTime = realTime
                if vcData.FirstDisplayTime == 0 then
                    vcData.FirstDisplayTime = ( realTime + timeOffset )
                    timeOffset = ( timeOffset + 0.1 )
                end 
            end
            vcData.VoiceVolume = sndVol

            local drawAlpha = max( 0, 1 - ( ( realTime - vcData.LastPlayTime ) / 2 ) )
            if !IsValid( snd ) and drawAlpha == 0 then 
                _LAMBDAPLAYERS_VoicePopups[ lambda ] = nil
                continue 
            end
    
            vcData.AlphaRatio = drawAlpha
            if drawAlpha == 0 then
                vcData.FirstDisplayTime = 0
                continue 
            end
    
            canDrawSomething = true
            drawPopupIndexes[ lambda ] = vcData
        end

        if !canDrawSomething then return end
        local drawX, drawY = ( ScrW() - 298 + voicepopupx:GetInt() ), ( ScrH() - 142 + voicepopupy:GetInt() )
    
        local plyPopups = g_VoicePanelList
        if ispanel( plyPopups ) then drawY = ( drawY - ( 44 * #plyPopups:GetChildren() ) ) end

        local popupIndex = 0
        surface_SetFont( "GModNotify" )

        for lambda, vcData in SortedPairsByMemberValue( drawPopupIndexes, "FirstDisplayTime" ) do
            local drawAlpha = vcData.AlphaRatio
            popupBaseColor.a = ( drawAlpha * 255 )
    
            local vol = ( vcData.VoiceVolume * drawAlpha )
            local vcClr = vcData.Color
            popupVolColor.r = ( vol * vcClr.r )
            popupVolColor.g = ( vol * vcClr.g )
            popupVolColor.b = ( vol * vcClr.b )

            popupVolColor.a = ( drawAlpha * 240 )
            draw.RoundedBox( 4, drawX, drawY, 246, 40, popupVolColor )
            
            surface_SetDrawColor( popupBaseColor )
            surface_SetMaterial( vcData.ProfilePicture )
            DrawTexturedRect( drawX + 4, drawY + 4, 32, 32 )
    
            local nickname = vcData.Nick
            local textWidth = surface_GetTextSize( nickname )
            if textWidth > 200 then
                nickname = sub( nickname, 0, ( ( #nickname * ( 202.5 / textWidth ) ) - 3 ) ) .. "..."
            end
            DrawText( nickname, "GModNotify", drawX + 43.5, drawY + 9, popupBaseColor, TEXT_ALIGN_LEFT )

            drawY = ( drawY - 44 )
            popupIndex = ( popupIndex + 1 )
        end
    end )


    -- Removes ragdolls that are were created while not drawn in clientside
    hook.Add( "PreCleanupMap", "LambdaPlayers_OnPreCleanupMap", function()
        for _, v in ipairs( _LAMBDAPLAYERS_ClientSideRagdolls ) do
            if IsValid( v ) then v:Remove() end
        end
    end )

end