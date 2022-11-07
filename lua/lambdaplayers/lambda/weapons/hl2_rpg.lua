local CurTime = CurTime
local random = math.random

table.Merge( _LAMBDAPLAYERSWEAPONS, {
--Missing guided rockets

    rpg = {
        model = "models/weapons/w_rocket_launcher.mdl",
        origin = "Half Life: 2",
        prettyname = "RPG",
        holdtype = "rpg",
        bonemerge = true,
        keepdistance = 800,
        attackrange = 5000,

        clip = 1,

        reloadtime = 3,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        reloadanimationspeed = 1,
        reloadsounds = { },

        callback = function( self, wepent, target )
            if self.l_Clip <= 0 then self:ReloadWeapon() return end-- Just in case
            
            self.l_WeaponUseCooldown = CurTime() + 3

            wepent:EmitSound( "weapons/rpg/rocketfire1.wav", 70, 100, 1, CHAN_WEAPON )

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG )

            local rocket = ents.Create( "rpg_missile" )
            if IsValid( rocket ) then
                rocket:SetPos( wepent:GetAttachment(2).Pos + wepent:GetAttachment(2).Ang:Forward() * 100 + Vector(0,0,15) )
                rocket:SetAngles( (target:GetPos() + target:OBBCenter() - wepent:GetPos()):Angle() )
                rocket:SetOwner( self )
                rocket:SetCollisionGroup( COLLISION_GROUP_DEBRIS )-- SetOwner should prevent collision but it doesn't
                rocket:Spawn()
                
                self:SimpleTimer(0.3, function()-- Grace period to avoid collision with the shooter
                    if !IsValid( rocket ) then return false end
                    rocket:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )
                end)

                rocket:CallOnRemove( "lambdaplayer_rpgrocket_"..rocket:EntIndex(), function()
                    rocket:StopSound( "weapons/rpg/rocket1.wav" )
                    util.BlastDamage( rocket, (self:IsValid()) and self or rocket, rocket:GetPos(), 260, 210)
                end)
            end
            
            return true
        end,

        islethal = true,
    }

})