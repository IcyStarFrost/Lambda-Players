local net = net
local pairs = pairs
local table_insert = table.insert
local TableToJSON = util.TableToJSON
local JSONToTable = util.JSONToTable
local table_ClearKeys = table.ClearKeys
local table_Empty = table.Empty
local SortedPairs = SortedPairs

-- Base panel stuff
if CLIENT then
    local string_find = string.find
    local lower = string.lower
    local tostring = tostring

    LAMBDAPANELS = {}

    -- Creates a Frame Panel
    function LAMBDAPANELS:CreateFrame( name, width, height )

        local panel = vgui.Create( "DFrame" )
        panel:SetSize( width, height )
        panel:SetSizable( true )
        panel:SetTitle( name )
        panel:SetDeleteOnClose( true )
        panel:SetIcon( "lambdaplayers/icon/lambda.png" )
        panel:Center()
        panel:MakePopup()

        return panel
    end

    function LAMBDAPANELS:CreateLabel( text, parent, dock )

        local panel = vgui.Create( "DLabel", parent )
        panel:SetText( text )
        panel:Dock( dock )

        return panel
    end

    function LAMBDAPANELS:CreateExportPanel( name, parent, dock, buttontext, targettable, exporttype, exportpath )

        local button = vgui.Create( "DButton", parent )
        button:SetText( buttontext )
        button:Dock( dock )

        function button:DoClick() 
            LAMBDAPANELS:WriteServerFile( exportpath, targettable, exporttype )
            Derma_Message( "Exported file to " .. "garrysmod/data/" .. exportpath, "Export", "Ok" )
        end

    end

    function LAMBDAPANELS:CreateImportPanel( name, parent, dock, buttontext, labels, searchpath, importfunction )


        local button = vgui.Create( "DButton", parent )
        button:SetText( buttontext )
        button:Dock( dock )

        function button:DoClick() 

            local panel = LAMBDAPANELS:CreateFrame( name .. " Import Panel", 400, 450 )

            for k, v in ipairs( labels ) do
                LAMBDAPANELS:CreateLabel( v, panel, TOP )
            end


            local listview = vgui.Create( "DListView", panel )
            listview:Dock( FILL )
            listview:AddColumn( "Files", 1 )

            local files, _ = file.Find( searchpath .. "/*", "DATA", "nameasc" )

            for k, v in ipairs( files ) do
                local line = listview:AddLine( v )
                line:SetSortValue( 1, v )
            end

            function listview:OnClickLine( line )

                Derma_Query(
                    "Are you sure you want to import" .. line:GetSortValue( 1 ) .. "?",
                    "Confirmation:",
                    "Yes",
                    function() importfunction( searchpath .. "/" .. line:GetSortValue( 1 ) ) end,
                    "No"
                )

            end

        end

        return panel
    end

    -- Creates a Text entry that acts as a search bar
    function LAMBDAPANELS:CreateSearchBar( listview, tbl, parent, searchkeys )

        local panel = vgui.Create( "DTextEntry", parent )
        panel:SetPlaceholderText( "Search Bar" )

        panel.l_searchtable = tbl

        -- Sets the table to search in
        function panel:SetSearchTable( tbl )
            panel.l_searchtable = tbl
        end

        function panel:OnEnter( value )
            listview:Clear()

            if value == "" then 

                for k, v in pairs( panel.l_searchtable ) do
                    local line = listview:AddLine( searchkeys and k or v  ) 
                    line:SetSortValue( 1, v )
                end
                
                return 
            end
            
            for k, v in pairs( panel.l_searchtable ) do

                if searchkeys then
                    local match = string_find( lower( tostring( k ) ), lower( value ) )

                    if match then local line = listview:AddLine( k ) line:SetSortValue( 1, v ) end
                else
                    local match = string_find( lower( tostring( v ) ), lower( value ) )

                    if match then local line = listview:AddLine( v ) line:SetSortValue( 1, v ) end
                end

            end
        end

        return panel
    end
    

    function LAMBDAPANELS:SortValues( tbl )
        local sorttable = {}

        for k, v in pairs( tbl ) do sorttable[ v ] = v end

        table_Empty( tbl )
        for k, v in SortedPairs( sorttable ) do tbl[ #tbl + 1 ] = v end
    end

    function LAMBDAPANELS:WriteServerFile( filename, content, type )
        net.Start( "lambdaplayers_writefile" )
        net.WriteString( filename )
        net.WriteString( TableToJSON( { content } ) )
        net.WriteString( type )
        net.SendToServer()
    end

    function LAMBDAPANELS:AddToServerFile( filename, content, type )
        net.Start( "lambdaplayers_addtoserverfile" )
        net.WriteString( filename )
        net.WriteString( TableToJSON( { content } ) )
        net.WriteString( type )
        net.SendToServer()
    end

    function LAMBDAPANELS:RemoveDataFromServerFile( filename, content, iskey, type )
        net.Start( "lambdaplayers_removedatafromfile" )
        net.WriteString( filename )
        net.WriteString( TableToJSON( { content } ) )
        net.WriteString( type )
        net.WriteBool( iskey )
        net.SendToServer()
    end

    function LAMBDAPANELS:RequestDataFromServer( filepath, callback )
        net.Start( "lambdaplayers_requestdata" )
        net.WriteString( filepath )
        net.WriteString( "json" )
        net.SendToServer()

        local retrieveddata = {}
        local bytes = 0

        net.Receive( "lambdaplayers_returndata", function( len )
            local key = net.ReadString()
            local value = net.ReadString()
            local isdone = net.ReadBool()
            

            bytes = bytes + #value + #key
            if key != "" and value != "" then
                key = JSONToTable( key ) [ 1 ]
                value = JSONToTable( value )[ 1 ]

                retrieveddata[ key ] = value
            end

            if isdone then
                callback( retrieveddata, bytes )
            end

        end )

    end

elseif SERVER then
    util.AddNetworkString( "lambdaplayers_requestdata" )
    util.AddNetworkString( "lambdaplayers_returndata" )
    util.AddNetworkString( "lambdaplayers_addtoserverfile" )
    util.AddNetworkString( "lambdaplayers_writefile" )
    util.AddNetworkString( "lambdaplayers_removedatafromfile" )

    local table_Count = table.Count
    local NiceSize = string.NiceSize


    net.Receive( "lambdaplayers_writefile", function( len, ply )
        local filename = net.ReadString()
        local content = net.ReadString()
        local type = net.ReadString()
        content = JSONToTable( content )[ 1 ]
    
        LAMBDAFS:WriteFile( filename, content, type ) 
    end )

    net.Receive( "lambdaplayers_addtoserverfile", function( len, ply )
        local filename = net.ReadString()
        local content = net.ReadString()
        local type = net.ReadString()
        content = JSONToTable( content )[ 1 ]
    
        LAMBDAFS:UpdateFile( filename, content, type ) 

    end )

    net.Receive( "lambdaplayers_removedatafromfile", function( len, ply )
        local filename = net.ReadString()
        local content = net.ReadString()
        local type = net.ReadString()
        local iskey = net.ReadBool()
        content = JSONToTable( content )[ 1 ]
        LAMBDAFS:RemoveDataFromFile( filename, content, iskey, type )
    end )

    net.Receive( "lambdaplayers_requestdata", function( len, ply )
        local requestedfilepath = net.ReadString()
        local filetype = net.ReadString()
        local bytes = 0

        local fileexists = file.Exists( requestedfilepath, "DATA" )

        print( "Lambda Players Net: " .. ply:Name() .. " | " .. ply:SteamID() .. " requested data from " .. requestedfilepath )

        if !fileexists then
            net.Start( "lambdaplayers_returndata" )
                net.WriteString( "" )
                net.WriteString( "" )
                net.WriteBool( true )
            net.Send( ply )
            bytes = 1
        else
            local filedata = LAMBDAFS:ReadFile( requestedfilepath, filetype )
            local count = table_Count( filedata )
            local currentindex = 0
            for k, v in pairs( filedata ) do
                currentindex = currentindex + 1

                local json = TableToJSON( { v } )
                bytes = bytes + #json

                net.Start( "lambdaplayers_returndata" )
                    net.WriteString( TableToJSON( { k } ) )
                    net.WriteString( json )
                    net.WriteBool( currentindex == count )
                net.Send( ply )
                
            end

        end

        print( "Lambda Players Net: Sent " .. NiceSize( bytes ) .. " to " .. ply:Name() .. " | " .. ply:SteamID() )
    
    end )

end


function RegisterLambdaPanel( name, desc, func )
    CreateLambdaConsoleCommand( "lambdaplayers_panels_open" .. name .. "panel", func, true, desc, { name = "Open " .. name .. " Panel", category = "Panels" } )
end

local panels = file.Find( "lambdaplayers/lambda/panels/*", "LUA", "nameasc" )

for k, luafile in ipairs( panels ) do
    if SERVER then
        AddCSLuaFile( "lambdaplayers/lambda/panels/" .. luafile )
    elseif CLIENT then
        include( "lambdaplayers/lambda/panels/" .. luafile )
        print( "Lambda Players: Included Panel [ " .. luafile .. " ]" )
    end
end

