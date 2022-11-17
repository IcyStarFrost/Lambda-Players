local CurTime = CurTime
local random = math.random
local bulletData = {
    Damage = 8,
    Force = 8,
    HullSize = 5,
    TracerName = "Tracer",
    Spread = Vector( 0.1, 0.1, 0 )
}

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    shotgun = {
        model = "models/weapons/w_shotgun.mdl",
        origin = "Half Life: 2",
        prettyname = "SPAS 12",
        holdtype = "shotgun",
        killicon = "weapon_shotgun",
        bonemerge = true,
        keepdistance = 150,
        attackrange = 500,

        clip = 6,

        reloadtime = 3,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN,
        reloadanimspeed = 1,

        callback = function( self, wepent, target )
            if self.l_Clip <= 0 then self:ReloadWeapon() return end

            -- Secondary double barrel attack
            if self.l_Clip >= 2 and random( 8 ) == 1 and self:GetRangeSquaredTo( target ) <= ( 400 * 400 ) then
                self.l_WeaponUseCooldown = CurTime() + random( 1.2, 1.5 )
                wepent:EmitSound( "Weapon_Shotgun.Double" )
                bulletData.Num = 12
                self.l_Clip = self.l_Clip - 2
            else
                self.l_WeaponUseCooldown = CurTime() + random( 1, 1.25 )
                wepent:EmitSound( "Weapon_Shotgun.Single" )
                bulletData.Num = 7
                self.l_Clip = self.l_Clip - 1
            end

            self:HandleMuzzleFlash( 1 )

            bulletData.Attacker = self
            bulletData.IgnoreEntity = self
            bulletData.Src = wepent:GetPos()
            bulletData.Dir = ( target:WorldSpaceCenter() - wepent:GetPos() ):GetNormalized()
            wepent:FireBullets( bulletData )

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN )
            
            -- To simulate pump action after the shot
            self:SimpleTimer( 0.6, function()
                wepent:EmitSound( "Weapon_Shotgun.Special1", 70, 100, 1, CHAN_WEAPON )
                self:HandleShellEject( "ShotgunShellEject", Vector( 0, 12, 0 ), Angle( -180, 0, 0 ) )
            end)

            return true
        end,

        islethal = true,
    }

})