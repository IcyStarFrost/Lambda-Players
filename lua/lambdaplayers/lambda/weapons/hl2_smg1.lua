local IsValid = IsValid
local CurTime = CurTime
local random = math.random
local RandAngle = AngleRand

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    smg = {
        model = "models/weapons/w_smg1.mdl",
        origin = "Half-Life 2",
        prettyname = "SMG",
        killicon = "weapon_smg1",
        holdtype = "smg",
        bonemerge = true,
        keepdistance = 300,
        attackrange = 1500,

        clip = 45,
        tracername = "Tracer",
        damage = 4,
        spread = 0.15,
        rateoffire = 0.075,
        muzzleflash = 1,
        shelleject = "ShellEject",
        shelloffpos = Vector( 3, 5, 5 ),
        shelloffang = Angle( -180, 0, 0 ),
        attackanim = ACT_HL2MP_GESTURE_RANGE_ATTACK_SMG1,
        attacksnd = "Weapon_SMG1.Single",

        reloadtime = 1.5,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_SMG1,
        reloadanimspeed = 1,
        reloadsounds = { { 0, "Weapon_SMG1.Reload" } },

        OnAttack = function( self, wepent, target )
            -- Secondary grenade launcher
            if random( 75 ) != 1 or !self:IsInRange( target, 1000 ) then return end
            
            local grenade = ents.Create( "grenade_ar2" )
            if !IsValid( grenade ) then return end

            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG )
            self.l_WeaponUseCooldown = CurTime() + 0.5

            wepent:EmitSound( "Weapon_SMG1.Double" )
            
            local vecThrow = ( target:WorldSpaceCenter() - self:EyePos() ):Angle()
            grenade:SetPos( self:EyePos() + vecThrow:Forward() * 32 + vecThrow:Up() * 32 )
            grenade:SetAngles( vecThrow )
            grenade:SetOwner( self )
            grenade:Spawn()
            grenade:SetVelocity( vecThrow:Forward() * 1000 )
            grenade:SetLocalAngularVelocity( RandAngle( -400, 400 ) )

            return true
        end,

        islethal = true,
    }

})