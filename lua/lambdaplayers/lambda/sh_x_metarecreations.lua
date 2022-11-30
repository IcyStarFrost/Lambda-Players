-- Functions below are recreations of whatever gmod meta functions
local random = math.random

local Trace = util.TraceLine
local eyetracetable = {}

-- Our name
function ENT:Nick()
    return self:GetLambdaName()
end

-- Returns our eye position
function ENT:EyePos()
    return self:GetAttachmentPoint( "eyes" ).Pos
end

-- Our team
function ENT:Team()
    return TEAM_UNASSIGNED
end


-- If we are alive
function ENT:Alive()
    return !self:GetIsDead() 
end

function ENT:IsPlayer()
    return true
end

-- Returns the direction we are looking to
function ENT:GetAimVector()
    if IsValid( self:GetEnemy() ) and self:GetUsingSWEP() then
        return ( ( ( isfunction( self:GetEnemy().EyePos ) and self:GetEnemy():EyePos() or self:GetEnemy():WorldSpaceCenter() ) - self:GetAttachmentPoint( "eyes" ).Pos ):Angle() + AngleRand( -self.l_swepspread, self.l_swepspread ) ):Forward()
    elseif IsValid( self:GetEnemy() ) then
        return ( ( isfunction( self:GetEnemy().EyePos ) and self:GetEnemy():EyePos() or self:GetEnemy():WorldSpaceCenter() ) - self:GetAttachmentPoint( "eyes" ).Pos ):GetNormalized()
    end 
    return self:GetAttachmentPoint( "eyes" ).Ang:Forward()
end

-- Returns our current armor value
function ENT:Armor()
    return self:GetArmor()
end

function ENT:GetActiveWeapon()
    return IsValid( self:GetSWEPWeaponEnt() ) and self:GetSWEPWeaponEnt() or self:GetWeaponENT()
end

local keydownsmove = {
    [ IN_FORWARD ] = true,
    [ IN_BACK ] = true,
    [ IN_LEFT ] = true,
    [ IN_RIGHT ] = true,
}
function ENT:KeyDown( key )
    if !self.loco:GetVelocity():IsZero() and keydownsmove[ key ] then return true end
    if self:GetIsFiring() and key == IN_ATTACK then return true end
    return false
end

function ENT:IsWorldClicking()
    return false
end

function ENT:KeyDownLast( key )
    return false
end

function ENT:KeyReleased( key )
    if self.loco:GetVelocity():IsZero() and keydownsmove[ key ] then return true end
    if !self:GetIsFiring() and key == IN_ATTACK then return true end
    return false
end

function ENT:KeyPressed( key )
    if !self.loco:GetVelocity():IsZero() and keydownsmove[ key ] then return true end
    return false
end

function ENT:ViewPunch()
end

function ENT:ViewPunchReset()
end

local SharedRandom = util.SharedRandom
function ENT:UniqueID()
    return SharedRandom( "uniqueid", 1, 1000000000, self:EntIndex() )
end

function ENT:TranslateWeaponActivity( act )
    return ACT_HL2MP_IDLE
end

function ENT:UnfreezePhysicsObjects()
    
end

-- Add a certain amount to the Lambda's frag count (or kills count)
function ENT:AddFrags( count ) 
    self:SetFrags( self:GetFrags() + count )
end

-- Add a certain amount to the Lambda's death count
function ENT:AddDeaths( count ) 
    self:AddDeaths( self:GetDeaths() + count )
end


-- Returns our kill count
function ENT:Frags()
    return self:GetFrags()
end

-- Returns how much we died
function ENT:Deaths()
    return self:GetDeaths()
end

-- Returns our current ping
function ENT:Ping()
    return self:GetPing()
end

function ENT:IsAdmin()
    return false
end

function ENT:IsSuperAdmin()
    return false
end

-- Soon..
function ENT:IsTyping()
    return false
end

function ENT:IsUserGroup( groupname )
    return false 
end

function ENT:UserID()
    return self:EntIndex()
end

-- Similar to Real Player's :GetEyeTrace()
function ENT:GetEyeTrace()
    local attach = self:GetAttachmentPoint( "eyes" )
    eyetracetable.start = attach.Pos
    eyetracetable.endpos = attach.Ang:Forward() * 32768
    eyetracetable.filter = self
    local result = Trace( eyetracetable )
    return result
end

-- Return random fake steam ids
function ENT:SteamID64()
    return self:GetSteamID64()
end

-- Return random fake steam ids
function ENT:SteamID()
    return self:GetNW2String( "lambda_steamid", "STEAM_0:0:0" )
end

function ENT:StopSprinting()
end

function ENT:StopWalking()
end

function ENT:SetDuckSpeed( duckSpeed )
end

function ENT:SetDSP( soundFilter, fastReset )
end

function ENT:IsPlayingTaunt()
    return self:GetState() == "UsingAct"
end

function ENT:IsSprinting()
    return self:GetRun()
end

function ENT:IsSuitEquipped()
    return true
end

function ENT:SetDrivingEntity()
end

function ENT:SetClassID( classID )
end

function ENT:SetCanZoom( canZoom )
end

function ENT:SetCanWalk( abletowalk )
end

function ENT:SetAmmo( ammoCount, ammoType )
end

function ENT:SetAvoidPlayers( avoidPlayers )
end

local clamp = math.Clamp
function ENT:SetCrouchedWalkSpeed( speed )
    self:SetCrouchSpeed( self:GetWalkSpeed() * clamp( speed, 0, 1 ))
end

function ENT:SetCurrentViewOffset( viewOffset )
end

function ENT:SetEyeAngles( angle )
    self:SetAngles( Angle( 0, angle[ 2 ], 0 ) )
end 

function ENT:SetFOV( fov, time, requester )
end

function ENT:StartSprinting()
end

function ENT:SetWeaponColor( Color )
end

function ENT:ShouldDrawLocalPlayer()
    return self:IsBeingDrawn()
end

function ENT:StartWalking()
end

function ENT:SetViewOffsetDucked( viewOffset )
end

function ENT:SetViewOffset( viewOffset )
end

function ENT:SetViewPunchAngles( punchVel )
end

function ENT:SetViewPunchVelocity( punchVel )
end

function ENT:SetObserverMode( mode )
end

function ENT:SetPData( key, value )
end

function ENT:SetPlayerColor( col )
    self:SetPlyColor( col )
end

function ENT:SetUnDuckSpeed( UnDuckSpeed )
end

function ENT:SetPressedWidget()
end

function ENT:SetRenderAngles( ang )
end

function ENT:SetSlowWalkSpeed( speed )
end

function ENT:SetStepSize( stepHeight )
end

function ENT:SetSuitPower( power )
end

function ENT:SetSuppressPickupNotices( doSuppress )
end

function ENT:SetMaxSpeed( walkSpeed )
end

function ENT:SetJumpPower( jumpPower )
end

function ENT:SetHullDuck( hullMins, hullMaxs )
end

function ENT:SetHull( hullMins, hullMaxs )
end

function ENT:SetHands( hands )
end

function ENT:SetHoveredWidget()
end

function ENT:SetLadderClimbSpeed( speed )
end

function ENT:SetAllowFullRotation( Allowed )
end

function ENT:ScreenFade()
end

function ENT:ResetHull()
end

function ENT:RemovePData( key )
end

function ENT:RemoveAmmo( ammoCount, ammoName )
end

local QuickTrace = util.QuickTrace
function ENT:PlayStepSound( volume )
    local result = QuickTrace( self:WorldSpaceCenter(), self:GetUp() * -32600, self )
    local stepsounds = _LAMBDAPLAYERSFootstepMaterials[ result.MatType ] or _LAMBDAPLAYERSFootstepMaterials[ MAT_DEFAULT ]
    self:EmitSound( snd, 75, 100, volume )
end

function ENT:PrintMessage(  type,  message )
end

function ENT:MotionSensorPos( bone )
end

function ENT:Name()
    return self:GetLambdaName()
end

function ENT:PacketLoss()
    return 0
end

function ENT:LimitHit( type )
end

function ENT:LastHitGroup()
    return self.l_lasthitgroup or 0
end


function ENT:LagCompensation( lagCompensation )
end

function ENT:IsDrivingEntity()
    return false
end

function ENT:IsFrozen()
    return self.l_isfrozen
end

function ENT:LocalEyeAngles()
    return self:EyeAngles()
end

function ENT:HasGodMode()
    return false
end

function ENT:HasWeapon( className )
    return _LAMBDAPLAYERSWEAPONS[ className ] != nil
end

function ENT:InVehicle()
    return false
end

function ENT:GetWeapons()
    return {}
end

function ENT:GetViewEntity()
end

function ENT:GetVehicle()
end

function ENT:GetUseEntity()
end

function ENT:GetUnDuckSpeed()
end

function ENT:GetTool()
end

function ENT:GetUserGroup()
    return "user"
end

function ENT:GetViewModel()
    return self:GetSWEPWeaponEnt()
end

function ENT:GetViewOffset()
    return self:OBBCenter()
end

function ENT:GetViewOffsetDucked()
    return self:OBBCenter()
end

function ENT:GetViewPunchAngles()
    return Angle()
end

function ENT:GetViewPunchVelocity()
    return Angle()
end

function ENT:GetWeapon( className )
end

function ENT:GetSuitPower()
    return 100
end

function ENT:GetShootPos()
    return self:EyePos()
end

function ENT:GetPressedWidget()
end

function ENT:GetPreviousWeapon()
end

function ENT:GetPunchAngle()
    return Angle()
end

function ENT:GetRagdollEntity()
    return self.ragdoll
end

function ENT:GetRenderAngles()
    return Angle()
end

function ENT:GetSlowWalkSpeed()
    return self:GetWalkSpeed()
end

function ENT:GetStepSize()
    return self.loco:GetStepHeight()
end

function ENT:GetObserverTarget()
end

function ENT:GetNoCollideWithTeammates()
    return false
end

function ENT:GetHoveredWidget()
end

function ENT:GetHands()
end

function ENT:GetHull()
    return self:GetCollisionBounds()
end

function ENT:GetHullDuck()
    return self:GetCollisionBounds()
end 

function ENT:GetInfo( cVarName )
end

function ENT:GetFOV()
    return 70
end

function ENT:GetAllowFullRotation()
    return false
end

function ENT:GetAllowWeaponsInVehicle()
    return false
end

function ENT:GetAmmo()
    return {}
end

function ENT:GetAmmoCount()
    return 500
end

function ENT:GetAvoidPlayers()
    return false
end

function ENT:GetCanWalk()
    return true
end

function ENT:GetCanZoom()
    return false
end

function ENT:GetClassID()
    return self:EntIndex()
end

function ENT:GetCount()
    return 0
end

function ENT:GetCrouchedWalkSpeed()
    return self:GetCrouchSpeed()
end

function ENT:GetCurrentCommand()
end

function ENT:GetCurrentViewOffset()
    return self:OBBCenter()
end

function ENT:GetDrivingEntity()
end

function ENT:GetDrivingMode()
    return 0
end

function ENT:GetDuckSpeed()
    return 0.3
end

function ENT:GetEntityInUse()
end

function ENT:GetEyeTraceNoCursor()
    return self:GetEyeTrace()
end

function ENT:GetInfoNum( cVarName, default )
    return default
end

function ENT:GetJumpPower()
    return self.loco:GetJumpHeight()
end

function ENT:GetLadderClimbSpeed()
    return 200
end

function ENT:GetLaggedMovementValue()
    return 1
end

function ENT:GetMaxSpeed()
    return self:GetRunSpeed()
end

function ENT:GetObserverMode()
    return 0
end

function ENT:GetPData()
end

function ENT:GetPlayerColor()
    return self:GetPlyColor()
end

function ENT:GetPlayerInfo()
    local info = {
        name = self:Nick(),
        customfiles = {
            00000000,
            00000000,
            00000000,
            00000000,
        },
        fakeplayer = false,
        guid = self:SteamID(),
        ishltv = false,
        filesdownloaded = 0,
        friendid = random( 1, 1000000 ),
        userid = self:EntIndex(),
    }
end



function ENT:FlashlightIsOn()
    return self:GetFlashlightOn()
end

function ENT:GetWeaponColor()
    return self:GetPhysColor()
end

function ENT:DoSecondaryAttack()
end

function ENT:DoAttackEvent()
end

function ENT:DoAnimationEvent( data )
end

function ENT:DoCustomAnimEvent( event, data )
end

function ENT:DoReloadEvent()
end

function ENT:Crouching()
    return self:GetCrouch()
end

function ENT:DrawViewModel()
end

function ENT:ConCommand( command )
end

function ENT:CanUseFlashlight()
    return true
end

function ENT:AnimSetGestureWeight( slot, weight )
end

function ENT:AnimSetGestureSequence( slot, sequenceID )
end

function ENT:AnimRestartMainSequence()
end

function ENT:AnimRestartGesture()
end

function ENT:AnimResetGestureSlot( slot )
end

function ENT:Armor()
    return self:GetArmor()
end

function ENT:ChatPrint( message )
end

function ENT:CheckLimit( limitType )
    return false
end

function ENT:AddVCDSequenceToGestureSlot()
end

function ENT:AllowFlashlight( canFlashlight )
end

function ENT:AddCount( str, ent )
end

function ENT:AddCleanup( type, ent )
end

function ENT:AccountID()
    return SharedRandom( "accountid", 1, 1000000, self:EntIndex() )
end

if SERVER then
    local TraceHull = util.TraceHull
    local tracehull = {}
    function ENT:TraceHullAttack( startPos, endPos, mins, maxs, damage, damageFlags, damageForce, damageAllNPCs )
        tracehull.start = startPos
        tracehull.endpos = endPos
        tracehull.mins = mins
        tracehull.maxs = maxs
        tracehull.filter = self
        local result = TraceHull( tracehull )
        local hitent = result.Entity
        if IsValid( hitent ) then
            local info = DamageInfo()
            info:SetDamage( damage )
            info:SetAttacker( self )
            info:SetDamageType( damageFlags )
            info:SetDamageForce( damageForce )

            hitent:TakeDamageInfo( info )
        end
    end

    function ENT:Flashlight( isOn )
    end

    function ENT:ExitVehicle()
    end

    function ENT:CrosshairEnable()
    end

    function ENT:CrosshairDisable()
    end

    function ENT:CreateRagdoll()
    end

    function ENT:AllowImmediateDecalPainting( allow )
    end

    function ENT:EquipSuit()
    end

    function ENT:DrawWorldModel( draw )
    end

    function ENT:DropWeapon()
    end

    function ENT:DropNamedWeapon()
    end
    
    function ENT:DropObject()
    end

    function ENT:DetonateTripmines()
    end

    function ENT:DebugInfo()
        print( "Name: " .. self:GetLambdaName(), "\nPos: " .. tostring( self:GetPos() ) )
    end

    function ENT:EnterVehicle( vehicle )
    end

    -- Text chat will be added sometime.
    function ENT:Say()
    end

    function ENT:GodEnable()
        self.l_godmode = true
    end

    function ENT:GetPreferredCarryAngles( carryEnt )
    end

    function ENT:Give( weaponClassName )
        self:SwitchWeapon( weaponClassName )
    end

    function ENT:Freeze( freeze )
        self.l_isfrozen = freeze
    end

    function ENT:GiveAmmo()
    end

    function ENT:GetTimeoutSeconds()
        return 500
    end

    function ENT:GodDisable()
        self.l_godmode = false
    end

    function ENT:IsTimingOut()
        return false
    end

    function ENT:Ban( minutes )
        self:Remove()
    end

    function ENT:Kick( reason )
        self:Remove()
    end

    function ENT:Kill()
        local info = DamageInfo()
        info:SetDamage( 0 )
        info:SetDamageForce( 0 )
        info:SetAttacker( Entity( 0 ) )
        info:SetDamagePosition( self:GetPos() )
        self:LambdaOnKilled( info )
    end

    function ENT:KillSilent()
        local info = DamageInfo()
        info:SetDamage( 0 )
        info:SetDamageForce( 0 )
        info:SetAttacker( Entity( 0 ) )
        info:SetDamagePosition( self:GetPos() )
        self:LambdaOnKilled( info )
    end

    function ENT:Lock()
        self.l_isfrozen = true
        self.l_godmode = true
    end

    function ENT:UnLock()
        self.l_isfrozen = false
        self.l_godmode = false
    end

    -- Lambda players ip leak!!!!!!!!!
    function ENT:IPAddress()
        return self:GetNW2String( "lambda_ip", "000.000.0.000:27005" )
    end

    -- troll
    function ENT:IsBot()
        return false
    end

    function ENT:IsConnected()
        return true
    end

    function ENT:RemoveAllItems()
    end

    function ENT:IsListenServerHost()
        return false
    end

    function ENT:IsFullyAuthenticated()
        return true
    end
    
    function ENT:RemoveAllAmmo()
    end

    function ENT:OwnerSteamID64()
        return self:SteamID64()
    end

    function ENT:PickupWeapon()
    end

    function ENT:PickupObject( entity )
    end

    function ENT:PhysgunUnfreeze()
    end

    function ENT:RemoveSuit()
    end

    function ENT:StripAmmo()
    end

    function ENT:StopZooming()
    end

    function ENT:SetActiveWeapon( weapon )
    end

    function ENT:SelectWeapon( className )
        if _LAMBDAPLAYERSWEAPONS[ className ] then
            self:SwitchWeapon( className )
        end
    end

    function ENT:SendHint( name, delay )
    end

    function ENT:SendLua( script )
    end

    function ENT:SetActivity( act )
        self:StartActivity( act )
    end

    function ENT:StripWeapon()
        self:SwitchWeapon( "none" )
    end

    function ENT:SprintEnable()
        self:SetRun( true )
    end

    function ENT:SetAllowWeaponsInVehicle( allow )
    end

    function ENT:SetupHands( ent )
    end

    function ENT:SetUserGroup( groupName )
    end
    
    function ENT:SetViewEntity( viewEntity )
    end

    function ENT:SimulateGravGunDrop( ent )
    end

    function ENT:SimulateGravGunPickup( ent )
    end

    function ENT:Spectate( mode )
    end

    function ENT:SpectateEntity( entity )
    end

    function ENT:SetLaggedMovementValue( timescale )
    end

    function ENT:SetLastHitGroup( hitgroup )
    end

    function ENT:SetNoCollideWithTeammates( shouldNotCollide )
    end

    function ENT:SetNoTarget( visibility )
        if visibility then self:AddFlags( FL_NOTARGET) else self:RemoveFlags( FL_NOTARGET ) end
    end

    local spraytbl = {}
    function ENT:SprayDecal( sprayOrigin, sprayEndPos )
        spraytbl.start = sprayOrigin
        spraytbl.endpos = sprayEndPos
        spraytbl.filter = self
        spraytbl.collisiongroup = COLLISION_GROUP_WORLD
        local trace = Trace( spraytbl )

        LambdaPlayers_Spray( LambdaPlayerSprays[ random( #LambdaPlayerSprays ) ], trace.HitPos, trace.HitNormal, self:GetCreationID() )
        self:EmitSound( "player/sprayer.wav", 65 )
    end

    function ENT:SprintDisable()
        self:SetRun( false )
    end

    function ENT:ShouldDropWeapon( drop )
    end

    function ENT:StripWeapons()
        self:SwitchWeapon( "none", true )
    end

    function ENT:SuppressHint()
    end

    function ENT:SwitchToDefaultWeapon()
        self:SwitchWeapon( self.l_SpawnWeapon )
    end

    function ENT:TimeConnected()
        return SysTime() - self.debuginitstart
    end

    function ENT:AddFrozenPhysicsObject()
    end

elseif CLIENT then

    function ENT:AddPlayerOption()
    end

    function ENT:ShowProfile()
    end

    function ENT:IsMuted() 
        return self.l_ismuted
    end

    function ENT:VoiceVolume()
        return self:GetVoiceLevel()
    end

    function ENT:IsVoiceAudible()
        return true
    end

    function ENT:GetFriendStatus()
        return "none"
    end

    function ENT:SetMuted()
        self.l_ismuted = true
    end

    function ENT:SetVoiceVolumeScale()
    end

    function ENT:GetVoiceVolumeScale()
        return 1
    end


end