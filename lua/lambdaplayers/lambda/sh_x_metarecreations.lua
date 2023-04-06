-- Functions below are recreations of whatever gmod meta functions
local random = math.random


local eyetracetable = {}

-- Our name
function ENT:Nick()
    return self:GetLambdaName()
end

-- Returns our eye position
function ENT:EyePos2()
    return self:GetAttachmentPoint( "eyes" ).Pos
end

-- Returns our eye angles
function ENT:EyeAngles2()
    local eyeAttach = self:GetAttachmentPoint( "eyes" )

    local ene = self:GetEnemy()
    if IsValid( ene ) and self:GetNW2String( "lambda_state", "Idle" ) == "Combat" then
        return ( ( ene.IsLambdaPlayer and ene:GetAttachmentPoint( "eyes" ).Pos or ( isfunction( ene.EyePos ) and ene:EyePos() or ene:WorldSpaceCenter() ) ) - eyeAttach.Pos ):Angle()
    end 

    return eyeAttach.Ang
end

-- If we are alive
function ENT:Alive()
    return !self:GetIsDead() 
end

-- Returns the direction we are looking to
function ENT:GetAimVector()
    return self:EyeAngles2():Forward()
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
    local attach = self:GetAttachmentPoint( "eyes" )
    eyetracetable.start = attach.Pos
    eyetracetable.endpos = attach.Ang:Forward() * 32768
    eyetracetable.filter = self
    local result = util.TraceLine( eyetracetable )
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

function ENT:IsPlayingTaunt()
    return self:GetState() == "UsingAct"
end

function ENT:IsSprinting()
    return self:GetRun()
end

local clamp = math.Clamp
function ENT:SetCrouchedWalkSpeed( speed )
    self:SetCrouchSpeed( self:GetWalkSpeed() * clamp( speed, 0, 1 ))
end

function ENT:ShouldDrawLocalPlayer()
    return self:IsBeingDrawn()
end

function ENT:SetPlayerColor( col )
    self:SetPlyColor( col )
end

local QuickTrace = util.QuickTrace
local _LAMBDAPLAYERSFootstepMaterials = _LAMBDAPLAYERSFootstepMaterials
function ENT:PlayStepSound( volume )
    local stepMat = QuickTrace( self:WorldSpaceCenter(), self:GetUp() * -32756, self ).MatType
    if LambdaRunHook( "LambdaFootStep", self, self:GetPos(), stepMat ) == true then return end

    local waterLvl = self:GetWaterLevel()
    if waterLvl != 0 and waterLvl != 3 and self:IsOnGround() then
        self:EmitSound( "player/footsteps/wade" .. random( 1, 8 ) .. ".wav", 75, random( 90, 110 ), volume or 0.65 )
    else
        local stepSnds = ( _LAMBDAPLAYERSFootstepMaterials[ stepMat ] or _LAMBDAPLAYERSFootstepMaterials[ MAT_DEFAULT ] )
        self:EmitSound( stepSnds[ random( #stepSnds ) ], 75, 100, volume or 0.5 )
    end
end

function ENT:Name()
    return self:GetLambdaName()
end

function ENT:LastHitGroup()
    return self.l_lasthitgroup or 0
end

function ENT:IsFrozen()
    return self.l_isfrozen
end

function ENT:LocalEyeAngles()
    return self:EyeAngles()
end

function ENT:HasGodMode()
    return self.l_godmode
end

function ENT:GetStepSize()
    return self.loco:GetStepHeight()
end

function ENT:GetCrouchedWalkSpeed()
    return self:GetCrouchSpeed()
end

function ENT:GetJumpPower()
    return self.loco:GetJumpHeight()
end

function ENT:GetMaxSpeed()
    return self:GetRunSpeed()
end

function ENT:GetPlayerColor()
    return self:GetPlyColor()
end

function ENT:FlashlightIsOn()
    return self:GetFlashlightOn()
end

function ENT:GetWeaponColor()
    return self:GetPhysColor()
end

function ENT:Crouching()
    return self:GetCrouch()
end

function ENT:Team()
    return self:GetTeam()
end

function ENT:Armor()
    return self:GetArmor()
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

    function ENT:GodEnable()
        self.l_godmode = true
    end

    function ENT:Give( weaponClassName )
        self:SwitchWeapon( weaponClassName )
    end

    function ENT:Freeze( freeze )
        self.l_isfrozen = freeze
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
        self:SetRun( true )
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

    function ENT:StripWeapons()
        self:SwitchWeapon( "none", true )
    end

    function ENT:SwitchToDefaultWeapon()
        self:SwitchToSpawnWeapon()
    end

    function ENT:TimeConnected()
        return SysTime() - self.debuginitstart
    end

elseif CLIENT then

    function ENT:IsMuted() 
        return self.l_ismuted
    end

    function ENT:VoiceVolume()
        return self:GetVoiceLevel()
    end

    function ENT:SetMuted( bool )
        self.l_ismuted = bool
    end

end