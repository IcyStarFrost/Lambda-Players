
file.CreateDir( "lambdaplayers/texttypes")
file.CreateDir( "lambdaplayers/exportedtexttypes")
file.CreateDir( "lambdaplayers/importtexttypes")
local function OpenTextPanel( ply )
    if !ply:IsSuperAdmin() then return end

    local textdata = {}
    local exportpnl    
    local importpnl
    local curtexttype = ""

    local frame = LAMBDAPANELS:CreateFrame( "Text Line Editor", 700, 600 )

    function frame:OnClose()
        chat.AddText( "Remember to Update Lambda Data after any changes!" )
    end

    LAMBDAPANELS:CreateURLLabel( "Click here to learn about the default text types and keywords", "https://github.com/IcyStarFrost/Lambda-Players/wiki/Text-Chat", frame, TOP )
    LAMBDAPANELS:CreateLabel( "Select a text type to edit with the box below. Right Click a line to remove it", frame, TOP )

    local textentry = LAMBDAPANELS:CreateTextEntry( frame, BOTTOM, "Enter text here" )

    local listview = vgui.Create( "DListView", frame )
    listview:Dock( FILL )
    local column = listview:AddColumn( "Loading..", 1 )

    local toppnl = LAMBDAPANELS:CreateBasicPanel( frame, TOP )

    local textypebox = LAMBDAPANELS:CreateComboBox( toppnl, LEFT )
    local searchbar = LAMBDAPANELS:CreateSearchBar( listview, textdata, toppnl )

    searchbar:Dock( LEFT )
    searchbar:SetSize( frame:GetWide() / 2, 100 )
    textypebox:SetSize( frame:GetWide() / 2, 100 )

    function textentry:OnEnter( val )
        if val == "" then return end
        LAMBDAPANELS:UpdateSequentialFile( "lambdaplayers/texttypes/" .. curtexttype .. ".json", val, "json" ) 
        textentry:SetText( "" )
        textdata[ #textdata + 1 ] = val
        chat.AddText( "Added " .. val .. " to " .. curtexttype .. " lines" )
        surface.PlaySound( "buttons/button15.wav" )

        textentry:RequestFocus()

        local line = listview:AddLine( val )
        line:SetSortValue( 1, val )
    end

    function listview:OnRowRightClick( id, line )
        chat.AddText( "Removed " .. line:GetSortValue( 1 ) .. " from " .. curtexttype .. " lines" )
        surface.PlaySound( "buttons/button15.wav" )
        table.RemoveByValue( textdata, line:GetSortValue( 1 ) )
        listview:RemoveLine( id )
        LAMBDAPANELS:RemoveVarFromSQFile( "lambdaplayers/texttypes/" .. curtexttype .. ".json", line:GetSortValue( 1 ), "json" ) 
    end

    function listview:DoDoubleClick( id, line )
        surface.PlaySound( "buttons/button16.wav" )
        textentry:SetText( line:GetSortValue( 1 ) )
    end

    function textypebox:OnSelect( index, value, data )
        frame:UpdateTextType( value, data )
    end

    function frame:UpdateTextType( texttype, tbl )
        curtexttype = texttype
        table.Empty( textdata )

        if IsValid( exportpnl ) then
            exportpnl:Remove()
        end

        if IsValid( importpnl ) then
            importpnl:Remove()
        end
        

        exportpnl = LAMBDAPANELS:CreateExportPanel( "Text", frame, BOTTOM, "Export " .. texttype .. " Lines", textdata, "json", "lambdaplayers/exportedtexttypes/" .. texttype .. ".vmt" )

        local labels = {
            "Place exported any texttype .vmt files or .txt files that are formatted like",
            "A Text line 1",
            "A Text line 2",
            "A Text line 3",
            "In the garrysmod/data/lambdaplayers/importtexttypes folder to be able to import them"
        }

        importpnl = LAMBDAPANELS:CreateImportPanel( "Text", frame, BOTTOM, "Import " .. texttype .. " Lines", labels, "lambdaplayers/importtexttypes/*", function( path )
            local count = 0

            local jsoncontents = LAMBDAFS:ReadFile( path, "json" )

            if jsoncontents then
                
                for k, v in ipairs( jsoncontents ) do
                    if !table.HasValue( textdata, v ) then 
                        count = count + 1 
                        LAMBDAPANELS:UpdateSequentialFile( "lambdaplayers/texttypes/" .. texttype .. ".json", v, "json" )

                        local line = listview:AddLine( v )
                        line:SetSortValue( 1, v )
                
                        table.insert( textdata, v )
                    end
                end

                chat.AddText( "Imported " .. count .. " text lines to " .. texttype )
            else
                local txtcontents = LAMBDAFS:ReadFile( path ) 

                txtcontents = string.Explode( "\n", txtcontents )

                for k, v in ipairs( txtcontents ) do
                    if !table.HasValue( textdata, v ) then 
                        count = count + 1 
                        LAMBDAPANELS:UpdateSequentialFile( "lambdaplayers/texttypes/" .. texttype .. ".json", v, "json" )

                        local line = listview:AddLine( v )
                        line:SetSortValue( 1, v )
                
                        table.insert( textdata, v )
                    end
                end

                chat.AddText( "Imported " .. count .. " text lines to " .. texttype )
            end
        end )

        for k, v in ipairs( listview:GetLines() ) do
            listview:RemoveLine( k )
        end

        column:SetName( texttype .. " text lines" )

        if !LocalPlayer():IsListenServerHost() then
            LAMBDAPANELS:RequestDataFromServer( "lambdaplayers/texttypes/" .. texttype .. ".json", "json", function( data )
                if !data then return end

                table.Merge( textdata, data )

                for k, v in ipairs( textdata ) do
                    local line = listview:AddLine( v )
                    line:SetSortValue( 1, v )
                end
            end )
        else
            local data = LAMBDAFS:ReadFile( "lambdaplayers/texttypes/" .. texttype .. ".json", "json" )
            if !data then return end

            table.Merge( textdata, data )

            for k, v in ipairs( textdata ) do
                local line = listview:AddLine( v )
                line:SetSortValue( 1, v )
            end
        end
    end

    LAMBDAPANELS:RequestVariableFromServer( "LambdaTextTable", function( data )
        if !data then chat.AddText( "No text data was found by Server!" ) return end
        local tbl = data[ 1 ]

        -- data key = text type
        -- data value = sequential table

        if !IsValid( textypebox ) then return end

        textypebox:SetOptions( tbl )
        textypebox:SelectOptionByKey( "idle" )
        
        chat.AddText( "All text chat lines have been received!" )

    end )

end

RegisterLambdaPanel( "Text Lines", "Opens a panel that allows you to create custom Text Lines for Lambda Players. You must be a Super Admin to use this Panel. YOU MUST UPDATE LAMBDA DATA AFTER ANY CHANGES!", OpenTextPanel )