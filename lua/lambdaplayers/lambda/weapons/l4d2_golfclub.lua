local random = math.random
local CurTime = CurTime
local Rand = math.Rand

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    l4d2_golfclub = {
        model = "models/lambdaplayers/left4dead2_laststand/w_golfclub.mdl",
        origin = "Left 4 Dead 2",
        prettyname = "[L4D2] Golf Club",
        holdtype = "melee2",
        ismelee = true,
        bonemerge = false,
        keepdistance = 10,
        attackrange = 70,
                
        callback = function( self, wepent, target )
            self.l_WeaponUseCooldown = CurTime() + Rand(1.0,1.15)

            wepent:EmitSound('lambdaplayers/weapons/left4dead2/golf_club/wpn_golf_club_swing_miss_0'..math.random(2)..'.wav', 65)
            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )

            //add deploy sound later
            //make them fly later
            
            self:SimpleTimer( 0.3, function()
                if self:GetRangeSquaredTo( target ) > ( 70 * 70 ) then return end
                
                local dmg = random( 25,75 )
                local dmginfo = DamageInfo()
                dmginfo:SetDamage( dmg )
                dmginfo:SetAttacker( self )
                dmginfo:SetInflictor( wepent )
                dmginfo:SetDamageType( DMG_CLUB )
                dmginfo:SetDamageForce( ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * dmg )
                
                target:EmitSound('lambdaplayers/weapons/left4dead2/golf_club/wpn_golf_club_melee_0'..math.random(2)..'.wav', 80)
                
                target:TakeDamageInfo( dmginfo )
            end)
            
            return true
        end,

        islethal = true,
    }

})