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

function LambdaAddTextChatKeyWord( keyword, replacefunction )
    LambdaValidTextChatKeyWords[ keyword ] = replacefunction
end


local function GetOccurences( str, keyword )
    local count = 0
    for occurence in gmatch( str, keyword ) do
        count = count + 1
    end
    return count
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



local function RandomPlayerKeyword( self )
    local players = GetLambdaPlayers()
    table_Add( players, player_GetAll() )
    for k, v in RandomPairs( players ) do
        if v != self then return v:Nick() end
    end
end

local function Map( self )
    return game.GetMap()
end

local function Selfname( self )
    return self:GetLambdaName()
end

local function Keyentity( self )
    local keyent = self.l_keyentity

    if keyent:IsPlayer() or keyent.IsLambdaPlayer then return keyent:Nick() end
    return keyent:GetClass()
end


LambdaAddTextChatKeyWord( "/rndply/", RandomPlayerKeyword )
LambdaAddTextChatKeyWord( "/keyent/", Keyentity )
LambdaAddTextChatKeyWord( "/self/", Selfname )
LambdaAddTextChatKeyWord( "/map/", Map )