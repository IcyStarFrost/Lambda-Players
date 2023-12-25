
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local GetConVar = GetConVar
local table_insert = table.insert
local clientcolor = Color( 255, 145, 0 )
local servercolor = Color( 0, 174, 255 )
local net = net
local IsSinglePlayer = game.SinglePlayer
local RunConsoleCommand = RunConsoleCommand
local LocalPlayer = LocalPlayer

local epiccontributors = [[

-- Contributors On GitHub --
Special thanks to the following Contributors

:- CombineSlayer24
:- Fluffiest Floofers
:- YerMash

Your contributions are appreciated!
]]

local function CreateUrlLabel( text, url, parent, dock )
    local panel = vgui.Create( "DLabelURL", parent )
    panel:SetText( text )
    panel:SetURL( url )
    panel:Dock( dock )
    return panel
end

-- In dedicated servers, you can not change settings via the spawn menu. This function fixes that by allowing Super Admins to edit the Server's setting convars. 
-- Better than using the server console
local function InstallMPConVarHandling( PANEL, convar, paneltype, isserverside )
    if paneltype == "Bool" then
        function PANEL:OnChange( val )
            if IsSinglePlayer() or !isserverside then
                RunConsoleCommand( convar, val and "1" or "0" )
            elseif LocalPlayer():IsSuperAdmin() then
                net.Start( "lambdaplayers_updateconvar" )
                    net.WriteString( convar )
                    net.WriteString( val and "1" or "0" )
                net.SendToServer()
            else
                chat.AddText( "Only Super Admins can change Server-Side settings!" )
            end
        end
    elseif paneltype == "Text" then 
        function PANEL:OnChange()
            local val = self:GetText()

            if IsSinglePlayer() or !isserverside then
                RunConsoleCommand( convar, val )
            elseif LocalPlayer():IsSuperAdmin() then
                net.Start( "lambdaplayers_updateconvar" )
                    net.WriteString( convar )
                    net.WriteString( val )
                net.SendToServer()
            else
                chat.AddText( "Only Super Admins can change Server-Side settings!" )
            end
        end
    elseif paneltype == "Slider" then 
        function PANEL:OnValueChanged( val )
            if IsSinglePlayer() or !isserverside then
                RunConsoleCommand( convar, tostring( val ) )
            elseif LocalPlayer():IsSuperAdmin() then
                net.Start( "lambdaplayers_updateconvar" )
                    net.WriteString( convar )
                    net.WriteString( tostring( val ) )
                net.SendToServer()
            else
                chat.AddText( "Only Super Admins can change Server-Side settings!" )
            end
        end
    elseif paneltype == "Color" then 
        function PANEL:ValueChanged( col )
            local rvar = self:GetConVarR()
            local gvar = self:GetConVarG()
            local bvar = self:GetConVarB()

            if IsSinglePlayer() or !isserverside then
                RunConsoleCommand( rvar, tostring( col.r ) )
                RunConsoleCommand( gvar, tostring( col.g ) )
                RunConsoleCommand( bvar, tostring( col.b ) )
            elseif LocalPlayer():IsSuperAdmin() then
                net.Start( "lambdaplayers_updateconvar" )
                    net.WriteString( rvar )
                    net.WriteString( tostring( col.r ) )
                net.SendToServer()

                net.Start( "lambdaplayers_updateconvar" )
                    net.WriteString( gvar )
                    net.WriteString( tostring( col.g ) )
                net.SendToServer()

                net.Start( "lambdaplayers_updateconvar" )
                    net.WriteString( bvar )
                    net.WriteString( tostring( col.b ) )
                net.SendToServer()
            else
                chat.AddText( "Only Super Admins can change Server-Side settings!" )
            end
        end
    elseif paneltype == "Combo" then 
        function PANEL:OnSelect( index, val, data )
            if IsSinglePlayer() or !isserverside then
                RunConsoleCommand( convar, tostring( data ) )
            elseif LocalPlayer():IsSuperAdmin() then
                net.Start( "lambdaplayers_updateconvar" )
                    net.WriteString( convar )
                    net.WriteString( tostring( data ) )
                net.SendToServer()
            else
                chat.AddText( "Only Super Admins can change Server-Side settings!" )
            end
        end
    elseif paneltype == "Button" then 
        function PANEL:DoClick()
            if IsSinglePlayer() or !isserverside then
                RunConsoleCommand( convar )
            elseif LocalPlayer():IsSuperAdmin() then
                net.Start( "lambdaplayers_runconcommand" )
                    net.WriteString( convar )
                net.SendToServer()
            else
                chat.AddText( "Only Super Admins can run Server-Side Console Commands!" )
            end
        end
    end
end

local function AddLambdaPlayersOptions()
    local categories = {}
    for _, v in ipairs( _LAMBDAConVarSettings ) do -- See convars.lua 
        categories[ v.category ] = v.category
    end

    -- Credits and Infooooo
    spawnmenu.AddToolMenuOption( "Lambda Player", "Lambda Player", "lambdaplayer_credits" , "About, Credits, info", "", "", function( panel ) 
        local lambdaplayers = panel:Help( "   -- Lambda Players --" )
        lambdaplayers:SetColor( clientcolor ) 

        local starrrrr = panel:Help( "-- Created By StarFrost --" )
        starrrrr:SetColor( servercolor )

        -- Contributor thanks!
        local contributors = panel:Help( epiccontributors )
        contributors:SetColor( servercolor )

        local bugreporterVois = panel:Help( "Special thanks to all those who play tested Lambda Players and reported bugs!" )
        bugreporterVois:SetColor( servercolor )

        panel:Help( "\n-- Links --" )
        CreateUrlLabel( "Lambda Players GitHub", "https://github.com/IcyStarFrost/Lambda-Players", panel, TOP ) -- GitHub
        CreateUrlLabel( "StarFrost's YouTube Channel", "https://www.youtube.com/channel/UCu_7jXrDackiI85ABzd0CKA", panel, TOP ) -- Star's Youtube
        CreateUrlLabel( "Learn how to add Custom Content to Lambda Players and develop for Lambda Players", "https://github.com/IcyStarFrost/Lambda-Players/wiki", panel, TOP ) -- Wiki
    end )

    for categoryname, _ in pairs( categories ) do
        spawnmenu.AddToolMenuOption( "Lambda Player", "Lambda Player", "lambdaplayer_" .. categoryname , categoryname, "", "", function( panel ) 
            local clientList, foundCls = {}
            local serverList, foundSvs = {}
            for _, v in ipairs( _LAMBDAConVarSettings ) do
                if v.category != categoryname then continue end
                local isClient = v.isclient
                local tbl = ( isClient and clientList or serverList )
                
                if v.type == "Color" then
                    local clrCvar = v.red
                    tbl[ clrCvar ] = GetConVar( clrCvar ):GetDefault()

                    clrCvar = v.green
                    tbl[ clrCvar ] = GetConVar( clrCvar ):GetDefault()
                    
                    clrCvar = v.blue
                    tbl[ clrCvar ] = GetConVar( clrCvar ):GetDefault()

                    continue
                end

                local cvarName = v.convar
                if !cvarName then continue end
                tbl[ cvarName ] = GetConVar( cvarName ):GetDefault()

                if isClient then
                    foundCls = true
                else
                    foundSvs = true
                end
            end
            
            if foundCls then
                panel:ToolPresets( "lambdaclientcvarpreset_" .. categoryname, clientList )
                local clPresetInfo = panel:ControlHelp( "Client (User) Preset:" )
                clPresetInfo:SetColor( clientcolor )
            end

            if foundSvs then
                panel:ToolPresets( "lambdaservercvarpreset_" .. categoryname, serverList )
                local svPresetInfo = panel:ControlHelp( "Server (Admin) Preset:" )
                svPresetInfo:SetColor( servercolor )
            end

            for _, v in ipairs( _LAMBDAConVarSettings ) do
                if v.category != categoryname then continue end
                if v.type == "Slider" then
                    local slider = panel:NumSlider( v.name, v.convar, v.min, v.max, v.decimals or 2 )
                    
                    local lbl = panel:ControlHelp( v.desc .. "\nDefault Value: " .. v.default )
                    lbl:SetColor( v.isclient and clientcolor or servercolor )

                    InstallMPConVarHandling( slider, v.convar, "Slider", !v.isclient )
                elseif v.type == "Bool" then
                    local checkbox = panel:CheckBox( v.name, v.convar )

                    local lbl = panel:ControlHelp( v.desc .. "\nDefault Value: " .. ( v.default == 1 and "True" or "False") )
                    lbl:SetColor( v.isclient and clientcolor or servercolor )

                    InstallMPConVarHandling( checkbox, v.convar, "Bool", !v.isclient )
                elseif v.type == "Text" then
                    local textentry = panel:TextEntry( v.name, v.convar )
                    
                    local lbl = panel:ControlHelp( v.desc .. "\nDefault Value: " .. v.default )
                    lbl:SetColor( v.isclient and clientcolor or servercolor )

                    InstallMPConVarHandling( textentry, v.convar, "Text", !v.isclient )
                elseif v.type == "Button" then
                    local button = panel:Button( v.name, v.concmd )

                    local lbl = panel:ControlHelp( v.desc )
                    lbl:SetColor( v.isclient and clientcolor or servercolor )
                    
                    InstallMPConVarHandling( button, v.concmd, "Button", !v.isclient )
                elseif v.type == "Combo" then
                    local combo = panel:ComboBox( v.name, v.convar )
                    for k, j in pairs( v.options ) do
                        combo:AddChoice( k, j )
                    end

                    local lbl = panel:ControlHelp( v.desc .. "\nDefault Value: " .. v.default )
                    lbl:SetColor( v.isclient and clientcolor or servercolor )

                    InstallMPConVarHandling( combo, v.convar, "Combo", !v.isclient )
                elseif v.type == "Color" then
                    panel:Help( v.name )

                    local colormixer = vgui.Create( "DColorMixer", panel )
                    panel:AddItem( colormixer )

                    colormixer:SetConVarR( v.red )
                    colormixer:SetConVarG( v.green )
                    colormixer:SetConVarB( v.blue )

                    local lbl = panel:ControlHelp( v.desc .. "\nDefault Color: " .. v.default )
                    lbl:SetColor( v.isclient and clientcolor or servercolor )

                    InstallMPConVarHandling( colormixer, v.red, "Color", !v.isclient )
                end
            end
        end)
    end
end

local function CreateLambdaPlayersSettings()
    spawnmenu.AddToolTab( "Lambda Player", "#Lambda Player", "lambdaplayers/icon/lambda.png" )
end

hook.Add( "AddToolMenuTabs", "AddLambdaPlayertabs", CreateLambdaPlayersSettings )
hook.Add( "PopulateToolMenu", "AddLambdaPlayerPanels", AddLambdaPlayersOptions )