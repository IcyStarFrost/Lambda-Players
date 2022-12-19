local CurTime = CurTime
local IsValid = IsValid
local Effect = util.Effect
local BlastDamage = util.BlastDamage
--local Rand = math.Rand
--local convar = CreateLambdaConvar( "lambdaplayers_weapons_paigsentrybuster", 0, true, false, true, "If Lambda that spawn with the PAIG have the ability to act like the Sentry Buster from TF2.", 0, 1, { type = "Bool", name = "PAIG - Enable Sentry Buster Mode", category = "Weapon Utilities" } )

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

        callback = function( self, wepent, target )
            self.l_WeaponUseCooldown = CurTime() + 4

            wepent:EmitSound( "WeaponFrag.Throw", 70 )

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )

            --[[for _, v in ipairs( ents.FindByClass( "npc_lambdaplayer" ) ) do
                if v != self and v:IsInRange( self, 400 ) and v:Visible( self ) and LambdaIsValid( v ) then
                    v:SimpleTimer( Rand( 0.1, 0.5 ), function()
                        if LambdaIsValid( v ) then return end
                        --v:SetState( "Panic" )
                        --v:GetRandomSound()
                        --Play random scream
                    end)
                end
            end]]

            self:SimpleTimer( 0.3, function()
                if !IsValid( wepent ) then return end

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

                wepent:EmitSound( "BaseExplosionEffect.Sound" , 90 )
            end)

            return true
        end,

        islethal = true,
    }

})