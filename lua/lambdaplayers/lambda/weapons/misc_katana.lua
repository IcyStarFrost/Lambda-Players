local random = math.random
local CurTime = CurTime
local Rand = math.Rand
local util_Effect = util.Effect
local cos = math.cos
local IsValid = IsValid
local rad = math.rad
local blockCooldown = 0
-- local convar = CreateLambdaConvar( "lambdaplayers_weapons_katanamotivated", 0, true, false, true, "If Lambdas should bury the light deep within.", 0, 1, { type = "Bool", name = "Katana - Motivated Users", category = "Weapon Utilities" } )
local convar = CreateLambdaConvar( "lambdaplayers_weapons_katanablocking", 1, true, false, true, "If Lambdas should be able to block bullets.", 0, 1, { type = "Bool", name = "Katana - Blocking", category = "Weapon Utilities" } )

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    katana = {
        model = "models/lambdaplayers/katana/w_katana.mdl",
        origin = "Misc",
        prettyname = "Katana",
        holdtype = "melee2",
        ismelee = true,
        bonemerge = true,
        keepdistance = 10,
        attackrange = 70,
        addspeed = 50,

        OnEquip = function( lambda, wepent )
            --[[if GetConVar("lambdaplayers_weapons_katanamotivated"):GetBool() then
                wep:EmitSound( "lambdaplayers/weapons/katana/motivated/motivated"..random(1,20)..".mp3", 110 )
            end]]

            wepent:EmitSound( "lambdaplayers/weapons/katana/katana_deploy.mp3", 80 )

        end,

        -- Blocking
        OnDamage = function( lambda, wepent, dmginfo )
            if IsValid( lambda ) and GetConVar("lambdaplayers_weapons_katanablocking"):GetBool() then
                blockCooldown = blockCooldown or CurTime()
                local attacker = dmginfo:GetAttacker()

                if ( lambda:GetForward():Dot( ( attacker:GetPos() - lambda:GetPos() ):GetNormalized() ) <= cos( rad( 80 ) ) ) then return end
                
                local dmgType = ( dmginfo:IsBulletDamage() and 1 or ( dmginfo:GetDamageType() == DMG_GENERIC or dmginfo:GetDamageType() == DMG_CLUB or dmginfo:GetDamageType() == DMG_SLASH ) and 2 or 0 )
                if dmgType == 0 then return end -- We only block bullet/melee
                if CurTime() < blockCooldown then return end -- Can't block too fast

                dmginfo:ScaleDamage( Rand( random( 0.1, 0.2 ), 0.3 ) )
                
                lambda:RemoveGesture( ACT_HL2MP_FIST_BLOCK )
                lambda:AddGesture( ACT_HL2MP_FIST_BLOCK, false )

                lambda:SimpleTimer( 0.1, function () -- So we can pretend to block
                if !IsValid( lambda ) or !lambda:IsPlayingGesture( ACT_HL2MP_FIST_BLOCK ) then return end
                    lambda:RemoveGesture( ACT_HL2MP_FIST_BLOCK )
                end)

                local sparkPos = dmginfo:GetDamagePosition()
                if lambda:GetRangeSquaredTo( sparkPos ) > ( 150 * 150 ) then sparkPos = wepent:GetPos() end

                -- Blocking effect
                local sparkForward = ( ( attacker:WorldSpaceCenter() ) - sparkPos ):Angle():Forward()
                local effect = EffectData()
                    effect:SetOrigin( sparkPos + sparkForward * 20 )
                    effect:SetNormal( sparkForward )
                util_Effect( "StunstickImpact", effect, true, true )
                
                -- Fake bullet going somewhere to pretend we are deflecting the bullet
                if dmgType == 1 then
                    local trace = lambda:Trace( lambda:WorldSpaceCenter() + ( lambda:GetForward() + VectorRand( -100, 100 ) ) * 12000 )
                    local pos = trace.HitPos
                    local effect = EffectData()
                        effect:SetStart( effect:GetOrigin() )
                        effect:SetOrigin( pos )
                        effect:SetEntity( wepent )
                        effect:SetScale( 4000 )
                    util_Effect( "Tracer", effect, true, true)
                end

                if dmgType == 1 then
                    wepent:EmitSound( "lambdaplayers/weapons/katana/katana_deflect_bullet"..math.random(4)..".mp3", 70, math.random( 95, 110 ) )
                    blockCooldown = CurTime() + math.Rand(0, 0.3)
                else
                    wepent:EmitSound( "lambdaplayers/weapons/katana/katana_deflect_melee"..math.random(2)..".mp3", 70, math.random( 95, 110 ) )
                    blockCooldown = CurTime() + math.Rand(0.1, 0.6)
                end
            end
        end,
                
        callback = function( self, wepent, target )
            local cooldown = Rand(0.4, 1)
            self.l_WeaponUseCooldown = CurTime() + cooldown

            wepent:EmitSound( "lambdaplayers/weapons/katana/katana_swing_miss"..random(4)..".mp3", 65)

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            
            self:SimpleTimer( 0.075, function()
                if self:GetRangeSquaredTo( target ) > ( 70 * 70 ) then return end
                
                local dmg = 35 * ( cooldown / 0.8 )
                local dmginfo = DamageInfo()
                dmginfo:SetDamage( dmg )
                dmginfo:SetAttacker( self )
                dmginfo:SetInflictor( wepent )
                dmginfo:SetDamageType( DMG_SLASH )
                dmginfo:SetDamageForce( ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * dmg )
                
                target:EmitSound( "lambdaplayers/weapons/katana/katana_swing_hit"..random(3)..".mp3", 70 )
                
                target:TakeDamageInfo( dmginfo )
            end)
            
            return true
        end,

        islethal = true,
    }

})