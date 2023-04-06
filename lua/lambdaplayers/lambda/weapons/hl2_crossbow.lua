local CurTime = CurTime
local CreateEntity = ents.Create
local IsValid = IsValid

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    crossbow = {
        model = "models/weapons/w_crossbow.mdl",
        origin = "Half-Life 2",
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

        OnAttack = function( self, wepent, target )
            if self.l_Clip <= 0 then self:ReloadWeapon() return end

            local bolt = CreateEntity( "crossbow_bolt" )
            if !IsValid( bolt ) then return end

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
            bolt:Fire( "SetDamage", "100" )
            bolt:EmitSound( "Weapon_Crossbow.BoltFly" )

            return true
        end,

        islethal = true,
    }

})