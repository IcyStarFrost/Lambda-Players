local CurTime = CurTime
local IsValid = IsValid
local Effect = util.Effect
local BlastDamage = util.BlastDamage
local EffectData = EffectData
local DamageInfo = DamageInfo
local random = math.random
local CreateSound = CreateSound
local Rand = math.Rand
local ipairs = ipairs

game.AddParticles("particles/bigboom.pcf")

local busterMode = CreateLambdaConvar( "lambdaplayers_weapons_paigsentrybuster", 0, true, false, true, "If Lambda that spawn with the PAIG have the ability to act like the Sentry Buster from TF2.", 0, 1, { type = "Bool", name = "PAIG - Enable Sentry Buster Mode", category = "Weapon Utilities" } )

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
        speedmultiplier = 1.2,

        OnDeploy = function( self, wepent )
            wepent.SentryBusterMode = busterMode:GetBool()
            if !wepent.SentryBusterMode then return end
            
            wepent:EmitSound( "lambdaplayers/weapons/paig/sb_intro.mp3" )
           
            wepent.LoopSound = CreateSound( wepent, "lambdaplayers/weapons/paig/sb_loop.wav" ) -- Looping only works on .WAV formats, unfortunately
            if wepent.LoopSound then wepent.LoopSound:Play() end

            wepent:CallOnRemove( "Lambda_PAIG_StopSound" .. wepent:EntIndex(), OnPAIGRemoved )
        end,

        OnThink = function( self, wepent, dead )
            if !wepent.SentryBusterMode then return end
            
            local loopSnd = wepent.LoopSound
            if !loopSnd then return end

            if dead or CurTime() < self.l_WeaponUseCooldown then
                loopSnd:Stop()
                if dead then wepent:StopSound( "lambdaplayers/weapons/paig/sb_spin.mp3" ) end
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
            self.l_WeaponUseCooldown = CurTime() + 1

            local detonateTime = 0.3
            local detonateSnd = "BaseExplosionEffect.Sound"
            
            if wepent.SentryBusterMode then
                detonateTime = 2.069
                detonateSnd = "lambdaplayers/weapons/paig/sb_explode.mp3"

                wepent:EmitSound( "lambdaplayers/weapons/paig/sb_spin.mp3", 80 )
                if random( 1, 100 ) <= self:GetVoiceChance() then 
                    self:PlaySoundFile( self:GetVoiceLine( random( 1, 2 ) == 1 and "taunt" or "kill" ) ) 
                end
            end

            for _, v in ipairs( GetLambdaPlayers() ) do
                if v != self and LambdaIsValid( v ) and v:IsInRange( self, 400 ) or ( wepent.SentryBusterMode and v:IsInRange( self, 750 ) ) and v:CanTarget( self ) and ( wepent.SentryBusterMode or v:CanSee( self ) ) then
                    v:SimpleTimer( Rand( 0.0, 0.25 ), function() v:RetreatFrom( self, 1.0 + detonateTime ) end)
                end
            end

            self.l_WeaponUseCooldown = ( self.l_WeaponUseCooldown + detonateTime )

            self:SimpleWeaponTimer( detonateTime - 0.3, function()
                wepent:EmitSound( "WeaponFrag.Throw", 70 )
                self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
                self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
            end )

            self:SimpleWeaponTimer( detonateTime, function()
                local blowPos = self:GetAttachmentPoint( "hand" ).Pos

                local effectData = EffectData()
                effectData:SetOrigin( blowPos )
                Effect( "Explosion", effectData, true, true )

                if !wepent.SentryBusterMode then
                    BlastDamage( wepent, self, blowPos, 400, 1000 )
                elseif wepent.SentryBusterMode then
                    BlastDamage( wepent, self, blowPos, 750, 600 ) -- Sentrybuster does 600 damage, and has a larger radius
                end

                local selfDmg = DamageInfo()
                selfDmg:SetDamage( 1000 )
                selfDmg:SetDamageType( DMG_BLAST )
                selfDmg:SetAttacker( self )
                selfDmg:SetInflictor( wepent )
                self:TakeDamageInfo( selfDmg )

                wepent:EmitSound( detonateSnd, 90 )

                if wepent.SentryBusterMode then
                    util.ScreenShake(wepent:GetPos(),25,5,3,1000)
                    
                    ParticleEffect("fluidSmokeExpl_ring_mvm", wepent:GetPos(), wepent:GetAngles())
                    ParticleEffect("explosionTrail_seeds_mvm", wepent:GetPos(), wepent:GetAngles())
    
                    for _, v in ipairs(ents.FindInSphere(wepent:GetPos(), 1000)) do
                        if IsValid(v) and v:IsPlayer() then
                            v:ScreenFade(SCREENFADE.IN, Color(255, 255, 255, 255), 1.0, 0.1)
                        end
                    end
                end  
            end)

            return true
        end,

        islethal = true
    }
})