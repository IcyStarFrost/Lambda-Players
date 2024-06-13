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

        surface.PlaySound( "buttons/button15.wav" )
        nadeList:RemoveLine( id )
        LAMBDAPANELS:RemoveVarFromSQFile( "lambdaplayers/quicknades.json", nade, "json" ) 
    end

    local nades = {}

    local function AddWeaponToNades( weapon )
        local prettyName = _LAMBDAPLAYERSWEAPONS[ weapon ]
        prettyName = ( prettyName and prettyName.prettyname or weapon )

        local line = nadeList:AddLine( prettyName )
        line:SetSortValue( 1, weapon )
    end

    if !LocalPlayer():IsListenServerHost() then
        LAMBDAPANELS:RequestDataFromServer( "lambdaplayers/quicknades.json", "json", function( data ) 
            if !data then return end
            table_Merge( nades, data )

            for _, nade in ipairs( data ) do
                AddWeaponToNades( nade )
            end
        end )
    else
        local data = LAMBDAFS:ReadFile( "lambdaplayers/quicknades.json", "json" )
        if !data then return end
        table_Merge( nades, data )

        for _, nade in ipairs( data ) do
            AddWeaponToNades( nade )
        end
    end

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

RegisterLambdaPanel( "Quick Nade Weapons", "Opens a panel that allows you to select the weapons Lambda Players will as throw as a quick nade. You must be a Super Admin to use this Panel. YOU MUST UPDATE LAMBDA DATA AFTER ANY CHANGES!", OpenQuickNadePanel, "Lambda Weapons" )