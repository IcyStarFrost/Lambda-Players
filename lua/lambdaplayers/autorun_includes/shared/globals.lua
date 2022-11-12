local table_insert = table.insert
local pairs = pairs
local string_find = string.find
local tostring = tostring

_LAMBDAPLAYERSWEAPONS = {}

-- Merge all weapon lua files
local weaponluafiles = file.Find( "lambdaplayers/lambda/weapons/*", "LUA", "nameasc" )

for k, luafile in ipairs( weaponluafiles ) do
	AddCSLuaFile( "lambdaplayers/lambda/weapons/" .. luafile )
    include( "lambdaplayers/lambda/weapons/" .. luafile )
    print( "Lambda Players: Merged Weapon from [ " .. luafile .. " ]" )
end

if CLIENT then
	_LAMBDAPLAYERSWEAPONORIGINS = {}
end

-- Automatically creates convars for each weapon
_LAMBDAWEAPONALLOWCONVARS = {}
for k, v in pairs( _LAMBDAPLAYERSWEAPONS ) do
    local convar = CreateLambdaConvar( "lambdaplayers_weapons_allow" .. k, 1, true, false, false, "Allows the Lambda Players to equip " .. v.prettyname, 0, 1 )
	_LAMBDAWEAPONALLOWCONVARS[ k ] = convar
	if CLIENT then _LAMBDAPLAYERSWEAPONORIGINS[ v.origin ] = v.origin end
end

_LAMBDAWEAPONCLASSANDPRINTS = {}

for k, v in pairs( _LAMBDAPLAYERSWEAPONS ) do
	_LAMBDAWEAPONCLASSANDPRINTS[ v.prettyname ] = k
end

CreateLambdaConvar( "lambdaplayers_lambda_spawnweapon", "physgun", true, true, true, "The weapon lambda players will spawn with", 0, 1, { type = "Combo", options = _LAMBDAWEAPONCLASSANDPRINTS, name = "Spawn Weapon", category = "Lambda Player Settings" } )

-- One part of the duplicator support
-- Register the Lambdas so the duplicator knows how to handle these guys
duplicator.RegisterEntityClass( "npc_lambdaplayer", function( ply, Pos, Ang, info )

	local lambda = ents.Create( "npc_lambdaplayer" )
	lambda:SetPos( Pos )
	lambda:SetAngles( Ang )
	lambda:Spawn()

	lambda:ApplyLambdaInfo( info ) -- Apply our exported info when we were originally copied

	return lambda
end, "Pos", "Ang", "LambdaPlayerPersonalInfo" )



-- Custom ScreenScale function
-- Mostly used for testing but it's here if we want to do something with it
function LambdaScreenScale( x )
	return x * ( ScrW() / 640.0 )
end

local EntMeta = FindMetaTable("Entity")

function EntMeta:LambdaMoveMouth( weight )
    local flexID = self:GetFlexIDByName("jaw_drop")
    if flexID then self:SetFlexWeight(flexID, weight) end

    flexID = self:GetFlexIDByName("left_drop")
    if flexID then self:SetFlexWeight(flexID, weight) end

    flexID = self:GetFlexIDByName("right_drop")
    if flexID then self:SetFlexWeight(flexID, weight) end

    flexID = self:GetFlexIDByName("left_mouth_drop")
    if flexID then self:SetFlexWeight(flexID, weight) end

    flexID = self:GetFlexIDByName("right_mouth_drop")
    if flexID then self:SetFlexWeight(flexID, weight) end
end

function EntMeta:SetNWVar( key, value )
    
    if IsEntity( value ) then
        self:SetNWEntity( key, value )
    elseif isvector( value ) then
        self:SetNWVector( key, value )
    elseif isangle( value ) then
        self:SetNWAngle( key, value )
    elseif isbool( value ) then
        self:SetNWBool( key, value )
    elseif isnumber( value ) and string_find( tostring( value ), "." ) then
        self:SetNWFloat( key, value )
    elseif isnumber( value ) then
        self:SetNWInt( key, value )
    end
    
end

function EntMeta:LambdaHookTick( name, func )
    local id = self:EntIndex()
    hook.Add( "Tick", "lambdaplayers_hooktick" .. name .. id, function()
        if !IsValid( self ) then hook.Remove( "Tick", "lambdaplayers_hooktick" .. name .. id ) return end
        local result = func( self )
        if result == true then hook.Remove( "Tick", "lambdaplayers_hooktick" .. name .. id ) return end
    end )
end

function EntMeta:RemoveLambdaHookTick( name )
    local id = self:EntIndex()
    hook.Remove( "Tick", "lambdaplayers_hooktick" .. name .. id )
end


local IsValid = IsValid
function LambdaIsValid( object )
	if !object then return false end

	local isvalid = object.IsValid
	if !isvalid then return false end

	if IsValid( object ) and object.IsLambdaPlayer and object:GetIsDead() then return false end

	return IsValid( object )
end


-- Used for lua_run testing purposes. It is faster to type this than Entity(1):GetEyeTrace().Entity
function _tr()
	return Entity(1):GetEyeTrace().Entity
end


-- Changes certain functions in entities that derive from base_gmodentity to support Lambda Players
function LambdaHijackGmodEntity( ent, lambda )

    function ent:SetPlayer( ply )

        self.Founder = ply
    
        if ( IsValid( ply ) ) then
    
            self:SetNWString( "FounderName", ply:Nick() )

        else
    
            self:SetNWString( "FounderName", "" )
    
        end
    
    end

	function ent:GetOverlayText()

		local txt = self:GetNWString( "GModOverlayText" )
	
		if ( txt == "" ) then
			return ""
		end
	
		local PlayerName = self:GetPlayerName()
	
		return txt .. "\n(" .. PlayerName .. ")"
	
	end

    function ent:GetPlayer()

        if ( self.Founder == nil ) then
    
            -- SetPlayer has not been called
            return NULL
    
        elseif ( IsValid( self.Founder ) ) then
    
            -- Normal operations
            return self.Founder
    
        end
    
        -- See if the player has left the server then rejoined
        local ply = lambda
        if ( not IsValid( ply ) ) then
    
            -- Oh well
            return NULL
    
        end
    
        -- Save us the check next time
        self:SetPlayer( ply )
        return ply
    
    end

end