local CurTime = CurTime
local Rand = math.Rand
local Effect = util.Effect
local BlastDamage = util.BlastDamage
--local convar = CreateLambdaConvar( "lambdaplayers_weapons_paigsentrybuster", 0, true, true, true, "If Lambda that spawn with the PAIG have the ability to act like the Sentry Buster from TF2.", 0, 1, { type = "Bool", name = "PAIG Sentry Buster", category = "Lambda Player Settings" } )
--local PAIGSentryBuster = GetConVar( "lambdaplayers_weapons_paigsentrybuster" ) or false

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    paig = {
        model = "models/weapons/w_grenade.mdl",
        origin = "Misc",
        prettyname = "Punch Activated Impact Grenade",
        holdtype = "grenade",
        ismelee = true,
        bonemerge = true,
        keepdistance = 5,
        attackrange = 50,
        addspeed = 50,
        
        OnEquip = function( lambda, wepent )
            --lambda:FindTarget()
        end,

        callback = function( self, wepent, target )
            self.l_WeaponUseCooldown = CurTime() + 4

            wepent:EmitSound( "WeaponFrag.Throw", 70 )

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )

            --[[for _, v in ipairs( ents.FindByClass( "npc_lambdaplayer" ) ) do
                if v != self and v:GetRangeSquaredTo ( self ) <= ( 400*400 ) and v:Visible( self ) and LambdaIsValid( v ) then
                    v:SimpleTimer( Rand( 0.1, 0.5 ), function()
                        if LambdaIsValid( v ) then return end
                        --v:SetState( "Panic" )
                        --v:GetRandomSound()
                        --Play random scream
                    end)
                end
            end]]
            
            self:SimpleTimer( 0.3, function()
                if !IsValid( self ) or !IsValid( wepent ) then return end
                
                local effect = EffectData()
                effect:SetOrigin( wepent:GetPos() )
                Effect( "Explosion", effect, true, true )
                
                BlastDamage( self, self, wepent:GetPos(), 400, 1000 )

                wepent:EmitSound( "BaseExplosionEffect.Sound" , 90 )

            end)
            
            return true
        end,

        islethal = true,
    }

})