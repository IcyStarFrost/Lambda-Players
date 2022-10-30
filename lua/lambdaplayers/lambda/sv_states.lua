
-- State functions will now be called according to the self.l_State ( self:GetState() ) variable.
-- For example self.l_State = "Idle" will make the Lambda Player to call the Idle() function
-- Definitely a lot more cleaner this way



function ENT:Idle()

    local pos = self:GetRandomPosition()
    self:MoveToPos( pos )

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