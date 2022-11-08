local CurTime = CurTime
local random = math.random
local ballMass = GetConVar( "sk_weapon_ar2_alt_fire_mass" )
local ballRadius = GetConVar( "sk_weapon_ar2_alt_fire_radius" )
local ballTime = GetConVar( "sk_weapon_ar2_alt_fire_duration" )

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    ar2 = {
        model = "models/weapons/w_irifle.mdl",
        origin = "Half Life: 2",
        prettyname = "AR2",
        holdtype = "ar2",
        bonemerge = true,
        keepdistance = 400,
        attackrange = 2500,

        clip = 30,
        tracername = "AR2Tracer",
        damage = 8,
        spread = 0.1,
        rateoffire = 0.10,
        muzzleflash = 5,
        shelleject = "none",
        attackanim = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2,
        attacksnd = "Weapon_AR2.Single",

        reloadtime = 1.5,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        reloadanimationspeed = 1,
        reloadsounds = { 
            { 0, "Weapon_AR2.Reload_Rotate" },
            { 0.63, "Weapon_AR2.Reload_Push" }
        },

        islethal = true,

        callback = function( self, wepent, target )
            -- Secondary orb launcher
            if random( 75 ) == 1 then
                self.l_WeaponUseCooldown = CurTime() + 1.25
                wepent:EmitSound( "Weapon_CombineGuard.Special1" )

                self:SimpleTimer( 0.75, function()
                    if IsValid( wepent ) then
                        local comBall = ents.Create( "prop_combine_ball" )
                        if IsValid( comBall ) then 
                            wepent:EmitSound( "Weapon_IRifle.Single" )

                            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW )

                            local launchAng = ( IsValid( target ) and ( target:WorldSpaceCenter() - self:EyePos() ):Angle() or self:GetAngles() )
                            local launchVel = ( launchAng:Forward() * 1000 )
                            
                            comBall:SetSaveValue( "m_flRadius", ballRadius:GetFloat() )
                            comBall:SetPos( self:EyePos() + launchAng:Forward() * 32 + launchAng:Up() * 32 )
                            comBall:SetOwner( self )
                            comBall:Spawn()
                            comBall:SetSaveValue( "m_nState", 2 )
                            comBall:SetSaveValue( "m_flSpeed", launchVel:Length() )
                            comBall:Fire( "Explode", nil, ballTime:GetInt() )

                            local phys = comBall:GetPhysicsObject()
                            if IsValid( phys ) then
                                phys:SetVelocity( launchVel )
                                phys:AddGameFlag( FVPHYSICS_WAS_THROWN )

                                phys:SetMass( ballMass:GetFloat() )
                                phys:SetInertia( Vector( 500, 500, 500 ) )
                            end
                        end
                    end
                end)
                
                return true
            end
        end
    }

})