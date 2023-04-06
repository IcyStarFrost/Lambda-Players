local IsValid = IsValid
local random = math.random
local CurTime = CurTime

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    misc_pan = {
        model = "models/lambdaplayers/weapons/w_pan.mdl",
        origin = "Misc",
        prettyname = "Frying Pan",
        holdtype = "melee",
        killicon = "lambdaplayers/killicons/icon_frying_pan",
        ismelee = true,
        bonemerge = true,
        keepdistance = 10,
        attackrange = 60,

        OnAttack = function( self, wepent, target )
            self.l_WeaponUseCooldown = CurTime() + 0.5
            wepent:EmitSound( "lambdaplayers/weapons/pan/melee_pan_miss1.mp3", 70, random( 98, 102 ), 1, CHAN_WEAPON )

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE )
            local attackAnim = self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE )
            self:SetLayerPlaybackRate( attackAnim, 1.25 )

            -- To make sure damage syncs with the animation
            self:SimpleWeaponTimer( 0.2, function()
                if !IsValid( target ) or !self:IsInRange( target, 50 ) then return end

                local dmg = random( 10, 20 )
                local dmginfo = DamageInfo()
                dmginfo:SetDamage( dmg )
                dmginfo:SetAttacker( self )
                dmginfo:SetInflictor( wepent )
                dmginfo:SetDamageType( DMG_CLUB )
                dmginfo:SetDamageForce( ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * dmg )
                target:TakeDamageInfo( dmginfo )

                target:EmitSound( "lambdaplayers/weapons/pan/melee_pan_hit" .. random( 4 ) .. ".mp3", 70)
            end )
            
            return true
        end,

        islethal = true
    }

})