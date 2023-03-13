local IsValid = IsValid
local random = math.random
local math_min = math.min
local CurTime = CurTime
local Rand = math.Rand
local bor = bit.bor

local useReworkedVariant = CreateLambdaConvar( "lambdaplayers_weapons_fistsreworked", 0, true, false, true, "If Lambda Player's fists should use their reworked stats instead of default Gmod ones.", 0, 1, { type = "Bool", name = "Fists - Use Reworked Stats", category = "Weapon Utilities" } )
local useAltSounds = CreateLambdaConvar( "lambdaplayers_weapons_fistsaltsounds", 0, true, false, true, "If Lambda Player's fists should use alternate sounds instead of Half-Life 2 sounds.", 0, 1, { type = "Bool", name = "Fists - Use Alternate Sounds", category = "Weapon Utilities" } )

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    gmod_fists = {
        model = "",
        origin = "Garry's Mod",
        prettyname = "Fists",
        holdtype = "fist",
        killicon = "lambdaplayers/killicons/icon_fists",
        ismelee = true,
        nodraw = true,
        keepdistance = 16,
        attackrange = 64,
        dropondeath = false,

        OnDeploy = function( self, wepent )
            wepent.FistCombo = 0
            wepent.FistComboTime = CurTime()
        end,

        OnHolster = function( self, wepent )
            wepent.FistCombo = nil
            wepent.FistComboTime = nil
        end,

        OnThink = function( self, wepent, dead )
            if !dead then
                local keepDist = 16
                local speedScale = 1.0

                local ene = self:GetEnemy()
                if LambdaIsValid( ene ) and ene.IsLambdaPlayer and ene.l_HasMelee and ene:GetState() == "Combat" and ene:GetEnemy() == self and useReworkedVariant:GetBool() then
                    if random( 1, 4 ) == 1 then keepDist = 64 end
                    if self.l_movepos == ene and self:IsInRange( ene, 300 ) then speedScale = Rand( 0.66, 1.2 ) end
                end

                self.l_CombatKeepDistance = keepDist
                self.l_WeaponSpeedMultiplier = speedScale
            end

            return 0.1
        end,

        OnTakeDamage = function( self, wepent, dmginfo )
            if !useReworkedVariant:GetBool() or !dmginfo:IsDamageType( bor( DMG_CLUB, DMG_SLASH ) ) or random( 1, 2 ) == 1 or ( ( self.l_WeaponUseCooldown - 0.5 ) - CurTime() ) > 0 then return end

            self:RemoveGesture( ACT_HL2MP_FIST_BLOCK )
            self:AddGesture( ACT_HL2MP_FIST_BLOCK, false )
            self:SimpleTimer( 0.2, function() self:RemoveGesture( ACT_HL2MP_FIST_BLOCK ) end, true )

            dmginfo:ScaleDamage( Rand( 0.66, 0.8 ) )
            if !useAltSounds:GetBool() then wepent:EmitSound( "Flesh.ImpactHard" ) end
            if useAltSounds:GetBool() then wepent:EmitSound( "lambdaplayers/weapons/fist/strike_faceblow_".. random( 1, 3 ).. ".mp3", 80 ) end
            self.l_WeaponUseCooldown = self.l_WeaponUseCooldown + Rand( 0.25, 0.33 )
        end,

        OnAttack = function( self, wepent, target )
            if CurTime() > wepent.FistComboTime then wepent.FistCombo = 0 end
            local reworkStats = useReworkedVariant:GetBool()

            self.l_WeaponUseCooldown = CurTime() + ( reworkStats and Rand( 0.55, 0.75 ) or 0.9 )
            wepent.FistComboTime = self.l_WeaponUseCooldown + ( reworkStats and 0.25 or 0.1 )

            if !useAltSounds:GetBool() then wepent:EmitSound( "WeaponFrag.Throw" ) end
            if useAltSounds:GetBool() then wepent:EmitSound( "lambdaplayers/weapons/fist/whoosh_street_".. random( 1, 5 ).. ".mp3", 80 ) end

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST )
            local fistSeqID = self:LookupSequence( "range_fists_" .. ( random( 1, 2 ) == 1 and "r" or "l" ) )
            if fistSeqID != -1 then self:AddGestureSequence( fistSeqID ) else self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_FIST ) end

            self:SimpleWeaponTimer( 0.2, function()
                if !LambdaIsValid( target ) or !self:IsInRange( target, 55 ) then return end

                local dmginfo = DamageInfo()
                dmginfo:SetAttacker( self )
                dmginfo:SetInflictor( wepent )
                if reworkStats then dmginfo:SetDamageType( DMG_CLUB ) end

                local attackDmg = random( 8, 12 )
                local attackAng = ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):Angle()
                local attackForce = ( attackAng:Up() * 64 + attackAng:Forward() * 128 )
                if wepent.FistCombo and wepent.FistCombo >= ( reworkStats and random( 3, 5 ) or 2 ) then
                    attackDmg = random( 12, 24 )
                    attackForce = ( attackAng:Up() * 256 + attackAng:Forward() * 128 )
                    wepent.FistCombo = 0
                else
                    wepent.FistCombo = ( wepent.FistCombo and wepent.FistCombo + 1 or 0 )
                    if random( 2 ) == 1 then attackForce = ( attackAng:Up() * -64 + attackAng:Forward() * 128 ) end
                end

                dmginfo:SetDamage( attackDmg )
                dmginfo:SetDamageForce( attackForce )

                target:TakeDamageInfo( dmginfo )
                if !useAltSounds:GetBool() then wepent:EmitSound( "Flesh.ImpactHard" ) end
                if useAltSounds:GetBool() then wepent:EmitSound( "lambdaplayers/weapons/fist/strike_faceblow_".. random( 1, 3 ).. ".mp3", 80 ) end
            end)

            return true
        end,
        
        islethal = true
    }

})