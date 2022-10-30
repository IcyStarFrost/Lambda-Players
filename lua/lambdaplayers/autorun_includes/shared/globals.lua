
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