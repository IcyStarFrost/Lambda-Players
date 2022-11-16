local random = math.random
local CurTime = CurTime
local Rand = math.Rand

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    l4d2_golfclub = {
        model = "models/lambdaplayers/left4dead2_laststand/w_golfclub.mdl",
        origin = "Left 4 Dead 2",
        prettyname = "Golf Club",
        holdtype = "melee2",
        killicon = "lambdaplayers/killicons/icon_golfclub",
        ismelee = true,
        bonemerge = false,
        keepdistance = 10,
        attackrange = 70,
                
        callback = function( self, wepent, target )
            self.l_WeaponUseCooldown = CurTime() + Rand( 1.0, 1.15 )

            wepent:EmitSound( "lambdaplayers/weapons/left4dead2/golf_club/wpn_golf_club_swing_miss_0"..random(2)..".mp3", 65 )
            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )

            //add deploy sound later
            //make them fly later
            
            self:SimpleTimer( 0.3, function()
                if self:GetRangeSquaredTo( target ) > ( 70 * 70 ) then return end
                
                local dmg = random( 25, 75 )
                local dmginfo = DamageInfo()
                dmginfo:SetDamage( dmg )
                dmginfo:SetAttacker( self )
                dmginfo:SetInflictor( wepent )
                dmginfo:SetDamageType( DMG_CLUB )
                dmginfo:SetDamageForce( ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * dmg )
                
                target:EmitSound( "lambdaplayers/weapons/left4dead2/golf_club/wpn_golf_club_melee_0"..random(2)..".mp3", 80 )
                
                target:TakeDamageInfo( dmginfo )
            end)
            
            return true
        end,

        islethal = true,
    }

})