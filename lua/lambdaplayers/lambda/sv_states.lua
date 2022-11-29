
-- State functions will now be called according to the self.l_State ( self:GetState() ) variable.
-- For example self.l_State = "Idle" will make the Lambda Player to call the Idle() function
-- Definitely a lot more cleaner this way

local CurTime = CurTime
local RandomPairs = RandomPairs
local random = math.random
local Rand = math.Rand
local IsValid = IsValid
local IsInWorld = util.IsInWorld
local VectorRand = VectorRand
local coroutine_wait = coroutine.wait

function ENT:Idle()
    if random( 1, 100 ) < 70 then
        self:ComputeChance()
    else
        local pos = self:GetRandomPosition()
        self:MoveToPos( pos )
    end
end

local combattbl = { update = 0.2, run = true }
function ENT:Combat()
    if !LambdaIsValid( self:GetEnemy() ) then self:SetEnemy( NULL ) self:SetState( "Idle" ) return end

    if !self:HasLethalWeapon() then self:SwitchToLethalWeapon() end

    if !self:HookExists( "Tick", "CombatTick" ) then
        self:Hook( "Tick", "CombatTick", function()
            if self:IsDisabled() then return end
            if self:GetState() != "Combat" then self:SetIsFiring( false ) return "end" end -- Returns and removes this hook because we returned "end". See sh_util.lua for source

            local ene = self:GetEnemy()
            if !LambdaIsValid( ene ) then self:SetEnemy( NULL ) return "end" end

            local canSee = self:CanSee( ene )
            local attackDist = self.l_CombatAttackRange
            if attackDist and canSee and self:IsInRange( ene, attackDist ) then
                self:SetIsFiring( true )
                self.Face = ene
                self.l_Faceend = CurTime() + 1
                self:UseWeapon( ene )
            else
                self:SetIsFiring( false )
            end

            local keepDist = self.l_CombatKeepDistance
            if keepDist and canSee and self:IsInRange( ene, keepDist ) then
                local myOrigin = self:GetPos()
                local potentialPos = ( myOrigin + ( myOrigin - ene:GetPos() ):GetNormalized() * 200 ) + VectorRand( -1000, 1000 )
                self.l_movepos = ( IsInWorld( potentialPos ) and potentialPos or self:Trace( potentialPos ).HitPos )
            else
                self.l_movepos = ene
            end
        end )
    end

    self:MoveToPos( self:GetEnemy(), combattbl )
end

-- Wander around until we find someone to jump
function ENT:FindTarget()

    if !self:HasLethalWeapon() then self:SwitchToLethalWeapon() end

    self:Hook( "Tick", "CombatTick", function()
        if LambdaIsValid( self:GetEnemy() ) or self:GetState() != "FindTarget" then return "end" end
        local find = self:FindInSphere( nil, 1500, function( ent ) return self:CanTarget( ent ) and self:CanSee( ent ) end )

        for k, v in RandomPairs( find ) do
            self:AttackTarget( v )
            break
        end

    end, nil, 0.5 )


    self:MoveToPos( self:GetRandomPosition() )
end

-- We look for a button and press it
function ENT:PushButton()
    local button = self.l_buttonentity

    if !IsValid( button ) then self:SetState( "Idle" ) return end
    local pos = ( button:GetPos() + self:GetNormalTo( button:GetPos() ) * -60 )

    self:LookTo( button, 1 )
    coroutine_wait( 1 )
    if !IsValid( button ) then self:SetState( "Idle" ) return end

    self:MoveToPos( pos )
    if !IsValid( button ) then self:SetState( "Idle" ) return end

    if button:GetClass() == "func_button" then
        button:Fire( "Press" )
    elseif button:GetClass() == "gmod_button" then
        button:Toggle( !button:GetOn(), self )
    elseif button:GetClass() == "gmod_wire_button" then
        button:Switch( !button:GetOn() )
    end
    button:EmitSound( "HL2Player.Use", 80 )

    self:SetState( "Idle" )
end

local laughdir = GetConVar( "lambdaplayers_voice_laughdir" )
function ENT:Laughing()
    self:PlaySoundFile( laughdir:GetString() == "randomengine" and self:GetRandomSound() or self:GetVoiceLine( "laugh" ), true )
    self:PlayGestureAndWait( ACT_GMOD_TAUNT_LAUGH )
    self:SetState( "Idle" )
end

local acts = { ACT_GMOD_TAUNT_DANCE, ACT_GMOD_TAUNT_ROBOT, ACT_GMOD_TAUNT_MUSCLE, ACT_GMOD_TAUNT_CHEER }
function ENT:UsingAct()
    self:PlayGestureAndWait( acts[ random( #acts ) ] )
    self:SetState( "Idle" )
end


-- MW2/Halo lives in us forever
local t_options = { run = true }
function ENT:TBaggingPosition()

    self:MoveToPos( self.l_tbagpos, t_options )

    for i=1, random( 2, 8 ) do
        if self:GetState() != "TBaggingPosition" then return end
        self:SetCrouch( true )
        coroutine_wait( 0.2 )
        self:SetCrouch( false )
        coroutine_wait( 0.2 )
    end

    self:SetState( "Idle" )
end
