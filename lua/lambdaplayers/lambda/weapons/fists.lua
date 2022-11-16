local IsValid = IsValid
local random = math.random
local math_min = math.min
local CurTime = CurTime
local Rand = math.Rand

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    fists = {
        model = "",
        origin = "Garry's Mod",
        prettyname = "Fists",
        holdtype = "fist",
        killicon = "lambdaplayers/killicons/icon_fists",
        ismelee = true,
        nodraw = true,
        keepdistance = 15,
        attackrange = 45,
        
        OnEquip = function( lambda, wepent )
            wepent.FistCombo = 0
            wepent.FistComboTime = CurTime()
        end,

        OnUnequip = function( lambda, wepent )
            wepent.FistCombo = nil
            wepent.FistComboTime = nil
        end,

        callback = function( self, wepent, target )
            if CurTime() > wepent.FistComboTime then
                wepent.FistCombo = 0
            end

            self.l_WeaponUseCooldown = CurTime() + 0.9
            wepent.FistComboTime = self.l_WeaponUseCooldown + 0.1

            wepent:EmitSound( "WeaponFrag.Throw", 70 )

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST )
            
            self:SimpleTimer( 0.2, function()
                if !IsValid( target ) or self:GetRangeSquaredTo( target ) > ( 45 * 45 ) then return end

                local dmginfo = DamageInfo()
                dmginfo:SetAttacker( self )
                dmginfo:SetInflictor( wepent )
                
                local attackDmg = random( 8, 12 )
                local attackAng = ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):Angle()
                local attackForce = ( attackAng:Up() * 4912 + attackAng:Forward() * 9989 )
                if wepent.FistCombo >= 2 then
                    attackDmg = random( 12, 24 )
                    attackForce = ( attackAng:Up() * 5158 + attackAng:Forward() * 10012 )
                    wepent.FistCombo = 0
                else
                    wepent.FistCombo = wepent.FistCombo + 1
                    if random( 2 ) == 1 then attackForce = ( attackAng:Up() * -4912 + attackAng:Forward() * 9989 ) end
                end
                dmginfo:SetDamage( attackDmg )
                dmginfo:SetDamageForce( attackForce )
                
                target:TakeDamageInfo( dmginfo )
                wepent:EmitSound( "Flesh.ImpactHard", 70 )
            end)

            return true
        end,
        
        islethal = true
    }

})