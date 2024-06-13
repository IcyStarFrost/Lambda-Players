-- Functions below are recreations of whatever gmod meta functions

local eyetracetable = {}

-- Our name
function ENT:Nick()
    return self:GetLambdaName()
end

-- Our name #2
function ENT:Name()
    return self:GetLambdaName()
end

-- Returns our eye position (DEPRECATED)
function ENT:EyePos2()
    return self:EyePos()
end

-- Returns our eye angles (DEPRECATED)
function ENT:EyeAngles2()
    return self:EyeAngles()
end

-- If we are alive
function ENT:Alive()
    return !self:GetIsDead() 
end

-- Returns the direction we are looking to
function ENT:GetAimVector()
    return self:EyeAngles():Forward()
end

-- Returns our current armor value
function ENT:Armor()
    return self:GetArmor()
end

local SharedRandom = util.SharedRandom
function ENT:UniqueID()
    return SharedRandom( "uniqueid", 1, 1000000000, self:EntIndex() )
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

-- Returns if we are typing
function ENT:IsTyping()
    return self:GetIsTyping()
end

-- Similar to Real Player's :GetEyeTrace()
function ENT:GetEyeTrace()
    eyetracetable.start = self:EyePos()
    eyetracetable.endpos = ( self:GetAimVector() * 32768 )
    eyetracetable.filter = self
    return util.TraceLine( eyetracetable )
end
ENT.GetEyeTraceNoCursor = ENT.GetEyeTrace

-- Return random fake steam ids
function ENT:SteamID()
    return self:GetNW2String( "lambda_steamid", "STEAM_0:0:0" )
end

-- Returns if we are currently playing a taunt animation
function ENT:IsPlayingTaunt()
    return ( self:GetNW2Int( "lambda_curanimgesture" ) > 0 )
end

-- Returns if we are sprinting
function ENT:IsSprinting()
    return self:GetRun()
end

-- Scales our crouched walk speed to the set value
local clamp = math.Clamp
function ENT:SetCrouchedWalkSpeed( speed )
    self:SetCrouchSpeed( self:GetWalkSpeed() * clamp( speed, 0, 1 ) )
end

-- Sets our player model color
function ENT:SetPlayerColor( col )
    self:SetPlyColor( col )
end

-- Plays footstep sound at our position
local QuickTrace = util.QuickTrace
local _LAMBDAPLAYERSFootstepMaterials = _LAMBDAPLAYERSFootstepMaterials
function ENT:PlayStepSound( volume )
    local stepMat = QuickTrace( self:WorldSpaceCenter(), vector_up * -32756, self ).MatType
    local selfPos = self:GetPos()
    if LambdaRunHook( "LambdaFootStep", self, selfPos, stepMat ) == true then return end

    local sndPitch, sndName = 100
    local waterLvl = self:GetWaterLevel()
    if waterLvl != 0 and waterLvl != 3 and self:IsOnGround() then
        sndName = "player/footsteps/wade" .. LambdaRNG( 8 ) .. ".wav"
        sndPitch = LambdaRNG( 90, 110 )
        if !volume then volume = 0.65 end
    else
        local stepSnds = ( _LAMBDAPLAYERSFootstepMaterials[ stepMat ] or _LAMBDAPLAYERSFootstepMaterials[ MAT_DEFAULT ] )
        sndName = stepSnds[ LambdaRNG( #stepSnds ) ]
        if !volume then volume = 0.5 end
    end

    if DSteps then
        if self.DStep_HitGround then return end
        DSteps( self, selfPos, self.l_DStepsWhichFoot, sndName, volume )
        self.l_DStepsWhichFoot = ( self.l_DStepsWhichFoot == 0 and 1 or 0 )
    else
        self:EmitSound( sndName, 75, sndPitch, volume )
    end
end

-- Returns the last hitgroup we got damaged to
function ENT:LastHitGroup()
    return self.l_lasthitgroup or 0
end

-- Returns if we are currently frozen
function ENT:IsFrozen()
    return self.l_isfrozen
end

-- Same as ENT:EyeAngles()
function ENT:LocalEyeAngles()
    return self:EyeAngles()
end

-- Returns if we have god mode on (invincible)
function ENT:HasGodMode()
    return self.l_godmode
end

-- Returns the maximum height we can step onto while moving
function ENT:GetStepSize()
    return self.loco:GetStepHeight()
end

-- Returns our speed when crouch walking
function ENT:GetCrouchedWalkSpeed()
    return self:GetCrouchSpeed()
end

-- Returns our jump power
function ENT:GetJumpPower()
    return self.loco:GetJumpHeight()
end

-- Returns our maximum movement speed
function ENT:GetMaxSpeed()
    return self:GetRunSpeed()
end

-- Returns our player model color
function ENT:GetPlayerColor()
    return self:GetPlyColor()
end

-- Returns our weapon (physgun) color
function ENT:GetWeaponColor()
    return self:GetPhysColor()
end

-- Returns if we are currently crouched
function ENT:Crouching()
    return self:GetCrouch()
end

-- Returns our team
function ENT:Team()
    return self:GetTeam()
end

-- Returns our ammo
function ENT:Armor()
    return self:GetArmor()
end

-- Returns our fake account ID
function ENT:AccountID()
    return SharedRandom( "accountid" .. self:Name(), 1, 1000000, self:EntIndex() )
end

-- Returns a fake UID
function ENT:UniqueID()
    return SharedRandom(  "uniqueid" .. self:Name(), 1, 10000000000, self:EntIndex() )
end

-- Returns a fake SteamID
function ENT:SteamID()
    return "STEAM_0:0:" .. SharedRandom(  "steamid" .. self:Name(), 1, 200000000, self:EntIndex() )
end

-- Returns a fake community ID
function ENT:SteamID64()
    return 90071996842377216 + SharedRandom(  "steamid64" .. self:Name(), 1, 10000000000, self:EntIndex() )
end

-- Returns our ragdoll entity
function ENT:GetRagdollEntity()
    local ragdoll = self.ragdoll
    return ( IsValid( ragdoll ) and ragdoll or self:GetNW2Entity( "lambda_serversideragdoll", nil ) )
end

function ENT:AllowFlashlight( canFlashlight )
    self:SetAllowFlashlight( canFlashlight )
end

function ENT:CanUseFlashlight()
    return self:GetAllowFlashlight()
end

function ENT:SetEyeAngles( ang )
    self:SetAngles( ang )
end

local entMeta = FindMetaTable( "Entity" )
local freezeFun = entMeta.Freeze
if freezeFun then
    _LambdaBaseENTFreeze = ( _LambdaBaseENTFreeze or freezeFun )

    function entMeta:Freeze( freeze )
        if self.IsLambdaPlayer and SERVER then
            self.l_isfrozen = freeze
        end
        _LambdaBaseENTFreeze( self, freeze )
    end
else
    function ENT:Freeze( freeze )
        if ( CLIENT ) then return end
        self.l_isfrozen = freeze
    end
end

function ENT:DoAnimationEvent( data )
    if ( CLIENT ) then return end
    self:RemoveGesture( data )
    self:AddGesture( data )
end

function ENT:GetHull()
    return self:GetCollisionBounds()
end

--

local emptyFunc = function() end
local falseFunc = function() return false end

ENT.ScreenFade = emptyFunc
ENT.InVehicle = falseFunc
ENT.LagCompensation = emptyFunc
ENT.ViewPunch = emptyFunc

--

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

    function ENT:GodEnable()
        self.l_godmode = true
    end

    function ENT:Give( weaponClassName )
        self:SwitchWeapon( weaponClassName )
    end

    function ENT:GodDisable()
        self.l_godmode = false
    end

    function ENT:Kill()
        if self:GetIsDead() then return end
        local info = DamageInfo()
        info:SetDamage( 0 )
        info:SetDamageForce( Vector( 0, 0, 0 ) )
        info:SetAttacker( self )
        info:SetDamagePosition( self:GetPos() )
        self:LambdaOnKilled( info )
    end

    function ENT:KillSilent()
        if self:GetIsDead() then return end
        local info = DamageInfo()
        info:SetDamage( 0 )
        info:SetDamageForce( Vector( 0, 0, 0 ) )
        info:SetAttacker( self )
        info:SetDamagePosition( self:GetPos() )
        self:LambdaOnKilled( info, true )
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
    function ENT:OwnerSteamID64()
        return self:SteamID64()
    end

    function ENT:SelectWeapon( className )
        if _LAMBDAPLAYERSWEAPONS[ className ] then
            self:SwitchWeapon( className )
        end
    end

    function ENT:SetActivity( act )
        self:StartActivity( act )
    end

    function ENT:StripWeapon()
        self:SwitchWeapon( "none" )
    end

    function ENT:SprintEnable()
        self.l_cansprint = true
    end

    function ENT:SetNoTarget( visibility )
        if visibility then 
            self:AddFlags( FL_NOTARGET )
        else 
            self:RemoveFlags( FL_NOTARGET )
        end
    end

    local spraytbl = {}
    function ENT:SprayDecal( sprayOrigin, sprayEndPos )
        spraytbl.start = sprayOrigin
        spraytbl.endpos = sprayEndPos
        spraytbl.filter = self
        spraytbl.collisiongroup = COLLISION_GROUP_WORLD
        local trace = Trace( spraytbl )

        LambdaPlayers_Spray( LambdaPlayerSprays[ LambdaRNG( #LambdaPlayerSprays ) ], trace.HitPos, trace.HitNormal, self:GetCreationID() )
        self:EmitSound( "player/sprayer.wav", 65 )
    end

    function ENT:SprintDisable()
        self.l_cansprint = false
    end

    function ENT:StripWeapons()
        self:SwitchWeapon( "none", true )
    end

    function ENT:SwitchToDefaultWeapon()
        self:SwitchToSpawnWeapon()
    end

    function ENT:TimeConnected()
        return ( SysTime() - self.debuginitstart )
    end

    -- For ReAgdoll compatibility
    function ENT:SentenceStop()
    end
end

if ( CLIENT ) then
    -- Returns if our flashlight is currently on
    function ENT:FlashlightIsOn()
        return self.l_flashlighton
    end

    -- Returns whether our player model will be drawn at the time the function is called
    function ENT:ShouldDrawLocalPlayer()
        return self:IsBeingDrawn()
    end

    function ENT:IsMuted() 
        return self.l_ismuted
    end

    function ENT:SetMuted( bool )
        self.l_ismuted = bool
    end
end