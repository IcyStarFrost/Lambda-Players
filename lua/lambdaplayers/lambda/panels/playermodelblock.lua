local function OpenPlayermodelBlockPanel( ply )
    if !ply:IsSuperAdmin() then notification.AddLegacy( "You must be a Super Admin in order to use this!", 1, 4) surface.PlaySound( "buttons/button10.wav" ) return end

    local frame = LAMBDAPANELS:CreateFrame( "Playermodel Blocking", 600, 500 )
    LAMBDAPANELS:CreateLabel( "Click on playermodels to the left to block them. Right click a row on the right to unblock a model", frame, TOP )
    local leftpnl = vgui.Create( "DPanel", frame )
    local rightpnl = vgui.Create( "DPanel", frame )
    local playermodelscroll = LAMBDAPANELS:CreateScrollPanel( leftpnl, false, FILL )

    leftpnl:SetSize( 290, 1 )
    leftpnl:Dock( LEFT )
    rightpnl:SetSize( 300, 1 )
    rightpnl:DockMargin( 10, 0, 0, 0 )
    rightpnl:Dock( LEFT )

    
    LAMBDAPANELS:CreateLabel( "Playermodels", leftpnl, TOP )


    local mdllayout = vgui.Create( "DIconLayout", playermodelscroll )
    mdllayout:Dock( FILL )
    mdllayout:SetSpaceX( 5 )
    mdllayout:SetSpaceY( 5 )

    local blockedlist = vgui.Create( "DListView", rightpnl )
    blockedlist:Dock( FILL )
    blockedlist:AddColumn( "Blocked Playermodels", 1 )


    function blockedlist:OnRowRightClick( id, line )
        local icon = mdllayout:Add( "SpawnIcon" )
        icon:SetModel( line:GetColumnText( 1 ) )
        self:RemoveLine( id )
    end
    

    for k, mdl in SortedPairs( player_manager.AllValidModels() ) do
        local icon = mdllayout:Add( "SpawnIcon" )
        icon:SetModel( mdl )

        function icon:DoClick()
            blockedlist:AddLine( mdl )
            self:Remove()
        end
    end

    function frame:OnClose()
        local mdls = {}
        for k, line in pairs( blockedlist:GetLines() ) do mdls[ #mdls + 1 ] = line:GetColumnText( 1 ) end
        LAMBDAPANELS:WriteServerFile( "lambdaplayers/pmblockdata.json", mdls, "json" ) 
        chat.AddText( "Remember to Update Lambda Data after any changes!" )
    end

    if !LocalPlayer():IsListenServerHost() then
        LAMBDAPANELS:RequestDataFromServer( "lambdaplayers/pmblockdata.json", "json", function( data )
            if !data then return end

            for k, mdl in pairs( data ) do 
                blockedlist:AddLine( mdl )

                for _, icon in pairs( mdllayout:GetChildren() ) do
                    if icon:GetModelName() == mdl then icon:Remove() break end
                end

            end

        end )
    else
        local data = LAMBDAFS:ReadFile( "lambdaplayers/pmblockdata.json", "json" )
        if !data then return end

        for k, mdl in pairs( data ) do 
            blockedlist:AddLine( mdl )

            for _, icon in pairs( mdllayout:GetChildren() ) do
                if icon:GetModelName() == mdl then icon:Remove() break end
            end

        end
    end


end
RegisterLambdaPanel( "Playermodel Blacklist", "Opens a panel that allows you to prevent Lambdas from using certain playermodels. You must be a Super Admin to use this Panel. YOU MUST UPDATE LAMBDA DATA AFTER ANY CHANGES!", OpenPlayermodelBlockPanel )