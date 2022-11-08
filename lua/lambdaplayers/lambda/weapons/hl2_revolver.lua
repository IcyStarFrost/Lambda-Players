table.Merge( _LAMBDAPLAYERSWEAPONS, {

    revolver = {
        model = "models/weapons/w_357.mdl",
        origin = "Half Life: 2",
        prettyname = ".357 Revolver",
        holdtype = "revolver",
        bonemerge = true,
        keepdistance = 550,
        attackrange = 3500,

        clip = 6,
        tracername = "Tracer",
        damage = 40,
        spread = 0.08,
        rateoffire = 0.8,
        muzzleflash = 1,
        shelleject = "none",
        attackanim = ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER,
        attacksnd = "Weapon_357.Single",

        reloadtime = 3,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_REVOLVER,
        reloadanimationspeed = 1,
        reloadsounds = { 
            { 0, "Weapon_357.OpenLoader" }, 
            { 0.4, "Weapon_357.RemoveLoader" }, 
            { 1.5, "Weapon_357.ReplaceLoader" }, 
            { 2.2, "Weapon_357.Spin" } 
        },

        islethal = true,
    }

})