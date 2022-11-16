local random = math.random
local CurTime = CurTime
local backstabCvar = CreateLambdaConvar( "lambdaplayers_weapons_knifebackstab", 1, true, false, true, "If Lambda Players should be allowed to use the backstab feature of the Knife.", 0, 1, { type = "Bool", name = "Knife - Enable Backstab", category = "Weapon Utilities" } )

table.Merge( _LAMBDAPLAYERSWEAPONS, {

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
            wepent.IsFirstSwing = true
            wepent.NextFirstSwingTime = CurTime()
            wepent:EmitSound( "Weapon_Knife.Deploy" )
        end,

        OnUnequip = function( lambda, wepent )
            wepent.IsFirstSwing = nil
            wepent.NextFirstSwingTime = nil
        end,

        callback = function( self, wepent, target )
            if CurTime() > wepent.NextFirstSwingTime then
                wepent.IsFirstSwing = true
            end

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE )

            local slashSnd = "Weapon_Knife.Hit"
            local slashDmg = ( wepent.IsFirstSwing and 20 or 15 )
            if backstabCvar:GetBool() then
                local backstabCheck = self:WorldToLocalAngles( target:GetAngles() + Angle( 0, -90, 0 ) ).y
                if backstabCheck < -30 and backstabCheck > -140 then
                    slashDmg = 195
                    slashSnd = "Weapon_Knife.Stab"
                end
            end

            local dmginfo = DamageInfo() 
            dmginfo:SetDamage( slashDmg )
            dmginfo:SetAttacker( self )
            dmginfo:SetInflictor( wepent )
            dmginfo:SetDamageType( DMG_SLASH )
            dmginfo:SetDamageForce( ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * slashDmg )
            target:TakeDamageInfo( dmginfo )

            wepent:EmitSound( slashSnd )
            self.l_WeaponUseCooldown = CurTime() + ( slashDmg == 195 and 1.0 or 0.5 )

            wepent.IsFirstSwing = false
            wepent.NextFirstSwingTime = self.l_WeaponUseCooldown + 0.4

            return true
        end,

        islethal = true
    }

})