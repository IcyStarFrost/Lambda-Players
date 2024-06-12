local function OpenPropPanel( ply )
    if !ply:IsSuperAdmin() then notification.AddLegacy( "You must be a Super Admin in order to use this!", 1, 4) surface.PlaySound( "buttons/button10.wav" ) return end

    local frame = LAMBDAPANELS:CreateFrame( "Prop Panel", 800, 500 )
    LAMBDAPANELS:CreateLabel( "Click on models from the browser on the left to register them. Right click a row on the right to remove it", frame, TOP )
    local clearprops = vgui.Create( "DButton", frame )
    local resettodefault = vgui.Create( "DButton", frame )
    local filebrowser = vgui.Create( "DFileBrowser", frame )
    local proplist = vgui.Create( "DListView", frame )

    
    resettodefault:Dock( BOTTOM )
    resettodefault:SetText( "Reset to Default List" )
    clearprops:Dock( BOTTOM )
    clearprops:SetText( "Clear Prop List" )
    proplist:SetSize( 400, 1 )
    proplist:Dock( LEFT )
    proplist:AddColumn( "Allowed Props", 1 )

    function proplist:HasModel( mdl )
        for k, line in ipairs( self:GetLines() ) do 
            if line:GetColumnText( 1 ) == string.lower( mdl ) then return true end
        end
        return false
    end

    function clearprops:DoClick() proplist:Clear() end

    function resettodefault:DoClick()
        proplist:Clear()
        local defaultlist = LAMBDAFS:ReadFile( "materials/lambdaplayers/data/props.vmt", "json", "GAME", false )

        for k, v in ipairs( defaultlist ) do
            proplist:AddLine( v )
        end
    end

    function proplist:OnRowRightClick( id, line )
        self:RemoveLine( id )
        surface.PlaySound( "buttons/button15.wav" )
    end


    function frame:OnClose()
        local models = {}
        for k, line in pairs( proplist:GetLines() ) do models[ #models + 1 ] = line:GetColumnText( 1 ) end
        LAMBDAPANELS:WriteServerFile( "lambdaplayers/proplist.json", models, "json" ) 
    end

    if !LocalPlayer():IsListenServerHost() then
        LAMBDAPANELS:RequestDataFromServer( "lambdaplayers/proplist.json", "json", function( data ) 
            if !data then return end

            for k, mdl in ipairs( data ) do
                proplist:AddLine( mdl )
            end
        end )
    else
        local data = LAMBDAFS:ReadFile( "lambdaplayers/proplist.json", "json" )
        if !data then return end

        for k, mdl in ipairs( data ) do
            proplist:AddLine( mdl )
        end
    end

    filebrowser:SetFileTypes( "*.mdl" )
    filebrowser:SetSize( 400, 1 )
    filebrowser:Dock( LEFT )
    filebrowser:SetModels( true )
    filebrowser:SetBaseFolder( "models" )

    function filebrowser:OnSelect( path, pnl )
        if proplist:HasModel( path ) then notification.AddLegacy( path .. " is already registered!", 1, 3 ) surface.PlaySound( "buttons/button10.wav" ) return end
        surface.PlaySound( "buttons/button15.wav" )
        proplist:AddLine( string.lower( path ) )
    end

    local tree = filebrowser.Tree

    LambdaCreateThread( function()
        coroutine.wait( 0 )
        local files = file.Find( "settings/spawnlist/*", "GAME", "nameasc" )

        for k, spawnlist in ipairs( files ) do 
            local tbl = util.KeyValuesToTable( LAMBDAFS:ReadFile( "settings/spawnlist/" .. spawnlist, nil, "GAME" ) )
            local contents = tbl.contents

            if !contents then continue end

            local nodec = tree:AddNode( tbl.name, tbl.icon)

            

            function nodec:DoClick()
                if IsValid( filebrowser.Files ) then filebrowser.Files:Remove() end

                filebrowser.Files = filebrowser.Divider:Add( "DIconBrowser" )
                filebrowser.Files:SetManual( true )
                filebrowser.Files:SetBackgroundColor( Color( 234, 234, 234 ) )

                filebrowser.Divider:SetRight( filebrowser.Files )

                filebrowser.Files:Clear()

                for _, contenttbl in ipairs( contents ) do
                    if contenttbl.type != "model" then continue end
                    local icon = filebrowser.Files:Add( "SpawnIcon" )
                    icon:SetModel( contenttbl.model )

                    function icon:DoClick() 
                        if proplist:HasModel( string.lower( self:GetModelName() ) ) then notification.AddLegacy( string.lower( self:GetModelName() ) .. " is already registered!", 1, 3 ) surface.PlaySound( "buttons/button10.wav" ) return end
                        proplist:AddLine( string.lower( self:GetModelName() ) )
                        surface.PlaySound( "buttons/button15.wav" )
                    end
                end
            end
        end
    end )

end
RegisterLambdaPanel( "Prop Spawnlist", "Opens a panel that allows you to choose what props Lambdas are allowed to spawn. You must be a Super Admin to use this Panel. YOU MUST UPDATE LAMBDA DATA AFTER ANY CHANGES!", OpenPropPanel )