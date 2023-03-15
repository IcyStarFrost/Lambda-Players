local IsValid = IsValid
local random = math.random
local CurTime = CurTime
local Rand = math.Rand

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    shovel = {
        model = "models/lambdaplayers/weapons/w_shovel.mdl",
        origin = "Misc",
        prettyname = "Shovel",
        holdtype = "melee2",
        killicon = "lambdaplayers/killicons/icon_shovel",
        ismelee = true,
        bonemerge = true,
        keepdistance = 10,
        attackrange = 70,
                
        OnAttack = function( self, wepent, target )
            self.l_WeaponUseCooldown = CurTime() + Rand( 0.66, 0.85 )
            wepent:EmitSound( "Zombie.AttackMiss" )

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            
            self:SimpleWeaponTimer( 0.3, function()
                if !IsValid( target ) or !self:IsInRange( target, 60 ) then return end

                local dmg = random( 20, 30 )
                local dmginfo = DamageInfo()
                dmginfo:SetDamage( dmg )
                dmginfo:SetAttacker( self )
                dmginfo:SetInflictor( wepent )
                dmginfo:SetDamageType( DMG_CLUB )
                dmginfo:SetDamageForce( ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * dmg )
                target:TakeDamageInfo( dmginfo )

                wepent:EmitSound( "physics/metal/metal_sheet_impact_hard" .. random( 6, 7 ) .. ".wav", 70 )
                wepent:EmitSound( "physics/body/body_medium_impact_hard" .. random( 6 ) .. ".wav", 70 )
            end )

            return true
        end,

        islethal = true
    }

})