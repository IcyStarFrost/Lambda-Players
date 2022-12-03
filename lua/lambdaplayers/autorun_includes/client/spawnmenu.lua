
local pairs = pairs
local ipairs = ipairs
local table_insert = table.insert
local clientcolor = Color( 255, 145, 0 )
local servercolor = Color( 0, 174, 255 )


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

local function AddLambdaPlayersoptions()

    local categories = {}

    for k, v in ipairs( _LAMBDAConVarSettings ) do -- See convars.lua 
        categories[ v.category ] = v.category
    end

    -- Credits and Infooooo
    spawnmenu.AddToolMenuOption( "Lambda Player", "Lambda Player", "lambdaplayer_credits" , "About, Credits, info", "", "", function( panel ) 
        local lambdaplayers = panel:Help( "   -- Lambda Players --" ) lambdaplayers:SetColor( clientcolor ) 
        local starrrrr = panel:Help( "-- Created By StarFrost --" ) starrrrr:SetColor( servercolor )


        -- Contributor thanks!
        local contributors = panel:Help( epiccontributors ) contributors:SetColor( servercolor )

        panel:Help( "\n-- Links --" )

        CreateUrlLabel( "Lambda Players GitHub", "https://github.com/IcyStarFrost/Lambda-Players", panel, TOP ) -- GitHub
        CreateUrlLabel( "StarFrost's YouTube Channel", "https://www.youtube.com/channel/UCu_7jXrDackiI85ABzd0CKA", panel, TOP ) -- Star's Youtube
        CreateUrlLabel( "Learn how to add Custom Content to Lambda Players and develop for Lambda Players", "https://github.com/IcyStarFrost/Lambda-Players/wiki", panel, TOP ) -- Wiki


    end )

    spawnmenu.AddToolMenuOption( "Lambda Player", "Lambda Player", "lambdaplayer_weaponpermissions" , "Weapon Permissions", "", "", function( panel ) 
        panel:Help( "All weapon convars start with lambdaplayers_weapons" )
        for k, v in pairs( _LAMBDAPLAYERSWEAPONORIGINS ) do

            local weaponcheckboxes = {}
            local check = false

            panel:Help("------ " .. k .. " ------")

            local togglebutton = vgui.Create( "DButton", panel )
            togglebutton:SetText( "Toggle " .. k .. " Category" )
            panel:AddItem( togglebutton )

            function togglebutton:DoClick()
                if !LocalPlayer():IsSuperAdmin() then return end
                for id, box in ipairs( weaponcheckboxes ) do

                    net.Start( "lambdaplayers_updateconvar" )
                        net.WriteString( box.l_conVar )
                        net.WriteString( check and "1" or "0" )
                    net.SendToServer()
                    
                    box:SetChecked( check )
                end
                check = !check
            end

            for weaponclass, data in pairs( _LAMBDAPLAYERSWEAPONS ) do
                if data.origin == k then
                    local box = panel:CheckBox( "Allow " .. data.prettyname, "lambdaplayers_weapons_allow" .. weaponclass )
                    local lbl = panel:ControlHelp( "Server-Side | Allows the Lambda Players to equip " .. data.prettyname .. "\nConVar: lambdaplayers_weapons_allow" .. weaponclass )
                    lbl:SetColor( servercolor )
                    box.l_conVar = "lambdaplayers_weapons_allow" .. weaponclass
                    table_insert( weaponcheckboxes, box )
                end
            end

        end

    end)

    for categoryname, _ in pairs( categories ) do

        spawnmenu.AddToolMenuOption( "Lambda Player", "Lambda Player", "lambdaplayer_" .. categoryname , categoryname, "", "", function( panel ) 


            for k, v in ipairs( _LAMBDAConVarSettings ) do
                if v.category != categoryname then continue end
                if v.type == "Slider" then
                    panel:NumSlider( v.name, v.convar, v.min, v.max, v.decimals or 2 )
                    local lbl = panel:ControlHelp( v.desc .. "\nDefault Value: " .. v.default )
                    lbl:SetColor( v.isclient and clientcolor or servercolor )
                elseif v.type == "Bool" then
                    panel:CheckBox( v.name, v.convar )
                    local lbl = panel:ControlHelp( v.desc .. "\nDefault Value: " .. ( v.default == 1 and "True" or "False") )
                    lbl:SetColor( v.isclient and clientcolor or servercolor )
                elseif v.type == "Text" then
                    panel:TextEntry( v.name, v.convar )
                    local lbl = panel:ControlHelp( v.desc .. "\nDefault Value: " .. v.default )
                    lbl:SetColor( v.isclient and clientcolor or servercolor )
                elseif v.type == "Button" then
                    panel:Button( v.name, v.concmd )
                    local lbl = panel:ControlHelp( v.desc )
                    lbl:SetColor( v.isclient and clientcolor or servercolor )
                elseif v.type == "Combo" then
                    local combo = panel:ComboBox( v.name, v.convar )

                    for k, v in pairs( v.options ) do
                        combo:AddChoice( k, v )
                    end

                    local lbl = panel:ControlHelp( v.desc .. "\nDefault Value: " .. v.default )
                    lbl:SetColor( v.isclient and clientcolor or servercolor )
                elseif v.type == "Color" then
                    panel:Help( v.name )
                    local colormixer = vgui.Create( "DColorMixer", panel )
                    panel:AddItem( colormixer )
                    colormixer:SetConVarR( v.red )
                    colormixer:SetConVarG( v.green )
                    colormixer:SetConVarB( v.blue )

                    local lbl = panel:ControlHelp( v.desc .. "\nDefault Color: " .. v.default )
                    lbl:SetColor( v.isclient and clientcolor or servercolor )
                end
            end

        end)

    end


end

local function CreateLambdaPlayersSettings()
    spawnmenu.AddToolTab( "Lambda Player", "#Lambda Player", "lambdaplayers/icon/lambda.png" )
end

hook.Add( "AddToolMenuTabs", "AddLambdaPlayertabs", CreateLambdaPlayersSettings )
hook.Add( "PopulateToolMenu", "AddLambdaPlayerPanels", AddLambdaPlayersoptions )