local random = math.random
local CurTime = CurTime

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    pan = {
        model = "models/lambdaplayers/pan/w_pan.mdl",
        origin = "Misc",
        prettyname = "Frying Pan",
        holdtype = "melee",
        ismelee = true,
        bonemerge = true,
        keepdistance = 10,
        attackrange = 70,
        
        callback = function( self, wepent, target )
            self.l_WeaponUseCooldown = CurTime() + 0.5

            wepent:EmitSound( "lambdaplayers/weapons/pan/melee_pan_miss1.mp3", 70, random(98,102), 1, CHAN_WEAPON )
            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE )
            
            -- To make sure damage syncs with the animation
            self:SimpleTimer(0.25, function()
                if self:GetRangeSquaredTo( target ) > ( 70 * 70 ) then return end
                
                local dmg = DamageInfo()
                dmg:SetDamage( 15 )
                dmg:SetAttacker( self )
                dmg:SetInflictor( wepent )
                dmg:SetDamageType( DMG_CLUB )
                dmg:SetDamageForce( ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * 15 )
                
                target:EmitSound("lambdaplayers/weapons/pan/melee_pan_hit"..random(4)..".mp3", 70)
                
                target:TakeDamageInfo( dmg )
            end)
            
            return true
        end,

        islethal = true,
    }

})