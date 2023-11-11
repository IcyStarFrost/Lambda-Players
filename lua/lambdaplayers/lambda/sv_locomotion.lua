if ( CLIENT ) then return end

local LambdaIsValid = LambdaIsValid
local dev = GetConVar( "lambdaplayers_debug_path" )
local IsValid = IsValid
local math_max = math.max
local math_abs = math.abs
local table_Copy = table.Copy
local isvector = isvector
local Trace = util.TraceLine
local TraceHull = util.TraceHull
local debugoverlay = debugoverlay
local CurTime = CurTime
local FrameTime = FrameTime
local tracetable = { ignoreworld = true }
local unstucktable = {}
local airtable = {}
local laddermovetable = { collisiongroup = COLLISION_GROUP_PLAYER, ignoreworld = true, mask = MASK_PLAYERSOLID }
local ents_FindByName = ents.FindByName
local GetGroundHeight = navmesh.GetGroundHeight
local navmesh_IsLoaded = navmesh.IsLoaded
local navmesh_Find = navmesh.Find
local GetNearestNavArea = navmesh.GetNearestNavArea
local random = math.random
local Rand = math.Rand
local ipairs = ipairs
local coroutine_yield = coroutine.yield
local isnumber = isnumber
local band = bit.band
local obeynav = GetConVar( "lambdaplayers_lambda_obeynavmeshattributes" )
local shouldavoid = GetConVar( "lambdaplayers_lambda_avoid" )
local randomizepathfinding = GetConVar( "lambdaplayers_randomizepathingcost" )
local mincostscale = GetConVar( "lambdaplayers_randomizepathingcost_min" )
local maxcostscale = GetConVar( "lambdaplayers_randomizepathingcost_max" )

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
    -- If there is no nav mesh, try to go to the postion anyway
    local curArea = self.l_currentnavarea
    if !IsValid( curArea ) or !navmesh_IsLoaded() then 
        return self:MoveToPosOFFNAV( pos, options ) 
    end

    local movePos = ( isvector( pos ) and pos or ( IsValid( pos ) and pos:GetPos() or nil ) )
    if !movePos then return "failed" end

    self.l_issmoving = true
    options = ( options or {} )

    local overridePath, overrideOptions = LambdaRunHook( "LambdaOnBeginMove", self, movePos, true, options )
    if overridePath then movePos = overridePath end
    if overrideOptions then options = overrideOptions end

    local costFunctor = self:PathGenerator( options.update )
    local path = Path( "Follow" )

    path:Compute( self, overridePath or movePos, costFunctor )
    if !IsValid( path ) then self.l_issmoving = false; return "failed" end

    path:SetGoalTolerance( options.tol or 20 )
    path:SetMinLookAheadDistance( self.l_LookAheadDistance )
    
    self.l_movepos = movePos
    self.l_moveoptions = table_Copy( options )
    self.l_CurrentPath = path

    self:SetSlowWalk( options.walk or false )
    if options.run then
        self:SetRun( true )
    else
        self:SetRun( options.autorun and path:GetLength() > 1500 )
    end

    local loco = self.loco
    local runSpeed = self:GetRunSpeed()
    local stepH = loco:GetStepHeight()
    local jumpH = loco:GetJumpHeight()
    local curGoal, prevGoal
    local nextJumpT = CurTime() + 0.5
    local returnMsg = "ok"
    local callbackRunT = ( CurTime() + ( options.cbTime or 0 ) )
    local nearLadderCheckT = 0

    while ( IsValid( path ) ) do
        if self.AbortMovement then 
            self.AbortMovement = false 
            returnMsg = "aborted"; break 
        end
        if self:GetIsDead() then 
            returnMsg = "dead" 
            break
        end

        options = self.l_moveoptions or {}

        local timeout = options.timeout
        if timeout and path:GetAge() > timeout then 
            returnMsg = "timeout" 
            break 
        end

        movePos = ( isvector( self.l_movepos ) and self.l_movepos or ( IsValid( self.l_movepos ) and self.l_movepos:GetPos() or nil ) )
        if !movePos then 
            returnMsg = "invalid" 
            break 
        end

        local recomputePath = self.l_recomputepath
        if recomputePath then
            self.l_recomputepath = nil
            
            local recomputePos = ( isvector( recomputePath ) and recomputePath or ( IsValid( recomputePath ) and recomputePath:GetPos() or nil ) )
            if recomputePos then
                movePos = recomputePos
                self.l_movepos = recomputePos
                path:Compute( self, recomputePos, costFunctor )
            end
        else
            local update = options.update
            if update then
                local updateTime = math_max( update, update * ( path:GetLength() / runSpeed ) )
                if update > updateTime then 
                    updateTime = update
                elseif updateTime > 3.0 then
                    updateTime = 3.0
                end
                if path:GetAge() >= updateTime then path:Compute( self, movePos, costFunctor ) end
            end
        end

        if loco:IsStuck() then
            -- This prevents the stuck handling from running if we are right next to the entity we are going to            
            if isvector( movePos ) or !self:IsInRange( movePos, 100 ) then 
                local result = self:HandleStuck()
                if !result then returnMsg = "stuck"; break end
            else
                loco:ClearStuck()
            end
        end

        local goal = path:GetCurrentGoal()
        if goal and ( !curGoal or curGoal.area != goal.area ) then
            prevGoal = curGoal
            curGoal = goal
        end

        if !self:IsDisabled() and CurTime() >= self.l_moveWaitTime then
            local callback = options.callback
            if callback and CurTime() >= callbackRunT then 
                local returnVal = callback( self, movePos, path, curGoal )
                if returnVal == false then returnMsg = "callback" break end

                local cbTime = options.cbTime
                if cbTime then callbackRunT = ( CurTime() + cbTime ) end
            end
            path:Update( self )

            if curGoal and !self:IsInNoClip() then
                local selfPos = self:GetPos()
                local lastGoal = path:LastSegment()
                local destPos = ( ( lastGoal and curGoal.area == lastGoal.area ) and movePos or curGoal.pos )

                local goalAng = ( destPos - selfPos )
                goalAng.z = 0; goalAng = goalAng:Angle()

                local goalNormal = goalAng:Forward()
                self:AvoidCheck( goalAng )
                self:ObstacleCheck( goalNormal )

                local moveType = curGoal.type
                -- Ladder climbing ( 4 - Up, 5 - Down )
                if ( moveType == 4 or moveType == 5 ) then 
                    local ladder = curGoal.ladder
                    if IsValid( ladder ) then
                        local preClimbPos = destPos
                        destPos = ( moveType == 5 and ladder:GetTop() or ladder:GetBottom() )

                        if self:IsInRange( destPos, 70 ) then
                            self:ClimbLadder( ladder, ( moveType == 5 ), preClimbPos )

                            movePos = ( isvector( self.l_movepos ) and self.l_movepos or ( IsValid( self.l_movepos ) and self.l_movepos:GetPos() or nil ) )
                            if movePos then path:Compute( self, movePos, costFunctor ) end
                            destPos = preClimbPos
                        end
                    end
                else
                    local shouldJump = false
                    if moveType == 2 and ( prevGoal.pos.z - selfPos.z ) <= 0 then
                        shouldJump = true
                    elseif moveType == 3 and destPos:DistToSqr( selfPos ) <= 2048 then
                        shouldJump = true
                    elseif movePos:DistToSqr( selfPos ) > 4096 then
                        -- Jumping over ledges and close up jumping
                        local stepAhead = ( selfPos + vector_up * stepH )
                        curArea = self.l_currentnavarea
                        local grHeight, grNormal = GetSimpleGroundHeightWithFloor( curArea, stepAhead + goalNormal * 60 )
                        if grHeight and grNormal.z > 0.9 and ( grHeight - selfPos.z ) > stepH then shouldJump = true end

                        if !shouldJump then
                            grHeight = GetSimpleGroundHeightWithFloor( curArea, stepAhead + goalNormal * 30 )
                            if grHeight and ( grHeight - selfPos.z ) < -jumpH then shouldJump = true end
                        end
                    end

                    if shouldJump and CurTime() >= nextJumpT and self:LambdaJump() then
                        nextJumpT = CurTime() + 1.0
                    end
                end

                local shouldSlow = ( ( moveType == 1 or moveType == 2 or moveType == 3 or moveType == 4 or moveType == 5 ) and !self:IsPanicking() and !self:GetCrouch() and destPos:DistToSqr( selfPos ) <= 22500 )
                local walkTime = 0.1
                if !shouldSlow and CurTime() >= nearLadderCheckT then
                    nearLadderCheckT = ( CurTime() + 0.5 )

                    for _, area in ipairs( navmesh_Find( selfPos, 150, 150, 150 ) ) do
                        shouldSlow = ( IsValid( area ) and #area:GetLadders() != 0 and area:IsPartiallyVisible( self:WorldSpaceCenter(), self ) )
                        if shouldSlow then walkTime = 0.5; break end
                    end
                end
                if shouldSlow then self:ForceMoveSpeed( self:GetSlowWalkSpeed(), walkTime ) end

                -- Air movement
                if !self.l_isswimming and !self:IsOnGround() then
                    local mins, maxs = self:GetCollisionBounds()
                    local airVel = ( goalNormal * loco:GetDesiredSpeed() * FrameTime() )

                    airtable.start = selfPos
                    airtable.endpos = ( selfPos + airVel )
                    airtable.filter = self
                    airtable.mins = mins
                    airtable.maxs = maxs

                    if !TraceHull( airtable ).Hit then 
                        loco:SetVelocity( loco:GetVelocity() + airVel ) 
                    end
                end
            end
        end

        if dev:GetBool() then path:Draw() end
        coroutine_yield()
    end

    self.l_issmoving = false 
    self.l_movepos = nil
    self.l_moveoptions = nil
    self.l_CurrentPath = nil

    return returnMsg
end

-- If the map we are on does not have a navmesh, the Lambda Players will default their movement to this so they can actually move
function ENT:MoveToPosOFFNAV( pos, options )
    local movePos = ( isvector( pos ) and pos or ( IsValid( pos ) and pos:GetPos() or nil ) )
    if !movePos then return "failed" end

    self.l_issmoving = true
    options = options or {}

    local overridePath, overrideOptions = LambdaRunHook( "LambdaOnBeginMove", self, movePos, false, options )
    if overridePath then movePos = overridePath end
    if overrideOptions then options = overrideOptions end

    self.l_movepos = movePos
    self.l_moveoptions = table_Copy( options )
    self.l_CurrentPath = movePos

    local timeout = options.timeout
    if timeout then 
        options.timeout = ( CurTime() + timeout ) 
    end

    self:SetSlowWalk( options.walk or false )
    if options.run then
        self:SetRun( true )
    else
        self:SetRun( options.autorun and !self:IsInRange( movePos, 1500 ) )
    end

    local returnMsg = "ok"
    local loco = self.loco
    local callbackRunT = ( CurTime() + ( options.cbTime or 0 ) )

    while ( IsValid( self ) ) do 
        if self:GetIsDead() then 
            returnMsg = "dead" 
            break
        end
        if self.AbortMovement then 
            self.AbortMovement = false 
            returnMsg = "aborted"; break
        end

        options = self.l_moveoptions or {}

        local timeout = options.timeout
        if timeout and CurTime() >= timeout then 
            returnMsg = "timeout" 
            break 
        end

        movePos = ( isvector( self.l_movepos ) and self.l_movepos or ( IsValid( self.l_movepos ) and self.l_movepos:GetPos() or nil ) )
        if !movePos then returnMsg = "invalid" break end

        if loco:IsStuck() then
            -- This prevents the stuck handling from running if we are right next to the entity we are going to            
            if isvector( movePos ) or !self:IsInRange( movePos, 100 ) then 
                local result = self:HandleStuck()
                if !result then returnMsg = "stuck" break end
            else
                loco:ClearStuck()
            end
        end

        local selfPos = self:GetPos()
        local posSelfZ = movePos; posSelfZ.z = selfPos.z

        if self:IsInRange( posSelfZ, options.tol or 30 ) then
            break
        elseif !self:IsDisabled() and CurTime() >= self.l_moveWaitTime then
            local callback = options.callback
            if callback and CurTime() >= callbackRunT then 
                local returnVal = callback( self, movePos )
                if returnVal == false then returnMsg = "callback" break end

                local cbTime = options.cbTime
                if cbTime then callbackRunT = ( CurTime() + cbTime ) end
            end

            loco:FaceTowards( movePos )
            loco:Approach( movePos, 1 )

            local goalAng = ( movePos - selfPos )
            goalAng.z = 0; goalAng = goalAng:Angle()
            self:AvoidCheck( goalAng )
            self:ObstacleCheck( goalAng:Forward() )
        end

        if dev:GetBool() then debugoverlay.Line( selfPos, movePos, 0.1, color_white, true ) end
        coroutine_yield()
    end

    self.l_issmoving = false
    self.l_movepos = nil
    self.l_moveoptions = nil
    self.l_CurrentPath = nil

    return returnMsg
end

-- Start climbing the provided ladder
function ENT:ClimbLadder( ladder, isDown, movePos )
    self.l_ladderarea = ladder 

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
            local closePoint = v:GetCenter()
            local closeDist = movePos:DistToSqr( closePoint )
            if closeDist >= lastDist then continue end

            lastDist = closeDist
            finishPos = closePoint
        end
    end

    local climbFract = 0
    local climbState = 1
    local nextSndTime = 0

    local climbStart = self:GetPos()
    local climbEnd = ( startPos + ( ladder:GetNormal() * 20 ) )
    local climbNormal = ( climbEnd - climbStart ):GetNormalized()
    local climbDist = climbStart:Distance( climbEnd )
    local stuckTime = ( CurTime() + random( 2, 5 ) )

    while ( true ) do
        local climbPos = ( climbStart + climbNormal * climbFract )
        laddermovetable.start = climbPos
        laddermovetable.endpos = ( climbPos + climbNormal * 10 )
        laddermovetable.filter = self
        laddermovetable.mins, laddermovetable.maxs = self:GetCollisionBounds()

        if !self.l_issmoving or CurTime() >= stuckTime or !self:Alive() or self:IsInNoClip() then
            local obstacle = TraceHull( laddermovetable ).Entity
            if obstacle != self and self:GetEnemy() != obstacle and IsValid( obstacle ) and self:CanTarget( obstacle ) then
                stuckTime = ( stuckTime + 5 )
                self:AttackTarget( obstacle )
            else
                if self:IsInRange( finishPos, 40 ) then
                    self:SetPos( finishPos )
                else
                    local dir = ( climbState != 1 and ladder:GetNormal() or ( climbStart - self:GetPos() ):GetNormalized() )
                    self:SetPos( self:GetPos() + dir * 20 )
                    self.loco:SetVelocity( dir * 275 )
                end

                break
            end
        end

        if climbState != 2 or ( !self:IsDisabled() or self:GetIsTyping() ) and CurTime() >= self.l_moveWaitTime then
            if !IsValid( TraceHull( laddermovetable ).Entity ) then
                climbFract = ( climbFract + ( 250 * FrameTime() ) )
                stuckTime = ( CurTime() + random( 2, 5 ) )

                if climbFract >= climbDist then
                    if climbState == 1 then
                        climbEnd = goalPos + ( ladder:GetNormal() * 16 )
                    elseif climbState == 2 then
                        climbEnd = finishPos
                    else
                        break
                    end

                    climbStart = self:GetPos()
                    climbNormal = ( climbEnd - climbStart ):GetNormalized()
                    climbDist = climbStart:Distance( climbEnd )

                    climbFract = 0
                    climbState = ( climbState + 1 )
                end

                if climbState == 2 and CurTime() >= nextSndTime then
                    self:EmitSound( "player/footsteps/ladder" .. random( 4 ) .. ".wav" )
                    nextSndTime = CurTime() + 0.466
                end
            end
        end

        climbPos = ( climbStart + climbNormal * climbFract )
        self:SetPos( climbPos )
        self.loco:FaceTowards( self:GetPos() + climbNormal )

        coroutine_yield()
    end

    self.l_ladderarea = nil
end

-- If we are moving while this function is called, recompute our current path or change the goal position and recompute
function ENT:RecomputePath( pos )
    if !self.l_issmoving then return end
    self.l_recomputepath = ( pos or self.l_movepos )
end

-- Stops movement from :MoveToPos() and :MoveToPosOFFNAV()
function ENT:CancelMovement()
    self.AbortMovement = self.l_issmoving
end

-- Makes lambda wait and stop while moving for a given amount of time
function ENT:WaitWhileMoving( time )
    if !self.l_issmoving then return end
    if CurTime() >= self.l_moveWaitTime then
        self.loco:SetVelocity( vector_origin )
    end
    self.l_moveWaitTime = ( CurTime() + time )
end

-- Force the Lambda Player to move in a set speed for given amount of time
function ENT:ForceMoveSpeed( speed, time, noWepMult )
    if noWepMult != true then speed = ( speed * self.l_WeaponSpeedMultiplier ) end
    self.loco:SetDesiredSpeed( speed )
    self.l_nextspeedupdate = ( CurTime() + ( time or 0.1 ) )
end

-- This function will either return true or false
-- If this returns true, continue on our current path
-- Unless false, don't continue and stop
function ENT:HandleStuck()
    if self:GetIsDead() then -- Who knows just in case
        self.loco:ClearStuck() 
        return false 
    end

    self.l_stucktimes = self.l_stucktimes + 1
    self.l_stucktimereset = CurTime() + 10

    -- Allow external addons to control our stuck process. We assume whoever made that hook and returns "stop" or "continue" will handle the unstuck behaviour
    local result = LambdaRunHook( "LambdaOnStuck", self, self.l_stucktimes )
    if result == "stop" then 
        return false 
    elseif result == "continue" then 
        return true 
    end

    if self.l_stucktimes == 3 then 
        self.l_unstuck = true 
        return true 
    elseif self.l_stucktimes == 4 then 
        self.l_unstuck = true 
        return false 
    end

    local selfPos = self:GetPos()
    local mins, maxs = self:GetCollisionBounds()

    unstucktable.start = selfPos
    unstucktable.endpos = selfPos + vector_up * 4
    unstucktable.mins = mins
    unstucktable.maxs = maxs
    unstucktable.filter = self

    local istuckinsomething = TraceHull( unstucktable )
    if !istuckinsomething.Hit then -- If we didn't get stuck in any entity then try to jump
        self:LambdaJump()
        self.loco:ClearStuck()
    else -- We got stuck in something. Force our way out
        self.l_unstuck = true
    end

    return true
end

-- Approaches a direction
function ENT:ApproachDir( dir, time )
    time = ( CurTime() + ( time or 1 ) )

    self:Hook( "Tick", "approachposition", function()
        if CurTime() >= time then return "end" end
        self.loco:Approach( self:GetPos() + dir * self.loco:GetDesiredSpeed(), 99 )
    end )
end

local doorClasses = {
    ["prop_door_rotating"] = true,
    ["func_door"] = true,
    ["func_door_rotating"] = true
}
-- Fires a trace in front of the player that will open doors if it hits a door and shoot at breakable obstacles
function ENT:ObstacleCheck( pathDir )
    if CurTime() < self.l_nextobstaclecheck then return end
    self.l_nextobstaclecheck = ( CurTime() + 0.1 )

    local selfPos = ( self:GetPos() + vector_up * self.loco:GetStepHeight() )
    tracetable.start = selfPos
    tracetable.endpos = ( selfPos + pathDir * 60 )
    tracetable.filter = self

    local ent = Trace( tracetable ).Entity
    if !IsValid( ent ) then return end

    local class = ent:GetClass()
    if doorClasses[ class ] and ent.Fire then
        -- Back up while opening the door(s)
        if ent:GetInternalVariable( "m_eDoorState" ) != 2 and ent:GetInternalVariable( "m_toggle_state" ) != 0 then
            self:ApproachDir( -pathDir, 0.5 )
        end

        if class == "prop_door_rotating" then
            ent:Fire( "OpenAwayFrom", "!activator", 0, self )
            local slaveDoor = ents_FindByName( ent:GetKeyValues().slavename )
            if IsValid( slaveDoor ) then slaveDoor:Fire( "OpenAwayFrom", "!activator", 0, self ) end
        else
            ent:Fire( "Open" )
        end

        return
    end

    if ent:Health() <= 0 or ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then return end
    if LambdaRunHook( "LambdaCanTarget", self, ent ) == true then return end
    if self:HookExists( "Tick", "ShootAtObstacle" ) then return end

    if !self:HasLethalWeapon() then self:SwitchToLethalWeapon() end
    local fireTime = ( CurTime() + Rand( 0.5, 1.0 ) )

    self:Hook( "Tick", "ShootAtObstacle", function()
        if CurTime() >= fireTime or !IsValid( ent ) or ent:Health() <= 0 then return "end" end
        self:LookTo( ent, 1.0 )
        self:UseWeapon( ent )
    end )
end

local avoidtracetable = {
    mins = Vector( -10, -10, 0 ),
    maxs = Vector( 10, 10, 20 )
} -- Recycled table
local hitcol = Color( 255, 0, 0, 10 )
local safecol = Color( 0, 255, 0, 10 )

-- Fires 2 hull traces that will make the player try to move out of the way of whatever is blocking the way
function ENT:AvoidCheck( goalAng )
    if !shouldavoid:GetBool() then return end

    local isStuck = self.l_AvoidCheck_IsStuck
    if CurTime() >= self.l_AvoidCheck_NextStuckCheck then
        self.l_AvoidCheck_NextStuckCheck = ( CurTime() + ( isStuck and 2 or 1 ) )

        local selfPos = self:GetPos()
        local lastPos = self.l_AvoidCheck_LastPos
        if !isStuck and self:IsInRange( lastPos, ( 50 - math_abs( lastPos.z - selfPos.z ) ) ) then
            isStuck = true
        else
            isStuck = false
            self.l_AvoidCheck_LastPos = selfPos
        end
    end

    self.l_AvoidCheck_IsStuck = isStuck
    if isStuck then return end

    local selfPos = self:GetPos()
    local selfRight = goalAng:Right()
    local selfForward = goalAng:Forward()

    avoidtracetable.start = ( selfPos + vector_up * ( self.loco:GetStepHeight() + 8 ) + selfForward * 30 + selfRight * 12.5 )
    avoidtracetable.endpos = avoidtracetable.start 
    avoidtracetable.filter = self

    local rightresult = TraceHull( avoidtracetable )
    if dev:GetBool() then
        debugoverlay.Box( avoidtracetable.start, avoidtracetable.mins, avoidtracetable.maxs, 0.1, ( rightresult.Hit and hitcol or safecol ), false )
    end

    avoidtracetable.start = ( avoidtracetable.start - selfRight * 25 )
    avoidtracetable.endpos = avoidtracetable.start 

    local leftresult = TraceHull( avoidtracetable )
    if dev:GetBool() then
        debugoverlay.Box( avoidtracetable.start, avoidtracetable.mins, avoidtracetable.maxs, 0.1, ( leftresult.Hit and hitcol or safecol ), false )
    end

    if leftresult.Hit and rightresult.Hit then -- Back up
        local lent, rent = leftresult.Entity, rightresult.Entity
        if IsValid( lent ) and doorClasses[ lent:GetClass() ] or IsValid( rent ) and doorClasses[ rent:GetClass() ] then return end

        self:ApproachDir( -selfForward, 0.25 )
    end
    if leftresult.Hit and !rightresult.Hit then -- Move to the right
        self.loco:Approach( self:GetPos() + selfRight * self.loco:GetDesiredSpeed(), 100 )
    elseif rightresult.Hit and !leftresult.Hit then  -- Move to the left
        self.loco:Approach( self:GetPos() - selfRight * self.loco:GetDesiredSpeed(), 100 )
    end
end

-- CNavArea --
local CNavAreaMeta                                   = FindMetaTable( "CNavArea" )
local CNavArea_GetCenter                             = CNavAreaMeta.GetCenter
local CNavArea_GetAdjacentAreas                      = CNavAreaMeta.GetAdjacentAreas
local CNavArea_GetLaddersAtSide                      = CNavAreaMeta.GetLaddersAtSide
local CNavArea_ClearSearchLists                      = CNavAreaMeta.ClearSearchLists
local CNavArea_AddToOpenList                         = CNavAreaMeta.AddToOpenList
local CNavArea_SetCostSoFar                          = CNavAreaMeta.SetCostSoFar
local CNavArea_SetTotalCost                          = CNavAreaMeta.SetTotalCost
local CNavArea_UpdateOnOpenList                      = CNavAreaMeta.UpdateOnOpenList
local CNavArea_IsOpenListEmpty                       = CNavAreaMeta.IsOpenListEmpty
local CNavArea_PopOpenList                           = CNavAreaMeta.PopOpenList
local CNavArea_AddToClosedList                       = CNavAreaMeta.AddToClosedList
local CNavArea_GetCostSoFar                          = CNavAreaMeta.GetCostSoFar
local CNavArea_IsOpen                                = CNavAreaMeta.IsOpen
local CNavArea_IsClosed                              = CNavAreaMeta.IsClosed
local CNavArea_RemoveFromClosedList                  = CNavAreaMeta.RemoveFromClosedList
local CNavArea_ComputeAdjacentConnectionHeightChange = CNavAreaMeta.ComputeAdjacentConnectionHeightChange
local CNavArea_GetAttributes                         = CNavAreaMeta.GetAttributes
local CNavArea_HasAttributes                         = CNavAreaMeta.HasAttributes
--

-- CNavLadder --
local CNavLadderMeta                                 = FindMetaTable( "CNavLadder" )
local CNavLadder_GetLength                           = CNavLadderMeta.GetLength
local CNavLadder_GetTopForwardArea                   = CNavLadderMeta.GetTopForwardArea
local CNavLadder_GetTopLeftArea                      = CNavLadderMeta.GetTopLeftArea
local CNavLadder_GetTopRightArea                     = CNavLadderMeta.GetTopRightArea
local CNavLadder_GetTopBehindArea                    = CNavLadderMeta.GetTopBehindArea
local CNavLadder_GetBottomArea                       = CNavLadderMeta.GetBottomArea
--

-- CLuaLocomotion --
local CLuaLocomotionMeta                             = FindMetaTable( "CLuaLocomotion" )
local CLuaLocomotion_GetStepHeight                   = CLuaLocomotionMeta.GetStepHeight
local CLuaLocomotion_GetJumpHeight                   = CLuaLocomotionMeta.GetJumpHeight
--

-- Vector --
local VectorMeta                                     = FindMetaTable( "Vector" )
local GetDistTo                                      = VectorMeta.Distance
local GetDistToSqr                                   = VectorMeta.DistToSqr
--

local crouchWalkPenalty = 5
local jumpPenalty = 15
local ladderPenalty = 20
local avoidPenalty = 100
local retreatDangerPenalty = 125
local combatLadderPenalty = 175

-- Returns a pathfinding function for the :Compute() function
function ENT:PathGenerator( canUpdate, isLambdaCheck )
    local loco = self.loco
    local stepHeight = CLuaLocomotion_GetStepHeight( loco )
    local jumpHeight = CLuaLocomotion_GetJumpHeight( loco ) + 12
    local thirdHealth = ( self:Health() * 0.75 )
    local obeyNavmesh = obeynav:GetBool()
    local isInNoClip = self:IsInNoClip()
    local isAttacking = ( self:InCombat() and self:GetIsFiring() )

    local retreatTargArea, retreatTargPos
    if self:IsPanicking() and IsValid( self:GetEnemy() ) then
        retreatTargPos = self:GetEnemy():GetPos()
        retreatTargArea = GetNearestNavArea( retreatTargPos, true, 400, false, true, 0 )
    end

    local randomizeCost = randomizepathfinding:GetBool()
    local minRandCost = mincostscale:GetFloat()
    local maxRandCost = maxcostscale:GetFloat()
    local randCost = Rand( minRandCost, maxRandCost )

    return function( area, fromArea, ladder, elevator, length )
        if !IsValid( fromArea ) then return 0 end

        local areaPos = CNavArea_GetCenter( area )
        local fromPos = CNavArea_GetCenter( fromArea )

        local dist = 0
        if !isInNoClip and IsValid( ladder ) then
            dist = ( CNavLadder_GetLength( ladder ) * ladderPenalty )
            if isLambdaCheck then dist = ( dist * dist ) end
        elseif length > 0 then
            dist = length
        elseif isLambdaCheck then
            dist = GetDistToSqr( fromPos, areaPos )
        else
            dist = GetDistTo( fromPos, areaPos )
        end

        local cost = ( CNavArea_GetCostSoFar( fromArea ) + dist )
        if randomizeCost then
            if !canUpdate then randCost = Rand( minRandCost, maxRandCost ) end
            cost = ( cost * randCost ) 
        end

        if !isInNoClip then 
            if !IsValid( ladder ) then
                local deltaZ = CNavArea_ComputeAdjacentConnectionHeightChange( fromArea, area )
                if !areaPos:IsUnderwater() then
                    local height = -deltaZ
                    local fallDamage = self:GetFallDamageFromHeight( height )
                    if fallDamage > 0 then
                        if fallDamage >= thirdHealth then
                            return -1
                        end
                        cost = ( cost + dist * ( fallDamage * 2 ) )
                    end
                    cost = ( cost + dist * random( height * 0.5, height ) )
                end

                if !fromPos:IsUnderwater() then
                    if deltaZ > jumpHeight then
                        return -1
                    elseif deltaZ > stepHeight then
                        cost = ( cost + dist * jumpPenalty )
                    end
                end
            elseif isAttacking then
                cost = ( cost + dist * combatLadderPenalty )
            end

            if obeyNavmesh then
                local attributes = CNavArea_GetAttributes( area )

                -- Simple, try to avoid going through this area unless there is no other way
                if band( attributes, NAV_MESH_AVOID ) != 0 then
                    cost = ( cost + dist * avoidPenalty ) 
                end

                -- We slow down when slow-walking or crouching, so try avoid these areas if possible
                if band( attributes, NAV_MESH_WALK ) != 0 or band( attributes, NAV_MESH_CROUCH ) != 0 then
                    cost = ( cost + dist * crouchWalkPenalty ) 
                end
            end
        end

        if retreatTargArea and area == retreatTargArea or retreatTargPos and GetDistToSqr( areaPos, retreatTargPos ) <= 262144 then
            cost = ( cost + dist * retreatDangerPenalty )
        end

        -- Too costy for performance...
        -- local hookCost = LambdaRunHook( "LambdaOnPathGenerate", self, area, fromArea, cost, dist, ladder, length )
        -- if hookCost then cost = hookCost end

        return cost
    end
end

local GetNavArea = navmesh.GetNavArea
local GetNavAreaCount = navmesh.GetNavAreaCount

-- Using the A* algorithm and navmesh, finds out if we can reach the given area
-- Was created because base CLuaLocomotion's 'IsAreaTraversable' seems to be broken
-- Not recommended to use in loops with large tables
-- The 'area' and 'startArea' variables can be either a vector or a navmesh area
function ENT:IsAreaTraversable( area, startArea, pathGenerator )
    if isvector( area ) then area = GetNavArea( area, 100 ) end 
    if !IsValid( area ) then return false end

    local isCached = self.l_cachedunreachableares[ area ]
    if isCached then 
        if CurTime() < isCached then return false end
        self.l_cachedunreachableares[ area ] = nil
    end

    local myArea = startArea or self.l_currentnavarea
    if isvector( myArea ) then myArea = GetNavArea( myArea, 100 ) end 
    if !IsValid( myArea ) then return false end

    if area == myArea then return true end
    pathGenerator = pathGenerator or self:PathGenerator( nil, true )

    CNavArea_ClearSearchLists( myArea )
    CNavArea_AddToOpenList( myArea )
    CNavArea_SetCostSoFar( myArea, 0 )

    local areaPos = CNavArea_GetCenter( area )
    CNavArea_SetTotalCost( myArea, GetDistToSqr( CNavArea_GetCenter( myArea ), areaPos ) )
    CNavArea_UpdateOnOpenList( myArea )

    local foundAreas = 0
    local navCount = GetNavAreaCount()

    while ( !CNavArea_IsOpenListEmpty( myArea ) ) do
        local curArea = CNavArea_PopOpenList( myArea )
        if curArea == area then return true end

        local ladderList
        local searchIndex = 1
        local searchLadders = false
        local ladderUp = true
        local ladderTopDir = 0
        local floorList = CNavArea_GetAdjacentAreas( curArea )

        while ( true ) do
            local newArea, ladder

            if !searchLadders then
                if searchIndex > #floorList then
                    searchLadders = true
                    ladderList = CNavArea_GetLaddersAtSide( curArea, 0 )
                    
                    searchIndex = 1
                    continue
                end

                newArea = floorList[ searchIndex ]
                searchIndex = ( searchIndex + 1 )
            else
                if searchIndex > #ladderList then
                    if !ladderUp then break end
                    ladderUp = false
                    ladderList = CNavArea_GetLaddersAtSide( curArea, 1 )
                    searchIndex = 1
                    continue
                end

                ladder = ladderList[ searchIndex ]
                if ladderUp then
                    if ladderTopDir == 0 then
                        newArea = CNavLadder_GetTopForwardArea( ladder )
                    elseif ladderTopDir == 1 then
                        newArea = CNavLadder_GetTopLeftArea( ladder )
                    elseif ladderTopDir == 2 then
                        newArea = CNavLadder_GetTopRightArea( ladder )
                    elseif ladderTopDir == 3 then
                        newArea = CNavLadder_GetTopBehindArea( ladder )
                    else
                        searchIndex = ( searchIndex + 1 )
                        ladderTopDir = 0
                        continue
                    end

                    ladderTopDir = ( ladderTopDir + 1 )
                else
                    newArea = CNavLadder_GetBottomArea( ladder )
                    searchIndex = ( searchIndex + 1 )
                end
            end
            if !IsValid( newArea ) or newArea == curArea then continue end

            local newCostSoFar = pathGenerator( newArea, curArea, ladder, nil, -1 )
            if !isnumber( newCostSoFar ) then 
                newCostSoFar = 1e30 
            elseif newCostSoFar < 0 then 
                continue
            end

            if ( CNavArea_IsOpen( newArea ) or CNavArea_IsClosed( newArea ) ) and CNavArea_GetCostSoFar( newArea ) <= newCostSoFar then continue end
            CNavArea_SetCostSoFar( newArea, newCostSoFar )
            CNavArea_SetTotalCost( newArea, newCostSoFar + GetDistToSqr( CNavArea_GetCenter( newArea ), areaPos ) )

            if CNavArea_IsClosed( newArea ) then
                CNavArea_RemoveFromClosedList( newArea )
            end
            
            if CNavArea_IsOpen( newArea ) then
                CNavArea_UpdateOnOpenList( newArea )
            else
                CNavArea_AddToOpenList( newArea )
            end

            foundAreas = ( foundAreas + 1 )
            if foundAreas >= navCount then break end
        end

        CNavArea_AddToClosedList( curArea )
    end

    self.l_cachedunreachableares[ area ] = ( CurTime() + 120 )
    return false
end
