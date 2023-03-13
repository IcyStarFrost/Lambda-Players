local random = math.random
local CurTime = CurTime
local Rand = math.Rand
local DamageInfo = DamageInfo

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    l4d2_golfclub = {
        model = "models/lambdaplayers/weapons/w_golfclub.mdl",
        origin = "Left 4 Dead 2",
        prettyname = "Golf Club",
        holdtype = "melee2",
        killicon = "lambdaplayers/killicons/icon_golfclub",
        ismelee = true,
        keepdistance = 10,
        attackrange = 70,
        bonemerge = true,

        OnDeploy = function( self, wepent )
            wepent:EmitSound( "lambdaplayers/weapons/left4dead2/generic_melee_equip.mp3", 65 )
        end,

        OnAttack = function( self, wepent, target )
            self.l_WeaponUseCooldown = CurTime() + Rand( 1.0, 1.15 )
            wepent:EmitSound( "lambdaplayers/weapons/left4dead2/golf_club/wpn_golf_club_swing_miss_0" .. random( 1, 2 ) .. ".mp3", 65 )

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            
            self:SimpleWeaponTimer( 0.3, function()
                if !LambdaIsValid( target ) or !self:IsInRange( target, 70 ) then return end

                local dmg = random( 25, 75 )
                local dmgAng = ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):Angle()

                local dmginfo = DamageInfo()
                dmginfo:SetDamage( dmg )
                dmginfo:SetAttacker( self )
                dmginfo:SetInflictor( wepent )
                dmginfo:SetDamageType( DMG_CLUB )
                dmginfo:SetDamageForce( dmgAng:Forward() * ( dmg * 150 ) + dmgAng:Up() * ( dmg * 125 ) )

                target:TakeDamageInfo( dmginfo )
                target:EmitSound( "lambdaplayers/weapons/left4dead2/golf_club/wpn_golf_club_melee_0" .. random( 1, 2 ) .. ".mp3" )
            end)

            return true
        end,

        islethal = true
    }
})