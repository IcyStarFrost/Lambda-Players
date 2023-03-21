local random = math.random
local tobool = tobool
local ents_GetAll = ents.GetAll
local isfunction = isfunction
local ipairs = ipairs
local bor = bit.bor
local CurTime = CurTime
local max = math.max
local SortTable = table.sort
local ceil = math.ceil
local band = bit.band
local rand = math.Rand
local TraceHull = util.TraceHull
local fallTrTbl = {}
local debugvar = GetConVar( "lambdaplayers_debug" )
local obeynav = GetConVar( "lambdaplayers_lambda_obeynavmeshattributes" )
local callnpchook = GetConVar( "lambdaplayers_lambda_callonnpckilledhook" )
local deathAlways = GetConVar( "lambdaplayers_voice_alwaysplaydeathsnds" )
local respawnTime = GetConVar( "lambdaplayers_lambda_respawntime" )
local respawnSpeech = GetConVar( "lambdaplayers_lambda_dontrespawnifspeaking" )
local retreatLowHP = GetConVar( "lambdaplayers_combat_retreatonlowhealth" )
local serversidecleanup = GetConVar( "lambdaplayers_lambda_serversideragdollcleanuptime" )
local serversidecleanupeffect = GetConVar( "lambdaplayers_lambda_serversideragdollcleanupeffect" )
local cleanupondeath = GetConVar( "lambdaplayers_building_cleanupondeath" )
local flashlightsprite = Material( "sprites/light_glow02_add" )
local flashlightbeam = Material( "effects/lamp_beam" )
local aidisabled = GetConVar( "ai_disabled" )
local faded = Color( 100, 100, 100, 100 )
local serversideragdolls = GetConVar( "lambdaplayers_lambda_serversideragdolls" )

if SERVER then

    -- Due to the issues of Lambda Players not taking damage when they die internally, we have no choice but to recreate them to get around this.
    -- If there is a fix for the damage handling failing to prevent them from actually getting below 0 please make it known so it can be fixed ASAP.
    -- UPDATE: This seems to be fixed by the workaround in gamemode_overrides.lua
    function ENT:OnKilled( info )
        if self.l_internalkilled then return end
        if debugvar:GetBool() then ErrorNoHaltWithStack( "WARNING! ", self:GetLambdaName(), " was killed on a engine level! The entity will be recreated!" ) end
        self:Recreate()
        self.l_internalkilled = true
    end

    function ENT:CreateClientsideRagdoll( info, overrideEnt )
        overrideEnt = overrideEnt or self.l_BecomeRagdollEntity

        local dmgforce, dmgpos = vector_origin, vector_origin
        if info then
            dmgforce = info:GetDamageForce()
            dmgpos = info:GetDamagePosition()
        end

        net.Start( "lambdaplayers_becomeragdoll" )
            net.WriteEntity( self )
            net.WriteVector( self:GetPlyColor() )
            net.WriteVector( dmgforce )
            net.WriteVector( dmgpos )
            net.WriteEntity( overrideEnt )
        net.Broadcast()
    end

    function ENT:CreateServersideRagdoll( info, overrideEnt )
        overrideEnt = overrideEnt or self.l_BecomeRagdollEntity

        local ragdoll = ents.Create( "prop_ragdoll" )
        local visualEnt = ( IsValid( overrideEnt ) and overrideEnt or self )

        ragdoll:SetModel( visualEnt:GetModel() )
        ragdoll:SetPos( visualEnt:GetPos() )
        ragdoll:SetOwner( self )
        ragdoll:AddEffects( EF_BONEMERGE ) -- Pretty much sets up the bones for us
        ragdoll:SetParent( visualEnt )
        ragdoll:Spawn()
        ragdoll:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
        ragdoll.LambdaOwner = self
        self.ragdoll = ragdoll
        ragdoll.IsLambdaSpawned = true

        self:SetNW2Entity( "lambda_serversideragdoll", ragdoll )
    
        ragdoll:SetSkin( visualEnt:GetSkin() )
        for k, v in ipairs( visualEnt:GetBodyGroups() ) do 
            ragdoll:SetBodygroup( v.id, visualEnt:GetBodygroup( v.id ) )
        end

        ragdoll:SetParent()
        ragdoll:RemoveEffects( EF_BONEMERGE )
        
        local vel = visualEnt:GetVelocity()
        for i = 0, ( ragdoll:GetPhysicsObjectCount() - 1 ) do
            local phys = ragdoll:GetPhysicsObjectNum( i )
            if IsValid( phys ) then phys:AddVelocity( vel ) end
        end
    
        if info then ragdoll:TakePhysicsDamage( info ) end

        net.Start( "lambdaplayers_serversideragdollplycolor" )
            net.WriteEntity( ragdoll )
            net.WriteVector( self:GetPlyColor() ) 
        net.Broadcast()

        if serversidecleanup:GetInt() != 0 then 
            local startTime = CurTime()

            LambdaCreateThread( function()
                while ( CurTime() < ( startTime + serversidecleanup:GetInt() ) or IsValid( self ) and self:IsSpeaking() ) do 
                    if !IsValid( ragdoll ) then return end
                    coroutine.yield() 
                end
                
                if !IsValid( ragdoll ) then return end
                if serversidecleanupeffect:GetBool() then
                    net.Start( "lambdaplayers_disintegrationeffect" )
                        net.WriteEntity( ragdoll )
                    net.Broadcast()

                    coroutine.wait( 5 )
                end

                if !IsValid( ragdoll ) then return end
                ragdoll:Remove()
            end ) 
        end

        -- Required for other addons to detect and get Lambda's ragdoll
        if _LambdaGamemodeHooksOverriden then
            hook.Run( "CreateEntityRagdoll", self, ragdoll )
        end

        return ragdoll
    end

    function ENT:LambdaOnKilled( info, silent )
        if self:GetIsDead() then return end
        if LambdaRunHook( "LambdaOnPreKilled", self, info, silent ) == true then return end -- If someone wants to override the default behavior

        local wepent = self.WeaponEnt
        local attacker = info:GetAttacker()
        local inflictor = info:GetInflictor()

        if !silent then
            self:DebugPrint( "was killed by ", attacker )

            self:EmitSound( info:IsDamageType( DMG_FALL ) and "Player.FallGib" or "Player.Death" )
            
            if ( deathAlways:GetBool() or random( 1, 100 ) <= self:GetVoiceChance() ) and !self:GetIsTyping() then
                self:PlaySoundFile( self:GetVoiceLine( "death" ) )
            end

            LambdaKillFeedAdd( self, attacker, inflictor )
            if callnpchook:GetBool() then LambdaRunHook( "OnNPCKilled", self, attacker, inflictor ) end
            self:SetDeaths( self:GetDeaths() + 1 )

            if !serversideragdolls:GetBool() then
                self:CreateClientsideRagdoll( info )
            else
                self:CreateServersideRagdoll( info )
            end

            if self.l_DropWeaponOnDeath and !self:IsWeaponMarkedNodraw() then
                net.Start( "lambdaplayers_createclientsidedroppedweapon" )
                    net.WriteEntity( wepent )
                    net.WriteEntity( self )
                    net.WriteVector( self:GetPhysColor() )
                    net.WriteString( self:GetWeaponName() )
                    net.WriteVector( info:GetDamageForce() )
                    net.WriteVector( info:GetDamagePosition() )
                net.Broadcast()
            end
        end

        self:SetHealth( -1 ) -- SNPCs will think that we are still alive without doing this.
        self:SetIsDead( true )
        self:SetNoClip( false )
        self:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )

        self:ClientSideNoDraw( self, true )
        self:ClientSideNoDraw( wepent, true )
        self:SetNoDraw( true )
        self:DrawShadow( false )
        wepent:SetNoDraw( true )
        wepent:DrawShadow( false )
        self:LookTo( nil )

        self:GetPhysicsObject():EnableCollisions( false )

        -- Restart our coroutine thread
        self:ResetAI()

        -- Stop playing current gesture animation
        self:RemoveGesture( self.l_CurrentPlayedGesture )
        self.l_CurrentPlayedGesture = -1
        self.l_UpdateAnimations = true

        for k, v in ipairs( self.l_Hooks ) do if !v[ 3 ] then self:RemoveHook( v[ 1 ], v[ 2 ] ) end end -- Remove all non preserved hooks
        self:RemoveTimers()
        self:TerminateNonIgnoredDeadTimers()
        self:RemoveFlags( FL_OBJECT )

        self.l_BecomeRagdollEntity = NULL

        LambdaRunHook( "LambdaOnKilled", self, info, silent )
        --hook.Run( "PlayerDeath", self, info:GetInflictor(), info:GetAttacker() )


        self:Thread( function()

            local deathTime = CurTime()
            local canRespawn = self:GetRespawn()

            while ( ( CurTime() - deathTime ) < ( canRespawn and respawnTime:GetFloat() or 0.1 ) or self:GetIsTyping() or self:IsSpeaking() and ( !canRespawn or respawnSpeech:GetBool() ) ) do
                coroutine.yield() 
            end

            if !canRespawn then
                self:Remove()
            else
                self:LambdaRespawn()
            end

        end, "DeathThread", true )


        for k ,v in ipairs( ents_GetAll() ) do
            if IsValid( v ) and v != self and v:IsNextBot() then
                v:OnOtherKilled( self, info )
            end
        end

        if attacker != self and IsValid( attacker ) then 
            if attacker:IsPlayer() then attacker:AddFrags( 1 ) end
            if !self:IsSpeaking() and random( 1, 100 ) <= self:GetTextChance() and self:CanType() and !self.l_preventdefaultspeak then
                self.l_keyentity = attacker

                local deathtype = ( attacker.IsLambdaPlayer or attacker:IsPlayer() ) and "deathbyplayer" or "death"
                local line = self:GetTextLine( deathtype )
                line = LambdaRunHook( "LambdaOnStartTyping", self, line, deathtype ) or line
                self:TypeMessage( line )
            end

            local attackerWepEnt = attacker.WeaponEnt
            if IsValid( attackerWepEnt ) and inflictor == attackerWepEnt then
                local dealDmgFunc = attacker.l_OnDealDamagefunction
                if dealDmgFunc then dealDmgFunc( attacker, attackerWepEnt, self, info, true, true ) end
            end
        end

        if cleanupondeath:GetBool() then
            self:CleanSpawnedEntities()
        end

        local onDeathFunc = self.l_OnDeathfunction
        if isfunction( onDeathFunc ) then onDeathFunc( self, wepent, info ) end
    end

    function ENT:OnInjured( info )
        local attacker = info:GetAttacker()

        if !self:IsPanicking() and attacker != self and random( 1, 2 ) == 1 and LambdaIsValid( attacker ) and retreatLowHP:GetBool() then
            local hpThreshold = ( 100 - self:GetCombatChance() )
            if hpThreshold > 33 then hpThreshold = hpThreshold / random( 2, 4 ) end
            if hpThreshold <= 10 then hpThreshold = hpThreshold * random( 1, 2 ) end

            if self:Health() < hpThreshold then
                self:CancelMovement()
                self:SetEnemy( NULL )
                self:RetreatFrom( attacker )
                return
            end
        end

        if ( self:ShouldTreatAsLPlayer( attacker ) and random( 1, 3 ) == 1 or !self:ShouldTreatAsLPlayer( attacker ) and true ) and self:CanTarget( attacker ) and self:GetEnemy() != attacker and attacker != self and self:CanSee( attacker ) then
            if !self:HasLethalWeapon() then self:SwitchToLethalWeapon() end
            self:AttackTarget( attacker )
        end
    end
    
    function ENT:OnTraceAttack( dmginfo, dir, trace )
        hook.Run( "ScalePlayerDamage", self, trace.HitGroup, dmginfo )
    end

    function ENT:OnOtherKilled( victim, info )
        LambdaRunHook( "LambdaOnOtherKilled", self, victim, info )

        local attacker = info:GetAttacker()

        if self:GetState() != "Combat" and self:IsInRange( victim, 2000 ) and self:CanSee( victim ) then
            local witnessChance = random( 1, 10 )
            if witnessChance == 1 then
                self:LaughAt( victim ) 
            elseif witnessChance == 2 then
                self:LookTo( victimPos, random( 1, 3 ) )
                self:SimpleTimer( rand( 0.1, 1.0 ), function()
                    if self.l_preventdefaultspeak then return end
                    if ( victim:IsPlayer() or victim.IsLambdaPlayer ) and random( 1, 100 ) <= self:GetTextChance() and !self:IsSpeaking() and self:CanType() and !self:InCombat() then
                        self.l_keyentity = victim
                        local line = self:GetTextLine( "witness" )
                        line = LambdaRunHook( "LambdaOnStartTyping", self, line, "witness" ) or line
                        self:TypeMessage( line )
                    elseif self:GetVoiceChance() > 0 then
                        self:PlaySoundFile( self:GetVoiceLine( "witness" ) )
                    end
                end )
            elseif witnessChance == 3 and retreatLowHP:GetBool() then
                self:DebugPrint( "I'm running away, I saw someone die." )
                self:RetreatFrom()
                self:SetEnemy( NULL )
                self:CancelMovement()
            end
        end

        -- If we killed the victim
        if attacker == self then
            local killerActionChance = random( 1, 10 )
            self:DebugPrint( "killed ", victim )
            self:SetFrags( self:GetFrags() + 1 )

            if victim == self:GetEnemy() then

                if random( 1, 100 ) <= self:GetVoiceChance() and !self.l_preventdefaultspeak then
                    self:PlaySoundFile( self:GetVoiceLine( "kill" ) )
                elseif random( 1, 100 ) <= self:GetTextChance() and !self:IsSpeaking() and self:CanType() and !self.l_preventdefaultspeak then
                    self.l_keyentity = victim
                    local line = self:GetTextLine( "kill" )
                    line = LambdaRunHook( "LambdaOnStartTyping", self, line, "kill" ) or line
                    self:TypeMessage( line )
                end

                if killerActionChance == 1 then 
                    self.l_tbagpos = victim:GetPos(); self:SetState( "TBaggingPosition" )
                elseif killerActionChance == 2 and !self:IsSpeaking() and retreatLowHP:GetBool() then
                    self:DebugPrint( "I'm running away, I killed someone." )
                    self:RetreatFrom()
                    self:SetEnemy( NULL )
                    self:CancelMovement()
                end
            end

            if !victim.IsLambdaPlayer then LambdaKillFeedAdd( victim, info:GetAttacker(), info:GetInflictor() ) end
        else -- Someone else killed the victim
            if self:GetState() == "Combat" and victim == self:GetEnemy() and random( 1, 100 ) <= self:GetVoiceChance() and ( attacker:IsPlayer() or attacker:IsNPC() or attacker:IsNextBot() ) and self:CanSee( attacker ) then
                self:LookTo( attacker, 1 )
                self:SimpleTimer( rand( 0.1, 1.0 ), function()
                    if !IsValid( attacker ) or self.l_preventdefaultspeak then return end
                    self:PlaySoundFile( self:GetVoiceLine( "assist" ) )
                end )
            end
        end

        if victim == self:GetEnemy() then
            self:DebugPrint( "Enemy was killed by", attacker )
            self:SetEnemy( NULL )
            self:CancelMovement()
        end
    end

    -- Part of Duplicator Support. See shared/globals.lua for the other part of the duplicator support
    function ENT:PreEntityCopy()
        self.LambdaPlayerPersonalInfo = self:ExportLambdaInfo()
    end

    local NavmeshFunctions = {
        [ NAV_MESH_CROUCH ] = function( self, hasEntered ) 
            self:SetCrouch( hasEntered )
        end,
        [ NAV_MESH_RUN ] = function( self ) 
            self:SetRun( true ) 
        end,
        [ NAV_MESH_WALK ] = function( self, hasEntered ) 
            self:SetSlowWalk( hasEntered ) 
        end,
        [ NAV_MESH_JUMP ] = function( self, hasEntered ) 
            if !hasEntered then return end
            self:LambdaJump() 
        end,
        [ NAV_MESH_STOP ] = function( self, hasEntered )
            if !hasEntered then return end
            self:WaitWhileMoving( rand( 0.66, 1.0 ) )
        end,
        [ NAV_MESH_STAND ] = function( self ) 
            self:SetCrouch( false )
        end
    }

    -- Sets our current nav area
    function ENT:OnNavAreaChanged( old, new ) 
        self.l_currentnavarea = new
        
        local movePos = self.l_CurrentPath
        if movePos == self.l_movepos and self.l_issmoving then
            self:CancelMovement()
            self:MoveToPos( ( isentity( movePos ) and IsValid( movePos ) and movePos:GetPos() or movePos ), self.l_moveoptions )
        end

        if obeynav:GetBool() then
            local newAttributes = new:GetAttributes()
            local oldAttributes = ( IsValid( old ) and old:GetAttributes() )
            for attribute, navFunc in pairs( NavmeshFunctions ) do
                if band( newAttributes, attribute ) != 0 then
                    navFunc( self, true )
                elseif oldAttributes and band( oldAttributes, attribute ) != 0 then
                    navFunc( self, false )
                end
            end
        end
    end

    -- Called when we collide with something
    function ENT:HandleCollision( data )
        if self:GetIsDead() or self:GetNoClip() then return end
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
        elseif collider.CustomOnDoDamage_Direct then -- Makes VJ projectiles able to do direct damages to us.
            local owner = collider:GetOwner()
            local dmgPos = ( data and data.HitPos or collider:GetPos() )

            collider:CustomOnDoDamage_Direct( data, data.HitObject, self )
            
            local damagecode = DamageInfo()
            damagecode:SetDamage( collider.DirectDamage)
            damagecode:SetDamageType( collider.DirectDamageType)
            damagecode:SetDamagePosition(dmgPos)
            damagecode:SetAttacker( ( IsValid( owner ) and owner or collider ) )
            damagecode:SetInflictor( ( IsValid( owner ) and owner or collider ) )
            
            self:TakeDamageInfo( damagecode, collider )
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

    -- Apparently this took me a few hours to come up with this solution to personality presets like this
    local personalitypresets = {
        [ "custom" ] = function( ply, lambda ) -- Custom Personality set by Sliders
            local tbl = {}
            for k, v in ipairs( LambdaPersonalityConVars ) do
                tbl[ v[ 1 ] ] = ply:GetInfoNum( "lambdaplayers_personality_" .. v[ 1 ] .. "chance", 30 )
            end
            lambda:SetVoiceChance( ply:GetInfoNum( "lambdaplayers_personality_voicechance", 30 ) )
            lambda:SetTextChance( ply:GetInfoNum( "lambdaplayers_personality_textchance", 30 ) )
            return  tbl
        end,
        [ "customrandom" ] = function( ply, lambda ) -- Same thing as Custom except the values from Sliders are used in RNG
            local tbl = {}
            for k, v in ipairs( LambdaPersonalityConVars ) do
                tbl[ v[ 1 ] ] = random( ply:GetInfoNum( "lambdaplayers_personality_" .. v[ 1 ] .. "chance", 30 ) )
            end
            lambda:SetVoiceChance( random( 0, ply:GetInfoNum( "lambdaplayers_personality_voicechance", 30 ) ) )
            lambda:SetTextChance( random( 0, ply:GetInfoNum( "lambdaplayers_personality_textchance", 30 ) ) )
            return  tbl
        end,
        [ "fighter" ] = function( ply, lambda ) -- Focused on Combat
            local tbl = {}
            for k, v in ipairs( LambdaPersonalityConVars ) do
                tbl[ v[ 1 ] ] = 0
            end
            tbl[ "Build" ] = 5
            tbl[ "Combat" ] = 80
            tbl[ "Tool" ] = 5
            lambda:SetVoiceChance( 60 )
            lambda:SetTextChance( 60 )
            return tbl
        end,
        [ "builder" ] = function( ply, lambda ) -- Focused on Building
            local tbl = {}
            for k, v in ipairs( LambdaPersonalityConVars ) do
                tbl[ v[ 1 ] ] = random( 1, 100 )
            end
            tbl[ "Build" ] = 80
            tbl[ "Combat" ] = 5
            tbl[ "Tool" ] = 80
            lambda:SetVoiceChance( 60 )
            lambda:SetTextChance( 60 )
            return tbl
        end
    } 

    
    function ENT:OnSpawnedByPlayer( ply )
        local respawn = tobool( ply:GetInfoNum( "lambdaplayers_lambda_shouldrespawn", 0 ) )
        local weapon = ply:GetInfo( "lambdaplayers_lambda_spawnweapon" )
        local voiceprofile = ply:GetInfo( "lambdaplayers_lambda_voiceprofile" )
        local textprofile = ply:GetInfo( "lambdaplayers_lambda_textprofile" )
        local personality = ply:GetInfo( "lambdaplayers_personality_preset" )

        self:SetRespawn( respawn )
        
        self.l_SpawnWeapon = weapon 
        self:SwitchToSpawnWeapon()
        
        self.l_VoiceProfile = voiceprofile != "" and voiceprofile or self.l_VoiceProfile
        self:SetNW2String( "lambda_vp", self.l_VoiceProfile )
        
        self.l_TextProfile = textprofile != "" and textprofile or self.l_TextProfile
        self:SetNW2String( "lambda_tp", self.l_TextProfile )
        
        if personality != "random" then
            self:BuildPersonalityTable( personalitypresets[ personality ]( ply, self ) )

            SortTable( self.l_Personality, function( a, b ) return a[ 2 ] > b[ 2 ] end )
        end
        

        self:DebugPrint( "Applied client settings from ", ply )
    end

    -- Fall damage handling
    -- Note that this doesn't always work due to nextbot quirks but that's alright.

    local realisticfalldamage = GetConVar( "lambdaplayers_lambda_realisticfalldamage" )
    
    function ENT:OnLandOnGround( ent )
        if IsValid( self.l_ladderarea ) or self:IsInNoClip() then return end
        -- Play land animation
        self:AddGesture( ACT_LAND )

        --hook.Run( "OnPlayerHitGround", self, self:GetPos():IsUnderwater(), false, self.l_FallVelocity )
        LambdaRunHook( "LambdaOnLandOnGround", self, ent )

        if !self:GetPos():IsUnderwater() then
            local damage = 0
            local maxsafefallspeed = 526.5 -- sqrt( 2 * gravity * 20 * 12 )

            if realisticfalldamage:GetBool() then
                local fatalfallspeed = 922.5 -- sqrt( 2 * gravity * 60 * 12 ) but right now this will do
                local damageforfall = 100 / (fatalfallspeed - maxsafefallspeed) -- Simulate the same fall damage as players

                damage = (self.l_FallVelocity - maxsafefallspeed) * damageforfall -- If the fall isn't long enough it gives us a negative number and that's fine, we check for higher than 0 anyway. 
            elseif self.l_FallVelocity > maxsafefallspeed then
                damage = 10
            end

            if damage > 0 then
                local info = DamageInfo()
                info:SetDamage( damage )
                info:SetAttacker( Entity( 0 ) )
                info:SetDamageType( DMG_FALL )
                self:TakeDamageInfo( info )

                self:EmitSound( "Player.FallDamage" )
                --hook.Run( "GetFallDamage", self, self.l_FallVelocity )
            end
        end

        if self.l_FallVelocity > 300 then
            self:PlayStepSound( 0.85 )
            self.l_nextfootsteptime = CurTime() + self:GetStepSoundTime()
        end

        self.l_FallVelocity = 0
    end

    function ENT:OnLeaveGround( ent ) 
        LambdaRunHook( "LambdaOnLeaveGround", self, ent )
        
        -- Fall Voiceline Handling
        local selfPos = self:WorldSpaceCenter() 
        local mins, maxs = self:GetCollisionBounds()
        
        fallTrTbl.start = selfPos
        fallTrTbl.endpos = ( selfPos - vector_up * 32756 )
        fallTrTbl.filter = self
        fallTrTbl.mins = mins
        fallTrTbl.maxs = maxs
        local fallTr = TraceHull( fallTrTbl )
        
        local hitPos = fallTr.HitPos
        if hitPos:IsUnderwater() then return end

        local deathDist = 800
        if realisticfalldamage:GetBool() then deathDist = max( 256, 800 * ( self:Health() / self:GetMaxHealth() ) ) end
        if hitPos:DistToSqr( selfPos ) < ( deathDist * deathDist ) then return end

        if !self.l_preventdefaultspeak then
            self:PlaySoundFile( self:GetVoiceLine( "fall" ) )
        end
    end

    function ENT:OnBeginTyping( text )
        self:AddGesture( ACT_GMOD_IN_CHAT, false )
    end

    function ENT:OnEndMessage( text )
        self:RemoveGesture( ACT_GMOD_IN_CHAT )
    end

end

------ SHARED ------

function ENT:OnRemove()
    LambdaRunHook( "LambdaOnRemove", self )

    if ( SERVER ) then
        self:RemoveTimers()
        self:CleanSpawnedEntities()
    end

    if ( CLIENT ) then
        local flashlight = self.l_flashlight
        if IsValid( flashlight ) then flashlight:Remove() end
    end
end

-- A function for holding self:Hook() functions. Called in the ENT:Initialize() in npc_lambdaplayer
function ENT:InitializeMiniHooks()
    if ( SERVER ) then

        self:Hook( "PostEntityTakeDamage", "OnOtherInjured", function( target, info, tookdamage )
            if target == self or ( !target:IsNPC() and !target:IsNextBot() and !target:IsPlayer() ) then return end
            LambdaRunHook( "LambdaOnOtherInjured", self, target, info, tookdamage )

            local wepent = self:GetWeaponENT()
            local inflictor = info:GetInflictor()
            local dealDmgFunc = self.l_OnDealDamagefunction
            if info:GetAttacker() == self and inflictor == wepent and isfunction( dealDmgFunc ) then
                local killed = ( tookdamage and ( ( target.IsLambdaPlayer or target:IsPlayer() ) and !target:Alive() or target:Health() <= 0 ) )
                dealDmgFunc( self, wepent, target, info, tookdamage, killed )
            end
        end, true )

        -- Hoookay so interesting stuff here. When a nextbot actually dies by reaching 0 or below hp, no matter how high you set their health after the fact, they will no longer take damage.
        -- To get around that we basically predict if the Lambda is gonna die and completely block the damage so we don't actually die. This of course is exclusive to Respawning
        self:Hook( "LambdaTakeDamage", "DamageHandling", function( target, info )
            if target != self then return end
            if self.l_godmode then return true end

            local result = LambdaRunHook( "LambdaOnInjured", self, info )
            if result == true then return true end

            -- Armor Damage Reduction
            local curArmor = self:GetArmor()
            if curArmor > 0 and !info:IsDamageType( bor( DMG_DROWN, DMG_POISON, DMG_FALL, DMG_RADIATION ) ) then
                local flDmg = info:GetDamage()
                local flNew = flDmg * 0.2
                local flArmor = max( ( flDmg - flNew ), 1 )

                if flArmor > curArmor then
                    flArmor = curArmor
                    flNew = ( flDmg - flArmor )
                    self:SetArmor( 0 )
                else
                    self:SetArmor( curArmor - flArmor )
                end

                flDmg = flNew
                info:SetDamage( flDmg )
            end

            -- Fixes Lambda-launched Combine Balls not setting its damage's attacker properly
            local attacker = info:GetAttacker()
            if IsValid( attacker ) and attacker:GetClass() == "prop_combine_ball" then
                local owner = attacker:GetOwner()
                if IsValid( owner ) and owner.IsLambdaPlayer then info:SetAttacker( owner ) end
            end

            local onDmgFunc = self.l_OnDamagefunction
            if isfunction( onDmgFunc ) and onDmgFunc( self, self:GetWeaponENT(), info ) == true then return true end

            local potentialdeath = ( self:Health() - ceil( info:GetDamage() ) ) <= 0
            if potentialdeath then
                info:SetDamageBonus( 0 )
                info:SetBaseDamage( 0 )
                info:SetDamage( 0 ) -- We need this because apparently the nextbot would think it is dead and do some wacky health issues without it
                self:LambdaOnKilled( info )
                return true
            end
        
            self:SimpleTimer( 0, function() self:UpdateHealthDisplay() end, true )
        end, true )

        self:Hook( "OnEntityCreated", "NPCRelationshipHandle", function( ent )
            self:SimpleTimer( 0, function() 
                if IsValid( ent ) and ent:IsNPC() then self:HandleNPCRelations( ent ) end
            end )
        end, true )

        self:Hook( "PhysgunPickup", "Physgunpickup", function( ply, ent )
            if ent == self then self.l_ispickedupbyphysgun = true end
        end, true )

        self:Hook( "PhysgunDrop", "Physgundrop", function( ply, ent )
            if ent == self then self.l_ispickedupbyphysgun = false end
        end, true )

        self:Hook( "LambdaPlayerSay", "lambdatextchat", function( ply, text )
            if aidisabled:GetBool() then return end
            if ply == self or self:IsDisabled() or self.l_preventdefaultspeak then return end

            if random( 1, 200 ) < self:GetTextChance() and !self:GetIsTyping() and !self:IsSpeaking() and self:CanType() then
                self.l_keyentity = ply
                local line = self:GetTextLine( "response" )
                line = LambdaRunHook( "LambdaOnStartTyping", self, line, "response" ) or line
                self:TypeMessage( line )
            end
        end, true )

        self:Hook( "PlayerSay", "lambdarespondtoplayertextchat", function( ply, text )
            if aidisabled:GetBool() then return end
            if self:IsSpeaking() or self.l_preventdefaultspeak then return end

            if random( 1, 100 ) <= self:GetVoiceChance() and self:IsInRange( ply, 300 ) then
                self:PlaySoundFile( self:GetVoiceLine( "idle" ) )
            elseif random( 1, 100 ) <= self:GetTextChance() and self:CanType() and !self:InCombat() and !self:IsPanicking() then
                self.l_keyentity = ply
                local line = self:GetTextLine( "response" )
                line = LambdaRunHook( "LambdaOnStartTyping", self, line, "response" ) or line
                self:TypeMessage( line )
            end
        end, true )

        self:Hook( "LambdaOnRealPlayerEndVoice", "lambdarespondtoplayervoicechat", function( ply )
            if aidisabled:GetBool() then return end
            if self:IsSpeaking() or !self:IsInRange( ply, 300 ) or self.l_preventdefaultspeak then return end
            
            if random( 1, 100 ) <= self:GetVoiceChance() then
                self:PlaySoundFile( self:GetVoiceLine( "idle" ) )
            elseif random( 1, 100 ) <= self:GetTextChance() and self:CanType() and !self:InCombat() and !self:IsPanicking() then
                self.l_keyentity = ply
                local line = self:GetTextLine( "response" )
                line = LambdaRunHook( "LambdaOnStartTyping", self, line, "response" ) or line
                self:TypeMessage( line )
            end
        end, true )

    end

    if ( CLIENT ) then

        self:Hook( "PreDrawEffects", "CustomWeaponRenderEffects", function()
            if self:GetIsDead() or !self:IsBeingDrawn() or !self:GetHasCustomDrawFunction() then return end
            local func = _LAMBDAPLAYERSWEAPONS[ self:GetWeaponName() ].Draw or _LAMBDAPLAYERSWEAPONS[ self:GetWeaponName() ].OnDraw
            if func then func( self, self:GetWeaponENT() ) end
        end, true )


        local DrawSprite = render.DrawSprite
        local SetMaterial = render.SetMaterial
        local color_white = color_white
        self:Hook( "PreDrawEffects", "flashlighteffects", function()
            if self:GetIsDead() or !self:IsBeingDrawn() then return end

            if self.l_flashlighton then
                local hand = self:GetAttachmentPoint( "hand" )
                local start = hand.Pos + hand.Ang:Forward() * 3
                local endpos = hand.Pos + hand.Ang:Forward() * 150

                SetMaterial( flashlightsprite )
                DrawSprite(start, 4, 4, color_white )

                SetMaterial( flashlightbeam )
                
                render.DrawBeam( start, endpos, 40, 0, 0.9, faded )
            end

        end, true )

    end

end
