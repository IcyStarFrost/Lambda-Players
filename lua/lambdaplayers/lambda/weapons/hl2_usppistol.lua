table.Merge( _LAMBDAPLAYERSWEAPONS, {

    pistol = {
        model = "models/weapons/w_pistol.mdl",
        origin = "Half-Life 2",
        prettyname = "Pistol",
        holdtype = "pistol",
        killicon = "weapon_pistol",
        bonemerge = true,
        keepdistance = 350,
        attackrange = 2000,

        clip = 18,
        tracername = "Tracer",
        damage = 5,
        spread = 0.2,
        rateoffiremin = 0.2,
        rateoffiremax = 0.45,
        muzzleflash = 1,
        shelleject = "ShellEject",
        shelloffpos = Vector(0,2,5),
        attackanim = ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL,
        attacksnd = "Weapon_Pistol.Single",

        reloadtime = 1.8,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        reloadanimspeed = 1,
        reloadsounds = { { 0, "Weapon_Pistol.Reload" } },

        islethal = true,
    }

})