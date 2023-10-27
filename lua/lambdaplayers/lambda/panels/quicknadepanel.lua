local ipairs = ipairs
local table_Merge = table.Merge

local function OpenQuickNadePanel( ply )
    if !ply:IsSuperAdmin() then
        notification.AddLegacy( "You must be a Super Admin in order to use this!", 1, 4 )
        surface.PlaySound( "buttons/button10.wav" )
        return 
    end

    local mainframe = LAMBDAPANELS:CreateFrame( "Quick Nade Weapons", 300, 400 )

    local nadeList = vgui.Create( "DListView", mainframe )
    nadeList:Dock( FILL )
    nadeList:AddColumn( "Weapon", 1 )

    function nadeList:DoDoubleClick( id, line )
        local conmenu = DermaMenu( false, mainframe )
        local nade = line:GetSortValue( 1 )

        local prettyName = _LAMBDAPLAYERSWEAPONS[ nade ]
        prettyName = ( prettyName and prettyName.notagprettyname or nade )

        conmenu:AddOption( "Delete " .. prettyName .. "?", function()
            chat.AddText( "Deleted " .. prettyName .. " from the quick nade list.")
            surface.PlaySound( "buttons/button15.wav" )
            nadeList:RemoveLine( id )
            LAMBDAPANELS:RemoveVarFromSQFile( "lambdaplayers/quicknades.json", nade, "json" ) 
        end )
        conmenu:AddOption( "Cancel", function() end )
    end

    local nades = {}

    local function AddWeaponToNades( weapon )
        local prettyName = _LAMBDAPLAYERSWEAPONS[ weapon ]
        prettyName = ( prettyName and prettyName.prettyname or weapon )

        local line = nadeList:AddLine( prettyName )
        line:SetSortValue( 1, weapon )
    end

    LAMBDAPANELS:RequestDataFromServer( "lambdaplayers/quicknades.json", "json", function( data ) 
        if !data then return end
        table_Merge( nades, data )

        for _, nade in ipairs( data ) do
            AddWeaponToNades( nade )
        end
    end )

    LAMBDAPANELS:CreateButton( mainframe, BOTTOM, "Add Weapon", function()
        LambdaWeaponSelectPanel( "none", function( chosenWeapon )
            if chosenWeapon == "none" then return end
            for _, nade in ipairs( nades ) do
                if chosenWeapon == nades then return end
            end

            AddWeaponToNades( chosenWeapon )
            LAMBDAPANELS:UpdateSequentialFile( "lambdaplayers/quicknades.json", chosenWeapon, "json" )
        end, true, false, false )
    end )
end

RegisterLambdaPanel( "Quick Nade Weapons", "Opens a panel that allows you to select the weapons Lambda Players will as throw as a quick nade. You must be a Super Admin to use this Panel.", OpenQuickNadePanel, "Lambda Weapons" )