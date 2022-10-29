
-- State functions will now be called according to the self.l_State variable.
-- For example self.l_State = "Idle" will make the Lambda Player to call the Idle() function
-- Definitely a lot more cleaner this way

function ENT:Idle()

    local pos = self:GetRandomPosition()
    self:MoveToPos( pos )

end