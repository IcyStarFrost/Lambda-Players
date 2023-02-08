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

local busterMode = CreateLambdaConvar( "lambdaplayers_weapons_paigsentrybuster", 0, true, false, true, "If Lambda that spawn with the PAIG have the ability to act like the Sentry Buster from TF2.", 0, 1, { type = "Bool", name = "PAIG - Enable Sentry Buster Mode", category = "Weapon Utilities" } )

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

        OnEquip = function( self, wepent )
            wepent.SentryBusterMode = busterMode:GetBool()
            if !wepent.SentryBusterMode then return end
            
            wepent:EmitSound( "lambdaplayers/weapons/paig/sb_intro.mp3" )
           
            wepent.LoopSound = CreateSound( wepent, "lambdaplayers/weapons/paig/sb_loop.wav" ) -- Looping only works on .WAV formats, unfortunately
            if wepent.LoopSound then wepent.LoopSound:Play() end

            wepent:CallOnRemove( "Lambda_PAIG_StopSound" .. wepent:EntIndex(), function() 
                wepent:StopSound( "lambdaplayers/weapons/paig/sb_intro.mp3" )
                wepent:StopSound( "lambdaplayers/weapons/paig/sb_spin.mp3" )
                if wepent.LoopSound then wepent.LoopSound:Stop(); wepent.LoopSound = nil end 
            end )

            wepent:LambdaHookTick( "Lambda_PAIG_SentryBusterThink", function() 
                local loopSnd = wepent.LoopSound
                if !loopSnd then return true end

                if !LambdaIsValid( self ) or CurTime() <= self.l_WeaponUseCooldown then 
                    loopSnd:Stop() 
                elseif !loopSnd:IsPlaying() then
                    loopSnd:Play()
                end 
            end )
        end,

        OnUnequip = function( self, wepent )
            wepent.SentryBusterMode = nil
            wepent:StopSound( "lambdaplayers/weapons/paig/sb_intro.mp3" )
            wepent:StopSound( "lambdaplayers/weapons/paig/sb_spin.mp3" )
            if wepent.LoopSound then wepent.LoopSound:Stop(); wepent.LoopSound = nil end
        end,

        callback = function( self, wepent, target )
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
                if v != self and LambdaIsValid( v ) and v:IsInRange( self, 400 ) and v:CanTarget( self ) and ( wepent.SentryBusterMode or v:CanSee( self ) ) then
                    v:SimpleTimer( Rand( 0.0, 0.25 ), function() v:RetreatFrom( self, 1.0 + detonateTime ) end)
                end
            end

            self.l_WeaponUseCooldown = CurTime() + 1 + detonateTime

            self:SimpleTimer( detonateTime - 0.3, function()
                if !IsValid( wepent ) or self:GetWeaponName() != "paig" then return end
                wepent:EmitSound( "WeaponFrag.Throw", 70 )
                
                self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
                self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
            end )

            self:SimpleTimer( detonateTime, function()
                if !IsValid( wepent ) or self:GetWeaponName() != "paig" then return end

                local blowPos = self:GetAttachmentPoint( "hand" ).Pos

                local effectData = EffectData()
                effectData:SetOrigin( blowPos )
                Effect( "Explosion", effectData, true, true )

                BlastDamage( wepent, self, blowPos, 400, 1000 )

                local selfDmg = DamageInfo()
                selfDmg:SetDamage( 1000 )
                selfDmg:SetDamageType( DMG_BLAST )
                selfDmg:SetAttacker( self )
                selfDmg:SetInflictor( wepent )
                self:TakeDamageInfo( selfDmg )

                wepent:EmitSound( detonateSnd, 90 )
            end)

            return true
        end,

        islethal = true
    }
})