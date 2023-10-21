
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
local Vector = Vector
local coroutine_wait = coroutine.wait
local table_insert = table.insert
local ignoreLambdas = GetConVar( "lambdaplayers_combat_dontrdmlambdas" )

local wandertbl = { autorun = true }
function ENT:Idle()
    if random( 100 ) < 70 then
        self:ComputeChance()
        return
    end

    local pos
    if random( 3 ) == 1 then
        local triggers = self:FindInSphere( nil, 2000, function( ent ) 
            return ( ent:GetClass() == "trigger_teleport" and !ent:GetInternalVariable( "StartDisabled" ) and bit_band( ent:GetInternalVariable( "spawnflags" ), 2 ) == 2 and self:CanSee( ent ) )
        end )

        if #triggers == 0 then return end
        pos = triggers[ random( #triggers ) ]:WorldSpaceCenter()
    end

    self:MoveToPos( ( pos or self:GetRandomPosition() ), wandertbl )
end

local combattbl = { update = 0.2, run = true, tol = 10 }
function ENT:Combat()
    if !LambdaIsValid( self:GetEnemy() ) then self:SetEnemy( NULL ) return true end
    if !self:HasLethalWeapon() then self:SwitchToLethalWeapon() end
    self:MoveToPos( self:GetEnemy(), combattbl )
end

-- Heal ourselves when hurt
function ENT:HealUp()
    local rndVec = ( self:GetForward() * random( -16, 16 ) + self:GetRight() * random( -16, 16 ) + self:GetUp() * random( -16, -4 ) )
    if !self:Trace( ( self:GetPos() + rndVec ), self:GetAttachmentPoint( "eyes" ).Pos ).Hit then
        self:MoveToPos( self:GetRandomPosition( nil, 100 ) )
        if !self:GetState( "HealUp" ) then return true end
    end

    local spawnRate = Rand( 0.2, 0.4 )
    coroutine_wait( spawnRate )
    
    local spawnCount = ceil( ( self:GetMaxHealth() - self:Health() ) / 25 )
    for i = 1, random( ( spawnCount / 2 ), spawnCount ) do
        if !self:GetState( "HealUp" ) or !self:IsUnderLimit( "Entity" ) then break end
        if self:Health() >= self:GetMaxHealth() then break end

        local lookPos = ( self:GetPos() + rndVec )
        self:LookTo( lookPos, spawnRate )
        
        local healthkit = LambdaSpawn_SENT( self, "item_healthkit", self:Trace( lookPos, self:GetAttachmentPoint( "eyes" ).Pos ) )
        if !IsValid( healthkit ) then break end
        
        self:DebugPrint( "spawned an entity item_healthkit" )
        self:ContributeEntToLimit( healthkit, "Entity" )
        table_insert( self.l_SpawnedEntities, 1, healthkit )

        coroutine_wait( spawnRate )
    end

    return true
end

-- Armor ourselves for better chance at surviving in combat
function ENT:ArmorUp()
    local rndVec = ( self:GetForward() * random( -16, 16 ) + self:GetRight() * random( -16, 16 ) + self:GetUp() * random( -16, -4 ) )
    if !self:Trace( ( self:GetPos() + rndVec ), self:GetAttachmentPoint( "eyes" ).Pos ).Hit then
        self.l_noclipheight = 0
        self:MoveToPos( self:GetRandomPosition( nil, 100 ) )
        if !self:GetState( "ArmorUp" ) then return true end
    end

    local spawnRate = Rand( 0.2, 0.4 )
    coroutine_wait( spawnRate )
    
    local spawnCount = ceil( ( self:GetMaxArmor() - self:Armor() ) / 15 )
    for i = 1, random( ( spawnCount / 3 ), spawnCount ) do
        if !self:GetState( "ArmorUp" ) or !self:IsUnderLimit( "Entity" ) then break end
        if self:Armor() >= self:GetMaxArmor() then break end

        local lookPos = ( self:GetPos() + rndVec )
        self:LookTo( lookPos, spawnRate )

        local battery = LambdaSpawn_SENT( self, "item_battery", self:Trace( lookPos, self:GetAttachmentPoint( "eyes" ).Pos ) )
        if !IsValid( battery ) then break end

        self:DebugPrint( "spawned an entity item_battery" )
        self:ContributeEntToLimit( battery, "Entity" )
        table_insert( self.l_SpawnedEntities, 1, battery )

        coroutine_wait( spawnRate )
    end
    
    return true
end

-- Wander around until we find someone to jump
local ft_options = { cbTime = 0.5, callback = function( lambda )
    if lambda:InCombat() or !lambda:GetState( "FindTarget" ) then return false end
    
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
        local rndTarget = findTargets[ random( #findTargets ) ]
        if ( rndTarget:IsPlayer() or rndTarget.IsLambdaPlayer ) and random( 200 ) <= lambda:GetTextChance() and lambda:CanType() then
            lambda.l_keyentity = rndTarget
            lambda:TypeMessage( lambda:GetTextLine( "announceattack" ) )
        end

        lambda:AttackTarget( rndTarget )
        return false
    end
end }
function ENT:FindTarget()
    if !self:HasLethalWeapon() then self:SwitchToLethalWeapon() end
    if random( 5 ) == 1 then self:SetSlowWalk( true ) end
    self:MoveToPos( self:GetRandomPosition(), ft_options )
    return ( random( 100 ) > self:GetCombatChance() )
end

-- We look for a button and press it
function ENT:PushButton( button )
    if IsValid( button ) then
        self:LookTo( button, 1 )
        coroutine_wait( 1 )

        if IsValid( button ) then
            local pos = button:GetPos()
            self:MoveToPos( pos + self:GetNormalTo( pos ) * -60 )

            if IsValid( button ) then
                local class = button:GetClass()
                if class == "func_button" then
                    button:Fire( "Press" )
                elseif class == "gmod_button" then
                    button:Toggle( !button:GetOn(), self )
                elseif class == "gmod_wire_button" then
                    button:Switch( !button:GetOn() )
                end

                button:EmitSound( "HL2Player.Use" )
            end
        end
    end

    return true
end

function ENT:Laughing( args )
    if !args or !istable( args ) then return true end

    local target = args[ 1 ]
    if isentity( target ) and !IsValid( target ) then return true end

    if target:IsPlayer() then
        local ragdoll = target:GetRagdollEntity()
        if IsValid( ragdoll ) then target = ragdoll end
    end
    self:LookTo( target, 1 )

    local laughDelay = ( random( 1, 6 ) * 0.1 )
    self:PlaySoundFile( "laugh", laughDelay )

    local movePos = args[ 2 ]
    local actTime = ( laughDelay * Rand( 0.8, 1.2 ) )
    if !movePos then
        coroutine_wait( actTime )
    else
        self:MoveToPos( movePos, { run = false, cbTime = actTime, callback = function( self ) return false end } )
    end

    if !self.l_preventdefaultspeak and !self:IsSpeaking( "laugh" ) then self:PlaySoundFile( "laugh", false ) end
    if self:GetState( "Laughing" ) then self:PlayGestureAndWait( ACT_GMOD_TAUNT_LAUGH ) end
    
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
function ENT:TBaggingPosition( pos )
    self:MoveToPos( pos, t_options )

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

function ENT:HealSomeone( target )
    if !LambdaIsValid( target ) or target:Health() >= target:GetMaxHealth() or target.IsLambdaPlayer and target:GetEnemy() == self then
        return true
    end

    if self.l_Weapon != "gmod_medkit" then
        if !self:CanEquipWeapon( "gmod_medkit" ) then return true end 
        self:SwitchWeapon( "gmod_medkit" )
    end

    if self:IsInRange( target, 64 ) then
        self:LookTo( target, 1 )
        self:UseWeapon( target )

        if target.IsLambdaPlayer and target:Health() >= target:GetMaxHealth() then
            target:LookTo( self, 1 )
            if !target.l_preventdefaultspeak then target:PlaySoundFile( "assist" ) end
        end
    else
        local cancelled = false
        self:PreventWeaponSwitch( true )

        self:MoveToPos( target, { run = true, update = 0.33, tol = 48, callback = function()
            if !self:GetState( "HealSomeone" ) or self:Health() < self:GetMaxHealth() then cancelled = true return false end
            if !LambdaIsValid( target ) then cancelled = true return false end
            if target:Health() >= target:GetMaxHealth() then cancelled = true return false end
            if target.IsLambdaPlayer and target:GetEnemy() == self then cancelled = true return false end
            if self:IsInRange( target, 64 ) then return false end
        end } )

        self:PreventWeaponSwitch( false ) 
        if cancelled then return true end
    end
end