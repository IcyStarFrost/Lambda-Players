
local IsValid = IsValid
local ipairs = ipairs
local table_remove = table.remove
local RealTime = RealTime
local LambdaScreenScale = LambdaScreenScale
local Left = string.Left

if SERVER then

    local wepDmgScale = GetConVar( "lambdaplayers_combat_weapondmgmultiplier" )

    hook.Add( "ScalePlayerDamage", "LambdaScalePlayerDamage", function( ply, hit, dmginfo )
        if !ply.IsLambdaPlayer then return end
        ply.l_lasthitgroup = hit
        ply.l_lastdamage = dmginfo:GetDamage()
    end )

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
        if IsValid( inflictor ) and inflictor.IsLambdaWeapon then
            dmginfo:ScaleDamage( wepDmgScale:GetFloat() )
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


    -- Zeta's old voice pop up
--[[     local function LegacyVoicePopUp( x, y, name, icon, volume, alpha )
        if #name > 17 then name = Left( name, 17 ) .. "..." end

        local popupColor = Color(0, 255 * volume, 0, alpha )
        draw.RoundedBox(4, x, y, 230, 50, popupColor)
        surface.SetDrawColor( Color(255, 255, 255, alpha ) )
        surface.SetMaterial( icon )
        surface.DrawTexturedRect(x + 5, y + 9, 32, 32)
        draw.DrawText( name, "lambdaplayers_voicepopuptext", x + 40, y + 12, Color( 255, 255, 255, alpha ), TEXT_ALIGN_LEFT )
    end ]]

    local draw_RoundedBox = draw.RoundedBox
    local surface_SetDrawColor = surface.SetDrawColor
    local surface_SetMaterial = surface.SetMaterial
    local surface_DrawTexturedRect = surface.DrawTexturedRect
    local draw_DrawText = draw.DrawText
    local allowpopups = GetConVar( "lambdaplayers_voice_voicepopups" )
    local voicepopupx = GetConVar( "lambdaplayers_voice_voicepopupxpos" )
    local voicepopupy = GetConVar( "lambdaplayers_voice_voicepopupypos" )
    local usegmodpopups = GetConVar( "lambdaplayers_voice_usegmodvoicepopups" )

    -- Lambda's newer and accurate Voice Pop up
    local function LambdaVoicePopUp( x, y, name, icon, volume, alpha )
        if #name > 20 + uiscale:GetFloat() then name = Left( name, 20 + uiscale:GetFloat() ) .. "..." end
        
        local popupColor = Color(0, 255 * volume, 0, alpha )
        draw_RoundedBox(4, x - 24, y, LambdaScreenScale( 83.5 + uiscale:GetFloat() ), LambdaScreenScale( 13.5 + uiscale:GetFloat() ), popupColor)
        surface_SetDrawColor( Color(255, 255, 255, alpha ) )
        surface_SetMaterial( icon )
        surface_DrawTexturedRect(x - 19, y + 5, LambdaScreenScale( 11 + uiscale:GetFloat() ), LambdaScreenScale( 11 + uiscale:GetFloat() ))
        draw_DrawText( name, "lambdaplayers_voicepopuptext", x + LambdaScreenScale( 9 + uiscale:GetFloat() ), y + 10, Color( 255, 255, 255, alpha ), TEXT_ALIGN_LEFT )
    end


    -- This handles the rendering of the Voice Popups to the right side 
    hook.Add( "HUDPaint", "lambdaplayervoicepopup", function()
        if !allowpopups:GetBool() or usegmodpopups:GetBool() then return end

        for k, v in ipairs( _LAMBDAPLAYERS_Voicechannels ) do
            local w, h = ScrW(), ScrH()
            local x, y = ( w - voicepopupx:GetInt() ), ( h - voicepopupy:GetInt() )
            y = y + ( k*-LambdaScreenScale( 17 + uiscale:GetFloat() ) )

            v[ "alpha" ] = v[ "alpha" ] or 245

            local volume = 0
            local invalid = false
            local snd = v[ 1 ]
            local name, icon, length = v[ 2 ], v[ 3 ], RealTime() + v[ 4 ]
            if !IsValid( snd ) or snd:GetState() == GMOD_CHANNEL_STOPPED then
                invalid = true
            else 
                local l, r = snd:GetLevel()
                volume = l + r
            end

            if RealTime() > length or invalid then
                v[ "alpha" ] = v[ "alpha" ] - 1
            end

            if v[ "alpha" ] <= 0 then
                table_remove( _LAMBDAPLAYERS_Voicechannels, k )
            else

                LambdaVoicePopUp( x, y, name, icon, volume, v[ "alpha" ] ) -- Call the voice pop up function

            end
        end
    end )

    -- Removes ragdolls that are were created while not drawn in clientside
    hook.Add( "PreCleanupMap", "LambdaPlayers_OnPreCleanupMap", function()
        for _, v in ipairs( _LAMBDAPLAYERS_ClientSideRagdolls ) do
            if IsValid( v ) then v:Remove() end
        end
    end )

end