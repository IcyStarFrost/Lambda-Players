local table_insert = table.insert

_LAMBDAPLAYERSWEAPONS = {}

local weaponluafiles = file.Find( "lambdaplayers/lambda/weapons/*", "LUA", "nameasc" )

for k, luafile in ipairs( weaponluafiles ) do
	AddCSLuaFile( "lambdaplayers/lambda/weapons/" .. luafile )
    include( "lambdaplayers/lambda/weapons/" .. luafile )
    print( "Lambda Players: Merged Weapon from [ " .. luafile .. " ]" )
end

if CLIENT then
	_LAMBDAPLAYERSWEAPONORIGINS = {}
end

_LAMBDAWEAPONALLOWCONVARS = {}
for k, v in pairs( _LAMBDAPLAYERSWEAPONS ) do
    local convar = CreateLambdaConvar( "lambdaplayers_weapons_allow" .. k, 1, true, false, false, "Allows the Lambda Players to equip " .. v.prettyname, 0, 1 )
	_LAMBDAWEAPONALLOWCONVARS[ k ] = convar
	if CLIENT then _LAMBDAPLAYERSWEAPONORIGINS[ v.origin ] = v.origin end
end

-- Register the Lambdas so the duplicator knows how to handle these guys
duplicator.RegisterEntityClass( "npc_lambdaplayer", function( ply, Pos, Ang, info )

	local lambda = ents.Create( "npc_lambdaplayer" )
	lambda:SetPos( Pos )
	lambda:SetAngles( Ang )
	lambda:Spawn()

	lambda:ApplyLambdaInfo( info ) -- Apply our exported info

	return lambda
end, "Pos", "Ang", "LambdaPlayerPersonalInfo" )


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



local IsValid = IsValid
function LambdaIsValid( object )
	if !object then return false end

	local isvalid = object.IsValid
	if !isvalid then return false end

	if IsValid( object ) and object.IsLambdaPlayer and object:GetIsDead() then return false end

	return IsValid( object )
end