
local SimpleTimer = timer.Simple
local random = math.random
local ents_Create = ents.Create
local tobool = tobool
local undo = undo
local ents_GetAll = ents.GetAll
local table_Merge = table.Merge
local isfunction = isfunction
local ipairs = ipairs
local bor = bit.bor
local CurTime = CurTime
local max = math.max
local ceil = math.ceil
local band = bit.band
local rand = math.Rand
local deathdir = GetConVar( "lambdaplayers_voice_deathdir" )
local killdir = GetConVar( "lambdaplayers_voice_killdir" )
local debugvar = GetConVar( "lambdaplayers_debug" )
local voicevar = GetConVar( "lambdaplayers_personality_voicechance" )
local obeynav = GetConVar( "lambdaplayers_lambda_obeynavmeshattributes" )
local callnpchook = GetConVar( "lambdaplayers_lambda_callonnpckilledhook" )

if SERVER then

    -- Due to the issues of Lambda Players not taking damage when they die internally, we have no choice but to recreate them to get around this.
    -- If there is a fix for the damage handling failing to prevent them from actually getting below 0 please make it known so it can be fixed ASAP.
    function ENT:OnKilled( info )
        if debugvar:GetBool() then ErrorNoHaltWithStack( "WARNING! ", self:GetLambdaName(), " was killed on a engine level! The entity will be recreated!" ) end

        local shouldblock = hook.Run( "LambdaOnInternalKilled", self )


        self:SimpleTimer( 0.1, function() self:Remove() end, true )
        if shouldblock == true then return end

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

    end

    function ENT:LambdaOnKilled( info )
        if self:GetIsDead() then return end
        self:DebugPrint( "was killed by ", info:GetAttacker() )

        self:EmitSound( info:IsDamageType( DMG_FALL ) and "Player.FallGib" or "Player.Death" )
        
        if random( 1, 100 ) <= self:GetVoiceChance() and !self:GetIsTyping() then
            self:PlaySoundFile( deathdir:GetString() == "randomengine" and self:GetRandomSound() or self:GetVoiceLine( "death" ) )
        end

        self:SetHealth( -1 ) -- SNPCs will think that we are still alive without doing this.
        self:SetIsDead( true )
        self:SetNoClip( false )
        self:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )

        self:ClientSideNoDraw( self, true )
        self:ClientSideNoDraw( self.WeaponEnt, true )
        self:SetNoDraw( true )
        self:DrawShadow( false )
        self.WeaponEnt:SetNoDraw( true )
        self.WeaponEnt:DrawShadow( false )

        if IsValid( self:GetSWEPWeaponEnt() ) then
            local swep = self:GetSWEPWeaponEnt()
            self:ClientSideNoDraw( swep, true )
            swep:SetNoDraw( true )
            swep:DrawShadow( false )
        end

        self:GetPhysicsObject():EnableCollisions( false )

        LambdaKillFeedAdd( self, info:GetAttacker(), info:GetInflictor() )
        if callnpchook:GetBool() then hook.Run( "OnNPCKilled", self, info:GetAttacker(), info:GetInflictor() ) end
        self:SetDeaths( self:GetDeaths() + 1 )

        for k, v in ipairs( self.l_Hooks ) do if !v[ 3 ] then self:RemoveHook( v[ 1 ], v[ 2 ] ) end end -- Remove all non preserved hooks
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
                net.WriteEntity( ( IsValid( self:GetSWEPWeaponEnt() ) and self:GetSWEPWeaponEnt() or self.WeaponEnt ) )
                net.WriteVector( info:GetDamageForce() )
                net.WriteVector( info:GetDamagePosition() )
                net.WriteVector( self:GetPhysColor() )
            net.Broadcast()
        end

        hook.Run( "LambdaOnKilled", self, info )
        --hook.Run( "PlayerDeath", self, info:GetInflictor(), info:GetAttacker() )


        self:Thread( function()

            local time = self:GetRespawn() and 2 or 0.1
            
            coroutine.wait( time )

            while self:GetIsTyping() do coroutine.yield() end

            if self:GetRespawn() then
                self:LambdaRespawn()
            else
                self:Remove()
            end

        end, "DeathThread", true )


        for k ,v in ipairs( ents_GetAll() ) do
            if IsValid( v ) and v != self and v:IsNextBot() then
                v:OnOtherKilled( self, info )
            end
        end

        local attacker = info:GetAttacker()
        if IsValid( attacker ) and attacker:IsPlayer() and attacker != self then 
            attacker:AddFrags( 1 ) 
            if random( 1, 100 ) <= self:GetTextChance() and !self:IsSpeaking() and self:CanType() then self.l_keyentity = attacker self:TypeMessage( self:GetTextLine( "deathbyplayer" ) ) end
        elseif IsValid( attacker ) and attacker.IsLambdaPlayer and attacker != self then
            if random( 1, 100 ) <= self:GetTextChance() and !self:IsSpeaking() and self:CanType() then self.l_keyentity = attacker self:TypeMessage( self:GetTextLine( "deathbyplayer" ) ) end
        elseif attacker != self then
            if random( 1, 100 ) <= self:GetTextChance() and !self:IsSpeaking() and self:CanType() then self.l_keyentity = attacker self:TypeMessage( self:GetTextLine( "death" ) ) end
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
        hook.Run( "LambdaOnOtherKilled", self, victim, info )

        local attacker = info:GetAttacker()

        local laughChance = ( ( IsValid( attacker ) and ( victim == attacker or attacker:IsPlayer() and !attacker:Alive() or attacker.IsLambdaPlayer and attacker:GetIsDead() ) ) and 4 or 10 )
        if self:GetState() != "Combat" and random( 1, laughChance ) == 1 and self:IsInRange( victim, 2000 ) and self:CanSee( victim ) then 
            self:LaughAt( victim ) 
        end

        -- If we killed the victim
        if attacker == self then
            local killlines = LambdaVoiceLinesTable.kill
            self:DebugPrint( "killed ", victim )
            self:SetFrags( self:GetFrags() + 1 )

            if victim == self:GetEnemy() then

                if random( 1, 100 ) <= self:GetVoiceChance() then
                    self:PlaySoundFile( killdir:GetString() == "randomengine" and self:GetRandomSound() or self:GetVoiceLine( "idle" ), true )
                elseif random( 1, 100 ) <= self:GetTextChance() and !self:IsSpeaking() and self:CanType() then
                    self.l_keyentity = victim
                    self:TypeMessage( self:GetTextLine( "kill" ) )
                end

                if random( 1, 10 ) == 1 then self.l_tbagpos = victim:GetPos(); self:SetState( "TBaggingPosition" ) end
            end

            if !victim.IsLambdaPlayer then LambdaKillFeedAdd( victim, info:GetAttacker(), info:GetInflictor() ) end
        else -- Someone else killed the victim

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

    local Navmeshfunctions = {

        [ NAV_MESH_CROUCH ] = function( self ) 
            self:SetCrouch( true )

            local lastState = self:GetState()
            local crouchTime = CurTime() + rand( 1, 30 )
            self:NamedTimer( "UnCrouch", 1, 0, function() 
                if self:GetState() != lastState or CurTime() >= crouchTime then
                    self:SetCrouch( false )
                    return true
                end
            end )
        end,

        [ NAV_MESH_RUN ] = function( self ) self:SetRun( true ) end,
        [ NAV_MESH_WALK ] = function( self ) self:SetRun( false ) end,
        [ NAV_MESH_JUMP ] = function( self ) self.loco:Jump() end
    }

    local attributes = NAV_MESH_CROUCH + NAV_MESH_WALK + NAV_MESH_RUN + NAV_MESH_JUMP

    -- Sets our current nav area
    function ENT:OnNavAreaChanged( old , new ) 
        self.l_currentnavarea = new

        local navfunc = Navmeshfunctions[ band( new:GetAttributes(), attributes ) ]
        if obeynav:GetBool() and navfunc then navfunc( self ) end
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
        [ "custom" ] = function( ply, self ) -- Custom Personality set by Sliders
            local tbl = {}
            for k, v in ipairs( LambdaPersonalityConVars ) do
                tbl[ v[ 1 ] ] = ply:GetInfoNum( "lambdaplayers_personality_" .. v[ 1 ] .. "chance", 30 )
            end
            self:SetVoiceChance( ply:GetInfoNum( "lambdaplayers_personality_voicechance", 30 ) )
            self:SetTextChance( ply:GetInfoNum( "lambdaplayers_personality_textchance", 30 ) )
            return  tbl
        end,
        [ "customrandom" ] = function( ply, self ) -- Same thing as Custom except the values from Sliders are used in RNG
            local tbl = {}
            for k, v in ipairs( LambdaPersonalityConVars ) do
                tbl[ v[ 1 ] ] = random( ply:GetInfoNum( "lambdaplayers_personality_" .. v[ 1 ] .. "chance", 30 ) )
            end
            self:SetVoiceChance( random( 0, ply:GetInfoNum( "lambdaplayers_personality_voicechance", 30 ) ) )
            self:SetTextChance( random( 0, ply:GetInfoNum( "lambdaplayers_personality_textchance", 30 ) ) )
            return  tbl
        end,
        [ "fighter" ] = function( ply, self ) -- Focused on Combat
            local tbl = {}
            for k, v in ipairs( LambdaPersonalityConVars ) do
                tbl[ v[ 1 ] ] = 0
            end
            tbl[ "Build" ] = 5
            tbl[ "Combat" ] = 80
            tbl[ "Tool" ] = 5
            self:SetVoiceChance( 30 )
            self:SetTextChance( 30 )
            return tbl
        end,
        [ "builder" ] = function( ply, self ) -- Focused on Building
            local tbl = {}
            for k, v in ipairs( LambdaPersonalityConVars ) do
                tbl[ v[ 1 ] ] = random( 1, 100 )
            end
            tbl[ "Build" ] = 80
            tbl[ "Combat" ] = 5
            tbl[ "Tool" ] = 80
            self:SetVoiceChance( 30 )
            self:SetTextChance( 30 )
            return tbl
        end
    } 

    local allowrespawn = GetConVar( "lambdaplayers_lambda_allownonadminrespawn" )
    function ENT:OnSpawnedByPlayer( ply )
        local respawn = tobool( ply:GetInfoNum( "lambdaplayers_lambda_shouldrespawn", 0 ) )
        local weapon = ply:GetInfo( "lambdaplayers_lambda_spawnweapon" )
        local voiceprofile = ply:GetInfo( "lambdaplayers_lambda_voiceprofile" )
        local textprofile = ply:GetInfo( "lambdaplayers_lambda_textprofile" )
        local personality = ply:GetInfo( "lambdaplayers_personality_preset" )

        self:SetRespawn( respawn )
        if self:WeaponDataExists( weapon ) then self:SwitchWeapon( weapon ) self.l_SpawnWeapon = weapon end
        self.l_VoiceProfile = voiceprofile != "" and voiceprofile or self.l_VoiceProfile
        self:SetNW2String( "lambda_vp", self.l_VoiceProfile )
        
        self.l_TextProfile = textprofile != "" and textprofile or self.l_TextProfile
        self:SetNW2String( "lambda_tp", self.l_TextProfile )
        
        if personality != "random" then
            self:BuildPersonalityTable( personalitypresets[ personality ]( ply, self ) )
        end
        

        self:DebugPrint( "Applied client settings from ", ply )
    end

    -- Fall damage handling
    -- Note that this doesn't always work due to nextbot quirks but that's alright.

    local realisticfalldamage = GetConVar( "lambdaplayers_lambda_realisticfalldamage" )
    
    function ENT:OnLandOnGround( ent )
        if self.l_ClimbingLadder or self:IsInNoClip() then return end
        -- Play land animation
        self:AddGesture( ACT_LAND )

        --hook.Run( "OnPlayerHitGround", self, self:GetPos():IsUnderwater(), false, self.l_FallVelocity )
        hook.Run( "LambdaOnLandOnGround", self, ent )

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
                info:SetDamageType( DMG_FALL)
                self:TakeDamageInfo( info )

                self:EmitSound( "Player.FallDamage" )
                --hook.Run( "GetFallDamage", self, self.l_FallVelocity )
            end
        end
    end

    function ENT:OnLeaveGround( ent ) 
        hook.Run( "LambdaOnLeaveGround", self, ent )
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
    hook.Run( "LambdaOnRemove", self )
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

        self:Hook( "PostEntityTakeDamage", "OnOtherInjured", function( target, info, tookdamage )
            if target == self or ( !target:IsNPC() and !target:IsNextBot() and !target:IsPlayer() ) then return end
            hook.Run( "LambdaOnOtherInjured", self, target, info, tookdamage )
        end, true )

        -- Hoookay so interesting stuff here. When a nextbot actually dies by reaching 0 or below hp, no matter how high you set their health after the fact, they will no longer take damage.
        -- To get around that we basically predict if the Lambda is gonna die and completely block the damage so we don't actually die. This of course is exclusive to Respawning
        self:Hook( "EntityTakeDamage", "DamageHandling", function( target, info )
            if target != self then return end

            local result = hook.Run( "LambdaOnInjured", self, info )
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

            if isfunction( self.l_OnDamagefunction ) then self.l_OnDamagefunction( self, self:GetWeaponENT(), info )  end

            local potentialdeath = ( self:Health() - info:GetDamage() ) <= 0
            if potentialdeath then
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

        self:Hook( "LambdaPlayerSay", "lambdatextchat", function( ply, text )
            if ply == self or self:IsDisabled() then return end

            if random( 1, 200 ) < self:GetTextChance() and !self:GetIsTyping() and !self:IsSpeaking() and self:CanType() then
                self.l_keyentity = ply
                self:TypeMessage( self:GetTextLine( "response" ) )
            end
        end, true )

        -- Might be better than constantly calling ENT:WaterLevel()?
        self:Hook( "OnEntityWaterLevelChanged", "OnWaterLevelChanged", function( ent, oldVal, newVal ) 
            if ent == self then self:SetIsUnderwater( newVal >= 2 ) end
        end, true )

    elseif CLIENT then

        self:Hook( "PreDrawEffects", "CustomWeaponRenderEffects", function()
            if self:GetIsDead() or !self:IsBeingDrawn() then return end

            if self:GetHasCustomDrawFunction() then
                local func = _LAMBDAPLAYERSWEAPONS[ self:GetWeaponName() ].Draw
        
                if isfunction( func ) then func( self, self:GetWeaponENT() ) end
            end
        
        end, true )

    end

end