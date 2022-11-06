local random = math.random
table.Merge( _LAMBDAPLAYERSWEAPONS, {
-- Missing firstSwing to simulate CSS knife better.

    css_knife = {
        model = "models/weapons/w_knife_t.mdl",
        origin = "Counter Strike: Source",
        prettyname = "Knife",
        holdtype = "knife",
        ismelee = true,
        bonemerge = true,
        keepdistance = 10,
        attackrange = 50,
		
		OnEquip = function( lambda, wepent )
            wepent:EmitSound("weapons/knife/knife_deploy1.wav")
        end,

        rateoffire = 0.5,
        attackanim = ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE,
        attacksnd = "weapons/knife/knife_slash*2*.wav",
        hitsnd = "weapons/knife/knife_hit*4*.wav",
		
		callback = function( self, wepent, target )
			--local firstSwing = false
			local backstabCheck = self:WorldToLocalAngles(target:GetAngles() + Angle(0,-90,0))
			
            self.l_WeaponUseCooldown = CurTime() + 0.5
            print(self.l_WeaponUseCooldown)
            print(CurTime())
            
            --if CurTime() > self.l_WeaponUseCooldown + 0.4 then firstSwing = true end

			local isBackstab = false
			--local dmg = (firstSwing and 20 or 15)
            local dmg = 15
            
            wepent:EmitSound( "weapons/knife/knife_slash"..random(2)..".wav", 70, 100, 1, CHAN_WEAPON )
			if backstabCheck.y < -30 and backstabCheck.y > -140 then
				isBackstab = true
				dmg = 195
				target:EmitSound("weapons/knife/knife_stab.wav", 80)
			end

            local dmginfo = DamageInfo() 
            dmginfo:SetDamage( dmg )
            dmginfo:SetAttacker( self )
            dmginfo:SetInflictor( wepent )
            dmginfo:SetDamageType( DMG_SLASH )
            dmginfo:SetDamageForce( ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * dmg )
            print(dmg)

			self.l_WeaponUseCooldown = CurTime() + (isBackstab and 1.0 or 0.5)
            target:EmitSound( "weapons/knife/knife_hit"..random(4)..".wav", 70 )

            target:TakeDamageInfo( dmginfo )

            return true
        end,

        islethal = true,
    }

})