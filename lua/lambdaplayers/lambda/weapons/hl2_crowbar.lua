table.Merge( _LAMBDAPLAYERSWEAPONS, {

    crowbar = {
        model = "models/weapons/w_crowbar.mdl",
        origin = "Half Life: 2",
        prettyname = "Crowbar",
        holdtype = "melee",
        ismelee = true,
        bonemerge = true,
        keepdistance = 10,
        attackrange = 50,

        damage = 10,
        rateoffire = 0.4,
        attackanim = ACT_HL2MP_GESTURE_RANGE_ATTACK_MELEE,
        attacksnd = "Weapon_Crowbar.Single",
        hitsnd = "Weapon_Crowbar.Melee_Hit",

        islethal = true,
    }

})