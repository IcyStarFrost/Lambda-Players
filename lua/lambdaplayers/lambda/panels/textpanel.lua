
file.CreateDir( "lambdaplayers/texttypes")
file.CreateDir( "lambdaplayers/exportedtexttypes")
file.CreateDir( "lambdaplayers/importtexttypes")
local function OpenTextPanel( ply )
    if !ply:IsSuperAdmin() then return end
    local ishost = ply:GetNW2Bool( "lambda_serverhost", false )

    local frame = LAMBDAPANELS:CreateFrame( "Text Line Editor", 700, 300 )

    function frame:OnClose()
        chat.AddText( "Remember to Update Lambda Data after any changes!" )
    end

    LAMBDAPANELS:CreateURLLabel( "Click here to learn about the default text types and keywords", "https://github.com/IcyStarFrost/Lambda-Players/wiki/Text-Chat", frame, TOP )
    LAMBDAPANELS:CreateLabel( "Right Click a line to remove it", frame, TOP )

    local framescroll = LAMBDAPANELS:CreateScrollPanel( frame, true, FILL )

    local function CreateTextEditingPanel( texttype )
        if !IsValid( framescroll ) then return end

        local pnl = LAMBDAPANELS:CreateBasicPanel( framescroll, LEFT )
        pnl:SetSize( 200, 200 )
        pnl:DockMargin( 10, 0, 0, 0 )
        pnl:Dock( LEFT )
        framescroll:AddPanel( pnl )
        local texttable = {}

        local listview = vgui.Create( "DListView", pnl )
        listview:Dock( FILL )
        listview:AddColumn( texttype .. " text lines", 1 )

        local isrequesting = true

        local textentry = LAMBDAPANELS:CreateTextEntry( pnl, BOTTOM, "Enter text here" )

        LAMBDAPANELS:CreateExportPanel( "Text", pnl, BOTTOM, "Export " .. texttype .. " Lines", texttable, "json", "lambdaplayers/exportedtexttypes/" .. texttype .. ".vmt" )

        local labels = {
            "Place exported any texttype .vmt files or .txt files that are formatted like",
            "A Text line 1",
            "A Text line 2",
            "A Text line 3",
            "In the garrysmod/data/lambdaplayers/importtexttypes folder to be able to import them"
        }

        LAMBDAPANELS:CreateImportPanel( "Text", pnl, BOTTOM, "Import " .. texttype .. " Lines", labels, "lambdaplayers/importtexttypes/*", function( path )
            local count = 0

            local jsoncontents = LAMBDAFS:ReadFile( path, "json" )
    
            if jsoncontents then
                
                for k, v in ipairs( jsoncontents ) do
                    if !table.HasValue( texttable, v ) then 
                        count = count + 1 
                        LAMBDAPANELS:UpdateSequentialFile( "lambdaplayers/texttypes/" .. texttype .. ".json", v, "json" )
    
                        local line = listview:AddLine( v )
                        line:SetSortValue( 1, v )
                
                        table.insert( texttable, v )
                    end
                end
    
                chat.AddText( "Imported " .. count .. " text lines to " .. texttype )
            else
                local txtcontents = LAMBDAFS:ReadFile( path ) 
    
                txtcontents = string.Explode( "\n", txtcontents )
    
                for k, v in ipairs( txtcontents ) do
                    if !table.HasValue( texttable, v ) then 
                        count = count + 1 
                        LAMBDAPANELS:UpdateSequentialFile( "lambdaplayers/texttypes/" .. texttype .. ".json", v, "json" )
    
                        local line = listview:AddLine( v )
                        line:SetSortValue( 1, v )
                
                        table.insert( texttable, v )
                    end
                end
    
                chat.AddText( "Imported " .. count .. " text lines to " .. texttype )
            end
        end )

        local searchbar = LAMBDAPANELS:CreateSearchBar( listview, texttable, pnl )
        searchbar:Dock( TOP )

        function textentry:OnEnter( val )
            if val == "" then return end
            LAMBDAPANELS:UpdateSequentialFile( "lambdaplayers/texttypes/" .. texttype .. ".json", val, "json" ) 
            textentry:SetText( "" )
            chat.AddText( "Added " .. val .. " to " .. texttype .. " lines" )
            surface.PlaySound( "buttons/button15.wav" )

            local line = listview:AddLine( val )
            line:SetSortValue( 1, val )
        end

        function listview:OnRowRightClick( id, line )
            chat.AddText( "Removed " .. line:GetSortValue( 1 ) .. " from " .. texttype .. " lines" )
            surface.PlaySound( "buttons/button15.wav" )
            listview:RemoveLine( id )
            LAMBDAPANELS:RemoveVarFromSQFile( "lambdaplayers/texttypes/" .. texttype .. ".json", line:GetSortValue( 1 ), "json" ) 
        end

        function listview:DoDoubleClick( id, line )
            surface.PlaySound( "buttons/button16.wav" )
            textentry:SetText( line:GetSortValue( 1 ) )
        end

        if !ishost then
            chat.AddText( "Requesting Text Lines for " .. texttype .. " from the Server")
            LAMBDAPANELS:RequestDataFromServer( "lambdaplayers/texttypes/" .. texttype .. ".json", "json", function( data )
                isrequesting = false

                if !data then return end

                table.Merge( texttable, data )

                for k, v in ipairs( texttable ) do
                    local line = listview:AddLine( v )
                    line:SetSortValue( 1, v )
                end

            end )
        else
            local data = LAMBDAFS:ReadFile( "lambdaplayers/texttypes/" .. texttype .. ".json", "json" )

            if !data then return end

            table.Merge( texttable, data )

            for k, v in ipairs( texttable ) do
                local line = listview:AddLine( v )
                line:SetSortValue( 1, v )
            end

            isrequesting = false
        end


        while isrequesting do coroutine.yield() end

        coroutine.wait( 0.5 )
    end

    LAMBDAPANELS:RequestVariableFromServer( "LambdaTextTable", function( data )
        if !data then chat.AddText( "No text data was found by Server!" ) return end
        local tbl = data[ 1 ]

        LambdaCreateThread( function()
            for k, v in pairs( tbl ) do
                CreateTextEditingPanel( k )
            end

            if !IsValid( framescroll ) then return end

            -- Adding this panel here fixes the strange cut off of the last panel made in the for loop above
            local pnl = LAMBDAPANELS:CreateBasicPanel( framescroll, LEFT )
            pnl:SetSize( 200, 200 )
            pnl:DockMargin( 10, 0, 0, 0 )
            pnl:Dock( LEFT )
            framescroll:AddPanel( pnl )
            
            chat.AddText( "All text chat lines have been received!" )
        end )

    end )

end

RegisterLambdaPanel( "Text Lines", "Opens a panel that allows you to create custom Text Lines for Lambda Players. You must be a Super Admin to use this Panel. YOU MUST UPDATE LAMBDA DATA AFTER ANY CHANGES!", OpenTextPanel )