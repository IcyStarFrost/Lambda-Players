
-- State functions will now be called according to the self.l_State ( self:GetState() ) variable.
-- For example self.l_State = "Idle" will make the Lambda Player to call the Idle() function
-- Definitely a lot more cleaner this way

local RandomPairs = RandomPairs
local random = math.random
local IsValid = IsValid


function ENT:Idle()
    if random( 1, 2 ) == 1 then
        self:ComputeChance()
    else
        local pos = self:GetRandomPosition()
        self:MoveToPos( pos )
    end
end

local combattbl = { update = 0.2 }

function ENT:Combat()
    if !LambdaIsValid( self:GetEnemy() ) then self:SetState( "Idle" ) return end

    if !self:HasLethalWeapon() then self:SwitchToLethalWeapon() end

    self:Hook( "Tick", "CombatTick", function()
        if !LambdaIsValid( self:GetEnemy() ) or self:GetState() != "Combat" then return "end" end -- Returns and removes this hook because we returned "end". See sh_util.lua for source

        self.Face = self:GetEnemy()
        self.l_Faceend = CurTime() + 1

        if self:GetRangeSquaredTo( self:GetEnemy() ) <= ( self.l_CombatAttackRange * self.l_CombatAttackRange ) and self:CanSee( self:GetEnemy() ) then
            self:UseWeapon( self:GetEnemy() )
        end

        if self.l_CombatKeepDistance and LambdaIsValid( self:GetEnemy() ) and self:GetRangeSquaredTo( self:GetEnemy() ) < ( self.l_CombatKeepDistance * self.l_CombatKeepDistance ) and self:CanSee( self:GetEnemy() ) then
            self.l_movepos = self:GetPos() + ( self:GetPos() - self:GetEnemy():GetPos() ):GetNormalized() * 200
        elseif self.l_CombatKeepDistance and LambdaIsValid( self:GetEnemy() ) and self:GetRangeSquaredTo( self:GetEnemy() ) > ( self.l_CombatKeepDistance * self.l_CombatKeepDistance ) or LambdaIsValid( ent ) and !self:CanSee( self:GetEnemy() ) then
            self.l_movepos = self:GetEnemy()
        end
    
    end )

    combattbl.speed = self:GetRunSpeed() + self.l_CombatSpeedAdd

    self:MoveToPos( self:GetEnemy(), combattbl )
end

function ENT:FindTarget()

    self:SwitchToLethalWeapon()

    self:Hook( "Tick", "CombatTick", function()
        if LambdaIsValid( self:GetEnemy() ) or self:GetState() != "FindTarget" then return "end" end
        local find = self:FindInSphere( nil, 1500, function( ent ) return self:CanTarget( ent ) end )

        for k, v in RandomPairs( find ) do
            self:AttackTarget( v )
            break
        end

    end, nil, 0.5 )


    self:MoveToPos( self:GetRandomPosition() )
end


local laughdir = GetConVar( "lambdaplayers_voice_laughdir" )
function ENT:Laughing()

    self:PlaySoundFile( laughdir:GetString() == "randomengine" and self:GetRandomSound() or self:GetVoiceLine( "laugh" ), true )

    self:PlaySequenceAndWait( "taunt_laugh" )

    self:SetState( "Idle" )
end


local acts = { "taunt_dance", "taunt_robot", "taunt_muscle", "taunt_cheer" }
function ENT:UsingAct()
    self:PlaySequenceAndWait( acts[ random( #acts ) ] )
    self:SetState( "Idle" )
end