
local SimpleTimer = timer.Simple
local random = math.random



if SERVER then

    function ENT:OnKilled( info )
        if self:GetIsDead() then return end

        self:PlaySoundFile( "vo/npc/male01/pain0" .. random( 1, 9 ) .. ".wav" )

        self:SetIsDead( true )
        self:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )

        self:ClientSideNoDraw( self, true )
        self:ClientSideNoDraw( self.WeaponEnt, true )
        self:SetNoDraw( true )
        self:DrawShadow( false )
        self.WeaponEnt:SetNoDraw( true )
        self.WeaponEnt:DrawShadow( false )

        self:RemoveFlags( FL_OBJECT )
        
        net.Start( "lambdaplayers_becomeragdoll" )
            net.WriteEntity( self )
            net.WriteVector( info:GetDamageForce() )
            net.WriteVector( info:GetDamagePosition() )
            net.WriteVector( self:GetPlyColor() )
        net.Broadcast()

        if !self:IsWeaponMarkedNodraw() then
            net.Start( "lambdaplayers_createclientsidedroppedweapon" )
                net.WriteEntity( self.WeaponEnt )
                net.WriteVector( info:GetDamageForce() )
                net.WriteVector( info:GetDamagePosition() )
                net.WriteVector( self:GetPhysColor() )
            net.Broadcast()
        end

        if self:GetRespawn() then
            self:SimpleTimer( 2, function() self:LambdaRespawn() end, true )
        else
            self:SimpleTimer( 0.1, function() self:Remove() end, true )
        end

    end

    function ENT:OnRemove()
        self:CleanSpawnedEntities()
    end

    function ENT:OnInjured( info )
        local attacker = info:GetAttacker()

        if ( self:ShouldTreatAsLPlayer( attacker ) and random( 1, 3 ) == 1 or !self:ShouldTreatAsLPlayer( attacker ) and true ) and self:CanTarget( attacker ) and self:GetEnemy() != attacker  then
            if !self:HasLethalWeapon() then self:SwitchToLethalWeapon() end
            self:CancelMovement()
            self:SetEnemy( attacker )
            self:SetState( "Combat" )
        end

    end

    function ENT:OnOtherKilled( victim, info )
        local attacker = info:GetAttacker()


        -- If we killed the victim
        if attacker == self then
            

        else -- Someone else killed the victim


        end

    end

    -- Part of Duplicator Support. See shared/globals.lua for the other part of the duplicator support
    function ENT:PreEntityCopy()
        self.LambdaPlayerPersonalInfo = self:ExportLambdaInfo()
    end

    function ENT:OnNavAreaChanged( old , new ) 
        self.l_currentnavarea = new
    end
    
    

end


------ SHARED ------

-- A function for holding self:Hook() functions. Called in the ENT:Initialize() in npc_lambdaplayer
function ENT:InitializeMiniHooks()


    if SERVER then

        -- Hoookay so interesting stuff here. When a nextbot actually dies by reaching 0 or below hp, no matter how high you set their health after the fact, they will no longer take damage.
        -- To get around that we basically predict if the lambda is gonna die and completely block the damage so we don't actually die. This of course is exclusive to Respawning
        self:Hook( "EntityTakeDamage", "DamageHandling", function( target, info )
            if target != self then return end

            local potentialdeath = ( self:Health() - info:GetDamage() ) <= 0
            if self:GetRespawn() and potentialdeath then
                info:SetDamage( 0 ) -- We need this because apparently the nextbot would think it is dead and do some wacky health issues without it
                self:OnKilled( info )
                return true
            end
        
        end, true )

        self:Hook( "OnEntityCreated", "NPCRelationshipHandle", function( ent )
            self:SimpleTimer( 0, function() 
                if IsValid( ent ) and ent:IsNPC() then
                    self:HandleNPCRelations( ent )
                end
            end )
        end, true )

    elseif CLIENT then

        self:Hook( "PreDrawEffects", "CustomWeaponRenderEffects", function()
            if self:GetIsDead() or RealTime() > self.l_lastdraw then return end

            if self:GetHasCustomDrawFunction() then
                self.l_weapondrawfunction = self.l_weapondrawfunction or _LAMBDAPLAYERSWEAPONS[ self:GetWeaponName() ].Draw
        
                if isfunction( self.l_weapondrawfunction ) then self.l_weapondrawfunction( self, self:GetWeaponENT() ) end
            else
                self.l_weapondrawfunction = nil
            end
        
        end, true )

    end

end