
local SimpleTimer = timer.Simple
local random = math.random
local ents_Create = ents.Create
local tobool = tobool

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

        self:RemoveTimers()
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
        self:RemoveTimers()
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

        if victim == self:GetEnemy() then
            self:DebugPrint( "Enemy was killed ", victim )
            self:SetEnemy( nil )
            self:CancelMovement()
        end

        -- If we killed the victim
        if attacker == self then
            self:DebugPrint( "killed ", victim )

        else -- Someone else killed the victim


        end

    end

    -- Part of Duplicator Support. See shared/globals.lua for the other part of the duplicator support
    function ENT:PreEntityCopy()
        self.LambdaPlayerPersonalInfo = self:ExportLambdaInfo()
    end


    -- Sets our current nav area
    function ENT:OnNavAreaChanged( old , new ) 
        self.l_currentnavarea = new
    end
    
    -- Called when we collide with something
    function ENT:HandleCollision( data )
        local collider = data.HitEntity
        if !IsValid( collider ) then return end
    
        local class = collider:GetClass()
        if class == "prop_combine_ball" then
            if self:IsFlagSet( FL_DISSOLVING ) then return end
    
            local dmginfo = DamageInfo()
            local owner = collider:GetPhysicsAttacker(1) 
            dmginfo:SetAttacker( IsValid( owner ) and owner or collider )
            dmginfo:SetInflictor( collider )
            dmginfo:SetDamage( 1000 )
            dmginfo:SetDamageType( DMG_DISSOLVE )
            dmginfo:SetDamageForce( collider:GetVelocity() )
            self:TakeDamageInfo( dmginfo )  
    
            collider:EmitSound( "NPC_CombineBall.KillImpact" )
        else
            local mass = data.HitObject:GetMass() or 500
            local impactdmg = ( ( data.TheirOldVelocity:Length() * mass ) / 1000 )
    
            if impactdmg > 10 then
                local dmginfo = DamageInfo()
                dmginfo:SetAttacker( collider )
                if IsValid( collider:GetPhysicsAttacker() ) then
                    dmginfo:SetAttacker( collider:GetPhysicsAttacker() )
                elseif collider:IsVehicle() and IsValid( collider:GetDriver() ) then
                    dmginfo:SetAttacker( collider:GetDriver() )
                    dmginfo:SetDamageType(DMG_VEHICLE)     
                end
                dmginfo:SetInflictor( collider )
                dmginfo:SetDamage( impactdmg )
                dmginfo:SetDamageType( DMG_CRUSH )
                dmginfo:SetDamageForce( data.TheirOldVelocity )
                self.loco:SetVelocity( self.loco:GetVelocity() + data.TheirOldVelocity )
                self:TakeDamageInfo( dmginfo )
            end
        end
    end

    local canuserespawn = GetConVar( "lambdaplayers_lambda_allownonadminrespawn" )
    function ENT:OnSpawnedByPlayer( ply )
        local respawn = tobool( ply:GetInfoNum( "lambdaplayers_lambda_shouldrespawn", 0 ) )

        self:SetRespawn( ply:IsAdmin() or !ply:IsAdmin() and canuserespawn:GetBool() )

        self:DebugPrint( "Applied client settings from ", ply )
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

        self:Hook( "PhysgunPickup", "Physgunpickup", function( ply, ent )
            if ent == self then self.l_ispickedupbyphysgun = true end
        end, true )

        self:Hook( "PhysgunDrop", "Physgundrop", function( ply, ent )
            if ent == self then self.l_ispickedupbyphysgun = false end
        end, true )

    elseif CLIENT then

        self:Hook( "PreDrawEffects", "CustomWeaponRenderEffects", function()
            if self:GetIsDead() or RealTime() > self.l_lastdraw then return end

            if self:GetHasCustomDrawFunction() then
                local func = _LAMBDAPLAYERSWEAPONS[ self:GetWeaponName() ].Draw
        
                if isfunction( func ) then func( self, self:GetWeaponENT() ) end
            end
        
        end, true )

    end

end