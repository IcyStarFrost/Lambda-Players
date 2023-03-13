local CurTime = CurTime
local min = math.min
local max = math.max

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    gmod_medkit = {
        model = "models/weapons/w_medkit.mdl",
        origin = "Garry's Mod",
        prettyname = "Medkit",
        holdtype = "slam",
        bonemerge = true,
        clip = 1,

        OnDeploy = function( self, wepent ) 
            wepent.HealAmount = 100
        end,
        
        OnHolster = function( self, wepent ) 
            wepent.HealAmount = nil
        end,

        OnThink = function( self, wepent, dead )
            if !dead then
                wepent.HealAmount = min( wepent.HealAmount + 2, 100 )
                if self:Health() < self:GetMaxHealth() then self:UseWeapon( self ) end
            end
            return 0.33
        end,

        OnDeath = function( self, wepent )
            wepent.HealAmount = 100
        end,

        OnAttack = function( self, wepent, target )
            if wepent.HealAmount == 0 then return true end

            local hp = target:Health()
            local maxHp = target:GetMaxHealth()
            if hp >= maxHp then return true end

            local healNeed = min( maxHp - hp, 20 )
            if wepent.HealAmount < healNeed then return true end

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM )

            target:SetHealth( min( hp + healNeed, maxHp ) )
            wepent:EmitSound( "HealthKit.Touch" )

            self.l_WeaponUseCooldown = CurTime() + 2.166748046875
            wepent.HealAmount = max( 0, wepent.HealAmount - healNeed )

            return true
        end,

        islethal = false
    }
} )