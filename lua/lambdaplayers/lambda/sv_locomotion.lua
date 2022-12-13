

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
local bit_band = bit.band
local unstucktable = {}
local ents_FindByName = ents.FindByName
local GetGroundHeight = navmesh.GetGroundHeight
local random = math.random
local ipairs = ipairs

-- Finds "simple" ground height, treating the provided nav area as part of the floor
local function GetSimpleGroundHeightWithFloor( navArea, pos )
    local height, normal = GetGroundHeight( pos )
    if !height or !normal then return end
    if IsValid( navArea ) and navArea:IsOverlapping( pos ) then height = math_max( height, navArea:GetZ( pos ) ) end
    return height, normal
end

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
    local autorun = options.autorun

	local path = Path( "Follow" )
    path:SetMinLookAheadDistance( self.l_LookAheadDistance )
	path:SetGoalTolerance( options.tol or 20 )
	path:Compute( self, ( !isvector( self.l_movepos ) and self.l_movepos:GetPos() or self.l_movepos), self:PathGenerator() )

    self:SetRun( !autorun and ( options.run or false ) or autorun and ( path:GetLength() > 1500 and true or false ) )

	if ( !path:IsValid() ) then return "failed" end

    self.l_CurrentPath = path
    self.l_issmoving = true

    local stepH = self.loco:GetStepHeight()

    hook.Run( "LambdaOnBeginMove", self, ( !isvector( self.l_movepos ) and self.l_movepos:GetPos() or self.l_movepos ), true )

	while ( path:IsValid() ) do
        if !isvector( self.l_movepos ) and !LambdaIsValid( self.l_movepos ) then return "invalid" end
        if self:GetIsDead() then return "dead" end
        if self.AbortMovement then self.AbortMovement = false self.l_issmoving = false self.l_CurrentPath = nil return "aborted" end

        local goal = path:GetCurrentGoal()
        

        if !self:IsDisabled() and CurTime() > self.l_moveWaitTime then
            if callback and isfunction( callback ) then callback( goal ) end 
            path:Update( self )
            self:DoorCheck()

            -- Close up jumping
            local aheadNormal = ( goal.pos - self:GetPos() ):GetNormalized(); aheadNormal.z = 0
            local grHeight = GetSimpleGroundHeightWithFloor( self.l_currentnavarea, self:WorldSpaceCenter() + aheadNormal * 40 )
            if grHeight and ( grHeight - self:GetPos().z ) > stepH then self.loco:Jump()  end
        end


        if dev:GetBool() then
            path:Draw()
        end

		if ( self.loco:IsStuck() ) then
            local pos = ( !isvector( self.l_movepos ) and self.l_movepos:GetPos() or self.l_movepos)

            -- This prevents the stuck handling from running if we are right next to the entity we are going to
            if !isvector( self.l_movepos ) and self:GetRangeSquaredTo( pos ) >= ( 100 * 100 ) or isvector( self.l_movepos ) then 
                local result = self:HandleStuck()
                if !result then self.l_issmoving = false self.l_CurrentPath = nil return "stuck" end
            else
                self.loco:ClearStuck()
            end

		end

		if timeout then
			if path:GetAge() > timeout then self.l_issmoving = false return "timeout" end
		end

        if self.l_recomputepath then
            path:Compute( self, ( !isvector( self.l_movepos ) and self.l_movepos:GetPos() or self.l_movepos ), self:PathGenerator() )
            self.l_recomputepath = nil
        end

		if update then
            local updateTime = math_max( update, update * ( path:GetLength() / 400 ) )
			if path:GetAge() > updateTime then path:Compute( self, ( !isvector( self.l_movepos ) and self.l_movepos:GetPos() or self.l_movepos ), self:PathGenerator() ) end
		end

        -- Checks if we need to climb ladder to traverse
        local moveType = goal.type
        if moveType == 4 or moveType == 5 then
            local ladder = goal.ladder
            if IsValid( ladder ) and self:IsInRange( ( moveType == 4 and ladder:GetBottom() or ladder:GetTop() ), 64 ) then
                self.l_ClimbingLadder = true
                self:ClimbLadder( ladder, ( moveType == 5 ), goal.pos )
                self.l_ClimbingLadder = false
                
                local movePos = ( ( isentity( self.l_movepos ) and IsValid( self.l_movepos ) ) and self.l_movepos:GetPos() or self.l_movepos )
                if IsValid( movePos ) then path:Compute( self, movePos, self:PathGenerator() ) end
            end
        end 
        
        coroutine.yield()
	end

    self.l_CurrentPath = nil
    self.l_issmoving = false

	return "ok"

end

-- Start climbing the provided ladder
function ENT:ClimbLadder( ladder, isDown, movePos )
    if !IsValid( ladder ) then return end

    local startPos, goalPos, finishPos
    if isDown then
        startPos = ladder:GetTop()
        goalPos = ladder:GetBottom()
        finishPos = ladder:GetBottomArea():GetClosestPointOnArea( goalPos )
    else
        startPos = ladder:GetBottom()
        goalPos = ladder:GetTop()

        local possibleAreas = {}
        local ladderArea = ladder:GetTopForwardArea()
        if IsValid( ladderArea ) then possibleAreas[ #possibleAreas + 1 ] = ladderArea end
        ladderArea = ladder:GetTopBehindArea()
        if IsValid( ladderArea ) then possibleAreas[ #possibleAreas + 1 ] = ladderArea end
        ladderArea = ladder:GetTopLeftArea()
        if IsValid( ladderArea ) then possibleAreas[ #possibleAreas + 1 ] = ladderArea end
        ladderArea = ladder:GetTopRightArea()
        if IsValid( ladderArea ) then possibleAreas[ #possibleAreas + 1 ] = ladderArea end

        local lastDist = math.huge
        for _, v in ipairs( possibleAreas ) do
            local closePoint = v:GetClosestPointOnArea( goalPos )
            local closeDist = movePos:DistToSqr( closePoint )
            if closeDist >= lastDist then continue end

            lastDist = closeDist
            finishPos = closePoint
        end
    end

    local endDir = ( finishPos - goalPos ):GetNormalized(); endDir.z = 0
    tracetable.start = finishPos
    tracetable.endpos = finishPos + endDir * 48
    tracetable.filter = self
    finishPos = Trace( tracetable ).HitPos

    local climbFract = 0
    local climbState = 1
    local nextSndTime = 0

    local climbStart = self:GetPos()
    local climbEnd = ( startPos + ( ladder:GetNormal() * 20 ) )
    local climbNormal = ( climbEnd - climbStart ):GetNormalized()
    local climbDist = climbStart:Distance( climbEnd )

    while ( true ) do
        if !LambdaIsValid( self ) or self:IsInNoClip() then return end

        self:SetPos( climbStart + climbNormal * climbFract )
        self.loco:FaceTowards( self:GetPos() + climbNormal )

        if !self:IsDisabled() and CurTime() > self.l_moveWaitTime or climbState != 2 then
            climbFract = climbFract + ( self:GetLadderClimbSpeed() * FrameTime() )

            if climbFract >= climbDist then
                if climbState == 1 then
                    climbEnd = goalPos + ( ladder:GetNormal() * 20 )
                elseif climbState == 2 then
                    climbEnd = finishPos
                else
                    return
                end

                climbStart = self:GetPos()
                climbNormal = ( climbEnd - climbStart ):GetNormalized()
                climbDist = climbStart:Distance( climbEnd ) - ( ( isDown and climbState == 2 ) and random( 0, 48 ) or 0 )

                climbFract = 0
                climbState = climbState + 1
            end

            if climbState == 2 and CurTime() > nextSndTime then
                self:EmitSound( "player/footsteps/ladder" .. random( 4 ) .. ".wav" )
                nextSndTime = CurTime() + 0.466
            end
        end
        
        coroutine.yield()
    end
end

-- If we are moving while this function is called, recompute our current path or change the goal position and recompute
function ENT:RecomputePath( pos )
    if self.l_issmoving then
        self.l_movepos = pos or self.l_movepos
        self.l_recomputepath = true
    end
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
    self.l_issmoving = true

    hook.Run( "LambdaOnBeginMove", self, ( !isvector( self.l_movepos ) and self.l_movepos:GetPos() or self.l_movepos ), false )

    while IsValid( self ) do 
        if !isvector( self.l_movepos ) and !LambdaIsValid( self.l_movepos ) then return "invalid" end
        if self:GetIsDead() then return "dead" end
        if self.AbortMovement then self.AbortMovement = false self.l_issmoving = false self.l_CurrentPath = nil return "aborted" end
        if self:GetRangeSquaredTo( ReplaceZ( self, ( !isvector( self.l_movepos ) and self.l_movepos:GetPos() or self.l_movepos ) ) ) <= ( tolerance * tolerance ) then break end

        if !self:IsDisabled() and CurTime() > self.l_moveWaitTime then
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
                if !result then self.l_issmoving = false self.l_CurrentPath = nil return "stuck" end
            else
                self.loco:ClearStuck()
            end
		end

        if timeout then
			if CurTime() > CurTime() + timeout then self.l_issmoving = false return "timeout" end
		end
        coroutine.yield()
    end

    self.l_CurrentPath = nil
    self.l_issmoving = false

    return "ok"
end

-- Stops movement from :MoveToPos() and :MoveToPosOFFNAV()
function ENT:CancelMovement()
    self.AbortMovement = self.l_issmoving
end

-- Makes lambda wait and stop while moving for a given amount of time
function ENT:WaitWhileMoving( time )
    if !self.l_issmoving then return end
    self.l_moveWaitTime = CurTime() + time
end

-- This function will either return true or false

-- If this returns true, continue on our current path
-- Unless false, don't continue and stop
function ENT:HandleStuck()
    if self:GetIsDead() then self.loco:ClearStuck() return false end -- Who knows just in case

    local mins, maxs = self:GetCollisionBounds()

    self.l_stucktimes = self.l_stucktimes + 1
    self.l_stucktimereset = CurTime() + 10

    -- Allow external addons to control our stuck process. We assume whoever made that hook and returns "stop" or "continue" will handle the unstuck behaviour
    local result = hook.Run( "LambdaOnStuck", self, self.l_stucktimes )
    if result == "stop" then return false elseif result == "continue" then return true end

    if self.l_stucktimes == 3 then self.l_unstuck = true return true elseif self.l_stucktimes == 4 then self.l_unstuck = true return false end

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
    local jumpPenalty = 10
    local isInNoClip = self:IsInNoClip()
    local stepHeight = self.loco:GetStepHeight()
    local jumpHeight = self.loco:GetJumpHeight()
    local deathHeight = -self.loco:GetDeathDropHeight()

    return function( area, fromArea, ladder, elevator, length )
        if !IsValid( fromArea ) then return 0 end
        if !self.loco:IsAreaTraversable( area ) or bit_band( area:GetAttributes(), NAV_MESH_AVOID ) == NAV_MESH_AVOID then return -1 end

        local dist = 0
        if !isInNoClip and IsValid( ladder ) then
            dist = ladder:GetBottom():Distance( ladder:GetTop() )
        else
            dist = ( length > 0 and length or fromArea:GetCenter():Distance( area:GetCenter() ) )
        end
        local cost = ( fromArea:GetCostSoFar() + dist )

        if !isInNoClip and !IsValid( ladder ) then
            local deltaZ = fromArea:ComputeAdjacentConnectionHeightChange( area )
            if deltaZ > jumpHeight or deltaZ < deathHeight then return -1 end
            if deltaZ > stepHeight then cost = cost + ( dist * jumpPenalty ) end
        end

        return cost
    end
end

-- Approaches a position 
function ENT:Approach( pos, time )
    time = CurTime() + time or CurTime() + 1
    self:Hook( "Tick", "approachposition", function()
        if CurTime() > time then return "end" end
        self.loco:Approach( pos, 99 )
    end )
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
    tracetable.endpos = ( tracetable.start + self:GetForward() * 50 )
    tracetable.filter = self
    
    local ent = Trace( tracetable ).Entity
    if IsValid( ent ) then
        local class = ent:GetClass()
        if doorClasses[ class ] and ent.Fire then
            if class == "prop_door_rotating" then
                ent:Fire( "OpenAwayFrom", "!activator", 0, self )
                local keys = ent:GetKeyValues()
                local slaveDoor = ents_FindByName( keys.slavename )
                if IsValid( slaveDoor ) then slaveDoor:Fire( "OpenAwayFrom", "!activator", 0, self ) end
            else
                ent:Fire( "Open" )
            end
            self.loco:Approach( self:GetPos() - self:GetForward() * 50, 90 )
            self:WaitWhileMoving( 1.0 )
        end
    end

    self.l_nextdoorcheck = CurTime() + 0.2
end