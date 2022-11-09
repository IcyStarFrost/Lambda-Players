local random = math.random
local math_min = math.min
local CurTime = CurTime
local Rand = math.Rand
local fistCombo = 0
local fistComboTime = 0

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    fists = {
        model = "",
        origin = "Garry's Mod",
        prettyname = "Fists",
        holdtype = "fist",
        ismelee = true,
        nodraw = true,
        keepdistance = 15,
        attackrange = 45,
        
        OnEquip = function( lambda, wepent )

        end,
        
        OnUnequip = function( lambda, wepent )
           
        end,
        
        callback = function( self, wepent, target )
            if CurTime() > fistComboTime then
                fistCombo = 0
            end

            self.l_WeaponUseCooldown = CurTime() + 0.9
            fistComboTime = self.l_WeaponUseCooldown + 0.1

            wepent:EmitSound( "WeaponFrag.Throw", 70 )

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST )
            
            self:SimpleTimer( 0.2, function()
                if self:GetRangeSquaredTo( target ) > (45 * 45) then return end
                
                local dmg = random( 8, 12 )
                if fistCombo >= 2 then 
                    dmg = random( 12, 24 )
                    fistCombo = -1
                end

                local dmginfo = DamageInfo()
                dmginfo:SetDamage( dmg )
                dmginfo:SetAttacker( self )
                dmginfo:SetInflictor( wepent )
                dmginfo:SetDamageType( DMG_SLASH )
                dmginfo:SetDamageForce( ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * dmg )
                
                wepent:EmitSound( "Flesh.ImpactHard", 70 )

                fistCombo = fistCombo + 1

                print(dmg)
                
                target:TakeDamageInfo( dmginfo )
            end)
            
            return true
        end,
        
        islethal = true,
    }

})