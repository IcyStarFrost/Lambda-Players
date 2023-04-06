local net = net
local pairs = pairs
local TableToJSON = util.TableToJSON
local NiceSize = string.NiceSize
local compress = util.Compress
local decompress = util.Decompress
local JSONToTable = util.JSONToTable
local table_Empty = table.Empty
local table_Count = table.Count
local ipairs = ipairs
local string_sub = string.sub
local table_concat = table.concat
local table_IsEmpty = table.IsEmpty
local SortedPairs = SortedPairs
local string_Replace = string.Replace
local string_lower = string.lower

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
    local vgui = vgui

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

    -- Creates a basic Editable panel
    function LAMBDAPANELS:CreateBasicPanel( parent, dock )
        local editablepanel = vgui.Create( "EditablePanel", parent )
        if dock then editablepanel:Dock( dock ) end
        return editablepanel
    end

    -- Creates a slider
    function LAMBDAPANELS:CreateNumSlider( parent, dock, default, text, min, max, decimals )
        local numslider = vgui.Create( "DNumSlider", parent )
        if dock then numslider:Dock( dock ) end
        numslider:SetText( text or "" )
        numslider:SetMin( min )
        numslider:SetMax( max )
        numslider:SetDecimals( decimals or 0 )
        numslider:SetValue( default )
        return numslider
    end

    function LAMBDAPANELS:CreateCheckBox( parent, dock, default, text )
        local basepnl = LAMBDAPANELS:CreateBasicPanel( parent, dock )
        basepnl:SetSize( 400, 16 )
        
        local checkbox = vgui.Create( "DCheckBox", basepnl )
        checkbox:SetSize( 16, 16 )
        checkbox:Dock( LEFT )
        checkbox:SetChecked( default or false )

        local lbl = LAMBDAPANELS:CreateLabel( text, basepnl, LEFT )
        lbl:SetSize( 400, 100 )
        lbl:DockMargin( 5, 0, 0, 0 )

        return checkbox, basepnl, lbl
    end

    -- Creates a box with a list of options
    -- I hate combo box. It's so weird
    function LAMBDAPANELS:CreateComboBox( parent, dock, options )
        local choiceindexes = { keys = {}, values = {} }
        local combobox = vgui.Create( "DComboBox", parent )
        if dock then combobox:Dock( dock ) end

        for k, v in pairs( options ) do 
            local index = combobox:AddChoice( k, v )
            choiceindexes.keys[ k ] = index
            choiceindexes.values[ v ] = index
        end

        function combobox:SelectOptionByKey( key )
            if choiceindexes.keys[ key ] then
                combobox:ChooseOptionID( choiceindexes.keys[ key ] )
            elseif choiceindexes.values[ key ] then
                combobox:ChooseOptionID( choiceindexes.values[ key ] )
            elseif key == nil then
                combobox:Clear()
            end
        end

        return combobox
    end

    -- Creates a text box
    function LAMBDAPANELS:CreateTextEntry( parent, dock, placeholder )
        local textentry = vgui.Create( "DTextEntry", parent )
        if dock then textentry:Dock( dock ) end
        textentry:SetPlaceholderText( placeholder or "" )
        return textentry
    end

    -- Creates a color mixer
    function LAMBDAPANELS:CreateColorMixer( parent, dock )
        local mixer = vgui.Create( "DColorMixer", parent )
        if dock then mixer:Dock( dock ) end
        return mixer
    end

    -- Creates a button
    function LAMBDAPANELS:CreateButton( parent, dock, text, doclick )
        local button = vgui.Create( "DButton", parent )
        if dock then button:Dock( dock ) end
        button:SetText( text or "" )
        button.DoClick = doclick
        return button
    end

    -- Creates a scroll panel
    function LAMBDAPANELS:CreateScrollPanel( parent, ishorizontal, dock )
        local class = ishorizontal and "DHorizontalScroller" or "DScrollPanel"
        local scroll = vgui.Create( class, parent )
        if dock then scroll:Dock( dock ) end
        return scroll 
    end

    -- Simply creates a label. Shocking!
    function LAMBDAPANELS:CreateLabel( text, parent, dock )
        local panel = vgui.Create( "DLabel", parent )
        panel:SetText( text )
        if dock then panel:Dock( dock ) end

        return panel
    end

    -- Creates a label that contains a URL
    function LAMBDAPANELS:CreateURLLabel( text, url, parent, dock )
        local panel = vgui.Create( "DLabelURL", parent )
        panel:SetText( text )
        panel:SetURL( url )
        if dock then panel:Dock( dock ) end

        return panel
    end
    
    -- Creates a button that will export the specified table to a specified file path
    function LAMBDAPANELS:CreateExportPanel( name, parent, dock, buttontext, targettable, exporttype, exportpath )

        local button = vgui.Create( "DButton", parent )
        button:SetText( buttontext )
        button:Dock( dock )

        function button:DoClick() 
            LAMBDAFS:WriteFile( exportpath, targettable, exporttype )
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

            local files, _ = file.Find( searchpath, "DATA", "nameasc" )

            for k, v in ipairs( files ) do
                local line = listview:AddLine( v )
                line:SetSortValue( 1, v )
            end

            function listview:OnClickLine( line )

                Derma_Query(
                    "Are you sure you want to import" .. line:GetSortValue( 1 ) .. "?",
                    "Confirmation:",
                    "Yes",
                    function() importfunction( string.Replace( searchpath, "*", "" ) .. line:GetSortValue( 1 ) ) end,
                    "No"
                )

            end

        end

        return panel
    end

    -- Creates a Text entry that acts as a search bar
    function LAMBDAPANELS:CreateSearchBar( listview, tbl, parent, searchkeys, linetextprefix )
        linetextprefix = linetextprefix or ""
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

                for k, v in SortedPairs( panel.l_searchtable ) do
                    local line = listview:AddLine( ( searchkeys and k or v ) .. linetextprefix ) 
                    line:SetSortValue( 1, v )
                end
                
                return 
            end
            
            for k, v in SortedPairs( panel.l_searchtable ) do

                if searchkeys then
                    local match = string_find( lower( tostring( k ) ), lower( value ) )

                    if match then local line = listview:AddLine( k .. linetextprefix ) line:SetSortValue( 1, v ) end
                else
                    local match = string_find( lower( tostring( v ) ), lower( value ) )

                    if match then local line = listview:AddLine( v .. linetextprefix ) line:SetSortValue( 1, v ) end
                end

            end
        end

        return panel
    end

    file.CreateDir( "lambdaplayers/presets" )
    -- Creates a panel that will handle convar presets. Cause Gmod's preset system is kinda garbage in my opinion
    function LAMBDAPANELS:CreateCVarPresetPanel( name, convars, presetcategory, isclientonly )
        if !isclientonly and !LocalPlayer():IsSuperAdmin() then chat.AddText( "This panel requires you to be a super admin due to this handling server data!" ) surface.PlaySound( "buttons/button10.wav" ) return end
        local frame = LAMBDAPANELS:CreateFrame( name, 300, 200 )

        LAMBDAPANELS:CreateLabel( "Right Click on a line for options", frame, TOP )

        local presetlist = vgui.Create( "DListView", frame )
        presetlist:Dock( FILL )
        presetlist:AddColumn( "Presets", 1 )

        local line = presetlist:AddLine( "[ Default ]" )
        line:SetSortValue( 1, convars )

        local presetfiledata = LAMBDAFS:ReadFile( "lambdaplayers/presets/" .. presetcategory .. ".json", "json" )
        if presetfiledata then
            for k, v in SortedPairs( presetfiledata ) do
                local line = presetlist:AddLine( k )
                line:SetSortValue( 1, v )
            end
        end

        function presetlist:OnRowRightClick( id, line )
            
            local menu = DermaMenu( false, presetlist )
            --menu:SetPos( input.GetCursorPos() )


            if line:GetColumnText( 1 ) != "[ Default ]" then 
                menu:AddOption( "Delete " .. line:GetColumnText( 1 ), function()
                    LAMBDAFS:RemoveVarFromKVFile( "lambdaplayers/presets/" .. presetcategory .. ".json", line:GetColumnText( 1 ), "json" )
                    presetlist:RemoveLine( id )
                    surface.PlaySound( "buttons/button15.wav" )
                    chat.AddText( "Deleted Preset " .. line:GetColumnText( 1 ) )
                end )
            end

            menu:AddOption( "Apply " .. line:GetColumnText( 1 ) .. " Preset", function()
                if isclientonly then
                    for k, v in pairs( line:GetSortValue( 1 ) ) do
                        GetConVar( k ):SetString( v )
                    end
                end

                local json = TableToJSON( line:GetSortValue( 1 ) )
                local compressed = compress( json )
                
                surface.PlaySound( "buttons/button15.wav" )
                chat.AddText( "Applied Preset " .. line:GetColumnText( 1 ) )

                if !isclientonly and LocalPlayer():IsSuperAdmin() then
                    net.Start( "lambdaplayers_setconvarpreset" )
                    net.WriteUInt( #compressed, 32 )
                    net.WriteData( compressed )
                    net.SendToServer()
                end
            end )

            menu:AddOption( "View " .. line:GetColumnText( 1 ) .. " Preset", function()
                local viewframe = LAMBDAPANELS:CreateFrame( line:GetColumnText( 1 ) .. " ConVar List", 300, 200 )

                local convarlist = vgui.Create( "DListView", viewframe )
                convarlist:Dock( FILL )
                convarlist:AddColumn( "ConVar", 1 )
                convarlist:AddColumn( "Value", 2 )

                for k, v in SortedPairs( line:GetSortValue( 1 ) ) do
                    convarlist:AddLine( k, v )
                end
                
            end )
            
        end

        LAMBDAPANELS:CreateButton( frame, BOTTOM, "Save Current Settings", function()

            Derma_StringRequest( "Save Preset", "Enter the name of this preset", "", function( str )
                if str == "[ Default ]" then chat.AddText( "You can not name a preset named the same as the default!" ) return end
                if str == "" then chat.AddText( "No text was inputted!" ) return end

                for k, v in ipairs( presetlist:GetLines() ) do
                    if v:GetColumnText( 1 ) == str then
                        
                        Derma_Query( str .. " already exists! Would you like to overwrite it with the new settings?", "File Overwrite", "Overwrite", function()
                        
                            local newpreset = {}

                            for k, v in pairs( convars ) do
                                newpreset[ k ] = GetConVar( k ):GetString()
                            end
            
                            surface.PlaySound( "buttons/button15.wav" )
                            chat.AddText( "Saved to Preset " .. str )
            
                            v:SetSortValue( 1, newpreset )
            
                            LAMBDAFS:UpdateKeyValueFile( "lambdaplayers/presets/" .. presetcategory .. ".json", { [ str ] = newpreset }, "json" ) 
                        
                        end, "Cancel", function() end )

                        return
                    end
                end

                local newpreset = {}

                for k, v in pairs( convars ) do
                    newpreset[ k ] = GetConVar( k ):GetString()
                end

                surface.PlaySound( "buttons/button15.wav" )
                chat.AddText( "Saved Preset " .. str )

                local line = presetlist:AddLine( str )
                line:SetSortValue( 1, newpreset )

                LAMBDAFS:UpdateKeyValueFile( "lambdaplayers/presets/" .. presetcategory .. ".json", { [ str ] = newpreset }, "json" ) 
            end, nil, "Confirm", "Cancel" )



        end )

    end


    local panelgetvalues = {
        [ "DTextEntry" ] = function( self ) return self:GetText() != "" and self:GetText() or nil end,
        [ "DCheckBox" ] = function( self ) return self:GetChecked() end,
        [ "DNumSlider" ] = function( self ) return self:GetValue() end,
        [ "DColorMixer" ] = function( self ) return self:GetColor() end,
        [ "DComboBox" ] = function( self ) local _,data = self:GetSelected() return data end,
    }

    local panelSetvalues = {
        [ "DTextEntry" ] = function( self, value ) self:SetText( ( value or "" ) ) end,
        [ "DCheckBox" ] = function( self, value ) self:SetChecked( ( value or false ) ) end,
        [ "DNumSlider" ] = function( self, value ) self:SetValue( ( value or self:GetDefaultValue() ) ) end,
        [ "DColorMixer" ] = function( self, value ) self:SetColor( ( value or Color( 255, 255, 255 ) ) ) end,
        [ "DComboBox" ] = function( self, value ) self:SelectOptionByKey( value ) end,
    }

    function LAMBDAPANELS:GetValue( pnl )
        if panelgetvalues[ pnl.LambdapnlClass ] then return panelgetvalues[ pnl.LambdapnlClass ]( pnl ) end 
    end

    function LAMBDAPANELS:SetValue( pnl, value )
        if panelSetvalues[ pnl.LambdapnlClass ] then panelSetvalues[ pnl.LambdapnlClass ]( pnl, value ) end 
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


    function LAMBDAPANELS:RequestVariableFromServer( var, callback )
        net.Start( "lambdaplayers_requestvariable" )
        net.WriteString( var )
        net.SendToServer()

        local datastring = ""
        local bytes = 0

        net.Receive( "lambdaplayers_returnvariable", function() 
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
        net.Start( "lambdaplayers_removevarfromkvfile" )
        net.WriteString( filename )
        net.WriteString( key )
        net.WriteString( type )
        net.SendToServer() 
    end

    function LAMBDAPANELS:WriteServerFile( filename, content, type ) 
        net.Start( "lambdaplayers_writeserverfile" )
        net.WriteString( filename )
        net.WriteString( TableToJSON( { content } ) )
        net.WriteString( type )
        net.SendToServer() 
    end



--[[     LAMBDAFS:UpdateSequentialFile( filename, addcontent, type ) 
    LAMBDAFS:UpdateKeyValueFile( filename, addcontent, type ) 
    LAMBDAFS:RemoveVarFromSQFile( filename, var, type )
    LAMBDAFS:RemoveVarFromKVFile( filename, key, type ) ]]

elseif SERVER then
    util.AddNetworkString( "lambdaplayers_writeserverfile" )
    util.AddNetworkString( "lambdaplayers_requestdata" )
    util.AddNetworkString( "lambdaplayers_requestvariable" )
    util.AddNetworkString( "lambdaplayers_updatesequentialfile" )
    util.AddNetworkString( "lambdaplayers_updatekvfile" )
    util.AddNetworkString( "lambdaplayers_removevarfromsqfile" )
    util.AddNetworkString( "lambdaplayers_removevarfromkvfile" )
    util.AddNetworkString( "lambdaplayers_returndata" )
    util.AddNetworkString( "lambdaplayers_returnvariable" )


    net.Receive( "lambdaplayers_writeserverfile", function( len, ply ) 
        if !ply:IsSuperAdmin() then return end
        local filename = net.ReadString()
        local content = JSONToTable( net.ReadString() )[ 1 ]
        local _type = net.ReadString()

        LAMBDAFS:WriteFile( filename, content, _type )

    end )

    net.Receive( "lambdaplayers_removevarfromkvfile", function( len, ply )
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


    net.Receive( "lambdaplayers_requestvariable", function( len, ply )
        if !ply:IsSuperAdmin() then return end

        local variable = net.ReadString()
        local content = _G[ variable ] or nil
        local bytes = 0
        local index = 0

        LambdaCreateThread( function()

            print( "Lambda Players Net: Preparing to send global variable " .. variable .. " to " .. ply:Name() .. " | " .. ply:SteamID() )

            if !content then
                net.Start( "lambdaplayers_returnvariable" )
                net.WriteString( "!!NIL" ) -- JSON chunk
                net.WriteBool( true ) -- Is done
                net.Send( ply )
            else
                local json = TableToJSON( { content } )
                local chunks = DataSplit( json )

                local count = table_Count( chunks )

                for key, chunk in ipairs( chunks ) do
                    index = index + 1
                
                    net.Start( "lambdaplayers_returnvariable" )
                    net.WriteString( chunk ) -- JSON chunk
                    net.WriteBool( index == count ) -- Is done
                    net.Send( ply )

                    bytes = bytes + #chunk
                    coroutine.wait( 0.5 )
                end

            end


            print( "Lambda Players Net: Sent " .. NiceSize( bytes ) .. " to " .. ply:Name() .. " | " .. ply:SteamID() )
        end )
    end )

    net.Receive( "lambdaplayers_setconvarpreset", function( len, ply )
        if !ply:IsSuperAdmin() then return end
        local bytes = net.ReadUInt( 32 )
        local data = net.ReadData( bytes )
        local decompressed = decompress( data )
        local convars = JSONToTable( decompressed)

        for k, v in pairs( convars ) do
            GetConVar( k ):SetString( v )
        end
    
        print( "Lambda Players: " .. ply:Name() .. " | " .. ply:SteamID() .. " Applied a preset on the server ")
    end )

end


function RegisterLambdaPanel( name, desc, func )
    local cmdName = ( string_lower( string_Replace( name, " ", "" ) ) )
    CreateLambdaConsoleCommand( "lambdaplayers_panels_open" .. cmdName .. "panel", func, true, desc, { name = "Open " .. name .. " Panel", category = "Panels" } )
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

