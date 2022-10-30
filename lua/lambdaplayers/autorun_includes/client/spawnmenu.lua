

local categories = {}

for k, v in ipairs( _LAMBDAConVarSettings ) do
    categories[ v.category ] = v.category
end

local function AddLambdaPlayersoptions()

    for categoryname, _ in pairs( categories ) do

        spawnmenu.AddToolMenuOption( "Lambda Player", "Lambda Player", "lambdaplayer_" .. categoryname , categoryname, "", "", function( panel ) 

            for k, v in ipairs( _LAMBDAConVarSettings ) do
                if v.category != categoryname then continue end

                if v.type == "Slider" then
                    panel:NumSlider( v.name, v.convar, v.min, v.max, v.decimals )
                    panel:ControlHelp( v.desc )
                elseif v.type == "Bool" then
                    panel:CheckBox( v.name, v.convar )
                    panel:ControlHelp( v.desc )
                end

            end

        end)

    end


end

local function CreateLambdaPlayersSettings()
    spawnmenu.AddToolTab( "Lambda Player", "#Lambda Player", "icon/physgun.png" )
end

hook.Add( "AddToolMenuTabs", "AddLambdaPlayertabs", CreateLambdaPlayersSettings )
hook.Add( "PopulateToolMenu", "AddLambdaPlayerPanels", AddLambdaPlayersoptions )