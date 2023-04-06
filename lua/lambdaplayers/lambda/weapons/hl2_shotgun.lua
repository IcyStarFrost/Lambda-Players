local CurTime = CurTime
local random = math.random
local coroutine_wait = coroutine.wait
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
        origin = "Half-Life 2",
        prettyname = "SPAS 12",
        holdtype = "shotgun",
        killicon = "weapon_shotgun",
        bonemerge = true,
        keepdistance = 150,
        attackrange = 500,

        clip = 6,
        OnAttack = function( self, wepent, target )
            if self.l_Clip <= 0 then self:ReloadWeapon() return end

            -- Secondary double barrel attack
            if self.l_Clip >= 2 and random( 8 ) == 1 and self:IsInRange( target, 400 ) then
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
            self:SimpleWeaponTimer( 0.6, function()
                wepent:EmitSound( "Weapon_Shotgun.Special1", 70, 100, 1, CHAN_WEAPON )
                self:HandleShellEject( "ShotgunShellEject", Vector( 0, 12, 0 ), Angle( -180, 0, 0 ) )
            end)

            return true
        end,

        OnReload = function( self, wepent )
            local animID = self:LookupSequence( "reload_shotgun_base_layer" )
            if animID != -1 then 
                self:AddGestureSequence( animID ) 
            else 
                self:AddGesture( ACT_HL2MP_GESTURE_RELOAD_SHOTGUN )
            end

            self:SetIsReloading( true )
            self:Thread( function()

                coroutine_wait( 0.5 )

                while ( self.l_Clip < self.l_MaxClip ) do
                    local ene = self:GetEnemy()
                    if self.l_Clip > 0 and random( 1, 2 ) == 1 and self:InCombat() and self:IsInRange( ene, 512 ) and self:CanSee( ene ) then break end
                    self.l_Clip = self.l_Clip + 1
                    wepent:EmitSound( "Weapon_Shotgun.Reload" )
                    coroutine_wait( 0.5 )
                end

                local ene = self:GetEnemy()
                if self.l_Clip > 0 and random( 1, 2 ) == 1 and self:InCombat() and self:IsInRange( ene, 512 ) and self:CanSee( ene ) then 
                    wepent:EmitSound( "Weapon_Shotgun.Special1" )
                else
                    coroutine_wait( 0.4 )
                end

                self:RemoveGesture( ACT_HL2MP_GESTURE_RELOAD_SHOTGUN )
                self:SetIsReloading( false )
            
            end, "HL2_ShotgunReload" )

            return true
        end,

        islethal = true
    }
} )