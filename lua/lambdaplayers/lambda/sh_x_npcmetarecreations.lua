-- Here are recreations of NPC meta functions

function ENT:AddEntityRelationship( target, disposition, priority )
end

function ENT:AddRelationship( relationstring )
end

function ENT:AlertSound()
end

function ENT:AutoMovement()
end

function ENT:CapabilitiesAdd( capabilities )
end

function ENT:CapabilitiesClear()
end

function ENT:CapabilitiesGet()
    return CAP_MOVE_GROUND
end

function ENT:CapabilitiesRemove( capabilities )
end

function ENT:Classify()
    return CLASS_PLAYER
end

function ENT:ClearBlockingEntity()
end

function ENT:ClearCondition( condition )
end

function ENT:ClearEnemyMemory()
    if self:GetState() == "Combat" or !IsValid( self:GetEnemy() ) then return end
    self:SetState( "Idle" )
    self:SetEnemy( NULL )
end

function ENT:ClearExpression()
end

function ENT:ClearGoal()
end

function ENT:ClearSchedule()
end

function ENT:ConditionName( cond )
end

function ENT:Disposition( ent )
    self:Relations( ent )
end

function ENT:ExitScriptedSequence()
end

function ENT:FearSound()
end

function ENT:FoundEnemySound()
end

function ENT:GetArrivalActivity()
    return 0
end

function ENT:GetArrivalSequence()
    return -1
end

function ENT:GetBestSoundHint( types )
end

function ENT:GetBlockingEntity()
    return NULL
end

function ENT:GetCurrentSchedule()
    return -1
end

function ENT:GetCurrentWeaponProficiency()
    return WEAPON_PROFICIENCY_GOOD
end

function ENT:GetCurWaypointPos()
    return ( isvector( self.l_CurrentPath ) and self.l_CurrentPath or ( IsValid( self.l_CurrentPath ) and self.l_CurrentPath:GetEnd() or nil ) )
end

function ENT:GetEnemyFirstTimeSeen()
end

function ENT:GetEnemyLastKnownPos()
end

function ENT:GetEnemyLastSeenPos()
end

function ENT:GetEnemyLastTimeSeen()
end

function ENT:GetExpression()
    return ""
end

function ENT:GetHullType()
    return HULL_HUMAN
end

function ENT:GetIdealActivity()
    return ACT_HL2MP_IDLE
end

function ENT:GetIdealMoveAcceleration()
end

function ENT:GetIdealMoveSpeed()
end

function ENT:GetKnownEnemies()
    return {}
end

function ENT:GetKnownEnemyCount()
    return 0
end

function ENT:GetLastTimeTookDamageFromEnemy()
    return 0
end

function ENT:GetMinMoveCheckDist()
    return self.loco:GetMinLookAheadDistance()
end

function ENT:GetMinMoveStopDist( min )
    return min
end

function ENT:GetMoveInterval()
    return 0
end

function ENT:GetMovementActivity()
    local anims = _LAMBDAPLAYERSHoldTypeAnimations[ self.l_HoldType ]
    return ( self:GetRun() and anims.crouchWalk or anims.run )
end

function ENT:GetMovementSequence()
    return -1
end

function ENT:GetMoveVelocity()
    return self.loco:GetVelocity()
end

function ENT:GetNavType()
    return 0
end

function ENT:GetNearestSquadMember()
    return NULL
end

function ENT:GetNextWaypointPos()
    return ( isvector( self.l_CurrentPath ) and self.l_CurrentPath or ( IsValid( self.l_CurrentPath ) and self.l_CurrentPath:GetEnd() or nil ) )
end

function ENT:GetNPCState()
    return self:GetIsDead() and NPC_STATE_DEAD or self:GetState() == "Idle" and NPC_STATE_IDLE or self:GetState() == "Combat" and NPC_STATE_COMBAT
end

function ENT:GetPathDistanceToGoal()
    return ( isvector( self.l_CurrentPath ) and self:GetRangeTo( self.l_CurrentPath ) or ( IsValid( self.l_CurrentPath ) and self.l_CurrentPath:GetLength() or nil ) )
end

function ENT:GetPathTimeToGoal()
    return 0
end

function ENT:GetSquad()
    return ""
end

function ENT:GetTarget()
    return self:GetEnemy()
end

function ENT:GetTaskStatus()
    return 3
end

function ENT:GetTimeEnemyLastReacquired()
    return 0
end

function ENT:HasCondition( condition )
    return false
end

function ENT:HasEnemyEluded()
    return false
end

function ENT:HasEnemyMemory()
    return false
end

function ENT:HasObstacles()
    return false
end

function ENT:IdleSound()
end

function ENT:IgnoreEnemyUntil()
end

function ENT:IsCurrentSchedule( schedule )
    return false
end

function ENT:IsGoalActive()
    return self.l_CurrentPath != nil
end

function ENT:IsMoveYawLocked()
    return false
end

function ENT:IsMoving()
    return self.l_issmoving
end

function ENT:IsRunningBehavior()
    return false
end

function ENT:IsSquadLeader()
    return false
end

function ENT:IsUnreachable( testEntity )
    return false
end

function ENT:LostEnemySound()
end

function ENT:MaintainActivity()
end

function ENT:MarkEnemyAsEluded()
end

function ENT:MarkTookDamageFromEnemy()
end

function ENT:MoveClimbExec()
    return 0
end

function ENT:MoveClimbStart()
end

function ENT:MoveClimbStop()
end

function ENT:MoveJumpExec()
    return 0
end

function ENT:MoveJumpStart( vel )
end

function ENT:MoveJumpStop()
    return 0
end

function ENT:MoveOrder( position )
    return ( isvector( self.l_CurrentPath ) and self:GetRangeTo( self.l_CurrentPath ) or ( IsValid( self.l_CurrentPath ) and self.l_CurrentPath:GetLength() or nil ) )
end

function ENT:MovePause()
end

function ENT:MoveStart()
end

function ENT:MoveStop()
end

function ENT:NavSetGoal()
    return false
end

function ENT:NavSetGoalPos( pos )
    return false
end

function ENT:NavSetGoalTarget()
    return false
end

function ENT:NavSetRandomGoal()
    return false
end

function ENT:NavSetWanderGoal()
    return false
end

function ENT:PlaySentence()
    return -1
end

function ENT:RememberUnreachable()
end

function ENT:RemoveMemory()
end

function ENT:ResetIdealActivity( act )
end

function ENT:ResetMoveCalc()
end

function ENT:RunEngineTask( taskID, taskData )
end

function ENT:SentenceStop()
end

function ENT:SetArrivalActivity( act )
end

function ENT:SetArrivalDirection()
end

function ENT:SetArrivalDistance( dist )
end

function ENT:SetArrivalSequence()
end

function ENT:SetArrivalSpeed( speed )
end

function ENT:SetCondition( condition )
end

function ENT:SetCurrentWeaponProficiency( proficiency )
end

function ENT:SetExpression( expression )
    return 0
end

function ENT:SetHullSizeNormal()
end

function ENT:SetHullType( hullType )
end

function ENT:SetIdealActivity( number )
end

function ENT:SetIdealYawAndUpdate()
end

function ENT:SetLastPosition( Position )
end

function ENT:SetMaxRouteRebuildTime( time )
end

function ENT:SetMoveInterval( time )
end

function ENT:SetMovementActivity( activity )
end

function ENT:SetMovementSequence( sequenceId )
end

function ENT:SetMoveVelocity( vel )
end

function ENT:SetMoveYawLocked( lock )
end

function ENT:SetNavType( navtype )
end

function ENT:SetNPCState( state )
end

function ENT:SetSchedule( schedule )
end

function ENT:SetSquad( name )
end

function ENT:SetTarget( entity )
end

function ENT:SetTaskStatus( status )
end

function ENT:StartEngineTask( task, taskData )
end

function ENT:StopMoving()
end

function ENT:TargetOrder( target )
end

function ENT:TaskComplete()
end

function ENT:TaskFail( task )
end

function ENT:UpdateEnemyMemory( enemy, pos )
end

function ENT:UpdateTurnActivity()
end

function ENT:UseActBusyBehavior()
    return false
end

function ENT:UseAssaultBehavior()
    return false
end

function ENT:UseFollowBehavior()
    return false 
end

function ENT:UseFuncTankBehavior()
    return false
end

function ENT:UseLeadBehavior()
    return false
end

function ENT:UseNoBehavior()
    return false
end