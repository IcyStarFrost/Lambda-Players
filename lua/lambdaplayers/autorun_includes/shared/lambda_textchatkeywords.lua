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
local string_EndsWith = string.EndsWith

LambdaValidTextChatKeyWords = {}
LambdaConditionalKeyWords = {}

-- keyword      | String |      The word that will be detected and replaced
-- replacefunction( lambda )      | Function |      Return a string in the function to replace the keyword with
function LambdaAddTextChatKeyWord( keyword, replacefunction )
    LambdaValidTextChatKeyWords[ keyword ] = replacefunction
end

-- keyword      | String |      The word that will be detected and will test the conditionfunc if the text line the keyword originated from can be used
-- conditionfunc( lambda )      | Function |      Return true to allow the text line to be used
function LambdaAddConditionalKeyWord( keyword, conditionfunc )
    LambdaConditionalKeyWords[ keyword ] = conditionfunc
end

-- If a text line has a conditional keyword anywhere, this will return if the text line can be used if the condition function allows it
function LambdaConditionalKeyWordCheck( self, str )
    if !str then return true end

    for keyword, conditionfunction in pairs( LambdaConditionalKeyWords ) do
        local haskeyword = string_find( str, keyword )

        if haskeyword then
            str = string_Replace( str, keyword, "" )
            return conditionfunction( self ), str
        end
    end

    return true, str
end

-- Replaces any existing key words in the provided string
function LambdaKeyWordModify( self, str ) 
    if !str then return "" end

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
    if !IsValid( keyent ) then return "someone" end

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

-- Remove the file pathy stuff, remove file extension, remove underscores, and numbers
local function PrettyName( mdlpath )
    local split = string_Explode( "/", mdlpath )
    local basename = StripExtension( split[ #split ] )
    basename = string_Replace( basename, "_", " " )
    for k, number in ipairs( numbers ) do basename = string_Replace( basename, number, "" ) end
    for k, ending in ipairs( endings ) do if string_EndsWith( basename, ending ) then basename = string_Left( basename, #basename - 1 ) break end end
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

-- Returns the amount of deaths the Lambda has died
local function selfdeaths( self )
    return tostring( self:Deaths() ) 
end

-- Return the amount of kills the Lambda has
local function selfkills( self )
    return tostring( self:Frags() ) 
end

-- Return the ping of the lambda
local function selfping( self )
    return tostring( self:Ping() ) 
end

-- Returns the current weapon name
local function selfWeapon( self )
    return self.l_WeaponPrettyName
end 

-- Returns the Key Ent's weapon
local function keyentWeapon( self )
    local keyent = self.l_keyentity
    if !IsValid( keyent ) then return "weapon" end
    local wep = keyent:GetActiveWeapon()
    return IsValid( wep ) and wep.GetPrintName and wep:GetPrintName() or keyent.IsLambdaPlayer and keyent.l_WeaponPrettyName or "weapon"
end 

-- Key words that will be replaced with some text --
LambdaAddTextChatKeyWord( "/rndply/", RandomPlayerKeyword )
LambdaAddTextChatKeyWord( "/keyent/", Keyentity )
LambdaAddTextChatKeyWord( "/self/", Selfname )
LambdaAddTextChatKeyWord( "/servername/", ServerName )
LambdaAddTextChatKeyWord( "/nearprop/", nearProp )
LambdaAddTextChatKeyWord( "/nearply/", nearPly )
LambdaAddTextChatKeyWord( "/deaths/", selfdeaths )
LambdaAddTextChatKeyWord( "/ping/", selfping )
LambdaAddTextChatKeyWord( "/kills/", selfkills )
LambdaAddTextChatKeyWord( "/map/", Map )
LambdaAddTextChatKeyWord( "/weapon/", selfWeapon )
LambdaAddTextChatKeyWord( "/keyweapon/", keyentWeapon )
------------------------------------------------------

-- Text lines with this condition can only be used if the Lambda has high ping
local function HighPing( self )
    return self:GetPing() > 200
end

-- Text lines with this condition can only be used if the Lambda has low health 
local function Lowhealth( self )
    return self:Health() < ( self:GetMaxHealth() * 0.4 )
end

-- Text lines with this condition can only be used if this is a lot of people packed together near the Lambda
local function IsCrowded( self )
   local near = self:FindInSphere( nil, 500, function( ent ) return ent.IsLambdaPlayer or ent:IsPlayer() end )
   return #near > 5
end

-- Conditional Key Words that will determine if a text line that has the key word can be used --
LambdaAddConditionalKeyWord( "|highping|", HighPing )
LambdaAddConditionalKeyWord( "|lowhp|", Lowhealth )
LambdaAddConditionalKeyWord( "|crowded|", IsCrowded )
------------------------------------------------------



-- LambdaAddKeyWords hook allows you to use LambdaAddTextChatKeyWord() and LambdaAddConditionalKeyWord() externally
if !LambdaFilesReloaded then
    hook.Add( "PreGamemodeLoaded", "lambdakeywordinit", function()
        hook.Run( "LambdaAddKeyWords" )
    end )
else
    hook.Run( "LambdaAddKeyWords" )
end