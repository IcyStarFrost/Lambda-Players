local IsValid = IsValid


local CurTime = CurTime
local DamageInfo = DamageInfo
local min = math.min

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
local motivationSnds = {
    "lambdaplayers/weapons/katana/katana_motivation1.mp3",
    "lambdaplayers/weapons/katana/katana_motivation2.mp3",
    "lambdaplayers/weapons/katana/katana_motivation3.mp3",
    "lambdaplayers/weapons/katana/katana_motivation4.mp3",
    "lambdaplayers/weapons/katana/katana_motivation5.mp3",
    "lambdaplayers/weapons/katana/katana_motivation6.mp3",
    "lambdaplayers/weapons/katana/katana_motivation7.mp3",
    "lambdaplayers/weapons/katana/katana_motivation8.mp3",
    "lambdaplayers/weapons/katana/katana_motivation9.mp3",
    "lambdaplayers/weapons/katana/katana_motivation10.mp3"
}

local getMotivated = CreateLambdaConvar( "lambdaplayers_weapons_katana_getmotivated", 1, true, false, false, "If a Lambda Player that equips the katana should get a little motivated (Plays a random part of Bury The Light upon equip).", 0, 1, { type = "Bool", name = "Katana - Get Motivation", category = "Weapon Utilities" } )

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

            if getMotivated:GetBool() then
                wepent:EmitSound( motivationSnds[ LambdaRNG( #motivationSnds ) ], 75, 100, 0.9, CHAN_STATIC )
            end
        end,

        OnHolster = function( self, wepent )
            wepent.IsGripReady = nil
            wepent.NextUnreadyTime = nil
            wepent.DodgeTime = nil
            wepent.NextEnergyRestoreTime = nil
            wepent:SetBodygroup( 0, 0 )
            wepent:EmitSound( "lambdaplayers/weapons/katana/katana_holster1.mp3", 70 )

            for i = 1, #motivationSnds do
                wepent:StopSound( motivationSnds[ i ] )
            end
        end,

        OnThink = function( self, wepent )
            if !dead then
                if CurTime() >= wepent.NextUnreadyTime then
                    if wepent.IsGripReady then
                        wepent.IsGripReady = false
                        wepent:EmitSound( "lambdaplayers/weapons/katana/katana_roll" .. LambdaRNG( 2 ) .. ".mp3", 65 )
                        wepent:SetBodygroup( 0, 1 )
                    end

                    local moveSpeed, holdType = 1.0, hTypeDocile
                    if self:InCombat() then
                        moveSpeed, holdType = 1.25, hTypeCombat
                    end

                    self.l_HoldType = holdType
                    self.l_WeaponSpeedMultiplier = moveSpeed
                elseif !wepent.IsGripReady then
                    wepent:EmitSound( "lambdaplayers/weapons/katana/katana_roll" .. LambdaRNG( 2 ) .. ".mp3", 65 )
                    wepent:SetBodygroup( 0, 0 )
                    
                    wepent.IsGripReady = true
                    self.l_HoldType = "melee2"
                end

                if CurTime() >= wepent.NextEnergyRestoreTime then
                    local energy, maxEnergy = self:Health(), self:GetMaxHealth()
                    if energy < maxEnergy then 
                        self:SetHealth( min( energy + 1, maxEnergy ) ) 
                    else
                        local energy, maxEnergy = self:Armor(), ( self:GetMaxArmor() * 0.5 )
                        if energy < maxEnergy then self:SetArmor( min( energy + 1, maxEnergy ) ) end
                    end

                    wepent.NextEnergyRestoreTime = ( CurTime() + 1 )
                end
            end

            return 0.1
        end,

        OnTakeDamage = function( self, wepent, dmginfo )
            if CurTime() >= wepent.NextUnreadyTime then 
                wepent.NextUnreadyTime = CurTime() + LambdaRNG( 4 ) 
            end
            wepent.NextEnergyRestoreTime = CurTime() + LambdaRNG( 2, 4 )

            if dmginfo:IsBulletDamage()then
                if CurTime() <= wepent.DodgeTime then return true end

                local onGround = self:IsOnGround()
                if ( !onGround or self.l_issmoving ) and LambdaRNG( 2 ) == 1 then
                    local selfCenter, selfPos = self:WorldSpaceCenter(), self:GetPos()
                    local stepHeight = ( vector_up * -self.loco:GetStepHeight() )

                    local inflictor = dmginfo:GetInflictor()
                    local dmgSrc = ( IsValid( inflictor ) and inflictor or dmginfo:GetAttacker() ):WorldSpaceCenter()

                    local dmgAng = ( dmgSrc - selfCenter ):Angle(); dmgAng.z = 0
                    local dodgeDir = ( LambdaRNG( 2 ) == 1 and -dmgAng:Right() or dmgAng:Right() )
                    local dodgeVel = 128

                    for i = 1, 2 do
                        local trace = self:Trace( selfCenter + dodgeDir * dodgeVel, selfCenter )
                        if trace.Hit then
                            local dist = trace.HitPos:Distance( selfCenter )
                            if dist <= 40 then
                                if i == 2 then break end
                                dodgeDir = -dodgeDir
                                continue
                            end
                            dodgeVel = dist
                        end

                        if i == 2 then
                            dodgeVel = ( dodgeVel * ( onGround and 10 or 2 ) )
                            self.loco:SetVelocity( ( onGround and self.loco:GetVelocity() or vector_origin ) + dodgeDir * dodgeVel )

                            self:EmitSound( "lambdaplayers/weapons/katana/katana_dodge" .. LambdaRNG( 2 ) .. ".mp3", 70, LambdaRNG( 95, 105 ), 1, CHAN_BODY )
                            wepent.DodgeTime = CurTime() + 0.2
                            return true
                        end
                    end
                end
            end

            dmginfo:ScaleDamage( LambdaRNG( 0.66, 0.75, true ) )
        end,

        OnAttack = function( self, wepent, target )
            wepent.NextUnreadyTime = CurTime() + LambdaRNG( 4 )
            wepent:EmitSound( "lambdaplayers/weapons/katana/katana_swing_miss" .. LambdaRNG( 4 ) .. ".mp3", 70 )

            self.l_WeaponUseCooldown = CurTime() + LambdaRNG( 0.4, 0.8, true )
            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )

            local attackGest = self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            local swingSpeed = LambdaRNG( 0.9, 1.4, true ); self:SetLayerPlaybackRate( attackGest, swingSpeed )

            self:SimpleWeaponTimer( ( 0.3 / swingSpeed ), function()
                if !LambdaIsValid( target ) or !self:IsInRange( target, 70 ) then return end

                local dmg = ( LambdaRNG( 30, 45 ) / swingSpeed )
                local dmginfo = DamageInfo()
                dmginfo:SetDamage( dmg )
                dmginfo:SetAttacker( self )
                dmginfo:SetInflictor( wepent )
                dmginfo:SetDamageType( DMG_SLASH )

                local dmgAng = ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):Angle()
                dmginfo:SetDamageForce( dmgAng:Forward() * dmg * 40 - dmgAng:Right() * dmg * 20 )

                local postHP = target:Health()
                target:TakeDamageInfo( dmginfo )
                target:EmitSound( "lambdaplayers/weapons/katana/katana_swing_hit" .. LambdaRNG( 3 ) .. ".mp3", 70 )

                if target:Health() < postHP then
                    local bleedTimer = "Lambda_Katana_BleedingEffect" .. target:GetCreationID()
                    self:RemoveNamedTimer( bleedTimer )

                    self:NamedTimer( bleedTimer, LambdaRNG( 0.75, 1.25, true ), LambdaRNG( 3, 10 ), function()
                        if !LambdaIsValid( target ) or target:Health() <= 0 or target:IsPlayer() and !target:Alive() then return true end
                        local bleedInfo = DamageInfo()
                        bleedInfo:SetDamage( LambdaRNG( 3 ) )
                        bleedInfo:SetDamageType( DMG_SLASH )
                        bleedInfo:SetInflictor( IsValid( wepent ) and wepent or IsValid( self ) and self or target )
                        bleedInfo:SetAttacker( IsValid( self ) and self or target )
                        target:TakeDamageInfo( bleedInfo )
                    end, true )
                end
            end)

            return true
        end,

        islethal = true
    }
} )