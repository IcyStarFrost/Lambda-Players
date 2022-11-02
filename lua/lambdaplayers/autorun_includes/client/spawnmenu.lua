
local pairs = pairs
local ipairs = ipairs
local table_insert = table.insert
local categories = {}

for k, v in ipairs( _LAMBDAConVarSettings ) do -- See convars.lua 
    categories[ v.category ] = v.category
end

local function AddLambdaPlayersoptions()

    for categoryname, _ in pairs( categories ) do

        spawnmenu.AddToolMenuOption( "Lambda Player", "Lambda Player", "lambdaplayer_weaponpermissions" , "Weapon Permissions", "", "", function( panel ) 

            for k, v in pairs( _LAMBDAPLAYERSWEAPONORIGINS ) do

                local weaponcheckboxes = {}
                local check = false

                panel:Help("------ " .. k .. " ------")

                local togglebutton = vgui.Create( "DButton", panel )
                togglebutton:SetText( "Toggle " .. k .. " Category" )
                panel:AddItem( togglebutton )

                function togglebutton:DoClick()
                    for id, box in ipairs( weaponcheckboxes ) do
                        box:SetChecked( check )
                    end
                    check = !check
                end

                for weaponclass, data in pairs( _LAMBDAPLAYERSWEAPONS ) do
                    if data.origin == k then
                        local box = panel:CheckBox( "Allow " .. data.prettyname, "lambdaplayers_weapons_allow" .. weaponclass )
                        panel:ControlHelp( "Server-Side | Allows the Lambda Players to equip " .. data.prettyname )
                        table_insert( weaponcheckboxes, box )
                    end
                end

            end

        end)

        spawnmenu.AddToolMenuOption( "Lambda Player", "Lambda Player", "lambdaplayer_" .. categoryname , categoryname, "", "", function( panel ) 

            for k, v in ipairs( _LAMBDAConVarSettings ) do
                if v.category != categoryname then continue end

                if v.type == "Slider" then
                    panel:NumSlider( v.name, v.convar, v.min, v.max, v.decimals or 2 )
                    panel:ControlHelp( v.desc )
                elseif v.type == "Bool" then
                    panel:CheckBox( v.name, v.convar )
                    panel:ControlHelp( v.desc )
                elseif v.type == "Text" then
                    panel:TextEntry( v.name, v.convar )
                    panel:ControlHelp( v.desc )
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