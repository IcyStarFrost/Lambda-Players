
local SimpleTimer = timer.Simple
local random = math.random

if SERVER then

    function ENT:OnKilled( info )
        if self:GetIsDead() then return end

        self:SetIsDead( true )
        self.WeaponEnt:SetNoDraw( true )
        self.WeaponEnt:DrawShadow( false )
        self:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
        self:SetNoDraw( true )
        self:DrawShadow( false )

        self:RemoveFlags( FL_OBJECT )
        
        net.Start( "lambdaplayers_becomeragdoll" )
            net.WriteEntity( self )
            net.WriteVector( info:GetDamageForce() )
            net.WriteVector( info:GetDamagePosition() )
            net.WriteVector( self:GetPlyColor() )
        net.Broadcast()

        if self:GetRespawn() then
            self:SimpleTimer( 2, function() self:LambdaRespawn() end, true )
        else
            self:SimpleTimer( 0.1, function() self:Remove() end, true )
        end

    end

    function ENT:OnInjured( info )


    end


    -- A function for holding self:Hook() functions. Called in the ENT:Initialize() in npc_lambdaplayer
    function ENT:InitializeMiniHooks()

        -- Hoookay so interesting stuff here. When a nextbot actually dies by reaching 0 or below hp, no matter how high you set their health after the fact, they will no longer take damage.
        -- To get around that we basically predict if the lambda is gonna die and completely block the damage so we don't actually die. This of course is exclusive to Respawning
        self:Hook( "EntityTakeDamage", "DamageHandling", function( target, info )
            if target != self then return end

            local potentialdeath = ( self:Health() - info:GetDamage() ) <= 0

            if self:GetRespawn() and potentialdeath then
                self:OnKilled( info )
                return true
            end
        
        end, true )

    end



end