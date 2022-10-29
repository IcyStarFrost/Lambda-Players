
local SimpleTimer = timer.Simple
local random = math.random

if SERVER then

    function ENT:OnKilled( info )
        
        net.Start( "lambdaplayers_becomeragdoll" )
            net.WriteEntity( self )
            net.WriteVector( info:GetDamageForce() )
            net.WriteVector( info:GetDamagePosition() )
            net.WriteVector( self:GetPlyColor() )
        net.Broadcast()

        SimpleTimer( 0.1, function() self:Remove() end )

    end



end