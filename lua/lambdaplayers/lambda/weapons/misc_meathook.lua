local random = math.random
table.Merge( _LAMBDAPLAYERSWEAPONS, {

    meathook = {
        model = "models/lambdaplayers/meathook/w_meathook.mdl",
        origin = "Misc",
        prettyname = "Meat Hook",
        holdtype = "melee2",
        ismelee = true,
        bonemerge = true,
        keepdistance = 10,
        attackrange = 65,
                
        callback = function( self, wepent, target )
            self.l_WeaponUseCooldown = CurTime() + math.Rand(1.0, 1.2)

            wepent:EmitSound( "npc/zombie/claw_miss1.wav", 70, 100, 1, CHAN_WEAPON )
            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            
            -- To make sure damage syncs with the animation
            self:SimpleTimer(0.3, function()
                if self:GetRangeTo(target) > (65) then return end
                
                local dmg = random(40,50)
                local dmginfo = DamageInfo()
                dmginfo:SetDamage(dmg)
                dmginfo:SetAttacker(self)
                dmginfo:SetInflictor(wepent)
                dmginfo:SetDamageType(DMG_SLASH)
                dmginfo:SetDamageForce( ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * dmg )
                
                target:EmitSound("lambdaplayers/meathook/hook-"..random(3)..".wav", 70)
                
                target:TakeDamageInfo( dmginfo )
            end)
            
            return true
        end,

        islethal = true,
    }

})