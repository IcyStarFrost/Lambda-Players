local net = net
local pairs = pairs
local table_insert = table.insert
local TableToJSON = util.TableToJSON
local NiceSize = string.NiceSize
local JSONToTable = util.JSONToTable
local table_ClearKeys = table.ClearKeys
local table_Empty = table.Empty
local table_Count = table.Count
local ipairs = ipairs
local string_sub = string.sub
local table_concat = table.concat
local table_IsEmpty = table.IsEmpty
local SortedPairs = SortedPairs

-- Data splitting done by https://github.com/alexgrist/NetStream
-- Very helpful function here
local function DataSplit( data )
    local index = 1
    local result = {}
    local buffer = {}

    for i = 0, #data do
        buffer[ #buffer + 1 ] = string_sub( data, i, i )
                
        if #buffer == 32768 then
            result[ #result + 1 ] = table_concat( buffer )
                index = index + 1
            buffer = {}
        end
    end
            
    result[ #result + 1 ] = table_concat( buffer )
    
    return result
end

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

    -- Simply creates a label. Shocking!
    function LAMBDAPANELS:CreateLabel( text, parent, dock )

        local panel = vgui.Create( "DLabel", parent )
        panel:SetText( text )
        panel:Dock( dock )

        return panel
    end

    -- Creates a button that will export the specified table to a specified file path
    function LAMBDAPANELS:CreateExportPanel( name, parent, dock, buttontext, targettable, exporttype, exportpath )

        local button = vgui.Create( "DButton", parent )
        button:SetText( buttontext )
        button:Dock( dock )

        function button:DoClick() 
            LAMBDAPANELS:WriteServerFile( exportpath, targettable, exporttype )
            Derma_Message( "Exported file to " .. "garrysmod/data/" .. exportpath, "Export", "Ok" )
        end

    end

    -- Creates a button that will open a panel that will search for files to import. importfunction must be used to handle the importing
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
    
    -- Sorts a table of strings by alphabet
    function LAMBDAPANELS:SortStrings( tbl )
        local sorttable = {}
        for k, v in pairs( tbl ) do sorttable[ v ] = v end
        table_Empty( tbl )
        for k, v in SortedPairs( sorttable ) do tbl[ #tbl + 1 ] = v end
    end

    -- Requests data from the specified file from the server
    function LAMBDAPANELS:RequestDataFromServer( filepath, type, callback )
        net.Start( "lambdaplayers_requestdata" )
        net.WriteString( filepath )
        net.WriteString( type )
        net.SendToServer()

        local datastring = ""
        local bytes = 0

        net.Receive( "lambdaplayers_returndata", function() 
            local chunkdata = net.ReadString()
            local isdone = net.ReadBool()
        
            datastring = datastring .. chunkdata
            bytes = bytes + #chunkdata

            if isdone then
                callback( datastring != "!!NIL" and JSONToTable( datastring ) or nil )
                chat.AddText( "Received all data from server! " .. NiceSize( bytes ) .. " of data was received" )
            end
            
        end )

    end


    -- Comment taken from shared/filesystem.lua
    -- Updates or creates a new file containing a sequential table
    -- type should be json or compressed
    function LAMBDAPANELS:UpdateSequentialFile( filename, addcontent, type ) 
        net.Start( "lambdaplayers_updatesequentialfile" )
        net.WriteString( filename )
        net.WriteType( addcontent )
        net.WriteString( type )
        net.SendToServer() 
    end

    -- Comment taken from shared/filesystem.lua
    -- Updates or creates a new file containing a table that uses strings as keys
    -- type should be json or compressed
    function LAMBDAPANELS:UpdateKeyValueFile( filename, addcontent, type ) 
        net.Start( "lambdaplayers_updatekvfile" )
        net.WriteString( filename )
        net.WriteString( TableToJSON( addcontent ) )
        net.WriteString( type )
        net.SendToServer() 
    end

    -- Comment taken from shared/filesystem.lua
    -- SQ short for Sequential
    -- Removes a value from the specified file containing a sequential table
    function LAMBDAPANELS:RemoveVarFromSQFile( filename, var, type ) 
        net.Start( "lambdaplayers_removevarfromsqfile" )
        net.WriteString( filename )
        net.WriteType( var )
        net.WriteString( type )
        net.SendToServer() 
    end

    -- Comment taken from shared/filesystem.lua
    -- KV short for Key Value
    -- Removes a key from the specified file containing a table that uses strings as keys
    function LAMBDAPANELS:RemoveVarFromKVFile( filename, key, type ) 
        net.Start( "lambdaplayers_removevarfromsqfile" )
        net.WriteString( filename )
        net.WriteString( key )
        net.WriteString( type )
        net.SendToServer() 
    end



--[[     LAMBDAFS:UpdateSequentialFile( filename, addcontent, type ) 
    LAMBDAFS:UpdateKeyValueFile( filename, addcontent, type ) 
    LAMBDAFS:RemoveVarFromSQFile( filename, var, type )
    LAMBDAFS:RemoveVarFromKVFile( filename, key, type ) ]]

elseif SERVER then
    util.AddNetworkString( "lambdaplayers_requestdata" )
    util.AddNetworkString( "lambdaplayers_updatesequentialfile" )
    util.AddNetworkString( "lambdaplayers_updatekvfile" )
    util.AddNetworkString( "lambdaplayers_removevarfromsqfile" )
    util.AddNetworkString( "lambdaplayers_removevarfromkvfile" )
    util.AddNetworkString( "lambdaplayers_returndata" )

    net.Receive( "lambdaplayers_removevarfromsqfile", function( len, ply )
        if !ply:IsSuperAdmin() then return end
        local filename = net.ReadString()
        local key = net.ReadString()
        local _type = net.ReadString()
    
        LAMBDAFS:RemoveVarFromKVFile( filename, key, _type )
    end )

    net.Receive( "lambdaplayers_removevarfromsqfile", function( len, ply )
        if !ply:IsSuperAdmin() then return end
        local filename = net.ReadString()
        local var = net.ReadType()
        local _type = net.ReadString()
    
        LAMBDAFS:RemoveVarFromSQFile( filename, var, _type )
    end )
    
    net.Receive( "lambdaplayers_updatekvfile", function( len, ply )
        if !ply:IsSuperAdmin() then return end
        local filename = net.ReadString()
        local content = JSONToTable( net.ReadString() )
        local _type = net.ReadString()

        LAMBDAFS:UpdateKeyValueFile( filename, content, _type ) 
    end )

    net.Receive( "lambdaplayers_updatesequentialfile", function( len, ply )
        if !ply:IsSuperAdmin() then return end
        local filename = net.ReadString()
        local content = net.ReadType() 
        local _type = net.ReadString()

        LAMBDAFS:UpdateSequentialFile( filename, content, _type ) 
    end )

    net.Receive( "lambdaplayers_requestdata", function( len, ply )
        if !ply:IsSuperAdmin() then return end

        local filepath = net.ReadString()
        local _type = net.ReadString()
        local content = LAMBDAFS:ReadFile( filepath, _type, "DATA" )
        local bytes = 0
        local index = 0

        LambdaCreateThread( function()

            print( "Lambda Players Net: Preparing to send data from " .. filepath .. " to " .. ply:Name() .. " | " .. ply:SteamID() )

            if !content or table_IsEmpty( content ) then
                net.Start( "lambdaplayers_returndata" )
                net.WriteString( "!!NIL" ) -- JSON chunk
                net.WriteBool( true ) -- Is done
                net.Send( ply )
            else
                content = TableToJSON( content )
                local chunks = DataSplit( content )

                for key, chunk in ipairs( chunks ) do
                    index = index + 1
                    
                    net.Start( "lambdaplayers_returndata" )
                    net.WriteString( chunk ) -- JSON chunk
                    net.WriteBool( index == key ) -- Is done
                    net.Send( ply )

                    bytes = bytes + #chunk
                    coroutine.wait( 0.5 )
                end

            end


            print( "Lambda Players Net: Sent " .. NiceSize( bytes ) .. " to " .. ply:Name() .. " | " .. ply:SteamID() )
        end )
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

