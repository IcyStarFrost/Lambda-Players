local random = math.random
local math_min = math.min
local CurTime = CurTime
local Rand = math.Rand

table.Merge( _LAMBDAPLAYERSWEAPONS, {
-- Missing leap attack and HP on kill

    zombieclaws = {
        model = "models/hunter/plates/plate.mdl",
        origin = "Misc",
        prettyname = "Zombie Claws",
        holdtype = "zombie",
        ismelee = true,
        nodraw = true,
        keepdistance = 30,
        attackrange = 65,
        addspeed = 100,
        
        OnEquip = function( lambda, wepent )
            local NextHPRegenTime = CurTime() + 0.5
            
            -- Damage reduction
            lambda:Hook( "EntityTakeDamage", "ZombieClawsScaleDamage", function( target, dmginfo )
                if target == lambda then
                    dmginfo:ScaleDamage( 0.75 )
                end
            end)
            
            -- HP Auto Regen
            lambda:Hook( "Think", "ZombieClawsThink", function( )
                if NextHPRegenTime and CurTime() > NextHPRegenTime and lambda:Health() < lambda:GetMaxHealth() then
                    lambda:SetHealth(math_min(lambda:Health() + 1, lambda:GetMaxHealth()))
                    NextHPRegenTime = CurTime() + 0.5
                end
            end)
        end,
        
        OnUnequip = function( lambda, wepent )
            lambda:RemoveHook( "EntityTakeDamage", "ZombieClawsScaleDamage" )
            lambda:RemoveHook( "Think", "ZombieClawsThink" )
        end,
        
        callback = function( self, wepent, target )
            self.l_WeaponUseCooldown = CurTime() + 1.25

            wepent:EmitSound( "npc/zombie/zo_attack"..random(2)..".wav", 70, 100, 1, CHAN_WEAPON )
            self:RemoveGesture( ACT_GMOD_GESTURE_RANGE_ZOMBIE )
            self:AddGesture( ACT_GMOD_GESTURE_RANGE_ZOMBIE )
            
            -- To make sure damage syncs with the animation
            self:SimpleTimer(0.75, function()
                if self:GetRangeSquaredTo(target) > (65 * 65) then wepent:EmitSound("npc/zombie/claw_miss"..random(2)..".wav", 70) return end
                
                local dmg = random(35,55)
                local dmginfo = DamageInfo()
                dmginfo:SetDamage(dmg)
                dmginfo:SetAttacker(self)
                dmginfo:SetInflictor(wepent)
                dmginfo:SetDamageType(DMG_SLASH)
                dmginfo:SetDamageForce( ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * dmg )
                
                target:EmitSound("npc/zombie/claw_strike"..random(3)..".wav", 70)
                
                -- HP regen on attacks
                if self:Health() < self:GetMaxHealth() * 2.25 and LambdaIsValid( target ) then
                    self:SetHealth(math_min(self:Health() + self:GetMaxHealth() * Rand(0.10, 0.25), self:GetMaxHealth() * 2.25))
                end
                
                target:TakeDamageInfo( dmginfo )
            end)
            
            return true
        end,
        
        islethal = true,
    }

})