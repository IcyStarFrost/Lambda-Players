

local LambdaIsValid = LambdaIsValid
local dev = GetConVar( "developer" )
local aidisable = GetConVar( "ai_disabled" )
local IsValid = IsValid
local math_max = math.max
local color_white = color_white
local isvector = isvector
local Trace = util.TraceLine
local TraceHull = util.TraceHull
local isfunction = isfunction
local debugoverlay = debugoverlay
local CurTime = CurTime
local tracetable = {}
local upvector = Vector( 0, 0, 1 )
local unstucktable = {}
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

    self:SetRun( options.run or false )

	if ( !path:IsValid() ) then return "failed" end

    self.l_CurrentPath = path
    self.IsMoving = true

	while ( path:IsValid() ) do
        if !isvector( self.l_movepos ) and !LambdaIsValid( self.l_movepos ) then return "invalid" end
        if self:GetIsDead() then return "dead" end
        if self.AbortMovement then self.AbortMovement = false self.IsMoving = false self.l_CurrentPath = nil return "aborted" end

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
            local pos = ( !isvector( self.l_movepos ) and self.l_movepos:GetPos() or self.l_movepos)

            -- This prevents the stuck handling from running if we are right next to the entity we are going to
            if !isvector( self.l_movepos ) and self:GetRangeSquaredTo( pos ) >= ( 100 * 100 ) or isvector( self.l_movepos ) then 
                local result = self:HandleStuck()
                if !result then self.IsMoving = false self.l_CurrentPath = nil return "stuck" end
            else
                self.loco:ClearStuck()
            end

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

    self.l_CurrentPath = nil
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
    self:SetRun( options.run or false )
    self.IsMoving = true

    while IsValid( self ) do 
        if !isvector( self.l_movepos ) and !LambdaIsValid( self.l_movepos ) then return "invalid" end
        if self:GetIsDead() then return "dead" end
        if self.AbortMovement then self.AbortMovement = false self.IsMoving = false self.l_CurrentPath = nil return "aborted" end
        if self:GetRangeSquaredTo( ReplaceZ( self, ( !isvector( self.l_movepos ) and self.l_movepos:GetPos() or self.l_movepos ) ) ) <= ( tolerance * tolerance ) then break end

        if !aidisable:GetBool() then
            if callback and isfunction( callback ) then callback() end 
            local approchpos = ( !isvector( self.l_movepos ) and self.l_movepos:GetPos() or self.l_movepos )
            self.loco:FaceTowards( approchpos )
            self.loco:Approach( approchpos, 1 )
            self:DoorCheck()
        end

        self.l_CurrentPath = ( !isvector( self.l_movepos ) and self.l_movepos:GetPos() or self.l_movepos )

        if dev:GetBool() then
            debugoverlay.Line( self:GetPos(), ( !isvector( self.l_movepos ) and self.l_movepos:GetPos() or self.l_movepos ), 0.1, color_white, true )
        end

        if ( self.loco:IsStuck() ) then
            -- This prevents the stuck handling from running if we are right next to the entity we are going to
            if !isvector( self.l_movepos ) and self:GetRangeSquaredTo( pos ) >= ( 100 * 100 ) or isvector( self.l_movepos ) then 
                local result = self:HandleStuck()
                if !result then self.IsMoving = false self.l_CurrentPath = nil return "stuck" end
            else
                self.loco:ClearStuck()
            end
		end

        if timeout then
			if CurTime() > CurTime() + timeout then self.IsMoving = false return "timeout" end
		end
        coroutine.yield()
    end

    self.l_CurrentPath = nil
    self.IsMoving = false

    return "ok"
end

-- Stops movement from :MoveToPos() and :MoveToPosOFFNAV()
function ENT:CancelMovement()
    self.AbortMovement = self.IsMoving
end

-- This function will either return true or false

-- If this returns true, continue on our current path
-- Unless false, don't continue and stop
function ENT:HandleStuck()
    if self:GetIsDead() then self.loco:ClearStuck() return false end -- Who knows just in case

    local mins, maxs = self:GetModelBounds()

    self.l_stucktimes = self.l_stucktimes + 1
    self.l_stucktimereset = CurTime() + 10

    -- Allow external addons to control our stuck process. We assume whoever made that hook and returns "stop" or "continue" will handle the unstuck behaviour
    local result = hook.Run( "LambdaOnStuck", self, self.l_stucktimes )
    if result == "stop" then return false elseif result == "continue" then return true end

    if self.l_stucktimes > 2 then self.l_stucktimes = 0 self.loco:ClearStuck() return false end

    unstucktable.start = self:GetPos() + upvector 
    unstucktable.endpos = self:GetPos() + upvector * 4
    unstucktable.mins = mins
    unstucktable.maxs = maxs
    --unstucktable.ignoreworld = true
    unstucktable.filter = self
    local istuckinsomething = TraceHull( unstucktable )

    if !istuckinsomething.Hit then -- If we didn't get stuck in any entity then try to jump
        self.loco:Jump()
        self.loco:ClearStuck()
        return true
    else -- We got stuck in something. Force our way out
        self.l_unstuck = true
        return true
    end

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