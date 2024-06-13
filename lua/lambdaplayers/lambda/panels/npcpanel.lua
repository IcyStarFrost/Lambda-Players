
local blue = Color( 0, 162, 255)
local function OpenNPCPanel( ply )
    if !ply:IsSuperAdmin() then notification.AddLegacy( "You must be a Super Admin in order to use this!", 1, 4) surface.PlaySound( "buttons/button10.wav" ) return end

    local frame = LAMBDAPANELS:CreateFrame( "NPC Panel", 600, 500 )
    local resettodefault = vgui.Create( "DButton", frame )
    LAMBDAPANELS:CreateLabel( "Click on a NPC on the left to register it for use. Right click a row to the right to unregister it for use", frame, TOP )
    local leftpnl = vgui.Create( "DPanel", frame )
    LAMBDAPANELS:CreateLabel( "NPCs", leftpnl, TOP )
    local scroll = LAMBDAPANELS:CreateScrollPanel( leftpnl )
    local npclayout = vgui.Create( "DIconLayout", scroll )
    local npclistpanel = vgui.Create( "DListView", frame )
    
    
    resettodefault:Dock( BOTTOM )
    resettodefault:SetText( "Reset to Default List" )

    leftpnl:SetSize( 290, 1 )
    leftpnl:Dock( LEFT )

    scroll:Dock( FILL )

    npclayout:Dock( FILL )
    npclayout:SetSpaceX( 5 )
    npclayout:SetSpaceY( 5 )

    npclistpanel:SetSize( 300, 1 )
    npclistpanel:DockMargin( 10, 0, 0, 0 )
    npclistpanel:Dock( LEFT )
    npclistpanel:AddColumn( "Allowed NPCs (Print Name)", 1 )
    npclistpanel:AddColumn( "Allowed NPCs (Class Name)", 2 )

    local npclist = list.Get( "NPC" )

    local function AddNPCpanel( class )
        if class == "npc_lambdaplayer" then return end -- no
        for k, v in pairs( npclayout:GetChildren() ) do if v:GetNPC() == class then return end end

        local pnl = npclayout:Add( "DPanel" )
        pnl:SetSize( 120, 120 )
        local img = vgui.Create( "DImageButton", pnl )
        img:SetSize( 1, 100 )
        img:Dock( TOP )
        img:SetMaterial( Material( "entities/" .. class .. ".png" ) )
        local lbl = LAMBDAPANELS:CreateLabel( ( npclist[ class ] and npclist[ class ].Name or class ), pnl, TOP )
        lbl:SetColor( blue )
        
        function img:DoClick()
            npclistpanel:AddLine( ( npclist[ class ] and npclist[ class ].Name or class ), class )
            pnl:Remove()
        end

        function pnl:GetNPC() return class end
    end

    function npclistpanel:OnRowRightClick( id, line )
        AddNPCpanel( line:GetColumnText( 2 ) )
        self:RemoveLine( id )
    end

    for k, v in pairs( npclist ) do
        AddNPCpanel( v.Class )
    end

    function resettodefault:DoClick()
        npclistpanel:Clear()
        local defaultlist = LAMBDAFS:ReadFile( "materials/lambdaplayers/data/defaultnpcs.vmt", "json", "GAME", false )

        for k, class in ipairs( defaultlist ) do
            npclistpanel:AddLine( ( npclist[ class ] and npclist[ class ].Name or class ), class )

            for _, pnl in pairs( npclayout:GetChildren() ) do
                if pnl:GetNPC() == class then pnl:Remove() break end 
            end
        end
    end

    function frame:OnClose()
        local classes = {}
        for k, line in pairs( npclistpanel:GetLines() ) do classes[ #classes + 1 ] = line:GetColumnText( 2 ) end
        LAMBDAPANELS:WriteServerFile( "lambdaplayers/npclist.json", classes, "json" ) 
    end

    if !LocalPlayer():IsListenServerHost() then
        LAMBDAPANELS:RequestDataFromServer( "lambdaplayers/npclist.json", "json", function( data )
            if !data then return end

            for k, class in ipairs( data ) do
                npclistpanel:AddLine( ( npclist[ class ] and npclist[ class ].Name or class ), class )

                for _, pnl in pairs( npclayout:GetChildren() ) do
                    if pnl:GetNPC() == class then pnl:Remove() break end 
                end
            end
        
        end )
    else
        local data = LAMBDAFS:ReadFile( "lambdaplayers/npclist.json", "json" )
        if !data then return end

        for k, class in ipairs( data ) do
            npclistpanel:AddLine( ( npclist[ class ] and npclist[ class ].Name or class ), class )

            for _, pnl in pairs( npclayout:GetChildren() ) do
                if pnl:GetNPC() == class then pnl:Remove() break end 
            end
        end
    end

end
RegisterLambdaPanel( "NPC Spawnlist", "Opens a panel that allows you to choose what NPCs Lambdas are allowed to spawn. You must be a Super Admin to use this Panel.", OpenNPCPanel )