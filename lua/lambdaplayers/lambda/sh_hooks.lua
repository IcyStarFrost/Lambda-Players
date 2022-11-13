
local SimpleTimer = timer.Simple
local random = math.random
local ents_Create = ents.Create
local tobool = tobool
local undo = undo
local ents_GetAll = ents.GetAll
local abs = math.abs
local table_Merge = table.Merge
local isfunction = isfunction
local ipairs = ipairs
local max = math.max
local ceil = math.ceil
local deathdir = GetConVar( "lambdaplayers_voice_deathdir" )
local killdir = GetConVar( "lambdaplayers_voice_killdir" )
local debugvar = GetConVar( "lambdaplayers_debug" )

if SERVER then

    -- Due to the issues of lambda players not taking damage when they die internally, we have no choice but to recreate them to get around this.
    -- If there is a fix for the damage handling failing to prevent them from actually getting below 0 please make it known so it can be fixed ASAP.
    function ENT:OnKilled( info )
        if debugvar:GetBool() then ErrorNoHaltWithStack( "WARNING! ", self:GetLambdaName(), " was killed on a engine level! The entity will be recreated!" ) end

        local exportinfo = self:ExportLambdaInfo()
        local newlambda = ents_Create( "npc_lambdaplayer" )
        newlambda:SetPos( self.l_SpawnPos )
        newlambda:SetAngles( self.l_SpawnAngles )
        newlambda:SetCreator( self:GetCreator() )
        newlambda:Spawn()
        newlambda:ApplyLambdaInfo( exportinfo )

        table_Merge( newlambda.l_SpawnedEntities, self.l_SpawnedEntities )

        if IsValid( self:GetCreator() ) then
            undo.Create( "Lambda Player ( " .. self:GetLambdaName() .. " )" )
                undo.SetPlayer( self:GetCreator() )
                undo.AddEntity( newlambda )
                undo.SetCustomUndoText( "Undone " .. "Lambda Player ( " .. self:GetLambdaName() .. " )" )
            undo.Finish( "Lambda Player ( " .. self:GetLambdaName() .. " )" )
        end

        self:SimpleTimer( 0.1, function() self:Remove() end, true )
    end

    function ENT:LambdaOnKilled( info )
        if self:GetIsDead() then return end
        self:DebugPrint( "was killed by ", info:GetAttacker() )

        local deathsounds = LambdaVoiceLinesTable.death
        
        self:PlaySoundFile( deathdir:GetString() == "randomengine" and self:GetRandomSound() or self:GetVoiceLine( "death" ) )

        self:SetIsDead( true )
        self:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )

        self:ClientSideNoDraw( self, true )
        self:ClientSideNoDraw( self.WeaponEnt, true )
        self:SetNoDraw( true )
        self:DrawShadow( false )
        self.WeaponEnt:SetNoDraw( true )
        self.WeaponEnt:DrawShadow( false )

        self:SwitchWeapon( "none", true )

        self:GetPhysicsObject():EnableCollisions( false )

        self:RemoveTimers()
        self:TerminateNonIgnoredDeadTimers()
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
            self:SimpleTimer( 0.1, function() print("Remove") self:Remove() end, true )
        end

        for k ,v in ipairs( ents_GetAll() ) do
            if IsValid( v ) and v != self and v:IsNextBot() then
                v:OnOtherKilled( self, info )
            end
        end

    end

    function ENT:OnInjured( info )
        local attacker = info:GetAttacker()

        if ( self:ShouldTreatAsLPlayer( attacker ) and random( 1, 3 ) == 1 or !self:ShouldTreatAsLPlayer( attacker ) and true ) and self:CanTarget( attacker ) and self:GetEnemy() != attacker and attacker != self  then
            if !self:HasLethalWeapon() then self:SwitchToLethalWeapon() end
            self:AttackTarget( attacker )
        end

    end

    function ENT:OnOtherKilled( victim, info )
        local attacker = info:GetAttacker()

        if victim == self:GetEnemy() then
            self:DebugPrint( "Enemy was killed by", attacker )
            self:SetEnemy( nil )
            self:CancelMovement()
        end

        if random( 1, 10 ) == 1 and self:GetRangeSquaredTo( victim ) <= ( 2000 * 2000 ) and !self:Trace( victim ).Hit then self:LaughAt( victim ) end

        -- If we killed the victim
        if attacker == self then
            local killlines = LambdaVoiceLinesTable.kill
            self:DebugPrint( "killed ", victim )

            if random( 1, 100 ) <= self:GetVoiceChance() then self:PlaySoundFile( killdir:GetString() == "randomengine" and self:GetRandomSound() or self:GetVoiceLine( "kill" ) ) end 

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
        if self:GetIsDead() then return end
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

    local allowrespawn = GetConVar( "lambdaplayers_lambda_allownonadminrespawn" )
    function ENT:OnSpawnedByPlayer( ply )
        local respawn = tobool( ply:GetInfoNum( "lambdaplayers_lambda_shouldrespawn", 0 ) )
        local weapon = ply:GetInfo( "lambdaplayers_lambda_spawnweapon" )
        local voiceprofile = ply:GetInfo( "lambdaplayers_lambda_voiceprofile" )

        self:SetRespawn( ply:IsAdmin() or allowrespawn:GetBool() )
        self:SwitchWeapon( weapon )
        self.l_SpawnWeapon = weapon
        self.l_VoiceProfile = voiceprofile != "" and voiceprofile or self.l_VoiceProfile
        

        self:DebugPrint( "Applied client settings from ", ply )
    end

    -- Fall damage handling
    -- Note that this doesn't always work due to nextbot quirks but that's alright.

    local snds = { "player/pl_fallpain1.wav", "player/pl_fallpain3.wav" }
    local realisticfalldamage = GetConVar( "lambdaplayers_lambda_realisticfalldamage" )
    
    function ENT:OnLandOnGround( ent )
        local damage = 0
        
        if realisticfalldamage:GetBool() then
            damage = max( 0, ceil( 0.3218 * abs( self.l_FallVelocity ) - 153.75 ) )
        elseif abs( self.l_FallVelocity ) > 500 then
            damage = 10
        end

        if damage > 0 then
            local info = DamageInfo()
            info:SetDamage( damage )
            info:SetAttacker( Entity( 0 ) )
            info:SetDamageType( DMG_FALL)

            self:EmitSound( snds[ random( 1, 2 ) ], 65 )

            self:TakeDamageInfo( info )
        end
    end

end


------ SHARED ------

function ENT:OnRemove()
    if SERVER then
        self:RemoveTimers()
        self:CleanSpawnedEntities()
    elseif CLIENT then
        if IsValid( self.l_flashlight ) then
            self.l_flashlight:Remove()
        end
    end
    
end

-- A function for holding self:Hook() functions. Called in the ENT:Initialize() in npc_lambdaplayer
function ENT:InitializeMiniHooks()


    if SERVER then

        -- Hoookay so interesting stuff here. When a nextbot actually dies by reaching 0 or below hp, no matter how high you set their health after the fact, they will no longer take damage.
        -- To get around that we basically predict if the lambda is gonna die and completely block the damage so we don't actually die. This of course is exclusive to Respawning
        self:Hook( "EntityTakeDamage", "DamageHandling", function( target, info )
            if target != self then return end

            if isfunction( self.l_OnDamagefunction ) then self.l_OnDamagefunction( self, self:GetWeaponENT(), info )  end

            local potentialdeath = ( self:Health() - info:GetDamage() ) <= 0
            if self:GetRespawn() and potentialdeath then
                info:SetDamageBonus( 0 )
                info:SetBaseDamage( 0 )
                info:SetDamage( 0 ) -- We need this because apparently the nextbot would think it is dead and do some wacky health issues without it
                self:LambdaOnKilled( info )
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