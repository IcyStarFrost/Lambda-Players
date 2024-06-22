-- TODO: Make this work with sprays

local bandwidth = GetConVar( "lambdaplayers_lambda_filesharing_networkspeed" )
local debug_mode = GetConVar( "lambdaplayers_debug" )

-- Purpose of this system here is to network files such as voice lines and pfps so other clients can hear and see them without the need of addons
if SERVER then

    -- Function to split files into chunks
    local function DataSplit( data )
        local index = 1
        local result = {}
        local buffer = {}
    
        for i = 0, #data do
            buffer[ #buffer + 1 ] = string.sub( data, i, i )
                    
            if #buffer == bandwidth:GetInt() then
                result[ #result + 1 ] = table.concat( buffer )
                    index = index + 1
                buffer = {}
            end
        end
                
        result[ #result + 1 ] = table.concat( buffer )
        
        return result
    end

    local active_streams = {}

    -- Stop the specified data sharing as the client requested
    net.Receive( "lambdaplayers_cancelfiletransfer", function( len, ply )
        local filepath = net.ReadString()
        active_streams[ ply ][ filepath ] = nil
    end )

    net.Receive( "lambdaplayers_sendfile", function( len, ply )
        local filepath = net.ReadString()
        local bytes = 0

        -- Read the file in binary mode. For some reason file.Read() is restricted(?) from reading the sounds folder. I presume it's the same for materials
        if debug_mode:GetBool() then
            print( "Lambda Players Net: Reading data from " .. filepath .. " for transfer to " .. ply:Name() .. " | " .. ply:SteamID() )
        end
        local file_ = file.Open( filepath, "rb", "GAME" )

        data = file_:Read()

        file_:Close()

        -- Abort
        if !data then return end

        -- Do not trust the client
        if string.StartWith( filepath, "sound/lambdaplayers/" ) or string.StartWith( filepath, "materials/lambdaplayers/" ) then
            if debug_mode:GetBool() then
                print( "Lambda Players Net: Preparing to send data from " .. filepath .. " to " .. ply:Name() .. " | " .. ply:SteamID() )
            end
            active_streams[ ply ] = active_streams[ ply ] or {}

            if active_streams[ ply ][ filepath ] then 
                if debug_mode:GetBool() then print( "Lambda Players Net: Aborting! Client is already being sent " .. filepath .. "!" ) end
                return 
            end

            active_streams[ ply ][ filepath ] = true

            LambdaCreateThread( function()
                
                -- Compress the data to speed up file transfer over the network
                local compressed = util.Compress( data )
                local chunks = DataSplit( compressed )

                -- Send each chunk to the client that sent the net message
                for k, block in ipairs( chunks ) do
                    if !active_streams[ ply ][ filepath ] then
                        if debug_mode:GetBool() then
                            print( "Lambda Players Net: Aborting! " .. ply:Name() .. " | " .. ply:SteamID() .. " Requested net streaming for " .. filepath .. " to cease!" )
                        end
                        return
                    end

                    if debug_mode:GetBool() then
                        print( "Lambda Players Net: Sent " .. #block .. " bytes (" .. ( math.Round( k / #chunks * 100, 0 ) ) .. "%) to " .. ply:Name() .. " | " .. ply:SteamID() )
                    end

                    net.Start( "lambdaplayers_sendfile" )
                    net.WriteUInt( #block, 32 )
                    net.WriteData( block, #block )
                    net.WriteBool( k == #chunks )
                    net.WriteString( filepath )
                    net.WriteString( math.Round( k / #chunks * 100, 0 ) .. "%" )
                    net.Send( ply )

                    bytes = bytes + #block
                    coroutine.wait( 0.3 )
                end
                
                if debug_mode:GetBool() then
                    print( "Lambda Players Net: Sent " .. string.NiceSize( bytes ) .. " to " .. ply:Name() .. " | " .. ply:SteamID() )
                end
            end )

        end
    end )

elseif CLIENT then
    file.CreateDir( "lambdaplayers/fileshare" )

    local requestedfiles = {} -- Table holding filepaths that are requested with a callback
    local datachunks = {} -- Table holding in progress data chunks

    -- Clear the fileshare folder on load to save storage
    for k, v in ipairs( file.Find( "lambdaplayers/fileshare/*", "DATA" ) ) do
        file.Delete( "lambdaplayers/fileshare/" .. v, "DATA" )
    end

    -- Function to request files RESTRICTED to sound and material folder

    -- If continue_callback is provided a function, if the function returns false, the data stream will be terminated.
    function LambdaRequestFile( filepath, callback, continue_callback )
        if requestedfiles[ filepath ] then return end
        if file.Exists( "lambdaplayers/fileshare/" .. string.Replace( filepath, "/", "" ), "DATA" ) then -- Already exists.
            return "lambdaplayers/fileshare/" .. string.Replace( filepath, "/", "" )
        end

        requestedfiles[ filepath ] = { callback, continue_callback }

        net.Start( "lambdaplayers_sendfile" )
        net.WriteString( filepath )
        net.SendToServer()

    end

    net.Receive( "lambdaplayers_sendfile", function( len, ply )
        local size = net.ReadUInt( 32 )
        local data = net.ReadData( size )
        local isdone = net.ReadBool()
        local filepath = net.ReadString()
        local percent_done = net.ReadString()

        hook.Add( "Think", "lambdaplayers_fileshare_" .. filepath, function()
            local should_continue = requestedfiles[ filepath ][ 2 ] and requestedfiles[ filepath ][ 2 ]() or !requestedfiles[ filepath ][ 2 ] and true
            if should_continue == false then
                if debug_mode:GetBool() then
                    print( "Lambda Players Net: Aborting request for " .. filepath )
                end
                net.Start( "lambdaplayers_cancelfiletransfer" )
                net.WriteString( filepath )
                net.SendToServer()
                hook.Remove( "Think", "lambdaplayers_fileshare_" .. filepath )
                return
            end
        end )
        local should_continue = requestedfiles[ filepath ][ 2 ] and requestedfiles[ filepath ][ 2 ]() or true
        if debug_mode:GetBool() then
            print( "Lambda Players Net: Received " .. size .. " bytes (" .. percent_done .. ") for " .. filepath, should_continue )
        end

        -- Build the chunks together
        local holder = datachunks[ filepath ] or ""
        holder = holder .. data
        datachunks[ filepath ] = holder

        -- Decompress, write to a file, and return the file path to the callback
        if isdone then
            hook.Remove( "Think", "lambdaplayers_fileshare_" .. filepath )
            local uncompressed = util.Decompress( datachunks[ filepath ] )
            datachunks[ filepath ] = nil 

            local file_ = file.Open( "lambdaplayers/fileshare/" .. string.Replace( filepath, "/", "" ), "wb", "DATA" )
            file_:Write( uncompressed )
            file_:Close()

            if debug_mode:GetBool() then
                print( "Lambda Players Net: Created file in ", "lambdaplayers/fileshare/" .. string.Replace( filepath, "/", "" ))
            end
            
            requestedfiles[ filepath ][ 1 ]( "lambdaplayers/fileshare/" .. string.Replace( filepath, "/", "" ) )
            requestedfiles[ filepath ] = nil
        end

    end )
    
end