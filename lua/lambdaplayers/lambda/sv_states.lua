
-- State functions will now be called according to the self:GetState() variable.
-- For example, if Lambda Player's self:GetState() is equal to "Idle" then it will call the Idle() function
-- Definitely a lot more cleaner this way

local CurTime = CurTime
local RandomPairs = RandomPairs
local random = math.random
local Rand = math.Rand
local ceil = math.ceil
local IsValid = IsValid
local bit_band = bit.band
local VectorRand = VectorRand
local coroutine_wait = coroutine.wait
local table_insert = table.insert
local ignoreLambdas = GetConVar( "lambdaplayers_combat_dontrdmlambdas" )

local wandertbl = { autorun = true }
function ENT:Idle()
    if random( 100 ) < 70 then
        self:ComputeChance()
    else
        local pos = self:GetRandomPosition()
        if random( 3 ) == 1 then
            local triggers = self:FindInSphere( nil, 2000, function( ent ) 
                return ( ent:GetClass() == "trigger_teleport" and !ent:GetInternalVariable( "StartDisabled" ) and bit_band( ent:GetInternalVariable( "spawnflags" ), 2 ) == 2 and self:Visible( ent ) )
            end )

            if #triggers == 0 then return end
            pos = triggers[ random( #triggers ) ]:WorldSpaceCenter()
        end
        self:MoveToPos( pos, wandertbl )
    end
end

local combattbl = { update = 0.2, run = true, tol = 10 }
function ENT:Combat()
    if !LambdaIsValid( self:GetEnemy() ) then self:SetEnemy( NULL ) return true end
    if !self:HasLethalWeapon() then self:SwitchToLethalWeapon() end
    self:MoveToPos( self:GetEnemy(), combattbl )
end

-- Heal ourselves when hurt
function ENT:HealUp()
    local spawnRate = Rand( 0.25, 0.4 )
    local spawnCount = ceil( ( self:GetMaxHealth() - self:Health() ) / 25 )
    local rndVec = VectorRand( -32, 32 )

    coroutine_wait( spawnRate )
    for i = 1, random( ( spawnCount / 2 ), spawnCount ) do
        if self:GetState() != "HealUp" or !self:IsUnderLimit( "Entity" ) then break end

        local lookPos = ( self:GetPos() + rndVec )
        self:LookTo( lookPos, spawnRate )
        
        local healthkit = LambdaSpawn_SENT( self, "item_healthkit", self:Trace( lookPos, self:GetAttachmentPoint( "eyes" ).Pos ) )
        if !IsValid( healthkit ) then break end
        
        self:DebugPrint( "spawned a Entity item_healthkit" )
        self:ContributeEntToLimit( healthkit, "Entity" )
        table_insert( self.l_SpawnedEntities, 1, healthkit )

        coroutine_wait( spawnRate )
    end

    return true
end

-- Armor ourselves for better chance at surviving in combat
function ENT:ArmorUp()
    local spawnRate = Rand( 0.25, 0.4 )
    local spawnCount = ceil( ( self:GetMaxArmor() - self:Armor() ) / 15 )
    local rndVec = VectorRand( -32, 32 )

    coroutine_wait( spawnRate )
    for i = 1, random( ( spawnCount / 3 ), spawnCount ) do
        if self:GetState() != "ArmorUp" or !self:IsUnderLimit( "Entity" ) then break end

        local lookPos = ( self:GetPos() + rndVec )
        self:LookTo( lookPos, spawnRate )
        
        local battery = LambdaSpawn_SENT( self, "item_battery", self:Trace( lookPos, self:GetAttachmentPoint( "eyes" ).Pos ) )
        if !IsValid( battery ) then break end
        
        self:DebugPrint( "spawned a Entity item_battery" )
        self:ContributeEntToLimit( battery, "Entity" )
        table_insert( self.l_SpawnedEntities, 1, battery )

        coroutine_wait( spawnRate )
    end
    
    return true
end

-- Wander around until we find someone to jump
local ft_options = { cbTime = 0.5, callback = function( lambda )
    if lambda:InCombat() or lambda:GetState() != "FindTarget" then return false end
    
    local ene = lambda:GetEnemy()
    if LambdaIsValid( ene ) and lambda:CanTarget( ene ) then
        lambda:AttackTarget( ene )
        return false
    end
    lambda:SetEnemy( NULL )

    local dontRDMLambdas = ignoreLambdas:GetBool()
    local findTargets = lambda:FindInSphere( nil, 1500, function( ent )
        if ent.IsLambdaPlayer and dontRDMLambdas then return false end
        return ( lambda:CanTarget( ent ) and lambda:CanSee( ent ) )
    end )
    if #findTargets != 0 then
        lambda:AttackTarget( findTargets[ random( #findTargets ) ] )
        return false
    end
end }
function ENT:FindTarget()
    if !self:HasLethalWeapon() then self:SwitchToLethalWeapon() end
    self:MoveToPos( self:GetRandomPosition(), ft_options )
    return ( random( 1, 8 ) == 1 )
end

-- We look for a button and press it
function ENT:PushButton()
    local button = self.l_buttonentity
    if !IsValid( button ) then return true end

    self:LookTo( button, 1 )
    coroutine_wait( 1 )
    if !IsValid( button ) then return true end

    local pos = ( button:GetPos() + self:GetNormalTo( button:GetPos() ) * -60 )
    self:MoveToPos( pos )
    if !IsValid( button ) then return true end

    local class = button:GetClass()
    if class == "func_button" then
        button:Fire( "Press" )
    elseif class == "gmod_button" then
        button:Toggle( !button:GetOn(), self )
    elseif class == "gmod_wire_button" then
        button:Switch( !button:GetOn() )
    end
    button:EmitSound( "HL2Player.Use" )

    return true
end

function ENT:Laughing()
    if !self.l_preventdefaultspeak and !self:IsSpeaking( "laugh" ) then self:PlaySoundFile( "laugh", false ) end
    self:PlayGestureAndWait( ACT_GMOD_TAUNT_LAUGH )
    return self:GetLastState()
end

local acts = { ACT_GMOD_TAUNT_DANCE, ACT_GMOD_TAUNT_ROBOT, ACT_GMOD_TAUNT_MUSCLE, ACT_GMOD_TAUNT_CHEER }
function ENT:UsingAct()
    self:PlayGestureAndWait( acts[ random( #acts ) ] )
    return true
end

-- MW2/Halo lives in us forever
local t_options = { run = true, callback = function( lambda )
    if lambda:GetState() != "TBaggingPosition" then return false end
end }
function ENT:TBaggingPosition()
    self:MoveToPos( self.l_tbagpos, t_options )

    for i = 1, random( 2, 8 ) do
        if self:GetState() != "TBaggingPosition" then return end
        self:SetCrouch( true )
        coroutine_wait( 0.2 )
        self:SetCrouch( false )
        coroutine_wait( 0.2 )
    end

    return true
end

local retreatOptions = { run = true, callback = function( lambda )
    if CurTime() >= lambda.l_retreatendtime then return false end
end }
function ENT:Retreat()
    local target = self:GetEnemy()
    if CurTime() > self.l_retreatendtime or IsValid( target ) and ( ( target.IsLambdaPlayer or target:IsPlayer() ) and !target:Alive() or !self:IsInRange( target, 2000 ) ) then 
        return true
    end

    local rndPos = self:GetRandomPosition( nil, 4000, function( selfPos, area, rndPoint )
        if !IsValid( target ) then return end 

        local targetPos = target:GetPos()
        if rndPoint:DistToSqr( targetPos ) > 250000 and ( targetPos - selfPos ):GetNormalized():Dot( ( rndPoint - selfPos ):GetNormalized() ) <= 0.2 then return end

        return true 
    end )
    self:MoveToPos( rndPos, retreatOptions )
end

local heal_options = { run = true, update = 0.33, tol = 48 }
function ENT:HealSomeone()
    if !LambdaIsValid( self.l_HealTarget ) or self.l_HealTarget:Health() >= self.l_HealTarget:GetMaxHealth() or self.l_HealTarget.IsLambdaPlayer and self.l_HealTarget:InCombat() and self.l_HealTarget:GetEnemy() == self then
        return true
    end

    if self.l_Weapon != "gmod_medkit" then 
        self:SwitchWeapon( "gmod_medkit" ) 
    end

    if self:IsInRange( self.l_HealTarget, 64 ) then
        self:LookTo( self.l_HealTarget, 1 )
        self:UseWeapon( self.l_HealTarget )

        if self.l_HealTarget.IsLambdaPlayer and self.l_HealTarget:Health() >= self.l_HealTarget:GetMaxHealth() then
            self.l_HealTarget:LookTo( self, 1 )
            if !self.l_preventdefaultspeak then self.l_HealTarget:PlaySoundFile( "assist" ) end
        end
    else
        local cancelled = false
        self:PreventWeaponSwitch( true )
        
        heal_options.callback = function()
            if self:GetState() != "HealSomeone" or self:Health() < self:GetMaxHealth() then self:CancelMovement(); cancelled = true return end
            if !LambdaIsValid( self.l_HealTarget ) then self:CancelMovement(); cancelled = true return end
            if self.l_HealTarget:Health() >= self.l_HealTarget:GetMaxHealth() then self:CancelMovement(); cancelled = true return end
            if self.l_HealTarget.IsLambdaPlayer and self.l_HealTarget:InCombat() and self.l_HealTarget:GetEnemy() == self then self:CancelMovement(); cancelled = true return end
            if self:IsInRange( self.l_HealTarget, 64 ) then self:CancelMovement() return end
        end

        self:MoveToPos( self.l_HealTarget, heal_options )
        if cancelled then return true end

        self:PreventWeaponSwitch( false ) 
    end
end