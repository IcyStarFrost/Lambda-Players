local random = math.random
local tobool = tobool
local ents_GetAll = ents.GetAll
local ents_Create = ents.Create
local isfunction = isfunction
local ipairs = ipairs
local pairs = pairs
local hook_Remove = hook.Remove
local bor = bit.bor
local CurTime = CurTime
local coroutine_yield = coroutine.yield
local coroutine_wait = coroutine.wait
local max = math.max
local floor = math.floor
local string_match = string.match
local SortTable = table.sort
local IsSinglePlayer = game.SinglePlayer
local SimpleTimer = timer.Simple
local FrameTime = FrameTime
local ceil = math.ceil
local band = bit.band
local rand = math.Rand
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
local faded = Color( 80, 80, 80, 80 )
local serversideragdolls = GetConVar( "lambdaplayers_lambda_serversideragdolls" )
local dropweaponents = GetConVar( "lambdaplayers_allowweaponentdrop" )
local typeNameRespond = GetConVar( "lambdaplayers_text_typenameonrespond" )

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

    -- Creates a clientside ragdoll with our look
    function ENT:CreateClientsideRagdoll( info, overrideEnt )
        overrideEnt = overrideEnt or self.l_BecomeRagdollEntity

        local dmgforce, dmgpos, forceScale = vector_origin, vector_origin, 3
        if info then
            dmgforce = info:GetDamageForce()
            dmgpos = info:GetDamagePosition()

            local attacker = info:GetAttacker()
            local inflictor = info:GetInflictor()
            if IsValid( attacker ) and attacker:GetClass() == "trigger_hurt" then
                forceScale = 8
            elseif IsValid( inflictor ) and inflictor:GetClass() == "crossbow_bolt" then
                forceScale = 8
            elseif info:IsExplosionDamage() then
                forceScale = 75
            end
        end

        net.Start( "lambdaplayers_becomeragdoll" )
            net.WriteEntity( self )
            net.WriteEntity( overrideEnt )
            net.WriteVector( self:WorldSpaceCenter() )
            net.WriteVector( dmgpos )
            net.WriteVector( dmgforce )
            net.WriteUInt( forceScale, 7 )
            net.WriteVector( self:GetPlyColor() )
        net.Broadcast()
    end

    -- Creates a serverside ragdoll with our look
    function ENT:CreateServersideRagdoll( info, overrideEnt, dontRemove )
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
        
        ragdoll.GS2Player = self -- Fixes black player color when GibSplat'd
        ragdoll.LambdaOwner = self
        self.ragdoll = ragdoll
        ragdoll.IsLambdaSpawned = true

        self:SetNW2Entity( "lambda_serversideragdoll", ragdoll )
    
        ragdoll:SetSkin( visualEnt:GetSkin() )
        for k, v in ipairs( visualEnt:GetBodyGroups() ) do 
            ragdoll:SetBodygroup( v.id, visualEnt:GetBodygroup( v.id ) )
        end

        ragdoll:SetParent( NULL )
        ragdoll:RemoveEffects( EF_BONEMERGE )
        
        local vel = visualEnt:GetVelocity()
        local dmgPos, dmgForce, forceScale
        if info then 
            dmgPos = info:GetDamagePosition()
            dmgForce = info:GetDamageForce()
            
            local attacker = info:GetAttacker()
            if IsValid( attacker ) and attacker:GetClass() == "trigger_hurt" then
                forceScale = 0.25
            elseif info:IsExplosionDamage() then
                forceScale = 9
            else
                forceScale = 3
            end
        end
        for i = 0, ( ragdoll:GetPhysicsObjectCount() - 1 ) do
            local phys = ragdoll:GetPhysicsObjectNum( i )
            if !IsValid( phys ) then continue end

            phys:AddVelocity( vel )
            if info then
                local distDiff = ( phys:GetPos():Distance( dmgPos ) / forceScale )
                phys:ApplyForceOffset( dmgForce / distDiff, dmgPos )
            end
        end
    
        if info and info:IsDamageType( DMG_DISSOLVE ) then
            local dissolver = ents_Create( "env_entity_dissolver" )
            dissolver:SetKeyValue( "target", "!activator" )
            dissolver:Input( "dissolve", ragdoll )
            dissolver:Remove()
        end

        -- Fixes playercolor not being assigned in multiplayer
        if IsSinglePlayer() then
            net.Start( "lambdaplayers_serversideragdollplycolor" )
                net.WriteEntity( ragdoll )
                net.WriteVector( self:GetPlyColor() ) 
            net.Broadcast()
        else
            SimpleTimer( FrameTime() * 2, function()
                if !IsValid( ragdoll ) then return end

                net.Start( "lambdaplayers_serversideragdollplycolor" )
                    net.WriteEntity( ragdoll )
                    net.WriteVector( self:GetPlyColor() ) 
                net.Broadcast()
            end )
        end

        if !dontRemove then
            local startTime = CurTime()
            LambdaCreateThread( function()
                while ( serversidecleanup:GetInt() == 0 or CurTime() < ( startTime + serversidecleanup:GetInt() ) or IsValid( self ) and self:IsSpeaking() ) do 
                    if !IsValid( ragdoll ) then return end
                    coroutine_yield() 
                end
                
                if !IsValid( ragdoll ) then return end
                if serversidecleanupeffect:GetBool() then
                    net.Start( "lambdaplayers_disintegrationeffect" )
                        net.WriteEntity( ragdoll )
                    net.Broadcast()

                    coroutine_wait( 5 )
                end

                if !IsValid( ragdoll ) then return end
                ragdoll:Remove()
            end ) 

            -- Required for other addons to detect and get Lambda's ragdoll
            if _LambdaGamemodeHooksOverriden then
                hook.Run( "CreateEntityRagdoll", self, ragdoll )
            end
        end

        return ragdoll
    end

    -- Creates a prop with our weapon's model and drops it
    function ENT:DropWeapon( dmginfo )
        if !self.l_DropWeaponOnDeath or self:IsWeaponMarkedNodraw() then return end
        local wepent = self.WeaponEnt

        local dropEnt = self.l_WeaponDropEntity
        if !dropEnt or !dropweaponents:GetBool() then
            net.Start( "lambdaplayers_createclientsidedroppedweapon" )
                net.WriteEntity( wepent )
                net.WriteString( wepent:GetModel() )
                net.WriteVector( wepent:GetPos() )
                net.WriteUInt( wepent:GetSkin(), 5 )
                net.WriteString( wepent:GetSubMaterial( 1 ) )
                net.WriteFloat( wepent:GetModelScale() )
                net.WriteVector( self:GetPhysColor() )
                net.WriteEntity( self )
                net.WriteString( self:GetWeaponName() )
                net.WriteVector( dmginfo and dmginfo:GetDamageForce() or vector_origin )
                net.WriteVector( dmginfo and dmginfo:GetDamagePosition() or wepent:GetPos() )
            net.Broadcast()
        else
            dropEnt = ents_Create( dropEnt )
            
            if IsValid( dropEnt ) then
                dropEnt:SetPos( wepent:GetPos() )
                dropEnt:SetAngles( wepent:GetAngles() )
                dropEnt:Spawn()

                dropEnt:SetSubMaterial( 1, wepent:GetSubMaterial( 1 ) )
                dropEnt:SetNW2Vector( "lambda_weaponcolor", self:GetPhysColor() )

                dropEnt.LambdaOwner = self
                dropEnt.IsLambdaSpawned = true

                if dmginfo then
                    local phys = dropEnt:GetPhysicsObject()
                    if IsValid( phys ) then
                        local force = ( dmginfo:GetDamageForce() / 7 )
                        phys:ApplyForceOffset( force, dmginfo:GetDamagePosition() )
                    end
                end

                self.weapondrop = dropEnt
                local wpnData = _LAMBDAPLAYERSWEAPONS[ self:GetWeaponName() ]
                if wpnData then
                    local dropFunc = wpnData.OnDrop
                    if isfunction( dropFunc ) then dropFunc( lambda, wepent, dropEnt ) end
                end

                local startTime = CurTime()
                LambdaCreateThread( function()
                    while ( serversidecleanup:GetInt() == 0 or CurTime() < ( startTime + serversidecleanup:GetInt() ) or IsValid( self ) and self:IsSpeaking() ) do 
                        if !IsValid( dropEnt ) or dropEnt:GetOwner() != self then return end
                        coroutine_yield() 
                    end
                    if !IsValid( dropEnt ) then return end

                    if serversidecleanupeffect:GetBool() then
                        net.Start( "lambdaplayers_disintegrationeffect" )
                            net.WriteEntity( dropEnt )
                        net.Broadcast()

                        coroutine_wait( 5 )
                    end

                    if !IsValid( dropEnt ) then return end
                    dropEnt:Remove()
                end ) 
            end
        end
    end

    function ENT:LambdaOnKilled( info, silent )
        if self:GetIsDead() then return end
        if LambdaRunHook( "LambdaOnPreKilled", self, info, silent ) == true then return end -- If someone wants to override the default behavior

        local wepent = self.WeaponEnt
        local attacker = info:GetAttacker()
        local inflictor = info:GetInflictor()

        if !silent then
            self:DebugPrint( "I was killed by", attacker )

            self:EmitSound( info:IsDamageType( DMG_FALL ) and "Player.FallGib" or "Player.Death" )
            
            if ( !self.l_killbinded and deathAlways:GetBool() or random( 100 ) <= self:GetVoiceChance() ) and !self:GetIsTyping() then
                self:PlaySoundFile( self.l_killbinded and "laugh" or "death" )
            else
                self:StopCurrentVoiceLine()
            end

            LambdaKillFeedAdd( self, attacker, inflictor )
            if callnpchook:GetBool() then LambdaRunHook( "OnNPCKilled", self, attacker, inflictor ) end

            self:SetDeaths( self:GetDeaths() + 1 )
            if attacker == self then self:SetFrags( self:GetFrags() - 1 ) end

            if !serversideragdolls:GetBool() and !info:IsDamageType( DMG_DISSOLVE ) then
                self:CreateClientsideRagdoll( info )
            else
                self:CreateServersideRagdoll( info )
            end

            self:DropWeapon()
        end

        -- Remove all non-preserved hooks
        for eventName, hooks in pairs( self.l_Hooks ) do
            for hookName, hookTbl in pairs( hooks ) do
                if hookTbl[ 2 ] == true then continue end
                hooks[ hookName ] = nil
                hook_Remove( hookName, hookTbl[ 1 ] )
            end
        end

        self:SetHealth( -1 ) -- SNPCs will think that we are still alive without doing this.
        self:SetIsDead( true )
        self:SetNoClip( false )
        self:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
        
        self:SetNoTarget( true )
        self:RemoveFlags( FL_CLIENT )

        self:ClientSideNoDraw( self, true )
        self:ClientSideNoDraw( wepent, true )
        self:SetNoDraw( true )
        self:DrawShadow( false )
        wepent:SetNoDraw( true )
        wepent:DrawShadow( false )
        self:LookTo( nil )

        self:GetPhysicsObject():EnableCollisions( false )

        -- Reset our state to Idle and restart the coroutine thread
        self:SetState( "Idle" )
        self:ResetAI()

        -- Stop playing all gesture animations
        self:RemoveAllGestures()
        self.l_UpdateAnimations = true 

        self:RemoveTimers()
        self:TerminateNonIgnoredDeadTimers()

        self.l_BecomeRagdollEntity = NULL
        self.l_DrownStartTime = false
        self.l_DrownLostHealth = 0
        self.l_DrownActionTime = 0

        info:SetDamage( self.l_PreDeathDamage )
        LambdaRunHook( "LambdaOnKilled", self, info, silent )
        --hook.Run( "PlayerDeath", self, info:GetInflictor(), info:GetAttacker() )

        local onDeathFunc = self.l_OnDeathfunction
        if isfunction( onDeathFunc ) then onDeathFunc( self, wepent, info ) end
        self:SwitchWeapon( "none", true )

        local deathTime = CurTime()
        local spawnCheckTime = deathTime
        local canRespawn = self:GetRespawn()
        self:Thread( function()
            while ( ( CurTime() - deathTime ) < ( canRespawn and respawnTime:GetFloat() or 0.1 ) or self:GetIsTyping() or self:IsSpeaking( "death" ) and ( !canRespawn or respawnSpeech:GetBool() ) ) or CurTime() < spawnCheckTime do
                if CurTime() >= spawnCheckTime then
                    spawnCheckTime = ( CurTime() + ( random( 0, 10 ) * 0.1 ) )
                end

                coroutine_yield() 
            end

            if !canRespawn then
                self:Remove()
            else
                self:LambdaRespawn()
            end
        end, "DeathThread", true )

        for _, npc in ipairs( ents_GetAll() ) do
            if npc == self or !IsValid( npc ) then continue end
            
            if npc:IsNPC() then 
                if npc:GetEnemy() == self then
                    npc:SetEnemy( NULL )
                end
                
                npc:ClearEnemyMemory( self )
            elseif npc:IsNextBot() then
                npc:OnOtherKilled( self, info )
                if npc.IsLambdaPlayer then 
                    LambdaRunHook( "LambdaOnOtherInjured", npc, self, info, true ) 
                end

                -- Keep them comin'!
                if npc.IsUltrakillNextbot and npc.RestartVoiceLine then
                    npc.PreviouslyKilled[ self:EntIndex() ] = true
                end
            end
        end

        if attacker != self and IsValid( attacker ) then 
            if attacker:IsPlayer() then 
                attacker:AddFrags( 1 ) 
            end

            if !self.l_preventdefaultspeak and random( 100 ) <= self:GetTextChance() and !self:IsSpeaking() and self:CanType() then
                self.l_keyentity = attacker

                local deathtype = ( ( attacker.IsLambdaPlayer or attacker:IsPlayer() ) and "deathbyplayer" or "death" )
                self:TypeMessage( self:GetTextLine( deathtype ) )
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
        
        net.Start( "lambdaplayers_updatecsstatus" )
            net.WriteEntity( self )
            net.WriteBool( true )
            net.WriteInt( self:GetFrags(), 11 )
            net.WriteInt( self:GetDeaths(), 11 )
        net.Broadcast()
    end

    function ENT:OnInjured( info )
        local attacker = info:GetAttacker()
        
        if retreatLowHP:GetBool() and !self:IsPanicking() and ( attacker != self and IsValid( attacker ) or self:InCombat() and ( attacker != self:GetEnemy() or !attacker.IsLambdaPlayer or !attacker:IsPanicking() or random( 1, 3 ) == 1 ) ) then
            local chance = ( 100 - self:GetCombatChance() )
            if chance <= 20 then
                chance = ( chance * rand( 1.0, 2.5 ) )
            elseif chance > 60 then
                chance = ( chance / rand( 1.5, 2.5 ) )
            end

            local hpThreshold = random( ( chance / 4 ), chance )
            local predHp = ( self:Health() - ( info:GetDamage() * rand( 1.0, 1.5 ) ) )
            if predHp <= hpThreshold then 
                self:RetreatFrom( attacker != self and attacker ) 
                return 
            end
        end

        local ene = self:GetEnemy()
        if attacker != self and attacker != ene and IsValid( attacker ) and ( !self:ShouldTreatAsLPlayer( attacker ) or random( 2 ) == 1 ) and ( !IsValid( ene ) or self:GetRangeSquaredTo( attacker ) < self:GetRangeSquaredTo( ene ) ) and self:CanTarget( attacker ) then
            self:AttackTarget( attacker )
        end
    end
    
    function ENT:OnTraceAttack( dmginfo, dir, trace )
        local hitGroup = trace.HitGroup
        self.l_lasthitgroup = hitGroup

        local maxDmg = dmginfo:GetMaxDamage()
        self.l_lastdamage = ( maxDmg != 0 and maxDmg or nil )
        
        hook.Run( "ScaleNPCDamage", self, hitGroup, dmginfo )
    end

    -- Called when someone gets killed
    function ENT:OnOtherKilled( victim, info )
        local preventDefActs = LambdaRunHook( "LambdaOnOtherKilled", self, victim, info )

        local attacker = info:GetAttacker()
        local inflictor = info:GetInflictor()
        if attacker == self then
            self:DebugPrint( "I killed", victim )
            self:SetFrags( self:GetFrags() + 1 )

            if !victim.IsLambdaPlayer then LambdaKillFeedAdd( victim, attacker, inflictor ) end
        end

        local enemy = self:GetEnemy()
        if victim == enemy then
            self:DebugPrint( "My enemy was killed by", attacker )
            self:SetEnemy( NULL )
            self:CancelMovement()

            self.l_nextnpccheck = 0 -- Search for the next enemy NPC immediately
        end

        if preventDefActs == true then return end
        
        if attacker == self then
            local killerActionChance = random( 10 )

            if victim == enemy then
                if !self.l_preventdefaultspeak then
                    if random( 100 ) <= self:GetVoiceChance() then
                        self:PlaySoundFile( "kill" )
                    elseif random( 100 ) <= self:GetTextChance() and !self:IsSpeaking() and self:CanType() then
                        self.l_keyentity = victim
                        self:TypeMessage( self:GetTextLine( "kill" ) )
                    end
                end

                if killerActionChance == 1 then 
                    self:SetState( "TBaggingPosition", victim:GetPos() )
                    self:DebugPrint( "I killed my enemy. It's t-bagging time..." )
                    return
                end
            end

            if killerActionChance == 10 and retreatLowHP:GetBool() then
                self:DebugPrint( "I killed someone. Retreating..." )
                self:RetreatFrom()
                self:CancelMovement()
                return
            end
        elseif victim == enemy and !self.l_preventdefaultspeak and random( 100 ) <= self:GetVoiceChance() and ( attacker:IsPlayer() or attacker:IsNPC() or attacker:IsNextBot() ) then
            if self:CanSee( attacker ) then
                self:LookTo( attacker, 1 )
            end
            self:PlaySoundFile( "assist", rand( 0.1, 1.0 ) )
        end

        if self:IsInRange( victim, 1500 ) and self:CanSee( victim ) then
            local witnessChance = random( 10 )
            if witnessChance == 1 or ( attacker == victim or attacker:IsWorld() ) and witnessChance >= 6 then
                self:SetState( "Laughing", { victim, self.l_movepos } )
                self:CancelMovement() 
                self:DebugPrint( "I killed or saw someone die. Laugh at this man!" )
            elseif attacker != self and victim != enemy then
                if witnessChance == 2 and !self.l_preventdefaultspeak then
                    self:LookTo( victimPos, random( 3 ) )
                    
                    if random( 100 ) <= self:GetVoiceChance() then
                        self:PlaySoundFile( "witness", rand( 0.1, 1.0 ) )
                    elseif random( 100 ) <= self:GetTextChance() and ( victim.IsLambdaPlayer or victim:IsPlayer() ) and !self:IsSpeaking() and self:CanType() then
                        self.l_keyentity = victim
                        self:TypeMessage( self:GetTextLine( "witness" ) )
                    end
                elseif witnessChance == 10 and !self:InCombat() and retreatLowHP:GetBool() then
                    self:DebugPrint( "I saw someone die. Retreating..." )
                    self:RetreatFrom( ( self:CanTarget( attacker ) and self:CanSee( attacker ) and random( 3 ) == 1 and attacker or nil ) )
                    self:CancelMovement()
                end
            end
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
        [ NAV_MESH_PRECISE ] = function( self, hasEntered ) 
            self:SetRun( self.l_moveoptions and self.l_moveoptions.run and !hasEntered ) 
        end,
        [ NAV_MESH_WALK ] = function( self, hasEntered ) 
            self:SetSlowWalk( hasEntered or self.l_moveoptions and self.l_moveoptions.walk ) 
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

    -- Called when our current nav area is changed
    function ENT:OnNavAreaChanged( old, new ) 
        self.l_currentnavarea = new
        
        local movePos = self.l_CurrentPath
        if movePos == self.l_movepos and self.l_issmoving then
            self:CancelMovement()
            self:MoveToPos( ( isentity( movePos ) and IsValid( movePos ) and movePos:GetPos() or movePos ), self.l_moveoptions )
        end

        if obeynav:GetBool() then
            local newAttributes = new:GetAttributes()
            local oldAttributes = ( IsValid( old ) and old:GetAttributes() or 0 )
            if newAttributes == 0 and oldAttributes == 0 then return end

            for attribute, navFunc in pairs( NavmeshFunctions ) do
                if band( newAttributes, attribute ) != 0 then
                    navFunc( self, true )
                elseif oldAttributes and band( oldAttributes, attribute ) != 0 then
                    navFunc( self, false )
                end
            end
        end
    end

    -- Called when our physics object collides with something
    function ENT:HandleCollision( data )
        if !self:Alive() or self:GetNoClip() then return end
        
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
        elseif ( CurTime() - self.l_LastPhysDmgTime ) > 0.1 then
            local mass = ( data.HitObject:GetMass() or 500 )
            local hitVel = data.TheirOldVelocity
            
            local impactDmg = ( mass * ( hitVel:Length() / 1000 ) )
            if impactDmg < 5 then return end
            impactDmg = ( floor( impactDmg / 5 ) * 5 )

            local dmginfo = DamageInfo()
            dmginfo:SetInflictor( collider )
            dmginfo:SetDamage( impactDmg )
            dmginfo:SetDamageForce( hitVel * impactDmg / 7.5 )

            local collAttacker = collider:GetPhysicsAttacker()
            if collider:IsVehicle() and IsValid( collider:GetDriver() ) then
                dmginfo:SetAttacker( collider:GetDriver() )
                dmginfo:SetDamageType( DMG_VEHICLE )     
            else
                dmginfo:SetDamageType( DMG_CRUSH )
                if IsValid( collAttacker ) then
                    dmginfo:SetAttacker( collAttacker )
                else
                    dmginfo:SetAttacker( collider )
                end
            end
            
            self.loco:SetVelocity( self.loco:GetVelocity() + hitVel )
            self:TakeDamageInfo( dmginfo )
            self.l_LastPhysDmgTime = CurTime()
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
                tbl[ v[ 1 ] ] = random( 100 )
            end
            tbl[ "Build" ] = 80
            tbl[ "Combat" ] = 5
            tbl[ "Tool" ] = 80
            lambda:SetVoiceChance( 60 )
            lambda:SetTextChance( 60 )
            return tbl
        end
    } 

    -- When we are spawned by a player
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

        self:DebugPrint( "Applied client settings from", ply )
    end

    -- Fall damage handling
    -- Note that this doesn't always work due to nextbot quirks but that's alright.
    function ENT:OnLandOnGround( ent )
        if !self.l_initialized or self:IsUsingLadder() or self:IsInNoClip() then return end
        
        --hook.Run( "OnPlayerHitGround", self, self:GetPos():IsUnderwater(), false, self.l_FallVelocity )
        if LambdaRunHook( "LambdaOnLandOnGround", self, ent ) != true then
            -- Play land animation
            local landSeq = self:LookupSequence( "jump_land" )
            if landSeq > 0 then
                self:AddGestureSequence( landSeq )
            else
                self:AddGesture( ACT_LAND )
            end

            local fallSpeed = self.l_FallVelocity
            if !self:GetPos():IsUnderwater() then
                local damage = self:GetFallDamage( fallSpeed )
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

            if DSteps and fallSpeed > 150 then
                self.DStep_HitGround = speed
                DSteps( self, self:GetPos(), 0, "" )
            else
                self.DStep_HitGround = nil

                if fallSpeed > 300 then
                    self:PlayStepSound( 0.85 )
                    self.l_nextfootsteptime = CurTime() + self:GetStepSoundTime()
                end
            end
        end

        if self:IsSpeaking( "fall" ) and !self:IsPanicking() then
            self:StopCurrentVoiceLine()
        end

        local moveOpt = self.l_moveoptions
        if moveOpt and !moveOpt.update then
            self:RecomputePath()
        end

        self.l_FallVelocity = 0
    end

    function ENT:OnLeaveGround( ent ) 
        LambdaRunHook( "LambdaOnLeaveGround", self, ent )
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
        
        if self:Alive() then
            self:RemoveFlags( FL_CLIENT )

            local wepData = _LAMBDAPLAYERSWEAPONS[ self.l_Weapon ]
            if wepData then 
                local onHolsterFunc = ( wepData.OnHolster or wepData.OnUnequip )
                if onHolsterFunc then onHolsterFunc( self, self:GetWeaponENT() ) end
            end
        end
    end

    if ( CLIENT ) then
        local flashlight = self.l_flashlight
        if IsValid( flashlight ) then flashlight:Remove() end

        hook.Run( "PlayerEndVoice", self ) 
    end
end

-- A function for holding self:Hook() functions. Called in the ENT:Initialize() in npc_lambdaplayer
function ENT:InitializeMiniHooks()
    if ( SERVER ) then
        self:Hook( "PostEntityTakeDamage", "OnOtherInjured", function( target, info, tookdamage )
            if target == self or ( !target:IsNPC() and !target:IsNextBot() and !target:IsPlayer() ) then return end
            LambdaRunHook( "LambdaOnOtherInjured", self, target, info, tookdamage )

            -- VJ Base's 'Become enemy to a friendly player' feature
            local attacker = info:GetAttacker()
            if attacker == self and target.IsVJBaseSNPC and !target.VJ_IsBeingControlled and target:CheckRelationship( self ) == D_LI then
                local curAnger = ( target.AngerLevelTowardsPlayer + 1 )
                target.AngerLevelTowardsPlayer = curAnger

                if curAnger > target.BecomeEnemyToPlayerLevel then
                    if target:Disposition( self ) != D_HT then
						target:CustomOnBecomeEnemyToPlayer( info, target:GetLastDamageHitGroup() )
                        if target.IsFollowing && target.FollowData.Ent == self then 
                            target:FollowReset() 
                        end

                        target.VJ_AddCertainEntityAsEnemy[ #target.VJ_AddCertainEntityAsEnemy + 1 ] = self
						target:AddEntityRelationship( self, D_HT, 2 )
						target.TakingCoverT = ( CurTime() + 2 )
						target:PlaySoundSystem( "BecomeEnemyToPlayer" )

                        if !IsValid( target:GetEnemy() ) then
							target:StopMoving()
							target:SetTarget( self )
							target:VJ_TASK_FACE_X( "TASK_FACE_TARGET" )
						end
                    end

                    target.Alerted = true
					target:SetNPCState( NPC_STATE_ALERT )
                end
            end

            local wepent = self:GetWeaponENT()
            local inflictor = info:GetInflictor()
            local dealDmgFunc = self.l_OnDealDamagefunction
            if attacker == self and inflictor == wepent and isfunction( dealDmgFunc ) then
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

            local dmg = info:GetDamage()
            local potentialdeath =  ( self:Health() - ceil( dmg ) ) <= 0
            if potentialdeath then
                info:SetDamageBonus( 0 )
                info:SetBaseDamage( 0 )

                self.l_PreDeathDamage = dmg
                info:SetDamage( 0 ) -- We need this because apparently the nextbot would think it is dead and do some wacky health issues without it
                
                self:LambdaOnKilled( info )
                return true
            end
        
            self:SimpleTimer( 0, function() self:UpdateHealthDisplay() end, true )
        end, true )

        self:Hook( "OnEntityCreated", "NPCRelationshipHandle", function( ent )
            self:SimpleTimer( 0, function() 
                if !IsValid( ent ) or ent.IsLambdaPlayer or !ent:IsNPC() and !ent:IsNextBot() then return end 
                self:HandleNPCRelations( ent ) 
            end )
        end, true )

        self:Hook( "PhysgunPickup", "Physgunpickup", function( ply, ent )
            if ent == self then self.l_ispickedupbyphysgun = true end
        end, true )

        self:Hook( "PhysgunDrop", "Physgundrop", function( ply, ent )
            if ent == self then self.l_ispickedupbyphysgun = false end
        end, true )

        self:Hook( "LambdaPlayerSay", "lambdatextchat", function( ply, text )
            if self.l_preventdefaultspeak or ply == self or !self:CanType() or aidisabled:GetBool() or self:InCombat() or self:IsPanicking() then return end

            local replyChan = ( string_match( text, self:Nick() ) and 100 or 200 )
            if random( replyChan ) > self:GetTextChance() then return end

            local replyTime = ( random( 5, 20 ) / 10 )
            self:SimpleTimer( replyTime, function()
                if !IsValid( ply ) or self:GetIsTyping() or self:IsSpeaking() then return end
                self.l_keyentity = ply

                local line = self:GetTextLine( "response" )
                if typeNameRespond:GetBool() and !string_match( line, "/keyent/" ) then
                    line = ply:Nick() .. ", " .. line
                end
                self:TypeMessage( line )
            end )
        end, true )

        self:Hook( "PlayerSay", "lambdarespondtoplayertextchat", function( ply, text )
            if self.l_preventdefaultspeak or self:GetIsTyping() or self:IsSpeaking() or aidisabled:GetBool() then return end

            if random( 100 ) <= self:GetVoiceChance() and self:IsInRange( ply, 300 ) then
                self:PlaySoundFile( "idle" )
                return
            end
            if !self:CanType() or self:InCombat() or self:IsPanicking() then return end

            local replyChan = ( string_match( text, self:Nick() ) and 100 or 200 )
            if random( replyChan ) > self:GetTextChance() then return end
            
            local replyTime = ( random( 5, 20 ) / 10 )
            self:SimpleTimer( replyTime, function()
                if !IsValid( ply ) or self:GetIsTyping() or self:IsSpeaking() then return end
                self.l_keyentity = ply

                local line = self:GetTextLine( "response" )
                if typeNameRespond:GetBool() and!string_match( line, "/keyent/" ) then
                    line = ply:Nick() .. ", " .. line
                end
                self:TypeMessage( line )
            end )
        end, true )

        self:Hook( "LambdaOnRealPlayerEndVoice", "lambdarespondtoplayervoicechat", function( ply )
            if self.l_preventdefaultspeak or self:GetIsTyping() or self:IsSpeaking() or aidisabled:GetBool() or !self:IsInRange( ply, 300 ) then return end

            if random( 100 ) <= self:GetVoiceChance() then
                self:PlaySoundFile( "idle" )
            elseif random( 100 ) <= self:GetTextChance() and self:CanType() and !self:InCombat() and !self:IsPanicking() then
                self:SimpleTimer( rand( 0.2, 1.5 ), function()
                    if !IsValid( ply ) or self:GetIsTyping() or self:IsSpeaking() then return end
                    self.l_keyentity = ply

                    local line = self:GetTextLine( "response" )
                    if typeNameRespond:GetBool() and!string_match( line, "/keyent/" ) then
                        line = ply:Nick() .. ", " .. line
                    end
                    self:TypeMessage( line )
                end )
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
        local DrawBeam = render.DrawBeam
        local SetMaterial = render.SetMaterial
        local color_white = color_white
        self:Hook( "PreDrawEffects", "flashlighteffects", function()
            if !self.l_flashlighton or self:GetIsDead() or self:IsDormant() then return end

            local handPos = self:GetAttachmentPoint( "hand" ).Pos
            local finPos = self:GetEyeTrace().HitPos
            local eyeFwd = ( finPos - handPos ):GetNormalized()

            local start = ( handPos + eyeFwd * 3 )
            SetMaterial( flashlightsprite )
            DrawSprite( start, 4, 4, color_white )
            
            local endpos = ( handPos + eyeFwd * 150 )
            SetMaterial( flashlightbeam )
            DrawBeam( start, endpos, 40, 0, 0.9, faded )
        end, true )
    end
end
