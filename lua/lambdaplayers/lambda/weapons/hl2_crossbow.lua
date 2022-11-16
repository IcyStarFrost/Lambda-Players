local CurTime = CurTime
local boltDmg = GetConVar("sk_plr_dmg_crossbow")

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    crossbow = {
        model = "models/weapons/w_crossbow.mdl",
        origin = "Half Life: 2",
        prettyname = "Crossbow",
        holdtype = "crossbow",
        killicon = "crossbow_bolt",
        bonemerge = true,
        keepdistance = 400,
        attackrange = 3500,

        clip = 1,

        reloadtime = 1.83,
        reloadsounds = { 
            { 0.93, "Weapon_Crossbow.BoltElectrify" }
        },

        callback = function( self, wepent, target )
            if self.l_Clip <= 0 then self:ReloadWeapon() return end
            
            local bolt = ents.Create( "crossbow_bolt" )
            if IsValid( bolt ) then
                self.l_Clip = self.l_Clip - 1
                self.l_WeaponUseCooldown = CurTime() + 0.4

                self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW )
                self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW )

                wepent:EmitSound( "Weapon_Crossbow.Single" )

                local fireDir = ( target:WorldSpaceCenter() - self:EyePos() ):Angle()

                bolt:SetPos( self:EyePos() + fireDir:Forward() * 32 + fireDir:Up() * 32 ) 
                bolt:SetAngles( fireDir )
                bolt:Spawn()
                bolt:SetOwner( self )
                bolt:SetVelocity( fireDir:Forward() * ( bolt:WaterLevel() == 0 and 2500 or 1500 ) )

                bolt:EmitSound( "Weapon_Crossbow.BoltFly" )
                bolt:CallOnRemove( "lambdaplayer_crossbowbolt_" .. bolt:EntIndex(), function()
                    local tr = bolt:GetTouchTrace()
                    if !tr or !tr.Entity or !IsValid( tr.Entity ) then return end

                    local dmgInfo = DamageInfo()
                    dmgInfo:SetDamage( boltDmg:GetFloat() )
                    dmgInfo:SetDamageType( bit.bor( DMG_BULLET, DMG_NEVERGIB ) )
                    dmgInfo:SetDamagePosition( tr.HitPos )
                    dmgInfo:SetAttacker( IsValid( self ) and self or bolt )
                    dmgInfo:SetInflictor( bolt )
                    dmgInfo:SetDamagePosition( tr.HitPos )
                    tr.Entity:DispatchTraceAttack( dmgInfo, tr )
                end)
            end

            return true
        end,

        islethal = true,
    }

})