local CurTime = CurTime
local random = math.random

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    grenade = {
        model = "models/weapons/w_grenade.mdl",
        origin = "Half Life: 2",
        prettyname = "Grenade",
        holdtype = "grenade",
        bonemerge = true,
        keepdistance = 450,
        attackrange = 1000,

        clip = 1,

        reloadtime = 1.5,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        reloadanimationspeed = 1,
        reloadsounds = { },

        callback = function( self, wepent, target )
            if self.l_Clip <= 0 then self:ReloadWeapon() return end-- Just in case

            self.l_WeaponUseCooldown = CurTime() + 1.5

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )

            local throwforce = 1200
            local normal = self:GetForward()

            wepent:EmitSound( "weapons/slam/throw.wav", 70, 100, 1, CHAN_WEAPON )

            if IsValid( target ) and self:GetRangeSquaredTo( target ) < (400 * 400) then
                throwforce = 400
            end
            if IsValid( target ) then
                normal = ( target:GetPos() - self:GetPos() ):Angle():Forward()
            end

            local grenade = ents.Create( "npc_grenade_frag" )
            grenade:SetPos( self:GetPos() + Vector(0,0,60) + self:GetForward() * 40 + self:GetRight() * -10 )
            grenade:Fire( "SetTimer", 3, 0 )
            grenade:SetSaveValue( "m_hThrower", self )
            grenade:SetOwner( self )
            grenade:Spawn()
            grenade:SetHealth( 99999 )
            local frag = grenade:GetPhysicsObject()
            if IsValid( frag ) then
                frag:ApplyForceCenter( normal * throwforce )
                frag:AddAngleVelocity( Vector(200,random(-600,600),0) )
            end
            
            return true
        end,

        islethal = true,
    }

})