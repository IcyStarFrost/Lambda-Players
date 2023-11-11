local CurTime = CurTime
local IsValid = IsValid
local min = math.min
local max = math.max

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    gmod_medkit = {
        model = "models/weapons/w_medkit.mdl",
        origin = "Garry's Mod",
        prettyname = "Medkit",
        holdtype = "slam",
        bonemerge = true,
        dropentity = "weapon_medkit",
        islethal = false,

        OnDeploy = function( self, wepent ) 
            wepent.l_MedkitHeals = ( wepent.l_MedkitHeals or 100 )
            if self:HookExists( "Think", "MedkitWepHealRegen" ) then return end

            self:Hook( "Think", "MedkitWepHealRegen", function()
                if !IsValid( wepent ) then return "end" end
                if !self:Alive() then wepent.l_MedkitHeals = 100; return end
                wepent.l_MedkitHeals = min( wepent.l_MedkitHeals + 2, 100 )
            end, true, 0.33 )
        end,

        OnThink = function( self, wepent, dead )
            if !dead and self:Health() < self:GetMaxHealth() then self:UseWeapon( self ) end
        end,

        OnAttack = function( self, wepent, target )
            if wepent.l_MedkitHeals == 0 then return true end

            local hp = target:Health()
            local maxHp = target:GetMaxHealth()
            if hp >= maxHp then return true end

            local healNeed = min( maxHp - hp, 20 )
            if wepent.l_MedkitHeals < healNeed then return true end

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM )

            target:SetHealth( min( hp + healNeed, maxHp ) )
            wepent:EmitSound( "HealthKit.Touch" )

            self.l_WeaponUseCooldown = ( CurTime() + 2.166748046875 )
            wepent.l_MedkitHeals = max( 0, wepent.l_MedkitHeals - healNeed )

            return true
        end,
    }
} )