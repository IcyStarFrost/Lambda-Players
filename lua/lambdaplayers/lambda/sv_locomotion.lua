

local LambdaIsValid = LambdaIsValid
local dev = GetConVar( "developer" )
local aidisable = GetConVar( "ai_disabled" )
local IsValid = IsValid
local math_max = math.max
local color_white = color_white
local isvector = isvector
local Trace = util.TraceLine
local isfunction = isfunction
local debugoverlay = debugoverlay
local CurTime = CurTime
local tracetable = {}
local ents_FindByName = ents.FindByName

-- Start off simple
-- Pos arg can be a vector or a entity.
function ENT:MoveToPos( pos, options )
    self.l_movepos = pos
    if !isvector( self.l_movepos ) and !LambdaIsValid( self.l_movepos ) then return "failed" end

    -- If there is no nav mesh, try to go to the postion anyway
    if !navmesh.IsLoaded() or !IsValid( self.l_currentnavarea ) then self:MoveToPosOFFNAV( self.l_movepos, options ) return end 

	local options = options or {}
    local timeout = options.timeout
    local update = options.update
    local callback = options.callback

	local path = Path( "Follow" )
	path:SetMinLookAheadDistance( options.lookahead or 300 )
	path:SetGoalTolerance( options.tol or 20 )
	path:Compute( self, ( !isvector( self.l_movepos ) and self.l_movepos:GetPos() or self.l_movepos), self:PathGenerator() )

    self.loco:SetDesiredSpeed( options.speed or 200 )

	if ( !path:IsValid() ) then return "failed" end

    self.IsMoving = true

	while ( path:IsValid() ) do
        if !isvector( self.l_movepos ) and !LambdaIsValid( self.l_movepos ) then return "invalid" end
        if self:GetIsDead() then return "dead" end
        if self.AbortMovement then self.AbortMovement = false self.IsMoving = false return "aborted" end

        local goal = path:GetCurrentGoal()


        if !aidisable:GetBool() then
            if callback and isfunction( callback ) then callback( goal ) end 
            path:Update( self )
            self:DoorCheck()
        end


        if dev:GetBool() then
            path:Draw()
        end

		if ( self.loco:IsStuck() ) then

			self:HandleStuck()
            self.IsMoving = false
			return "stuck"
		end

		if timeout then
			if path:GetAge() > timeout then self.IsMoving = false return "timeout" end
		end

		if update then
            local updateTime = math_max( update, update * ( path:GetLength() / 400 ) )
			if path:GetAge() > updateTime then path:Compute( self, ( !isvector( self.l_movepos ) and self.l_movepos:GetPos() or self.l_movepos ), self:PathGenerator() ) end
		end

		coroutine.yield()

	end

    self.IsMoving = false

	return "ok"

end

-- Replaces the Z in the provided Vector with self's Z
local function ReplaceZ( self, vector )
    vector[ 3 ] = self:GetPos()[ 3 ]
    return vector
end

-- If the map we are on does not have a navmesh, the Lambda Players will default their movement to this so they can actually move
function ENT:MoveToPosOFFNAV( pos, options )
    self.l_movepos = pos
    if !isvector( self.l_movepos ) and !LambdaIsValid( self.l_movepos ) then return "failed" end

	local options = options or {}
    local timeout = options.timeout
    local callback = options.callback
    local tolerance = options.tol or 20
    self.loco:SetDesiredSpeed( options.speed or 200 )

    self.IsMoving = true

    while IsValid( self ) do 
        if !isvector( self.l_movepos ) and !LambdaIsValid( self.l_movepos ) then return "invalid" end
        if self:GetIsDead() then return "dead" end
        if self.AbortMovement then self.AbortMovement = false self.IsMoving = false return "aborted" end
        if self:GetRangeSquaredTo( ReplaceZ( self, ( !isvector( self.l_movepos ) and self.l_movepos:GetPos() or self.l_movepos ) ) ) <= ( tolerance * tolerance ) then break end

        if !aidisable:GetBool() then
            if callback and isfunction( callback ) then callback() end 
            local approchpos = ( !isvector( self.l_movepos ) and self.l_movepos:GetPos() or self.l_movepos )
            self.loco:FaceTowards( approchpos )
            self.loco:Approach( approchpos, 1 )
            self:DoorCheck()
        end

        if dev:GetBool() then
            debugoverlay.Line( self:GetPos(), ( !isvector( self.l_movepos ) and self.l_movepos:GetPos() or self.l_movepos ), 0.1, color_white, true )
        end

        if ( self.loco:IsStuck() ) then
			self:HandleStuck()
            self.IsMoving = false
			return "stuck"
		end

        if timeout then
			if CurTime() > CurTime() + timeout then self.IsMoving = false return "timeout" end
		end
        coroutine.yield()
    end


    self.IsMoving = false

    return "ok"
end

-- Stops movement from :MoveToPos() and :MoveToPosOFFNAV()
function ENT:CancelMovement()
    self.AbortMovement = self.IsMoving
end

-- Returns a pathfinding function for the :Compute() function
function ENT:PathGenerator()
    local stepHeight = self.loco:GetStepHeight()
    local jumpHeight = self.loco:GetJumpHeight()
    local deathHeight = -self.loco:GetDeathDropHeight()

    return function( area, fromArea, ladder, elevator, length )
        if !IsValid(fromArea) then return 0 end
        if !self.loco:IsAreaTraversable( area ) then return -1 end

        local dist = 0
        if IsValid(ladder) then
            dist = ladder:GetBottom():DistToSqr( ladder:GetTop() )
        elseif length > 0 then
            dist = length
        else
            dist = fromArea:GetCenter():DistToSqr( area:GetCenter() )
        end

        local cost = (dist + fromArea:GetCostSoFar())
        if !IsValid(ladder) then
            local deltaZ = fromArea:ComputeAdjacentConnectionHeightChange( area )
            if deltaZ > stepHeight then
                if deltaZ > jumpHeight then return -1 end
                local jumpPenalty = 10
                cost = cost + jumpPenalty * dist
            elseif deltaZ < deathHeight then
                return -1
            end
        end

        return cost
    end
end

local doorClasses = {
    ["prop_door_rotating"] = true,
    ["func_door"] = true,
    ["func_door_rotating"] = true
}


-- Fires a trace in front of the player that will open doors if it hits a door
function ENT:DoorCheck()
    if CurTime() < self.l_nextdoorcheck then return end

    tracetable.start = self:WorldSpaceCenter()
    tracetable.endpos = self:WorldSpaceCenter() + self:GetForward() * 50
    tracetable.filter = self
    local trace = Trace( tracetable )
    local ent = trace.Entity
    if IsValid( ent ) then
        local class = ent:GetClass()
        if doorClasses[ class ] and ent.Fire then
            ent:Fire( "Open" )
            if class == "prop_door_rotating" then
                local keys = ent:GetKeyValues()
                local slaveDoor = ents_FindByName( keys.slavename )
                if IsValid( slaveDoor ) then slaveDoor:Fire( "Open" ) end
            end
        end
    end

    self.l_nextdoorcheck = CurTime() + 0.2
end