table.Merge( _LAMBDAPLAYERSWEAPONS, {
-- Missing secondary energy ball attack

    ar2 = {
        model = "models/weapons/w_irifle.mdl",
        origin = "Half Life: 2",
        prettyname = "AR2",
        holdtype = "ar2",
        bonemerge = true,
        keepdistance = 400,
        attackrange = 2500,

        clip = 30,
        tracername = "AR2Tracer",
        damage = 8,
        spread = 0.1,
        rateoffire = 0.10,
        muzzleflash = 1,
        shelleject = "none",
        attackanim = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2,
        attacksnd = "Weapon_AR2.Single",

        reloadtime = 1.5,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        reloadanimationspeed = 1,
        reloadsounds = { { 0, "weapons/ar2/ar2_reload.wav" } },

        islethal = true,
    }

})