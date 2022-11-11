local random = math.random
local math_min = math.min
local CurTime = CurTime
local Rand = math.Rand
local IsValid = IsValid
local math_sqrt = math.sqrt
local NextLeapAttack = 0.5

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    zombieclaws = {
        model = "models/hunter/plates/plate.mdl",
        origin = "Misc",
        prettyname = "Zombie Claws",
        holdtype = "zombie",
        ismelee = true,
        nodraw = true,
        keepdistance = 10,
        attackrange = 75,
        addspeed = 100,
        
        -- HP Auto Regen + Leap Attack
        OnEquip = function( lambda, wepent )
            lambda:Hook( "Think", "ZombieClawsThink", function( )
                if lambda:Health() < lambda:GetMaxHealth() then
                    lambda:SetHealth( math_min( lambda:Health() + 1, lambda:GetMaxHealth() ) )
                end

                if NextLeapAttack and CurTime() > NextLeapAttack then
                    local target = lambda:GetEnemy()
                    if IsValid( target ) then
                        local distTarget = lambda:GetRangeSquaredTo( target )
                        if distTarget > ( 300 * 300 ) and distTarget <= ( 600 * 600 ) and lambda.loco:IsOnGround() and target:Visible( lambda ) then
                            lambda.loco:Jump()

                            local jumpDir = ( target:GetPos() - lambda:GetPos() ):GetNormalized()
                            lambda.loco:SetVelocity( Vector( 0, 0, 400 ) + jumpDir * math_min( math_sqrt( distTarget ) * 0.4, 512))

                            lambda:EmitSound( "npc/fast_zombie/fz_scream1.wav", 80, lambda.VoicePitch)
                            NextLeapAttack = CurTime() + 5
                        end
                    end
                end
            end, nil, 0.5)
        end,

        -- Damage reduction
        OnDamage = function( lambda, wepent, dmginfo )
            if IsValid( lambda ) then
                dmginfo:ScaleDamage( 0.75 )
            end
        end,
        
        OnUnequip = function( lambda, wepent )
            lambda:RemoveHook( "Think", "ZombieClawsThink" )
        end,
        
        callback = function( self, wepent, target )
            self.l_WeaponUseCooldown = CurTime() + 1.25

            wepent:EmitSound( "npc/zombie/zo_attack"..random(2)..".wav", 70, self.VoicePitch, 1, CHAN_WEAPON )
            
            self:RemoveGesture( ACT_GMOD_GESTURE_RANGE_ZOMBIE )
            self:AddGesture( ACT_GMOD_GESTURE_RANGE_ZOMBIE )
            
            -- To make sure damage syncs with the animation
            self:SimpleTimer( 0.75, function()
                if self:GetRangeSquaredTo( target ) > ( 65 * 65 ) then wepent:EmitSound("npc/zombie/claw_miss"..random(2)..".wav", 70) return end
                
                local dmg = random( 35, 55 )
                local dmginfo = DamageInfo()
                dmginfo:SetDamage( dmg )
                dmginfo:SetAttacker( self )
                dmginfo:SetInflictor( wepent )
                dmginfo:SetDamageType( DMG_SLASH )
                dmginfo:SetDamageForce( ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * dmg )
                
                target:EmitSound( "npc/zombie/claw_strike"..random(3)..".wav", 70)
                
                -- HP regen on attacks
                if self:Health() < self:GetMaxHealth() * 2.25 and LambdaIsValid( target ) then
                    self:SetHealth( math_min( self:Health() + self:GetMaxHealth() * Rand( 0.10, 0.20 ), self:GetMaxHealth() * 2.25 ) )
                end
                
                target:TakeDamageInfo( dmginfo )
            end)
            
            return true
        end,
        
        islethal = true,
    }

})