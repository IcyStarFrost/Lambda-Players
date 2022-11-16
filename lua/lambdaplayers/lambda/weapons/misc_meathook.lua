local IsValid = IsValid
local random = math.random
local CurTime = CurTime
local Rand = math.Rand

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    meathook = {
        model = "models/lambdaplayers/meathook/w_meathook.mdl",
        origin = "Misc",
        prettyname = "Meat Hook",
        holdtype = "melee2",
        killicon = "lambdaplayers/killicons/icon_meathook",
        ismelee = true,
        bonemerge = true,
        keepdistance = 10,
        attackrange = 65,
                
        callback = function( self, wepent, target )
            self.l_WeaponUseCooldown = CurTime() + Rand(1.0, 1.2)

            wepent:EmitSound( "npc/zombie/claw_miss1.wav", 70, 100, 1, CHAN_WEAPON )
            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            
            self:SimpleTimer( 0.3, function()
                if !IsValid( target ) or self:GetRangeSquaredTo( target ) > ( 65 * 65 ) then return end

                local dmg = random( 40, 50 )
                local dmginfo = DamageInfo()
                dmginfo:SetDamage( dmg )
                dmginfo:SetAttacker( self )
                dmginfo:SetInflictor( wepent )
                dmginfo:SetDamageType( DMG_SLASH )
                dmginfo:SetDamageForce( ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * dmg )
                target:TakeDamageInfo( dmginfo )

                target:EmitSound( "lambdaplayers/weapons/meathook/hook-" .. random(3) .. ".mp3", 70 )
            end )
            
            return true
        end,

        islethal = true,
    }

})