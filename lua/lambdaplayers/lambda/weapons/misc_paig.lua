local CurTime = CurTime
local IsValid = IsValid
local Effect = util.Effect
local BlastDamage = util.BlastDamage
local EffectData = EffectData
local DamageInfo = DamageInfo

local CreateSound = CreateSound

local ipairs = ipairs
local ScreenShake = util.ScreenShake
local ParticleEffect = ParticleEffect
local FindInSphere = ents.FindInSphere

game.AddParticles( "particles/bigboom.pcf" )
PrecacheParticleSystem( "fluidSmokeExpl_ring_mvm" )
PrecacheParticleSystem( "explosionTrail_seeds_mvm" )

local busterMode = CreateLambdaConvar( "lambdaplayers_weapons_paig_sentrybustermode", 0, true, false, true, "If Lambda that equip the PAIG have the ability to act like the Sentry Buster from TF2.", 0, 1, { type = "Bool", name = "PAIG - Enable Sentry Buster Mode", category = "Weapon Utilities" } )

local function OnPAIGRemoved( self )
    self:StopSound( "lambdaplayers/weapons/paig/sb_intro.mp3" )
    self:StopSound( "lambdaplayers/weapons/paig/sb_spin.mp3" )
    if self.LoopSound then self.LoopSound:Stop(); self.LoopSound = nil end 
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    paig = {
        model = "models/weapons/w_grenade.mdl",
        origin = "Misc",
        prettyname = "Punch Activated Impact Grenade",
        holdtype = "grenade",
        killicon = "lambdaplayers/killicons/icon_paig",
        ismelee = true,
        bonemerge = true,
        keepdistance = 5,
        attackrange = 50,
        speedmultiplier = 1.1,

        OnDeploy = function( self, wepent )
            wepent.SentryBusterMode = busterMode:GetBool()
            if !wepent.SentryBusterMode then return end
            
            wepent:EmitSound( "lambdaplayers/weapons/paig/sb_intro.mp3" )
            wepent:CallOnRemove( "Lambda_PAIG_StopSound" .. wepent:EntIndex(), OnPAIGRemoved )
           
            wepent.LoopSound = CreateSound( wepent, "lambdaplayers/weapons/paig/sb_loop.wav" ) -- Looping only works on .WAV formats, unfortunately
            if wepent.LoopSound then wepent.LoopSound:Play() end
        end,

        OnThink = function( self, wepent, isDead )
            if !wepent.SentryBusterMode then return end

            local loopSnd = wepent.LoopSound
            if !loopSnd then return end

            if isDead or CurTime() < self.l_WeaponUseCooldown then
                loopSnd:Stop()
                if isDead then wepent:StopSound( "lambdaplayers/weapons/paig/sb_spin.mp3" ) end
            elseif !loopSnd:IsPlaying() then
                loopSnd:Play()
            end
        end,

        OnHolster = function( self, wepent )
            wepent.SentryBusterMode = nil
            wepent:StopSound( "lambdaplayers/weapons/paig/sb_spin.mp3" )
            if wepent.LoopSound then wepent.LoopSound:Stop(); wepent.LoopSound = nil end
        end,

        OnAttack = function( self, wepent, target )
            local busterMode = wepent.SentryBusterMode
            local detonateTime = ( busterMode and 2.069 or 0.3 )
            local detonateSnd = ( busterMode and "lambdaplayers/weapons/paig/sb_explode.mp3" or "BaseExplosionEffect.Sound" )
            self.l_WeaponUseCooldown = ( CurTime() + 1 + detonateTime )

            if busterMode then
                wepent:EmitSound( "lambdaplayers/weapons/paig/sb_spin.mp3", 80 )

                if LambdaRNG( 100 ) <= self:GetVoiceChance() then
                    local rndLine = LambdaRNG( 3 )
                    self:PlaySoundFile( rndLine == 1 and "taunt" or ( rndLine == 2 and "kill" or "fall" ) )
                end
            end

            for _, lambda in ipairs( GetLambdaPlayers() ) do
                if lambda == self or !LambdaIsValid( lambda ) or !lambda:IsInRange( self, ( !busterMode and 400 or 750 ) ) or !self:CanTarget( lambda ) or !busterMode and !lambda:CanSee( self ) then continue end
                lambda:SimpleTimer( LambdaRNG( 0.0, 0.25, true ), function() lambda:RetreatFrom( self, 1.0 + detonateTime ) end )
            end

            self:SimpleWeaponTimer( ( detonateTime - 0.3 ), function()
                wepent:EmitSound( "WeaponFrag.Throw", 70 )
                self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
                self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
            end )

            self:SimpleWeaponTimer( detonateTime, function()
                local blowPos = self:GetAttachmentPoint( "hand" ).Pos

                local effectData = EffectData()
                effectData:SetOrigin( blowPos )
                Effect( "Explosion", effectData, true, true )

                wepent:EmitSound( detonateSnd, 90 )
                BlastDamage( wepent, self, blowPos, ( !busterMode and 400 or 750 ), ( !busterMode and 1000 or 600 ) )

                local selfDmg = DamageInfo()
                selfDmg:SetDamage( 1000 )
                selfDmg:SetDamageType( DMG_BLAST )
                selfDmg:SetAttacker( self )
                selfDmg:SetInflictor( wepent )
				
				local blowAng = ( self:WorldSpaceCenter() - blowPos ):Angle()
                selfDmg:SetDamageForce( blowAng:Forward() * 1000 )
                
				self:TakeDamageInfo( selfDmg )

                if !busterMode then return end
                ScreenShake( blowPos, 25, 5, 3, 1000 )

                ParticleEffect( "fluidSmokeExpl_ring_mvm", blowPos, blowAng )
                ParticleEffect( "explosionTrail_seeds_mvm", blowPos, blowAng )

                for _, ply in ipairs( FindInSphere( blowPos, 1000 ) ) do
                    if !IsValid( ply ) or !ply:IsPlayer() then continue end
                    ply:ScreenFade( SCREENFADE.IN, color_white, 1.0, 0.1 )
                end
            end)

            return true
        end,

        islethal = true
    }
})