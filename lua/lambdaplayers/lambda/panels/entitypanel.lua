
local blue = Color( 0, 162, 255)
local function OpenEntityPanel( ply )
    if !ply:IsSuperAdmin() then notification.AddLegacy( "You must be a Super Admin in order to use this!", 1, 4) surface.PlaySound( "buttons/button10.wav" ) return end

    local frame = LAMBDAPANELS:CreateFrame( "Entity Panel", 600, 500 )
    local resettodefault = vgui.Create( "DButton", frame )
    LAMBDAPANELS:CreateLabel( "Click on a Entity on the left to register it for use. Right click a row to the right to unregister it for use", frame, TOP )
    local leftpnl = vgui.Create( "DPanel", frame )
    LAMBDAPANELS:CreateLabel( "Entities", leftpnl, TOP )
    local scroll = LAMBDAPANELS:CreateScrollPanel( leftpnl )
    local entitylayout = vgui.Create( "DIconLayout", scroll )
    local entitylistpanel = vgui.Create( "DListView", frame )
    
    
    resettodefault:Dock( BOTTOM )
    resettodefault:SetText( "Reset to Default List" )

    leftpnl:SetSize( 290, 1 )
    leftpnl:Dock( LEFT )

    scroll:Dock( FILL )

    entitylayout:Dock( FILL )
    entitylayout:SetSpaceX( 5 )
    entitylayout:SetSpaceY( 5 )

    entitylistpanel:SetSize( 300, 1 )
    entitylistpanel:DockMargin( 10, 0, 0, 0 )
    entitylistpanel:Dock( LEFT )
    entitylistpanel:AddColumn( "Allowed Entities (Print Name)", 1 )
    entitylistpanel:AddColumn( "Allowed Entities (Class Name)", 2 )

    local entitylist = list.Get( "SpawnableEntities" )

    local function AddEntitypanel( class )
        for k, v in pairs( entitylayout:GetChildren() ) do if v:GetEntity() == class then return end end

        local pnl = entitylayout:Add( "DPanel" )
        pnl:SetSize( 120, 120 )
        local img = vgui.Create( "DImageButton", pnl )
        img:SetSize( 1, 100 )
        img:Dock( TOP )
        img:SetMaterial( Material( "entities/" .. class .. ".png" ) )
        local lbl = LAMBDAPANELS:CreateLabel( entitylist[ class ] and entitylist[ class ].PrintName or class, pnl, TOP )
        lbl:SetColor( blue )
        
        function img:DoClick()
            entitylistpanel:AddLine( entitylist[ class ] and entitylist[ class ].PrintName or class, class )
            pnl:Remove()
        end

        function pnl:GetEntity() return class end
    end

    function entitylistpanel:OnRowRightClick( id, line )
        AddEntitypanel( line:GetColumnText( 2 ) )
        self:RemoveLine( id )
    end

    for k, v in pairs( entitylist ) do
        AddEntitypanel( v.ClassName )
    end

    function resettodefault:DoClick()
        entitylistpanel:Clear()
        local defaultlist = LAMBDAFS:ReadFile( "materials/lambdaplayers/data/defaultentities.vmt", "json", "GAME", false )

        for k, class in ipairs( defaultlist ) do
            entitylistpanel:AddLine( entitylist[ class ] and entitylist[ class ].PrintName or class, class )

            for _, pnl in pairs( entitylayout:GetChildren() ) do
                if pnl:GetEntity() == class then pnl:Remove() break end 
            end
        end
    end

    function frame:OnClose()
        local classes = {}
        for k, line in pairs( entitylistpanel:GetLines() ) do classes[ #classes + 1 ] = line:GetColumnText( 2 ) end
        LAMBDAPANELS:WriteServerFile( "lambdaplayers/entitylist.json", classes, "json" ) 
    end

    if !LocalPlayer():IsListenServerHost() then
        LAMBDAPANELS:RequestDataFromServer( "lambdaplayers/entitylist.json", "json", function( data )
            if !data then return end

            for k, class in ipairs( data ) do
                entitylistpanel:AddLine( entitylist[ class ] and entitylist[ class ].PrintName or class, class )

                for _, pnl in pairs( entitylayout:GetChildren() ) do
                    if pnl:GetEntity() == class then pnl:Remove() break end 
                end
            end
        
        end )
    else
        local data = LAMBDAFS:ReadFile( "lambdaplayers/entitylist.json", "json" )
        if !data then return end

        for k, class in ipairs( data ) do
            entitylistpanel:AddLine( entitylist[ class ] and entitylist[ class ].PrintName or class, class )

            for _, pnl in pairs( entitylayout:GetChildren() ) do
                if pnl:GetEntity() == class then pnl:Remove() break end 
            end
        end
    end

end
RegisterLambdaPanel( "Entity Spawnlist", "Opens a panel that allows you to choose what Entities Lambdas are allowed to spawn. You must be a Super Admin to use this Panel.", OpenEntityPanel )