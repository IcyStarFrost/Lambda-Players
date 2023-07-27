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
        islethal = true,
        dropentity = "weapon_pistol",

        clip = 18,
        tracername = "Tracer",
        damage = 5,
        spread = 0.133,
        rateoffiremin = 0.15,
        rateoffiremax = 0.3,
        muzzleflash = 1,
        shelleject = "ShellEject",
        shelloffpos = Vector(0,2,5),
        attackanim = ACT_HL2MP_GESTURE_RANGE_ATTACK_PISTOL,
        attacksnd = "Weapon_Pistol.Single",

        reloadtime = 1.8,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        reloadsounds = { { 0, "Weapon_Pistol.Reload" } }
    }
} )