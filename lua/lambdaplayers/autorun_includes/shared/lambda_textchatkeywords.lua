local table_Add = table.Add
local player_GetAll = player.GetAll
local pairs = pairs
local string_find = string.find
local RandomPairs = RandomPairs
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
local player_GetBySteamID = player.GetBySteamID
local string_EndsWith = string.EndsWith
local tonumber = tonumber
local os_date = os.date

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

    for keyWord, replaceFunc in pairs( LambdaValidTextChatKeyWords ) do
        if string_find( str, keyWord ) == nil then continue end

        str = gsub( str, keyWord, function( ... )  
            local count = table_Count( { ... } )
            local packed = {}
            for i = 1, count do 
                packed[ #packed + 1 ] = ( replaceFunc( self ) or keyWord ) 
            end
            return unpack( packed )
        end )
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

-- Returns a random map name
local function RandomMap( self )
    local maps = file.Find( "maps/gm_*", "GAME", "namedesc" )
    return string.StripExtension( maps[ LambdaRNG( #maps ) ] )
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

    -- Return the lambda's weapon name
    if keyent.IsLambdaPlayer then
        return keyent.IsLambdaPlayer and keyent.l_WeaponPrettyName or "weapon"
    end

    -- Return the entity's weapon name
    if isfunction( keyent.GetActiveWeapon ) then
        local wep = keyent:GetActiveWeapon()
        return IsValid( wep ) and wep.GetPrintName and wep:GetPrintName()
    end

    -- If all goes wrong
    return "weapon"
end 

-- Returns a Player that currently has a Birthday. SHOULD BE USED WITH CONDITION KEY WORD |birthday|
local function BirthdayPlayer( self )
    for steamid, birthdaydata in RandomPairs( _LambdaPlayerBirthdays ) do
        local ply = player_GetBySteamID( steamid )
        if IsValid( ply ) then
            return ply:Name()
        end
    end
    return "someone"
end 

-- Key words that will be replaced with some text --
LambdaAddTextChatKeyWord( "/rndply/", RandomPlayerKeyword )
LambdaAddTextChatKeyWord( "/rndmap/", RandomMap )
LambdaAddTextChatKeyWord( "/keyent/", Keyentity )
LambdaAddTextChatKeyWord( "/birthdayply/", BirthdayPlayer )
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

-- Text lines with this condition can only be used if there is no one nearby
local function IsAlone( self )
    local near = self:FindInSphere( nil, 2000, function( ent ) return ent.IsLambdaPlayer or ent:IsPlayer() end )
    return #near == 0
end


-- Text lines with this condition can only be used if there is less than 6 Lambda/players in the game
local function IsQuietServer( self )
    local players = player_GetAll()
    table_Add( players, GetLambdaPlayers() )
    return #players < 6
end

-- Text lines with this condition can only be used if there is more than 15 Lambda/players in the game
local function IsActiveServer( self )
    local players = player_GetAll()
    table_Add( players, GetLambdaPlayers() )
    return #players > 15
end

-- This condition must be used where /keyent/ is supported for it to work properly!
-- Text lines with this condition can only be used if the key ent is the host of the server. This doesn't work in Dedicated Servers
local function KeyEntIsHost( self )
    local keyent = self.l_keyentity
    if !IsValid( keyent ) or !keyent:IsPlayer() then return false end
    return keyent:GetNW2Bool( "lambda_serverhost", false )
end

-- Text lines with this condition can only be used if the time currently is in the night/morning ( AM )
local function AMTime( self )
    local date = os_date( "%p" )
    return date == "am"
end

-- Text lines with this condition can only be used if the time currently is in the noon/afternoon/evening ( PM )
local function PMTime( self )
    local date = os_date( "%p" )
    return date == "pm"
end

-- Text lines with this condition can only be used if it is currently Christmas
local function IsChristmasDay( self )
    local month = os_date( "%B" )
    local weekday = tonumber( os_date( "%d" ) )
    return month == "December" and weekday == 25
end

-- Text lines with this condition can only be used if it is currently New Years
local function IsNewYears( self )
    local month = os_date( "%B" )
    local weekday = tonumber( os_date( "%d" ) )
    return month == "January" and weekday == 1
end

-- Text lines with this condition can only be used if it is currently the addon's creation day
local function IsAddonBirthday( self )
    local month = os_date( "%B" )
    local weekday = tonumber( os_date( "%d" ) )
    return month == "October" and weekday == 28
end

-- Text lines with this condition can only be used if it is currently Thanksgiving
local function IsThanksgiving( self )
    local month = os_date( "%B" )
    local weekday = tonumber( os_date( "%d" ) )
    return month == "November" and weekday == 24
end

-- Text lines with this condition can only be used if it is currently the 4th of July
local function Is4thofJuly( self )
    local month = os_date( "%B" )
    local weekday = tonumber( os_date( "%d" ) )
    return month == "July" and weekday == 4
end


-- Text lines with this condition can only be used if it is currently Easter
local function IsEaster( self )
    local month = os_date( "%B" )
    local weekday = tonumber( os_date( "%d" ) )
    return month == "April" and weekday == 9
end

-- Text lines with this condition can only be used if it is currently someone's birthday. Best used with key word /birthdayply/
local function SomeonesBirthday( self )
    local month = os_date( "%B" )
    local weekday = tonumber( os_date( "%d" ) )
    for steamid, birthdaydata in pairs( _LambdaPlayerBirthdays ) do
        if birthdaydata.month == month and birthdaydata.day == weekday then return true end
    end
    return false
end


-- Conditional Key Words that will determine if a text line that has the key word can be used --
LambdaAddConditionalKeyWord( "|highping|", HighPing )
LambdaAddConditionalKeyWord( "|lowhp|", Lowhealth )
LambdaAddConditionalKeyWord( "|crowded|", IsCrowded )
LambdaAddConditionalKeyWord( "|alone|", IsAlone )
LambdaAddConditionalKeyWord( "|quietserver|", IsQuietServer )
LambdaAddConditionalKeyWord( "|activeserver|", IsActiveServer )
LambdaAddConditionalKeyWord( "|keyentishost|", KeyEntIsHost )
LambdaAddConditionalKeyWord( "|amtime|", AMTime )
LambdaAddConditionalKeyWord( "|pmtime|", PMTime )

-- Special Day Conditions --
LambdaAddConditionalKeyWord( "|birthday|", SomeonesBirthday )
LambdaAddConditionalKeyWord( "|christmas|", IsChristmasDay )
LambdaAddConditionalKeyWord( "|newyears|", IsNewYears )
LambdaAddConditionalKeyWord( "|addonbirthday|", IsAddonBirthday )
LambdaAddConditionalKeyWord( "|thanksgiving|", IsThanksgiving )
LambdaAddConditionalKeyWord( "|4thjuly|", Is4thofJuly )
LambdaAddConditionalKeyWord( "|easter|", IsEaster )
------------------------------------------------------

