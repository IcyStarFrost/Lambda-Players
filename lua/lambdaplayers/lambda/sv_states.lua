
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
    if !LambdaIsValid( self:GetEnemy() ) or !self:HasLethalWeapon() then self:SetState( "Idle" ) return end

    self:Hook( "Tick", "CombatTick", function()
        if !LambdaIsValid( self:GetEnemy() ) or self:GetState() != "Combat" then return false end -- Returns and removes this hook because we returned false. See sh_util.lua for source

        if self:GetRangeSquaredTo( self:GetEnemy() ) <= ( self.l_CombatAttackRange * self.l_CombatAttackRange ) then
            self:UseWeapon( self:GetEnemy() )
        end
    
    end )

    combattbl.speed = self:GetRunSpeed() + self.l_CombatSpeedAdd

    self:MoveToPos( self:GetEnemy(), combattbl )
end

function ENT:FindTarget()

    self:SwitchToLethalWeapon()

    self:Hook( "Tick", "CombatTick", function()
        if LambdaIsValid( self:GetEnemy() ) or self:GetState() != "FindTarget" then return false end
        local find = self:FindInSphere( nil, 1500, function( ent ) return self:CanTarget( ent ) end )

        for k, v in RandomPairs( find ) do
            self:SetEnemy( v )
            self:SetState( "Combat" )
            self:CancelMovement()
            break
        end

    end, nil, 0.5 )


    self:MoveToPos( self:GetRandomPosition() )
end

function ENT:ToolgunState()
    local find = self:FindInSphere( nil, 200, function( ent ) if !ent:IsNPC() and !ent:IsPlayer() and !ent:IsNextBot() and IsValid( ent:GetPhysicsObject() ) then return true end end )
    self:UseColorTool( find[ random( #find ) ] )

    self:SetState( "Idle" )
end