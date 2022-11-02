

_LAMBDAPLAYERSWEAPONS = {}

local weaponluafiles = file.Find( "lambdaplayers/lambda/weapons/*", "LUA", "nameasc" )

for k, luafile in ipairs( weaponluafiles ) do
	AddCSLuaFile( "lambdaplayers/lambda/weapons/" .. luafile )
    include( "lambdaplayers/lambda/weapons/" .. luafile )
    print( "Lambda Players: Merged Weapon from [ " .. luafile .. " ]" )
end



_LAMBDAWEAPONALLOWCONVARS = {}
for k, v in pairs( _LAMBDAPLAYERSWEAPONS ) do
    local convar = CreateLambdaConvar( "lambdaplayers_weapons_allow" .. k, 1, true, false, false, "Allows the Lambda Players to equip " .. v.prettyname, 0, 1, { type = "Bool", name = "Allow " .. v.prettyname, category = "Weapon Permissions" } )
	_LAMBDAWEAPONALLOWCONVARS[ k ] = v
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

function LambdaWriteFile( filename, content ) 
	local f = file.Open( filename, "w", "DATA" )
	if ( !f ) then return end

	f:Write( contents )
	f:Close()
end

function LambdaReadFile( filename, path )
	if ( path == true ) then path = "GAME" end
	if ( path == nil || path == false ) then path = "DATA" end

	local f = file.Open( filename, "r", path )
	if ( !f ) then return end

	local str = f:Read( f:Size() )

	f:Close()

	if ( !str ) then str = "" end
	return str
end

local IsValid = IsValid
function LambdaIsValid( object )
	if !object then return false end

	local isvalid = object.IsValid
	if !isvalid then return false end

	if IsValid( object ) and object.IsLambdaPlayer and object:GetIsDead() then return false end

	return IsValid( object )
end