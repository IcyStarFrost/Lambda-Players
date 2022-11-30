--[[ local table_insert = table.insert
local ipairs = ipairs
local SortedPairs = SortedPairs

local function OpenWeaponStatViewer( ply )

    local frame = LAMBDAPANELS:CreateFrame( "Weapon Stats Viewer", 630, 400 )

    local statspanel = LAMBDAPANELS:CreateBasicPanel( frame, LEFT  )
    statspanel:SetSize( 260, 300 )
    statspanel:Dock( LEFT )

    local mdlviewer = vgui.Create( "DModelPanel", frame )
    mdlviewer:SetSize( 200, 200 )
    mdlviewer:Dock( LEFT )
    mdlviewer:SetFOV( 30 )
    mdlviewer:SetLookAt( Vector() )

    local listpnl = vgui.Create( "DListView", frame )
    listpnl:SetSize( 100, 100 )
    listpnl:Dock( LEFT )
    listpnl:AddColumn( "Weapons", 1 )

    for k, v in SortedPairs( _LAMBDAPLAYERSWEAPONS ) do
        local line = listpnl:AddLine( v.prettyname )
        line:SetSortValue( 1, v )
    end








    local panels = {}
    local scroll = LAMBDAPANELS:CreateScrollPanel( statspanel, false, FILL )

    function listpnl:DoDoubleClick( id , line )
        for k, v in ipairs( panels ) do if v then v:Remove() end end
        for k, v in SortedPairs( line:GetSortValue( 1 ) ) do
            local lbl = LAMBDAPANELS:CreateLabel( k .. ": " .. tostring( v ), scroll, TOP )
            table_insert( panels, lbl )
        end
        mdlviewer:SetModel( line:GetSortValue( 1 ).model )
    end

end


RegisterLambdaPanel( "WeaponStat", "Opens a panel that allows you to view a weapon's stats", OpenWeaponStatViewer ) ]]