local tobool = tobool
local ents_GetAll = ents.GetAll
local ents_Create = ents.Create
local isfunction = isfunction
local ipairs = ipairs
local pairs = pairs
local hook_Remove = hook.Remove
local CurTime = CurTime
local coroutine_yield = coroutine.yield
local coroutine_wait = coroutine.wait
local max = math.max
local Clamp = math.Clamp
local floor = math.floor
local abs = math.abs
local Round = math.Round
local NormalizeAngle = math.NormalizeAngle
local string_match = string.match
local string_sub = string.sub
local lower = string.lower
local SortTable = table.sort
local table_Empty = table.Empty
local IsSinglePlayer = game.SinglePlayer
local SimpleTimer = timer.Simple
local FrameTime = FrameTime
local TickInterval = engine.TickInterval
local ceil = math.ceil
local band = bit.band
local EmitSentence = EmitSentence
local EffectData = EffectData
local IsFirstTimePredicted = IsFirstTimePredicted
local util_Effect = util.Effect
local EmitSound = EmitSound

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
local armorFeedback = GetConVar( "lambdaplayers_lambda_armorfeedback" )
local ablativeArmor = GetConVar( "lambdaplayers_lambda_ablativearmor" )

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
                forceScale = 50
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
        ragdoll.IsLambdaSpawned = true

        self.ragdoll = ragdoll
        self:SetNW2Entity( "lambda_serversideragdoll", ragdoll )

        ragdoll:SetSkin( visualEnt:GetSkin() )
        for k, v in ipairs( visualEnt:GetBodyGroups() ) do
            ragdoll:SetBodygroup( v.id, visualEnt:GetBodygroup( v.id ) )
        end

        ragdoll:SetParent( NULL )
        ragdoll:RemoveEffects( EF_BONEMERGE )

        local vel = visualEnt:GetVelocity()
        local dmgPos, dmgForce, forceScale
        if IsValid( info ) then
            dmgPos = info:GetDamagePosition()
            dmgForce = info:GetDamageForce()

            local attacker = info:GetAttacker()
            if IsValid( attacker ) and attacker:GetClass() == "trigger_hurt" then
                forceScale = 0.25
            elseif info:IsExplosionDamage() then
                forceScale = 7
            else
                forceScale = 3
            end

            if info:IsDamageType( DMG_DISSOLVE ) then
                local dissolver = ents_Create( "env_entity_dissolver" )
                dissolver:SetKeyValue( "target", "!activator" )
                dissolver:Input( "dissolve", ragdoll )
                dissolver:Remove()
            end
        end
        for i = 0, ( ragdoll:GetPhysicsObjectCount() - 1 ) do
            local phys = ragdoll:GetPhysicsObjectNum( i )
            if !IsValid( phys ) then continue end

            phys:AddVelocity( vel )
            if dmgPos then
                local distDiff = ( phys:GetPos():Distance( dmgPos ) / forceScale )
                phys:ApplyForceOffset( dmgForce / distDiff, dmgPos )
            end
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
        if ( !dropEnt or !dropweaponents:GetBool() ) and IsValid( wepent ) then
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

            if IsValid( dropEnt ) and IsValid( wepent ) then
                dropEnt:SetPos( wepent:GetPos() )
                dropEnt:SetAngles( wepent:GetAngles() )
                dropEnt:Spawn()

                dropEnt:SetSubMaterial( 1, wepent:GetSubMaterial( 1 ) )
                dropEnt:SetNW2Vector( "lambda_weaponcolor", self:GetPhysColor() )

                dropEnt.LambdaOwner = self
                dropEnt.IsLambdaSpawned = true

                if IsValid( dmginfo ) then
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

        self:SetIsDead( true )
        self.l_LastDeathTime = CurTime()

        if !silent then
            self:DebugPrint( "I was killed by", attacker )

            self:EmitSound( info:IsDamageType( DMG_FALL ) and "Player.FallGib" or "Player.Death" )

            if ( !self.l_killbinded and deathAlways:GetBool() or LambdaRNG( 100 ) <= self:GetVoiceChance() ) and !self:GetIsTyping() then
                self:PlaySoundFile( self.l_killbinded and "laugh" or "death" )
            else
                self:StopCurrentVoiceLine()
            end

            LambdaKillFeedAdd( self, attacker, inflictor )
            if callnpchook:GetBool() then LambdaRunHook( "OnNPCKilled", self, attacker, inflictor ) end

            self:SetDeaths( self:GetDeaths() + 1 )
            if attacker == self then self:SetFrags( self:GetFrags() - 1 ) end

            local beepTarg = self
            if !serversideragdolls:GetBool() and !info:IsDamageType( DMG_DISSOLVE ) then
                self:CreateClientsideRagdoll( info )
            else
                beepTarg = self:CreateServersideRagdoll( info )
            end

            if LambdaRNG( 2 ) == 1 then
                local pitch = ( LambdaRNG( 2 ) == 1 and 100 or ( LambdaRNG( 0, 6 ) + 98 ) )
                EmitSentence( "HEV_DEAD" .. LambdaRNG( 0, 1 ), self:GetPos(), beepTarg:EntIndex(), CHAN_VOICE, 0.25, 75, 0, pitch )
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
        table_Empty( self.l_cachedunreachableares )

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
                    spawnCheckTime = ( CurTime() + ( LambdaRNG( 0, 10 ) * 0.1 ) )
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

            if !self.l_preventdefaultspeak and LambdaRNG( 100 ) <= self:GetTextChance() and !self:IsSpeaking() and self:CanType() then
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

        if !self:IsPanicking() then
            if retreatLowHP:GetBool() and ( attacker != self and IsValid( attacker ) or self:InCombat() and ( attacker != self:GetEnemy() or !attacker.IsLambdaPlayer or !attacker:IsPanicking() or LambdaRNG( 1, 3 ) == 1 ) ) then
                local chance = self:GetCowardlyChance()
                if chance <= 20 then
                    chance = ( chance * LambdaRNG( 1.0, 2.5, true ) )
                elseif chance > 60 then
                    chance = ( chance / LambdaRNG( 1.5, 2.5, true ) )
                end

                local hpThreshold = LambdaRNG( ( chance / 4 ), chance )
                local predHp = ( self:Health() - ( info:GetDamage() * LambdaRNG( 1.0, 1.5, true ) ) )
                if predHp <= hpThreshold then
                    self:RetreatFrom( self:CanTarget( attacker ) and attacker or nil )
                    return
                end
            end
        elseif ( self:Health() - info:GetDamage() ) <= 1 and self:GetVoiceChance() > 0 then
            self:PlaySoundFile( "fall" )
        end

        local ene = self:GetEnemy()
        if attacker != self and attacker != ene and IsValid( attacker ) and ( !self:ShouldTreatAsLPlayer( attacker ) or LambdaRNG( 2 ) == 1 ) and ( !IsValid( ene ) or self:GetRangeSquaredTo( attacker ) < self:GetRangeSquaredTo( ene ) ) and self:CanTarget( attacker ) then
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

            self.l_nextsurroundcheck = 0 -- Search for the next enemy NPC immediately
        end

        if preventDefActs == true then return end

        if attacker == self then
            if victim == enemy then
                if !self.l_preventdefaultspeak then
                    if LambdaRNG( 100 ) <= self:GetVoiceChance() and LambdaRNG( 3 ) == 1 then
                        self:PlaySoundFile( "kill" )
                    elseif LambdaRNG( 100 ) <= self:GetTextChance() and !self:IsSpeaking() and self:CanType() then
                        self.l_keyentity = victim
                        self:TypeMessage( self:GetTextLine( "kill" ) )
                    end
                end

                if LambdaRNG( 10 ) == 1 then
                    self:SetState( "TBaggingPosition", victim:GetPos() )
                    self:DebugPrint( "I killed my enemy. It's t-bagging time..." )
                    return
                end
            end

            if LambdaRNG( 150 ) <= self:GetCowardlyChance() and retreatLowHP:GetBool() then
                self:DebugPrint( "I killed someone. Retreating..." )
                self:RetreatFrom( nil, nil, ( LambdaRNG( 100 ) <= self:GetVoiceChance() and LambdaRNG( 3 ) == 1 ) )
                self:CancelMovement()
                return
            end
        elseif victim == enemy and !self.l_preventdefaultspeak and LambdaRNG( 100 ) <= self:GetVoiceChance() and ( attacker:IsPlayer() or attacker:IsNPC() or attacker:IsNextBot() ) then
            if self:CanSee( attacker ) then
                self:LookTo( attacker, 1, false, 2 )
            end
            self:PlaySoundFile( "assist", LambdaRNG( 0.1, 1.0, true ) )
        end

        if self:IsInRange( victim, 1500 ) and self:CanSee( victim ) then
            local witnessChance = LambdaRNG( 10 )
            if witnessChance == 1 or ( attacker == victim or attacker:IsWorld() ) and witnessChance > 6 then
                self:SetState( "Laughing", { victim, self:GetDestination() } )
                self:CancelMovement()
                self:DebugPrint( "I killed or saw someone die. Laugh at this man!" )
            elseif attacker != self and victim != enemy then
                if witnessChance == 2 and !self.l_preventdefaultspeak then
                    self:LookTo( victim:GetPos(), LambdaRNG( 3 ), false, 1 )

                    if LambdaRNG( 100 ) <= self:GetVoiceChance() then
                        self:PlaySoundFile( "witness", LambdaRNG( 0.1, 1.0, true ) )
                    elseif LambdaRNG( 100 ) <= self:GetTextChance() and ( victim.IsLambdaPlayer or victim:IsPlayer() ) and !self:IsSpeaking() and self:CanType() then
                        self.l_keyentity = victim
                        self:TypeMessage( self:GetTextLine( "witness" ) )
                    end
                end

                if witnessChance != 2 and !self:InCombat() and LambdaRNG( 100 * ( isEnt and 1.5 or 2.5 ) ) <= self:GetCowardlyChance() and retreatLowHP:GetBool() then
                    local targ = ( ( self:CanTarget( attacker ) and self:CanSee( attacker ) and LambdaRNG( 3 ) == 1 ) and attacker or nil )
                    self:DebugPrint( "I saw someone die. Retreating..." )
                    self:LookTo( targ or victim:WorldSpaceCenter(), LambdaRNG( 1, 3, true ), false, 1 )

                    self:RetreatFrom( targ, nil, !self:IsSpeaking( "witness" ) )
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
            self:WaitWhileMoving( LambdaRNG( 0.66, 1.0, true ) )
        end,
        [ NAV_MESH_STAND ] = function( self )
            self:SetCrouch( false )
        end
    }

    -- Called when our current nav area is changed
    function ENT:OnNavAreaChanged( old, new )
        if !IsValid( new ) then return end
        self.l_currentnavarea = new

        local movePos = self.l_CurrentPath
        if self.l_issmoving and movePos == self:GetDestination() then
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
                tbl[ v[ 1 ] ] = LambdaRNG( ply:GetInfoNum( "lambdaplayers_personality_" .. v[ 1 ] .. "chance", 30 ) )
            end
            lambda:SetVoiceChance( LambdaRNG( 0, ply:GetInfoNum( "lambdaplayers_personality_voicechance", 30 ) ) )
            lambda:SetTextChance( LambdaRNG( 0, ply:GetInfoNum( "lambdaplayers_personality_textchance", 30 ) ) )
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
                tbl[ v[ 1 ] ] = LambdaRNG( 10 )
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
                    local hardLand = self.l_HardLandingRolls
                    if hardLand and hardLand.HasAnims and hardLand.Enabled:GetBool() then
                        self:EmitSound( "npc/combine_soldier/zipline_hitground" .. LambdaRNG( 2 ) .. ".wav", 75, 100, 1, CHAN_STATIC )
                        
                        local rolled = ( !self.loco:GetVelocity():IsZero() and LambdaRNG( 3 ) != 1 and fallSpeed <= hardLand.MaxFallSpeed:GetInt() )
                        local landSeq = self:LookupSequence( "wos_mma_" .. ( !rolled and "hardlanding" or "roll" ) )
                        local animLayer = self:AddGestureSequence( landSeq )

                        self:SetLayerCycle( animLayer, 0.1 )
                        self:SetLayerBlendIn( animLayer, 0.2 )
                        
                        local landDur = ( !rolled and hardLand.FailDuration or hardLand.RollDuration ):GetFloat()
                        self:SetLayerDuration( animLayer, landDur )
                        
                        self.loco:SetVelocity( vector_origin )
                        if !rolled then
                            self:Freeze( true )
                        else
                            self:ForceMoveSpeed( 0, landDur, true )
                            damage = 0
                            
                            local wepDelay = self.l_WeaponUseCooldown
                            self.l_WeaponUseCooldown = ( ( CurTime() >= wepDelay and CurTime() or wepDelay ) + landDur )

                            local rollDir = self:GetForward()
                            self:LookTo( ( self:GetPos() + rollDir * 32768 ), landDur, false, 4 )
    
                            local startTime = CurTime()
                            self:Hook( "Tick", "Hardlanding_RollVelocity", function()
                                local timePast = ( CurTime() - startTime )
                                if timePast >= landDur then return "end" end
                                local speed = Lerp( math.ease.InSine( timePast / landDur ), 300, 0 )
    
                                local rollVel = ( rollDir * speed )
                                rollVel.z = self.loco:GetVelocity().z
                                self.loco:SetVelocity( rollVel )
                            end )
                        end
    
                        self:SimpleTimer( ( landDur - 0.5 ), function()
                            self:SetLayerBlendOut( animLayer, 0.25 )
                        end )
                        self:SimpleTimer( landDur, function()
                            if !rolled then self:Freeze( false ) end
                        end, true )
                    end

                    if damage > 0 then
                        local info = DamageInfo()
                        info:SetDamage( damage )
                        info:SetAttacker( Entity( 0 ) )
                        info:SetDamageType( DMG_FALL )
                        
                        self:TakeDamageInfo( info )
                        self:EmitSound( "Player.FallDamage" )
                    end
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

        self:SimpleTimer( LambdaRNG( 0, 1, true ), function()
            if !self:IsSpeaking( "fall" ) or self:IsPanicking() or self:Health() <= 1 then return end
            self:StopCurrentVoiceLine()
        end )

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

local function GetNameResponseLine( lambda, ply )
    local line, preLine = lambda:GetTextLine( "response" )
    if typeNameRespond:GetBool() and !string_match( preLine, "/keyent/" ) then
        local upCount, normCount = 0, 0
        for i = 1, #line do
            if string_match( line[ i ], "%u" ) then
                upCount = ( upCount + 1 )
            else
                normCount = ( normCount + 1 )
            end
        end

        if upCount <= normCount then
            line = lower( line[ 1 ] ) .. string_sub( line, 2, #line )
        end
        line = ply:Nick() .. ", " .. line
    end
    return line
end

-- DRGBase Nextbot ConVars
local drg_MultDmg_Ply
local drg_MultDmg_NPC
--

-- MANDKIND IS DEAD. BLOOD IS FUEL. HELL IS FULL.
local ukHeal_Enabled
local ukHeal_MaxHeal
local ukHeal_Range
local ukHeal_NPCOnly
local ukHeal_HardDmg_Enabled
local ukHeal_HardDmg_Mult
local ukHeal_HardDmg_RecoveryMult
local ukHeal_HardDmg_Enforce
--

-- A function for holding self:Hook() functions. Called in the ENT:Initialize() in npc_lambdaplayer
function ENT:InitializeMiniHooks()
    if ( SERVER ) then
        if DrGBase then
            drg_MultDmg_Ply = ( drg_MultDmg_Ply or GetConVar( "drgbase_multiplier_damage_players" ) )
            drg_MultDmg_NPC = ( drg_MultDmg_NPC or GetConVar( "drgbase_multiplier_damage_npc" ) )
        end

        if UltrakillBase then
            ukHeal_Enabled = ( ukHeal_Enabled or GetConVar( "drg_ultrakill_healing" ) )
            ukHeal_MaxHeal = ( ukHeal_MaxHeal or GetConVar( "drg_ultrakill_healing_maxheal" ) )
            ukHeal_Range = ( ukHeal_Range or GetConVar( "drg_ultrakill_healing_range" ) )
            ukHeal_NPCOnly = ( ukHeal_NPCOnly or GetConVar( "drg_ultrakill_healing_ultrakillonly" ) )

            ukHeal_HardDmg_Enabled = ( ukHeal_HardDmg_Enabled or GetConVar( "drg_ultrakill_healing_harddamage" ) )
            ukHeal_HardDmg_Mult = ( ukHeal_HardDmg_Mult or GetConVar( "drg_ultrakill_healing_harddamage_multiplier" ) )
            ukHeal_HardDmg_RecoveryMult = ( ukHeal_HardDmg_RecoveryMult or GetConVar( "drg_ultrakill_healing_harddamage_recovery_multiplier" ) )
            ukHeal_HardDmg_Enforce = ( ukHeal_HardDmg_Enforce or GetConVar( "drg_ultrakill_healing_harddamage_enforce" ) )

            self:Hook( "Think", "UltrakillHardDmg", function()
                local hardDmg = self:GetNW2Int( "UltrakillBase_HardDamage", 0 )
                if hardDmg > 0 and self:Health() > ( self:GetMaxHealth() - hardDmg ) and ukHeal_HardDmg_Enforce:GetBool() then
                    self:SetHealth( self:GetMaxHealth() - Clamp( hardDmg, 0, self:GetMaxHealth() - 1 ) )
                end

                if !self:Alive() then
                    self:SetNW2Int( "UltrakillBase_HardDamage", 0 )
                    self:SetNW2Float( "UltrakillBase_HardDamage_Time", 0 )
                end

                local hardTime = self:GetNW2Float( "UltrakillBase_HardDamage_Time", 0 )
                if CurTime() > hardTime then
                    self:SetNW2Int( "UltrakillBase_HardDamage", ( hardDmg - 14 * TickInterval() ) )
                end
            end )
        end

        -- Hoookay so interesting stuff here. When a nextbot actually dies by reaching 0 or below hp, no matter how high you set their health after the fact, they will no longer take damage.
        -- To get around that we basically predict if the Lambda is gonna die and completely block the damage so we don't actually die. This of course is exclusive to Respawning
        self:Hook( "LambdaTakeDamage", "DamageHandling", function( target, info )
            if target != self then return end
            if self.l_godmode then return true end

            local result = LambdaRunHook( "LambdaOnInjured", self, info )
            if result == true then return true end

            local onDmgFunc = self.l_OnDamagefunction
            if isfunction( onDmgFunc ) and onDmgFunc( self, self:GetWeaponENT(), info ) == true then return true end

            local attacker = info:GetAttacker()
            if IsValid( attacker ) then
                if attacker.IsDrGNextbot then
                    info:SetDamage( ( info:GetDamage() / drg_MultDmg_NPC:GetFloat() ) * drg_MultDmg_Ply:GetFloat() )
                end

                -- ULTRAKILL SNPCs insta-kill moment (THIS WILL HURT/DIE)
                local isUkNPC = attacker.IsUltrakillNextbot
                if isUkNPC then
                    info:SetDamage( ( info:GetDamage() / UltrakillBase.ConVar_DmgMult:GetFloat() ) / 10 )
                -- BOOTY PLS PLEY DEE EMM CEE TOO, ITS DA BEST GAEM!!!
                elseif attacker.DevilTrigger then
                    info:SetDamage( info:GetDamage() * 0.1 )
                -- Hydrogen bomb(KLK Nextbot) VS Coughing baby(Lambda Player)
                elseif attacker.KLK_OwnDMGMult then
                    info:ScaleDamage( attacker.KLK_OwnDMGMult )
                -- THE UNENLIGHTENED MASSES
                elseif attacker.IsDrGNextbot and attacker:GetModel() == "models/resort/tf2_community/deadnaut.mdl" then
                    info:ScaleDamage( 0.1 )
                -- Fixes Lambda-launched Combine Balls not setting its damage's attacker properly
                elseif attacker:GetClass() == "prop_combine_ball" then
                    local owner = attacker:GetOwner()
                    if IsValid( owner ) and owner.IsLambdaPlayer then info:SetAttacker( owner ) end
                end

                if UltrakillBase and attacker != self and ukHeal_HardDmg_Enabled:GetBool() and ( !ukHeal_NPCOnly:GetBool() or isUkNPC or attacker.IsUltrakillProjectile ) then
                    local tookDmg = info:GetDamage()
                    local maxHp = self:GetMaxHealth()
                    if tookDmg > 0 and floor( ( self:Health() - ceil( tookDmg ) ) + tookDmg ) <= maxHp then
                        local diffInfo = UltrakillBase.GetDifficulty()
                        local fDelay = 1

                        if diffInfo <= 2 then
                            fDelay = 1
                        elseif diffInfo == 3 then
                            fDelay = 2
                        else
                            fDelay = 2.5
                        end

                        
                        local hardDmg = ( tookDmg * ukHeal_HardDmg_Mult:GetFloat() )
                        local time = ( Clamp( ( tookDmg / 20 ) + fDelay, 0, 5 ) / ukHeal_HardDmg_RecoveryMult:GetFloat() )

                        self:SetNW2Int( "UltrakillBase_HardDamage", Clamp( ( self:GetNW2Int( "UltrakillBase_HardDamage", 0 ) + hardDmg ), 0, ( maxHp - 1 ) ) )
                        self:SetNW2Float( "UltrakillBase_HardDamage_Time", ( time + CurTime() ) )
                    end
                end
            end

            -- Armor Damage Reduction
            local curArmor = self:GetArmor()
            if curArmor > 0 then
                local isPhysicalDmg = !info:IsDamageType( DMG_DROWN + DMG_POISON + DMG_FALL + DMG_RADIATION )

                if armorFeedback:GetBool() and isPhysicalDmg and IsFirstTimePredicted() then
                    local dmgPos = self:NearestPoint( info:GetDamagePosition() )
                    EmitSound( "physics/metal/metal_solid_impact_bullet" .. LambdaRNG( 4 ) .. ".wav", dmgPos, self:EntIndex(), nil, 0.6, 80, nil, LambdaRNG( 90, 110 ) )

                    local sparks = EffectData()
                    sparks:SetOrigin( dmgPos )
                    sparks:SetMagnitude( 1 )
                    sparks:SetScale( 1 )
                    sparks:SetRadius( 1 )
                    sparks:SetNormal( self:GetForward() )
                    util_Effect( "Sparks", sparks, true, true )
                end

                --

                local flDmg = info:GetDamage()
                if !ablativeArmor:GetBool() then
                    if isPhysicalDmg then
                        local flNew = flDmg * 0.2
                        local flArmor = max( ( flDmg - flNew ), 1 )

                        if flArmor > curArmor then
                            flArmor = curArmor
                            flNew = ( flDmg - flArmor )
                            self:SetArmor( 0 )
                        else
                            self:SetArmor( math.Round( curArmor - flArmor, 0 ) )
                        end

                        flDmg = flNew
                        info:SetDamage( flDmg )
                    end
                elseif curArmor >= flDmg then
                    self:SetArmor( math.Round( curArmor - flDmg, 0 ) )
                    return true
                elseif curArmor > 0 then
                    info:SetDamage( flDmg - curArmor )
                    self:SetArmor( 0 )
                end
            end

            local dmg = info:GetDamage()
            local potentialdeath = ( self:Health() - ceil( dmg ) ) <= 0
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

        self:Hook( "PostEntityTakeDamage", "OnOtherInjured", function( target, info, tookdamage )
            if target == self then
                if self.l_HasExtendedAnims and info:IsExplosionDamage() then
                    self:AddGesture( ACT_GESTURE_FLINCH_BLAST )
                end
                return
            end

            if ( !target:IsNPC() and !target:IsNextBot() and !target:IsPlayer() ) then return end
            LambdaRunHook( "LambdaOnOtherInjured", self, target, info, tookdamage )

            local attacker = info:GetAttacker()
            if attacker != self then return end

            if tookdamage then
                if UltrakillBase then
                    local hp, maxHp = self:Health(), self:GetMaxHealth()
                    if hp < maxHp and ukHeal_Enabled:GetBool() and ( !ukHeal_NPCOnly:GetBool() or target.IsUltrakillNextbot ) and !target:GetNW2Bool( "UltrakillBase_Sand" ) and self:IsInRange( target, ukHeal_Range:GetFloat() ) then
                        self:SetHealth( Clamp( hp + Clamp( info:GetDamage(), 0, ukHeal_MaxHeal:GetInt() ), 0, ( maxHp - self:GetNW2Int( "UltrakillBase_HardDamage", 0 ) ) ) )
                    end
                end

                -- VJ Base's 'Become enemy to a friendly player' feature
                if target.IsVJBaseSNPC and !target.VJ_IsBeingControlled and target:CheckRelationship( self ) == D_LI then
                    local curAnger = ( target.AngerLevelTowardsPlayer + 1 )
                    target.AngerLevelTowardsPlayer = curAnger

                    if curAnger > target.BecomeEnemyToPlayerLevel then
                        if target:Disposition( self ) != D_HT then
                            target:CustomOnBecomeEnemyToPlayer( info, target:GetLastDamageHitGroup() )
                            if target.IsFollowing and target.FollowData.Ent == self then
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
            end

            local wepent = self:GetWeaponENT()
            local inflictor = info:GetInflictor()
            local dealDmgFunc = self.l_OnDealDamagefunction
            if inflictor == wepent and isfunction( dealDmgFunc ) then
                local killed = ( tookdamage and ( ( target.IsLambdaPlayer or target:IsPlayer() ) and !target:Alive() or target:Health() <= 0 ) )
                dealDmgFunc( self, wepent, target, info, tookdamage, killed )
            end
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
            if LambdaRNG( replyChan ) > self:GetTextChance() then return end

            local replyTime = ( LambdaRNG( 5, 20 ) / 10 )
            self:SimpleTimer( replyTime, function()
                if !IsValid( ply ) or self:GetIsTyping() or self:IsSpeaking() then return end
                self.l_keyentity = ply
                self:TypeMessage( GetNameResponseLine( self, ply ) )
            end )
        end, true )

        self:Hook( "PlayerSay", "lambdarespondtoplayertextchat", function( ply, text )
            if self.l_preventdefaultspeak or self:GetIsTyping() or self:IsSpeaking() or aidisabled:GetBool() then return end

            if LambdaRNG( 100 ) <= self:GetVoiceChance() and self:IsInRange( ply, 300 ) then
                self:PlaySoundFile( "idle" )
                return
            end
            if !self:CanType() or self:InCombat() or self:IsPanicking() then return end

            local replyChan = ( string_match( text, self:Nick() ) and 100 or 200 )
            if LambdaRNG( replyChan ) > self:GetTextChance() then return end

            local replyTime = ( LambdaRNG( 5, 20 ) / 10 )
            self:SimpleTimer( replyTime, function()
                if !IsValid( ply ) or self:GetIsTyping() or self:IsSpeaking() then return end
                self.l_keyentity = ply
                self:TypeMessage( GetNameResponseLine( self, ply ) )
            end )
        end, true )

        self:Hook( "LambdaOnRealPlayerEndVoice", "lambdarespondtoplayervoicechat", function( ply )
            if self.l_preventdefaultspeak or self:GetIsTyping() or self:IsSpeaking() or aidisabled:GetBool() or !self:IsInRange( ply, 300 ) then return end

            if LambdaRNG( 100 ) <= self:GetVoiceChance() then
                self:PlaySoundFile( "idle" )
            elseif LambdaRNG( 100 ) <= self:GetTextChance() and self:CanType() and !self:InCombat() and !self:IsPanicking() then
                self:SimpleTimer( LambdaRNG( 0.2, 1.5, true ), function()
                    if !IsValid( ply ) or self:GetIsTyping() or self:IsSpeaking() then return end
                    self.l_keyentity = ply
                    self:TypeMessage( GetNameResponseLine( self, ply ) )
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

            local flashlight = self.l_flashlight
            if !IsValid( flashlight ) then return end

            local handPos = self:GetAttachmentPoint( "hand" ).Pos
            local eyeFwd = flashlight:GetAngles():Forward()

            local start = ( handPos + eyeFwd * 3 )
            SetMaterial( flashlightsprite )
            DrawSprite( start, 4, 4, color_white )

            local endpos = ( handPos + eyeFwd * 150 )
            SetMaterial( flashlightbeam )
            DrawBeam( start, endpos, 40, 0, 0.9, faded )
        end, true )
    end
end
