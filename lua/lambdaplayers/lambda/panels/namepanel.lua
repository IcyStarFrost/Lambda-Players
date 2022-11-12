file.CreateDir( "lambdaplayers/nameimport" )
file.CreateDir( "lambdaplayers/exportednames" )


-- This took way to long to make. It wasn't this panel's fault it was more so I was having so much trouble with file writing and that stuff
local function OpenNamePanel( ply )
    if !IsValid( ply ) then return elseif !ply:IsSuperAdmin() then notification.AddLegacy( "You must be a Super Admin in order to use this!", NOTIFY_ERROR, 4) surface.PlaySound( "buttons/button10.wav" ) return end

    local names = {}
    local sortednames = {}
    local hasdata = false
    local panel = LAMBDAPANELS:CreateFrame( "Custom Name Editor", 300, 300 ) -- Start with the panel

    local listview = vgui.Create( "DListView", panel ) -- List
    listview:Dock( FILL )
    listview:AddColumn( "Names", 1 )

    local addtextentry = vgui.Create( "DTextEntry", panel )
    addtextentry:SetPlaceholderText( "Enter names here!" )
    addtextentry:Dock( BOTTOM )

    LAMBDAPANELS:CreateLabel( "Remove a name by Right Clicking it", panel, TOP )
    LAMBDAPANELS:CreateLabel( "Remember to Update Lambda Data after any changes!", panel, TOP )

    local searchbar = LAMBDAPANELS:CreateSearchBar( listview, names, panel )
    searchbar:Dock( TOP )

    local labels = {
        "Place exported customnames.jsons or .txt files that are formatted like",
        "Garry",
        "Spanish Skeleton",
        "Oliver",
        "In the garrysmod/data/lambdaplayers/nameimport folder to be able to import them"
    }

    LAMBDAPANELS:CreateExportPanel( "Name", panel, BOTTOM, "Export Names to file", names, "json", "lambdaplayers/exportednames/nameexport.json" )

    LAMBDAPANELS:CreateImportPanel( "Name", panel, BOTTOM, "Import .TXT/.JSON files", labels, "lambdaplayers/nameimport", function( path )
        local isjson = string.EndsWith( path, ".json" )

        local count = 0

        if isjson then
            local jsoncontents = LAMBDAFS:ReadFile( path, "json" )
            
            for k, v in ipairs( jsoncontents ) do
                if !table.HasValue( names, v ) then 
                    count = count + 1 
                    LAMBDAPANELS:AddToServerFile( "lambdaplayers/customnames.json", { "!!INSERT", v }, "json" ) 

                    local line = listview:AddLine( v )
                    line:SetSortValue( 1, v )
            
                    table.insert( names, v )
                end
            end

            chat.AddText( "Imported " .. count .. " names to Server's Custom Names" )
        else
            local txtcontents = LAMBDAFS:ReadFile( path ) 
            txtcontents = string.Explode( "\n", txtcontents )

            for k, v in ipairs( txtcontents ) do
                if !table.HasValue( names, v ) then 
                    count = count + 1 
                    LAMBDAPANELS:AddToServerFile( "lambdaplayers/customnames.json", { "!!INSERT", v }, "json" ) 

                    local line = listview:AddLine( v )
                    line:SetSortValue( 1, v )
            
                    table.insert( names, v )
                end
            end

            chat.AddText( "Imported " .. count .. " names to Server's Custom Names" )
        end

    
    end )

    function addtextentry:OnEnter( value )
        if value == "" or !hasdata then return end
        addtextentry:SetText( "" )

        -- Since we get a copy of the Server's name data, we can safely prevent duplicates from here
        if table.HasValue( names, value ) then chat.AddText( "Server already has this name!" ) return end

        local line = listview:AddLine( value )
        line:SetSortValue( 1, value )

        table.insert( names, value )

        chat.AddText( "Added " .. value .. " to the Server's Custom Names" )
        LAMBDAPANELS:AddToServerFile( "lambdaplayers/customnames.json", { "!!INSERT", value }, "json" )
    end

    function listview:OnRowRightClick( id, line )
        chat.AddText( "Removed " .. line:GetSortValue( 1 ) .. " from the Server's names!" ) 
        table.RemoveByValue( names , line:GetSortValue( 1 ) )
        LAMBDAPANELS:RemoveDataFromServerFile( "lambdaplayers/customnames.json", line:GetSortValue( 1 ), false, "json" )
        listview:RemoveLine( id )
    end

    chat.AddText( "Requesting Names from Server.." )

    LAMBDAPANELS:RequestDataFromServer( "lambdaplayers/customnames.json", function( data, bytes )

        LAMBDAPANELS:SortValues( data )
        table.Merge( names, data ) 
        
        hasdata = true

        for k, v in ipairs( data ) do
            local line = listview:AddLine( v )
            line:SetSortValue( 1, v )
        end

        listview:InvalidateLayout()

        chat.AddText( "Received all names from Server! " .. string.NiceSize( bytes ) .. " of data was received" )
    end )

end

RegisterLambdaPanel( "Name", "Opens a panel that allows you to create custom names for Lambda Players. You must be a Super Admin to use this Panel", OpenNamePanel )