if SERVER then

    local function DataSplit( data )
        local index = 1
        local result = {}
        local buffer = {}
    
        for i = 0, #data do
            buffer[ #buffer + 1 ] = string.sub( data, i, i )
                    
            if #buffer == 10000 then
                result[ #result + 1 ] = table.concat( buffer )
                    index = index + 1
                buffer = {}
            end
        end
                
        result[ #result + 1 ] = table.concat( buffer )
        
        return result
    end

    net.Receive( "lambdaplayers_sendfile", function( len, ply )
        local filepath = net.ReadString()
        local bytes = 0
        local file_ = file.Open( filepath, "rb", "GAME" )

        data = file_:Read()

        file_:Close()

        if !data then print("FAIL", filepath, data ) return end

        -- Do not trust the client
        if string.StartWith( filepath, "sound/lambdaplayers/" ) or string.StartWith( filepath, "materials/lambdaplayers/" ) then
            
            print( "Lambda Players Net: Preparing to send data from " .. filepath .. " to " .. ply:Name() .. " | " .. ply:SteamID() )

            LambdaCreateThread( function()
                
                local compressed = util.Compress( data )
                local chunks = DataSplit( compressed )

                for k, block in ipairs( chunks ) do

                    net.Start( "lambdaplayers_sendfile" )
                    net.WriteUInt( #block, 32 )
                    net.WriteData( block, #block )
                    net.WriteBool( k == #chunks )
                    net.WriteString( filepath )
                    net.Send( ply )

                    bytes = bytes + #block
                    coroutine.wait( 0.3 )
                end
                
            
                print( "Lambda Players Net: Sent " .. string.NiceSize( bytes ) .. " to " .. ply:Name() .. " | " .. ply:SteamID() )
            end )

        end
    end )

elseif CLIENT then
    file.CreateDir( "lambdaplayers/fileshare" )

    local requestedfiles = {}
    local datachunks = {}

    for k, v in ipairs( file.Find( "lambdaplayers/fileshare", "DATA" ) ) do
        file.Delete( "lambdaplayers/fileshare/" .. v, "DATA" )
    end

    function LambdaRequestFile( filepath, callback )
        if requestedfiles[ filepath ] then return end
        if file.Exists( "lambdaplayers/fileshare/" .. string.Replace( filepath, "/", "" ), "DATA" ) then
            return "lambdaplayers/fileshare/" .. string.Replace( filepath, "/", "" )
        end

        requestedfiles[ filepath ] = callback

        net.Start( "lambdaplayers_sendfile" )
        net.WriteString( filepath )
        net.SendToServer()

    end

    net.Receive( "lambdaplayers_sendfile", function( len, ply )
        local size = net.ReadUInt( 32 )
        local data = net.ReadData( size )
        local isdone = net.ReadBool()
        local filepath = net.ReadString()


        local holder = datachunks[ filepath ] or ""
        holder = holder .. data
        datachunks[ filepath ] = holder

        if isdone then
            local uncompressed = util.Decompress( datachunks[ filepath ] )
            datachunks[ filepath ] = nil 

            local file_ = file.Open( "lambdaplayers/fileshare/" .. string.Replace( filepath, "/", "" ), "wb", "DATA" )
            file_:Write( uncompressed )
            file_:Close()

            print( "Lambda Players Net: Created file in ", "lambdaplayers/fileshare/" .. string.Replace( filepath, "/", "" ))

            requestedfiles[ filepath ]( "lambdaplayers/fileshare/" .. string.Replace( filepath, "/", "" ) )
            requestedfiles[ filepath ] = nil
        end

    end )
    
end