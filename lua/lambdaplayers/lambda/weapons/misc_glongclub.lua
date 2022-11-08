local random = math.random
local CurTime = CurTime
local Rand = math.Rand

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    longdriver = {
        model = "models/lambdaplayers/glongclub/w_golfclub_long.mdl",
        origin = "Misc",
        prettyname = "Comically Long Golf Club",
        holdtype = "melee2",
        ismelee = true,
        bonemerge = true,
        keepdistance = 64,
        attackrange = 150,

        callback = function( self, wepent, target )
            self.l_WeaponUseCooldown = CurTime() + Rand(1.33, 1.8)

            wepent:EmitSound( "lambdaplayers/weapons/glongclub/wpn_golf_club_swing_miss" .. random( 2 ) .. ".wav", 85, random( 95, 110 ), 1, CHAN_WEAPON )
            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            local gestAttack = self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            self:SetLayerPlaybackRate(gestAttack, 0.75)

            self:SimpleTimer(0.45, function()
                if !IsValid( target ) or self:GetRangeSquaredTo( target ) > ( 150 * 150 ) then return end

                local dmg = random( 500, 750 )
                local attackAng = ( target:WorldSpaceCenter() - self:EyePos() ):Angle()
                local attackForce = ( attackAng:Forward() * ( dmg * 200 ) + attackAng:Up() * ( dmg * 200 ) )
                local dmginfo = DamageInfo()
                dmginfo:SetDamage( dmg )
                dmginfo:SetAttacker( self )
                dmginfo:SetInflictor( wepent )
                dmginfo:SetDamageType( bit.bor( DMG_CLUB, DMG_CRUSH ) )
                
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

                wepent:EmitSound( "lambdaplayers/weapons/glongclub/wpn_golf_club_melee_0" .. random( 2 ) .. ".wav", 90 )
            end)

            return true
        end,

        islethal = true,
    }

} )