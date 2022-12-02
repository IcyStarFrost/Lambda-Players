local table_Add = table.Add
local random = math.random
local player_GetAll = player.GetAll
local pairs = pairs
local string_find = string.find
local RandomPairs = RandomPairs
local gmatch = string.gmatch
local IsValid = IsValid
local table_Count = table.Count
local unpack = unpack
local ipairs = ipairs
local string_Left = string.Left
local string_find = string.find
local string_Explode = string.Explode
local gsub = string.gsub
local StripExtension = string.StripExtension
local string_Replace = string.Replace

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

local props = {
    [ "prop_physics" ] = true,
    [ "prop_physics_multiplayer" ] = true,
    [ "prop_dynamic" ] = true
}


local numbers = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" }
local endings = { "a", "b", "c" }
-- Basically returns the end of the filepath and removes the extension
local function PrettyName( mdlpath )
    local split = string_Explode( "/", mdlpath )
    local basename = StripExtension( split[ #split ] )
    basename = string_Replace( basename, "_", " " )
    for k, number in ipairs( numbers ) do basename = string_Replace( basename, number, "" ) end
    for k, ending in ipairs( endings ) do if string_find( basename, ending ) then basename = string_Left( basename, #basename - 1 ) end end
    return basename
end

-- Returns the nearest prop's name
local function nearProp( self ) 
    local nearest = self:GetClosestEntity( nil, 1000, function( ent ) return props[ ent:GetClass() ] end )

    if IsValid( nearest ) then
        return PrettyName( nearest:GetModel() )
    end
    return "something"
end

-- Returns the nearest Lambda or player's name
local function nearPly( self ) 
    local nearest = self:GetClosestEntity( nil, 10000, function( ent ) return ent.IsLambdaPlayer or ent:IsPlayer() end )

    if IsValid( nearest ) then
        return nearest:Nick()
    end
    return "someone"
end


LambdaAddTextChatKeyWord( "/rndply/", RandomPlayerKeyword )
LambdaAddTextChatKeyWord( "/keyent/", Keyentity )
LambdaAddTextChatKeyWord( "/self/", Selfname )
LambdaAddTextChatKeyWord( "/servername/", ServerName )
LambdaAddTextChatKeyWord( "/nearprop/", nearProp )
LambdaAddTextChatKeyWord( "/nearply/", nearPly )
LambdaAddTextChatKeyWord( "/map/", Map )


-- LambdaAddKeyWords hook allows you to use LambdaAddTextChatKeyWord() externally
if !LambdaFilesReloaded then
    hook.Add( "PreGamemodeLoaded", "lambdakeywordinit", function()
        hook.Run( "LambdaAddKeyWords" )
    end )
else
    hook.Run( "LambdaAddKeyWords" )
end