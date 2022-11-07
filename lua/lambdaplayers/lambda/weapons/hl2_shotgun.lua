local CurTime = CurTime
local random = math.random
local bullettbl = {}

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    shotgun = {
        model = "models/weapons/w_shotgun.mdl",
        origin = "Half Life: 2",
        prettyname = "SPAS 12",
        holdtype = "shotgun",
        bonemerge = true,
        keepdistance = 150,
        attackrange = 500,

        clip = 6,

        reloadtime = 3,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN,
        reloadanimationspeed = 1,

        callback = function( self, wepent, target )
            if self.l_Clip <= 0 then self:ReloadWeapon() return end

            -- Special double shot
            if math.random(6) == 1 and self.l_Clip >= 2 and self:GetRangeSquaredTo(target) <= (400 * 400) then
                self.l_WeaponUseCooldown = CurTime() + random(1.2, 1.5)

                wepent:EmitSound( "weapons/shotgun/shotgun_dbl_fire7.wav", 70, random(90,95), 1, CHAN_WEAPON )

                bullettbl.Num = 12

                self.l_Clip = self.l_Clip - 2
            else
                self.l_WeaponUseCooldown = CurTime() + random(1, 1.25)

                wepent:EmitSound( "weapons/shotgun/shotgun_fire7.wav", 70, random(98,101), 1, CHAN_WEAPON )

                bullettbl.Num = 7

                self.l_Clip = self.l_Clip - 1
            end
            
            bullettbl.Attacker = self
            bullettbl.Damage = 8
            bullettbl.Force = 8
            bullettbl.HullSize = 5
            bullettbl.TracerName = tracer or "Tracer"
            bullettbl.Dir = ( target:WorldSpaceCenter() - wepent:GetPos() ):GetNormalized()
            bullettbl.Src = wepent:GetPos()
            bullettbl.Spread = Vector( 0.1, 0.1, 0 )
            bullettbl.IgnoreEntity = self

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN )
            
            self:HandleMuzzleFlash( 1 )

            wepent:FireBullets( bullettbl )

            -- To simulate pump action after the shot
            self:SimpleTimer(0.5, function()
                wepent:EmitSound( "weapons/shotgun/shotgun_cock.wav", 70, 100, 1, CHAN_WEAPON )
                if bullettbl.Num == 12 then
                    self:HandleShellEject( "ShotgunShellEject" )-- For the double shell secondary attack, not really important
                end
                self:HandleShellEject( "ShotgunShellEject" )
            end)
            
            return true
        end,

        islethal = true,
    }

})