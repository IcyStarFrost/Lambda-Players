table.Merge( _LAMBDAPLAYERSWEAPONS, {

--TF2 wiki used for refrence to balancing

	tf2shotgun = {
		model = "models/weapons/c_models/c_shotgun/c_shotgun.mdl",
		prettyname = "TF2 Shotgun",
		origin = "Team Fortress 2",
		holdtype = "shotgun",
		bonemerge = false,
		keepdistance = 125,
		attackrange = 450,
		
		clip = 6,
		tracername = "Tracer",
		bulletcount = 10,
		damage = 6,
		rateoffire = 0.625,
		spread = 0.3,
		muzzleflash = 1,
		
		shelleject = "ShotgunShellEject",
        shelloffpos = Vector(0,2,5),
        attackanim = ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN,
        attacksnd = "Weapon_Shotgun.Single",
		
		reloadtime = 3,
		reloadanim = ACT_HL2MP_GESTURE_RANGE_RELOAD_SHOTGUN,
		reloadanimationspeed = 1,
		reloadsounds = { { 0, "weapons/shotgun_reload.wav" }, {2.5, "weapons/shotgun_reload.wav"} },
		
		islethal = true,
	}
})
