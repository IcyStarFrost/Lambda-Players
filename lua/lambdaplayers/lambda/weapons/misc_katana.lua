local IsValid = IsValid
local random = math.random
local Rand = math.Rand
local CurTime = CurTime
local DamageInfo = DamageInfo
local min = math.min
local timer_Create = timer.Create
local timer_Exists = timer.Exists
local timer_Remove = timer.Remove

local hTypeDocile = {
    idle = ACT_HL2MP_IDLE_SUITCASE,
    run = ACT_HL2MP_RUN_SLAM,
    walk = ACT_HL2MP_WALK_SUITCASE,
    jump = ACT_HL2MP_JUMP_KNIFE,
    crouchIdle = ACT_HL2MP_IDLE_CROUCH_KNIFE,
    crouchWalk = ACT_HL2MP_WALK_CROUCH_KNIFE,
    swimIdle = ACT_HL2MP_SWIM_IDLE_KNIFE,
    swimMove = ACT_HL2MP_SWIM_KNIFE
}
local hTypeCombat = {
    idle = ACT_HL2MP_IDLE_KNIFE,
    run = ACT_HL2MP_RUN_CHARGING,
    walk = ACT_HL2MP_WALK_KNIFE,
    jump = ACT_HL2MP_JUMP_KNIFE,
    crouchIdle = ACT_HL2MP_IDLE_CROUCH_KNIFE,
    crouchWalk = ACT_HL2MP_WALK_CROUCH_KNIFE,
    swimIdle = ACT_HL2MP_SWIM_IDLE_KNIFE,
    swimMove = ACT_HL2MP_SWIM_KNIFE
}

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    katana = {
        model = "models/lambdaplayers/weapons/w_katana.mdl",
        origin = "Misc",
        prettyname = "Katana",
        holdtype = hTypeDocile,
        killicon = "lambdaplayers/killicons/icon_katana",
        ismelee = true,
        bonemerge = true,
        keepdistance = 24,
        attackrange = 80,
        speedmultiplier = 1.0,

        OnDeploy = function( self, wepent )
            wepent.IsGripReady = false
            wepent.NextUnreadyTime = 0
            wepent.DodgeTime = 0
            wepent.NextEnergyRestoreTime = CurTime() + 1
            wepent:SetBodygroup( 0, 1 )
            wepent:EmitSound( "lambdaplayers/weapons/katana/katana_deploy1.mp3", 70 )
        end,

        OnHolster = function( self, wepent )
            wepent.IsGripReady = nil
            wepent.NextUnreadyTime = nil
            wepent.DodgeTime = nil
            wepent.NextEnergyRestoreTime = nil
            wepent:SetBodygroup( 0, 0 )
            wepent:EmitSound( "lambdaplayers/weapons/katana/katana_holster1.mp3", 70 )
        end,

        OnThink = function( self, wepent )
            if !dead then
                if CurTime() > wepent.NextUnreadyTime then
                    if wepent.IsGripReady then
                        wepent.IsGripReady = false
                        wepent:EmitSound( "lambdaplayers/weapons/katana/katana_roll" .. random( 1, 2 ) .. ".mp3", 65 )
                        wepent:SetBodygroup( 0, 1 )
                    end

                    local moveSpeed = 1.0
                    local holdType = hTypeDocile
                    if self:GetState() == "Combat" and LambdaIsValid( self:GetEnemy() ) then
                        moveSpeed = 1.25
                        holdType = hTypeCombat
                    end
                    self.l_HoldType = holdType
                    self.l_WeaponSpeedMultiplier = moveSpeed
                else
                    if !wepent.IsGripReady then
                        wepent.IsGripReady = true
                        wepent:EmitSound( "lambdaplayers/weapons/katana/katana_roll" .. random( 1, 2 ) .. ".mp3", 65 )
                        wepent:SetBodygroup( 0, 0 )
                        self.l_HoldType = "melee2"
                    end
                end

                if CurTime() > wepent.NextEnergyRestoreTime then
                    local HP, maxHP = self:Health(), self:GetMaxHealth()
                    if HP < maxHP then 
                        self:SetHealth( min( HP + 1, maxHP ) ) 
                    else
                        local armor, maxArmor = self:Armor(), ( self:GetMaxArmor() / 2 )
                        if armor < maxArmor then self:SetArmor( min( armor + 1, maxArmor ) ) end
                    end

                    wepent.NextEnergyRestoreTime = CurTime() + 1
                end
            end

            return 0.1
        end,

        OnTakeDamage = function( self, wepent, dmginfo )
            if CurTime() > wepent.NextUnreadyTime then wepent.NextUnreadyTime = CurTime() + random( 1, 4 ) end

            if dmginfo:IsBulletDamage()then
                if CurTime() <= wepent.DodgeTime then return true end
                if random( 1, 2 ) == 1 and self:IsOnGround() and self.l_issmoving and !self:IsDisabled() then
                    local selfCenter, selfPos = self:WorldSpaceCenter(), self:GetPos()
                    local stepHeight = self:GetUp() * -self.loco:GetStepHeight()

                    local inflictor = dmginfo:GetInflictor()
                    local dmgSrc = ( IsValid( inflictor ) and inflictor:WorldSpaceCenter() or dmginfo:GetAttacker():WorldSpaceCenter() )

                    local dmgAng = ( dmgSrc - selfCenter ):Angle(); dmgAng.z = 0
                    local dodgeDir = ( dmgAng:Right() * ( random( 1, 2 ) == 1 and -1500 or 1500 ) )

                    local realVel = ( dodgeDir / 5 )
                    if self:Trace( selfCenter + realVel, selfCenter ).Hit or !self:Trace( selfPos + realVel + stepHeight, selfPos + realVel ).Hit then dodgeDir = -dodgeDir end

                    if !self:Trace( selfCenter + realVel, selfCenter ).Hit and self:Trace( selfPos + realVel + stepHeight, selfPos + realVel ).Hit then 
                        self.loco:SetVelocity( dodgeDir )
                        wepent:EmitSound( "lambdaplayers/weapons/katana/katana_dodge" .. random( 1, 2 ) .. ".mp3", 70 )
                        wepent.DodgeTime = CurTime() + 0.2
                        return true
                    end
                end
            end

            wepent.NextEnergyRestoreTime = CurTime() + random( 2, 4 )
            dmginfo:ScaleDamage( Rand( 0.66, 0.75 ) )
        end,

        OnAttack = function( self, wepent, target )
            wepent.NextUnreadyTime = CurTime() + random( 1, 4 )
            wepent:EmitSound( "lambdaplayers/weapons/katana/katana_swing_miss" .. random( 4 ) .. ".mp3", 70 )

            self.l_WeaponUseCooldown = CurTime() + Rand( 0.4, 0.8 )
            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )

            local attackGest = self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            local swingSpeed = Rand( 0.9, 1.4 ); self:SetLayerPlaybackRate( attackGest, swingSpeed )


            self:SimpleWeaponTimer( ( 0.3 / swingSpeed ), function()
                if !LambdaIsValid( target ) or !self:IsInRange( target, 70 ) then return end

                local dmg = ( random( 30, 45 ) / swingSpeed )
                local dmginfo = DamageInfo()
                dmginfo:SetDamage( dmg )
                dmginfo:SetAttacker( self )
                dmginfo:SetInflictor( wepent )
                dmginfo:SetDamageType( DMG_SLASH )

                local dmgAng = ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):Angle()
                dmginfo:SetDamageForce( dmgAng:Forward() * dmg * 40 - dmgAng:Right() * dmg * 20 )

                local postHP = target:Health()
                target:TakeDamageInfo( dmginfo )
                target:EmitSound( "lambdaplayers/weapons/katana/katana_swing_hit" .. random(3) .. ".mp3", 70 )

                if target:Health() < postHP then
                    local bleedTimer = "Lambda_Katana_BleedingEffect" .. target:EntIndex()
                    if timer_Exists( bleedTimer ) then timer_Remove( bleedTimer ) end

                    timer_Create( bleedTimer, Rand( 0.5, 1.5 ), random( 5, 15 ), function()
                        if !LambdaIsValid( target ) or target:Health() <= 0 or target:IsPlayer() and !target:Alive() then
                            timer_Remove( bleedTimer )
                            return
                        end

                        local bleedInfo = DamageInfo()
                        bleedInfo:SetDamage( random( 1, 3 ) )
                        bleedInfo:SetDamageType( DMG_SLASH )
                        bleedInfo:SetInflictor( IsValid( wepent ) and wepent or IsValid( self ) and self or target )
                        bleedInfo:SetAttacker( IsValid( self ) and self or target )

                        target:TakeDamageInfo( bleedInfo )
                    end )
                end
            end)

            return true
        end,

        islethal = true
    }
} )