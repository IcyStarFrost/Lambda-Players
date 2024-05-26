local IsValid = IsValid

local CurTime = CurTime


table.Merge( _LAMBDAPLAYERSWEAPONS, {

    misc_meathook = {
        model = "models/lambdaplayers/weapons/w_meathook.mdl",
        origin = "Misc",
        prettyname = "Meat Hook",
        holdtype = "melee2",
        killicon = "lambdaplayers/killicons/icon_meathook",
        ismelee = true,
        bonemerge = true,
        keepdistance = 10,
        attackrange = 55,

        OnAttack = function( self, wepent, target )
            self.l_WeaponUseCooldown = CurTime() + LambdaRNG( 1.0, 1.2, true )
            wepent:EmitSound( "Zombie.AttackMiss" )

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            local attackAnim = self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            self:SetLayerPlaybackRate( attackAnim, 0.8 )

            self:SimpleWeaponTimer( 0.4, function()
                if !IsValid( target ) or !self:IsInRange( target, 60 ) then return end

                local dmg = LambdaRNG( 45, 55 )
                local dmginfo = DamageInfo()
                dmginfo:SetDamage( dmg )
                dmginfo:SetAttacker( self )
                dmginfo:SetInflictor( wepent )
                dmginfo:SetDamageType( DMG_SLASH )
                dmginfo:SetDamageForce( ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * dmg )
                target:TakeDamageInfo( dmginfo )

                target:EmitSound( "lambdaplayers/weapons/meathook/hook-" .. LambdaRNG( 3 ) .. ".mp3", 70 )
            end )
            
            return true
        end,

        islethal = true,
    }

})