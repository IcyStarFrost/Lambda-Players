table.Merge( _LAMBDAPLAYERSWEAPONS, {

    revolver = {
        model = "models/weapons/w_357.mdl",
        origin = "Half Life: 2",
        prettyname = ".357 Revolver",
        holdtype = "revolver",
        killicon = "weapon_357",
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

        reloadtime = 3.66,
        --reloadanim = ACT_HL2MP_GESTURE_RELOAD_REVOLVER,
        reloadanimspeed = 1,
        reloadsounds = { 
            { 0.933, "Weapon_357.OpenLoader" }, 
            { 1.3, "Weapon_357.RemoveLoader" }, 
            { 2.233, "Weapon_357.ReplaceLoader" }, 
            { 3.066, "Weapon_357.Spin" } 
        },
        
        OnReload = function( self, wepent )
            local anim = self:LookupSequence( "reload_revolver_base_layer" )
            if anim != -1 then
                -- Stops animation's event sounds from running
                self:AddGestureSequence( anim )
            else
                self:AddGesture( ACT_HL2MP_GESTURE_RELOAD_REVOLVER )
            end

            -- Cool shell ejects
            self:SimpleTimer( 1.3, function() 
                if self.l_Weapon != "revolver" or !IsValid( wepent ) then return end
                for i = 1, 6 do self:HandleShellEject( "ShellEject" ) end
            end )
        end,

        islethal = true,
    }

})