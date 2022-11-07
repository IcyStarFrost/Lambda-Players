local random = math.random
local CurTime = CurTime

table.Merge( _LAMBDAPLAYERSWEAPONS, {
-- Missing firstSwing to simulate CSS knife better.

    knife = {
        model = "models/weapons/w_knife_t.mdl",
        origin = "Counter Strike: Source",
        prettyname = "Knife",
        holdtype = "knife",
        ismelee = true,
        bonemerge = true,
        keepdistance = 10,
        attackrange = 50,
        
        OnEquip = function( lambda, wepent )
            wepent:EmitSound( "weapons/knife/knife_deploy1.wav", 70, random(95,105), 1, CHAN_WEAPON  )
        end,

        callback = function( self, wepent, target )
            local backstabCheck = self:WorldToLocalAngles(target:GetAngles() + Angle(0,-90,0))
            
            self.l_WeaponUseCooldown = CurTime() + 0.5
            
            local isBackstab = false
            local dmg = 15

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE )
            
            wepent:EmitSound( "weapons/knife/knife_slash"..random(2)..".wav", 70, 100, 1, CHAN_WEAPON )
            if backstabCheck.y < -30 and backstabCheck.y > -140 then
                isBackstab = true
                dmg = 195
                target:EmitSound( "weapons/knife/knife_stab.wav", 80, random(95,105), 1, CHAN_WEAPON )
            end

            local dmginfo = DamageInfo() 
            dmginfo:SetDamage( dmg )
            dmginfo:SetAttacker( self )
            dmginfo:SetInflictor( wepent )
            dmginfo:SetDamageType( DMG_SLASH )
            dmginfo:SetDamageForce( ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * dmg )

            self.l_WeaponUseCooldown = CurTime() + (isBackstab and 1.0 or 0.5)
            target:EmitSound( "weapons/knife/knife_hit"..random(4)..".wav", 70 )

            target:TakeDamageInfo( dmginfo )

            return true
        end,

        islethal = true,
    }

})