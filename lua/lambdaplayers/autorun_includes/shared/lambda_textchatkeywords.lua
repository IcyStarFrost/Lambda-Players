local table_Add = table.Add
local random = math.random
local player_GetAll = player.GetAll
local pairs = pairs
local string_find = string.find
local RandomPairs = RandomPairs
local gmatch = string.gmatch
local table_Count = table.Count
local unpack = unpack
local gsub = string.gsub


LambdaValidTextChatKeyWords = {}

-- keyword      | String |      The word that will be detected and replaced
-- replacefunction( lambda )      | Function |      Return a string in the function to replace the keyword with
function LambdaAddTextChatKeyWord( keyword, replacefunction )
    LambdaValidTextChatKeyWords[ keyword ] = replacefunction
end



function LambdaKeyWordModify( self, str ) 
    for keyword, replacefunction in pairs( LambdaValidTextChatKeyWords ) do
        local haskeyword = string_find( str, keyword )

        if haskeyword then
            local modified = gsub( str, keyword, function( ... )  
                local count = table_Count( { ... } )
                local packed = {}
                for i=1, count do packed[ #packed + 1 ] = ( replacefunction( self ) or keyword ) end
            
                return unpack( packed )
            end )
            return modified
        end
    end
    return str
end


-- Get a random Player's or Lambda's name
local function RandomPlayerKeyword( self )
    local players = GetLambdaPlayers()
    table_Add( players, player_GetAll() )
    for k, v in RandomPairs( players ) do
        if v != self then return v:Nick() end
    end
end

-- Return the current map
local function Map( self )
    return game.GetMap()
end

-- Return the Server's name
local function ServerName( self )
    return GetHostName()
end

-- Return our name
local function Selfname( self )
    return self:GetLambdaName()
end

-- Return a key entity's name
local function Keyentity( self )
    local keyent = self.l_keyentity
    if !IsValid( keyent ) then return end

    if keyent:IsPlayer() or keyent.IsLambdaPlayer then return keyent:Nick() end
    return keyent:GetClass()
end


LambdaAddTextChatKeyWord( "/rndply/", RandomPlayerKeyword )
LambdaAddTextChatKeyWord( "/keyent/", Keyentity )
LambdaAddTextChatKeyWord( "/self/", Selfname )
LambdaAddTextChatKeyWord( "/servername/", ServerName )
LambdaAddTextChatKeyWord( "/map/", Map )


-- LambdaAddKeyWords hook allows you to use LambdaAddTextChatKeyWord() externally
if !LambdaFilesReloaded then
    hook.Add( "PreGamemodeLoaded", "lambdakeywordinit", function()
        hook.Run( "LambdaAddKeyWords" )
    end )
else
    hook.Run( "LambdaAddKeyWords" )
end