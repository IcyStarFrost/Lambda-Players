local random = math.random
local math_min = math.min
local CurTime = CurTime
local Rand = math.Rand
local IsValid = IsValid
local math_sqrt = math.sqrt
local PlaySound = sound.Play

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    zombieclaws = {
        model = "models/hunter/plates/plate.mdl",
        origin = "Misc",
        prettyname = "Zombie Claws",
        holdtype = "zombie",
        killicon = "lambdaplayers/killicons/icon_zclaws",
        ismelee = true,
        nodraw = true,
        keepdistance = 10,
        attackrange = 75,
        addspeed = 100,

        -- HP Auto Regen + Leap Attack
        OnEquip = function( lambda, wepent )
            wepent.NextLeapAttackTime = CurTime()

            lambda:Hook( "Think", "ZombieClawsThink", function( )
                if lambda:Health() < lambda:GetMaxHealth() then
                    lambda:SetHealth( math_min( lambda:Health() + 1, lambda:GetMaxHealth() ) )
                end

                if lambda:GetState() == "Combat" and CurTime() > wepent.NextLeapAttackTime then
                    local target = lambda:GetEnemy()
                    if LambdaIsValid( target ) then
                        local distTarget = lambda:GetRangeSquaredTo( target )
                        if distTarget > ( 300 * 300 ) and distTarget <= ( 600 * 600 ) and lambda.loco:IsOnGround() and lambda:Visible( target ) and target:Visible( lambda ) then
                            lambda.loco:Jump()

                            local jumpDir = ( target:GetPos() - lambda:GetPos() ):Angle()
                            lambda.loco:SetVelocity( jumpDir:Up() * 400 + jumpDir:Forward() * math_min( math_sqrt( distTarget ) * 1.5, 1024 ) )

                            lambda:EmitSound( "npc/fast_zombie/fz_scream1.wav", 80, lambda:GetVoicePitch() )
                            wepent.NextLeapAttackTime = CurTime() + 5
                        end
                    end
                end
            end, false, 0.5)
        end,

        -- Damage reduction
        OnDamage = function( lambda, wepent, dmginfo )
            dmginfo:ScaleDamage( 0.75 )
        end,

        OnUnequip = function( lambda, wepent )
            lambda:RemoveHook( "Think", "ZombieClawsThink" )
            wepent.NextLeapAttackTime = nil
        end,

        callback = function( self, wepent, target )
            self.l_WeaponUseCooldown = CurTime() + 1.25
            self:EmitSound( "npc/zombie/zo_attack" .. random(2) .. ".wav", 70, self:GetVoicePitch(), 1, CHAN_WEAPON )

            self:RemoveGesture( ACT_GMOD_GESTURE_RANGE_ZOMBIE )
            local attackAnim = self:AddGesture( ACT_GMOD_GESTURE_RANGE_ZOMBIE )
            self:SetLayerPlaybackRate( attackAnim, 1.5 ) -- Sped up attack animation

            -- To make sure damage syncs with the animation
            self:SimpleTimer( 0.5, function()
                if !LambdaIsValid( target ) or self:GetRangeSquaredTo( target ) > ( 65 * 65 ) then 
                    wepent:EmitSound( "Zombie.AttackMiss" ) 
                    return 
                end

                local dmg = random( 35, 55 )
                local dmginfo = DamageInfo()
                dmginfo:SetDamage( dmg )
                dmginfo:SetAttacker( self )
                dmginfo:SetInflictor( wepent )
                dmginfo:SetDamageType( DMG_SLASH )
                dmginfo:SetDamageForce( ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * dmg )

                local targetPrevHP = target:Health()
                target:TakeDamageInfo( dmginfo )
                PlaySound( "Zombie.AttackHit", target:WorldSpaceCenter() )

                -- Steal target's HP on successful hit
                local maxHP = self:GetMaxHealth() * 2.25
                if target:Health() < targetPrevHP and self:Health() < maxHP then
                    self:SetHealth( math_min( self:Health() + ( targetPrevHP - target:Health() ), maxHP ) )
                end
            end)

            return true
        end,
        
        islethal = true,
    }

})