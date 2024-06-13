
local CurTime = CurTime
local IsValid = IsValid


table.Merge( _LAMBDAPLAYERSWEAPONS, {

    misc_longdriver = {
        model = "models/lambdaplayers/weapons/w_golfclub_long.mdl",
        origin = "Misc",
        prettyname = "Comically Long Golf Club",
        holdtype = "melee2",
        killicon = "lambdaplayers/killicons/icon_golfclub",
        ismelee = true,
        bonemerge = true,
        keepdistance = 64,
        attackrange = 175,

        OnAttack = function( self, wepent, target )
            self.l_WeaponUseCooldown = CurTime() + LambdaRNG( 1.33, 1.8, false )
            wepent:EmitSound( "lambdaplayers/weapons/glongclub/wpn_golf_club_swing_miss" .. LambdaRNG( 2 ) .. ".mp3", 85, LambdaRNG( 95, 110 ), 1, CHAN_WEAPON )

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            local gestAttack = self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            self:SetLayerPlaybackRate( gestAttack, 0.75 )

            self:SimpleWeaponTimer( 0.45, function()
                if !IsValid( target ) or !self:IsInRange( target, 200 ) then return end

                local dmg = LambdaRNG( 500, 750 )
                local attackAng = ( target:WorldSpaceCenter() - self:EyePos() ):Angle()
                local attackForce = ( attackAng:Forward() * ( dmg * 200 ) + attackAng:Up() * ( dmg * 200 ) )
                local dmginfo = DamageInfo()
                dmginfo:SetDamage( dmg )
                dmginfo:SetAttacker( self )
                dmginfo:SetInflictor( wepent )
                dmginfo:SetDamageType( DMG_CLUB + DMG_CRUSH )
                
                -- Doesn't send them flying if not done like this
                if target.IsLambdaPlayer then
                    target.loco:Jump()
                    target.loco:SetVelocity( target.loco:GetVelocity() + ( attackForce * 0.01 ) )
                    timer.Simple(0.1, function()
                        if !LambdaIsValid( target ) then return end
                        target:TakeDamageInfo( dmginfo )
                    end)
                else
                    dmginfo:SetDamageForce( attackForce )
                    target:TakeDamageInfo( dmginfo )
                end

                wepent:EmitSound( "lambdaplayers/weapons/glongclub/wpn_golf_club_melee_0" .. LambdaRNG( 2 ) .. ".mp3", 90 )
            end )

            return true
        end,

        islethal = true,
    }

} )