local IsValid = IsValid
local CurTime = CurTime
local DamageInfo = DamageInfo
local min = math.min
local IsFirstTimePredicted = IsFirstTimePredicted
local EffectData = EffectData
local util_Effect = util.Effect

local getMotivated = CreateLambdaConvar( "lambdaplayers_weapons_katana_getmotivated", 1, true, false, false, "If a Lambda Player that equips the katana should get a little motivated (Plays a random part of Bury The Light upon equip).", 0, 1, { type = "Bool", name = "Katana - Get Motivation", category = "Weapon Utilities" } )
local summonKnifes = CreateLambdaConvar( "lambdaplayers_weapons_katana_summonknifes", 1, true, false, false, "If a Lambda Player with katana should be able to summon knifes that target their enemy and launch at them.", 0, 1, { type = "Bool", name = "Katana - Summon Knifes", category = "Weapon Utilities" } )

local knifeDist = 45
local knifeOffset = Angle( 90 )

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
    idle = ACT_HL2MP_IDLE_SUITCASE,
    run = ACT_HL2MP_RUN_CHARGING,
    walk = ACT_HL2MP_WALK_SUITCASE,
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
local extendedAnims = { ACT_VM_SWINGMISS, ACT_VM_MISSRIGHT, ACT_VM_MISSLEFT }

local function OnKnifeThink( self )
    if !self.l_HasFired then
        local fireAng = self:GetAngles()

        local owner = self:GetOwner()
        if LambdaIsValid( owner ) then
            local ene = owner:GetEnemy()
            if LambdaIsValid( ene ) then
                local eneVel = ene:GetVelocity()
                if ene:IsNextBot() then eneVel = ene.loco:GetVelocity() end
                fireAng = ( ( ene:WorldSpaceCenter() + ( eneVel * 0.2 ) ) - self:GetPos() ):Angle()
            else
                fireAng = owner:EyeAngles()
            end

            self:SetAngles( fireAng + knifeOffset )
            self:SetPos( owner:WorldSpaceCenter() + fireAng:Up() * 15 + fireAng:Right() * ( self.l_FromLeft and -knifeDist or knifeDist ) )
        end

        if CurTime() >= self.l_FireTime then
            self.l_HasFired = true
            self:EmitSound( "lambdaplayers/weapons/katana/pl030_genei_shot.mp3", 85 )
            self:SetVelocity( fireAng:Forward() * 1000 )
        end
    end

    self:NextThink( CurTime() )
    return true
end

local function OnKnifeTouch( self, ent )
    if !self.l_HasFired then return end

    local owner = self:GetOwner()
    if ent == owner or !ent:IsSolid() or ent:GetSolidFlags() == FSOLID_VOLUME_CONTENTS then return end

    local touchTr = self:GetTouchTrace()
    if !touchTr.HitSky then
        local hitPos = self:GetPos()

        if IsValid( owner ) then
            local dmginfo = DamageInfo()
            dmginfo:SetDamage( 25 )
            dmginfo:SetAttacker( owner )
            dmginfo:SetInflictor( self )
            dmginfo:SetDamagePosition( hitPos )
            dmginfo:SetDamageForce( self:GetVelocity() * 25 )
            dmginfo:SetDamageType( DMG_SLASH )

            ent:DispatchTraceAttack( dmginfo, touchTr, self:GetForward() )
        end

        if IsFirstTimePredicted() then
            local effectData = EffectData()
            effectData:SetOrigin( hitPos )
            effectData:SetStart( hitPos )
            effectData:SetSurfaceProp( touchTr.SurfaceProps )
            effectData:SetHitBox( touchTr.HitBox )
            effectData:SetDamageType( DMG_SLASH )
            effectData:SetEntity( ent )
            util_Effect( "Impact", effectData )

            local breakEffect = EffectData()
            breakEffect:SetOrigin( hitPos )
            util_Effect( "GlassImpact", breakEffect )
            util_Effect( "AR2Impact", breakEffect )
        end
    end

    self:EmitSound( "lambdaplayers/weapons/katana/pl030_genei_crash.mp3", 85 )
    self:Remove()
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    katana = {
        model = "models/lambdaplayers/weapons/w_katana.mdl",
        origin = "Misc",
        prettyname = "Katana",
        holdtype = hTypeDocile,
        killicon = "lambdaplayers/killicons/icon_katana",
        ismelee = true,
        bonemerge = true,
        keepdistance = 40,
        attackrange = 80,
        speedmultiplier = 1.0,

        OnDeploy = function( self, wepent )
            wepent.IsGripReady = false
            wepent.NextUnreadyTime = 0
            wepent.DodgeTime = 0
            wepent.NextKnifeSummon = 0
            wepent.SummonLeftKnife = false
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
            wepent.NextKnifeSummon = nil
            wepent.SummonLeftKnife = nil
            wepent.NextEnergyRestoreTime = nil
            wepent:SetBodygroup( 0, 0 )
            wepent:EmitSound( "lambdaplayers/weapons/katana/katana_holster1.mp3", 70 )

            for i = 1, #motivationSnds do
                wepent:StopSound( motivationSnds[ i ] )
            end
        end,

        OnThink = function( self, wepent )
            if dead then return end

            if CurTime() >= wepent.NextUnreadyTime then
                if wepent.IsGripReady then
                    wepent.IsGripReady = false
                    wepent:EmitSound( "lambdaplayers/weapons/katana/katana_roll" .. LambdaRNG( 2 ) .. ".mp3", 65 )
                    wepent:SetBodygroup( 0, 1 )
                end

                local ene = self:GetEnemy()
                local moveSpeed, holdType = 1.0, hTypeDocile
                if IsValid( ene ) then
                    moveSpeed, holdType = 1.1, hTypeCombat

                    if CurTime() >= wepent.NextKnifeSummon and summonKnifes:GetBool() and !self:IsInRange( ene, 100 ) and self:IsInRange( ene, 1500 ) and self:CanSee( ene ) then
                        local selfPos = self:WorldSpaceCenter()
                        local enePos = ene:WorldSpaceCenter()
                        local fromLeft = wepent.SummonLeftKnife
                        local eneAng = ( enePos - selfPos ):Angle()
                        local spawnPos = ( selfPos + eneAng:Up() * 15 + eneAng:Right() * ( fromLeft and -knifeDist or knifeDist ) )

                        local trCheck = self:Trace( enePos, spawnPos )
                        if !trCheck.Hit or trCheck.Entity == ene then
                            local throwAng = ( trCheck.HitPos - spawnPos ):Angle()
                            local knife = ents.Create( "base_gmodentity" )
                            knife:SetModel( "models/weapons/w_knife_t.mdl" )
                            knife:SetPos( spawnPos )
                            knife:SetAngles( throwAng + knifeOffset )
                            knife:SetOwner( self )
                            knife:Spawn()

                            knife:SetMaterial( "models/props_combine/portalball001_sheet" )
                            knife:SetModelScale( 2.33, 0 )
                            knife:EmitSound( "lambdaplayers/weapons/katana/pl030_genei_sp_ap0" .. LambdaRNG( 2 ) .. ".mp3", 85 )

                            knife:SetSolid( SOLID_BBOX )
                            knife:SetMoveType( MOVETYPE_FLY )
                            knife:SetMoveCollide( MOVECOLLIDE_FLY_CUSTOM )

                            local effectData = EffectData()
                            effectData:SetOrigin( spawnPos )
                            util_Effect( "ElectricSpark", effectData )

                            knife.l_FireTime = ( CurTime() + 0.366 )
                            knife.l_HasFired = false
                            knife.l_FromLeft = fromLeft
                            knife.l_UseLambdaDmgModifier = true

                            knife.Think = OnKnifeThink
                            knife.Touch = OnKnifeTouch

                            wepent.SummonLeftKnife = !fromLeft
                            wepent.NextKnifeSummon = ( CurTime() + 0.85 )
                        end
                    end
                end

                self.l_HoldType = holdType
                self.l_WeaponSpeedMultiplier = moveSpeed
            elseif !wepent.IsGripReady then
                wepent:EmitSound( "lambdaplayers/weapons/katana/katana_roll" .. LambdaRNG( 2 ) .. ".mp3", 65 )
                wepent:SetBodygroup( 0, 0 )

                wepent.IsGripReady = true
                self.l_HoldType = hTypeCombat
            end

            if CurTime() >= wepent.NextEnergyRestoreTime then
                local energy, maxEnergy = self:Health(), self:GetMaxHealth()
                if energy < maxEnergy then
                    self:SetHealth( min( energy + 1, maxEnergy ) )
                else
                    local energy, maxEnergy = self:Armor(), ( self:GetMaxArmor() * 0.5 )
                    if energy < maxEnergy then self:SetArmor( min( energy + 1, maxEnergy ) ) end
                end

                wepent.NextEnergyRestoreTime = ( CurTime() + 0.75 )
            end
        end,

        OnTakeDamage = function( self, wepent, dmginfo )
            wepent.NextEnergyRestoreTime = CurTime() + LambdaRNG( 3, 5 )

            if dmginfo:IsBulletDamage()then
                if CurTime() <= wepent.DodgeTime then return true end

                local onGround = self:IsOnGround()
                if ( !onGround or self.l_issmoving ) and LambdaRNG( 3 ) == 1 then
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
            self.l_WeaponUseCooldown = CurTime() + LambdaRNG( 0.33, 0.75, true )
            wepent.NextUnreadyTime = CurTime() + LambdaRNG( 4 )
            wepent:EmitSound( "lambdaplayers/weapons/katana/katana_swing_miss" .. LambdaRNG( 4 ) .. ".mp3", 70 )

            local anim = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2
            if self.l_HasExtendedAnims then
                anim = extendedAnims[ LambdaRNG( #extendedAnims ) ]
                for i = 1, #extendedAnims do self:RemoveGesture( extendedAnims[ i ] ) end
            else
                self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE2 )
            end

            local swingSpeed = LambdaRNG( 1.25, 1.4, true )
            self:SetLayerPlaybackRate( self:AddGesture( anim ), swingSpeed )

            self:SimpleWeaponTimer( ( 0.275 / swingSpeed ), function()
                if !LambdaIsValid( target ) or !self:IsInRange( target, 70 ) then return end

                local dmg = LambdaRNG( 25, 35 )
                local dmginfo = DamageInfo()
                dmginfo:SetDamage( dmg )
                dmginfo:SetAttacker( self )
                dmginfo:SetInflictor( wepent )
                dmginfo:SetDamageType( DMG_SLASH )

                local dmgAng = ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):Angle()
                dmginfo:SetDamageForce( dmgAng:Forward() * dmg * 40 - dmgAng:Right() * dmg * 20 )

                target:TakeDamageInfo( dmginfo )
                target:EmitSound( "lambdaplayers/weapons/katana/katana_swing_hit" .. LambdaRNG( 3 ) .. ".mp3", 70 )
            end)

            return true
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, dealtDmg )
            if !dealtDmg then return end

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
        end,

        islethal = true
    }
} )