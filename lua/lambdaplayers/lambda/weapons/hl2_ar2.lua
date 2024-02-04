local IsValid = IsValid
local CurTime = CurTime
local ents_Create = ents.Create


local ballIntertia = Vector( 500, 500, 500 )

local ballMass = GetConVar( "sk_weapon_ar2_alt_fire_mass" )
local ballRadius = GetConVar( "sk_weapon_ar2_alt_fire_radius" )
local ballTime = GetConVar( "sk_weapon_ar2_alt_fire_duration" )


table.Merge( _LAMBDAPLAYERSWEAPONS, {

    ar2 = {
        model = "models/weapons/w_irifle.mdl",
        origin = "Half-Life 2",
        prettyname = "AR2",
        holdtype = "ar2",
        killicon = "weapon_ar2",
        bonemerge = true,
        keepdistance = 400,
        attackrange = 2500,
        islethal = true,
        dropentity = "weapon_ar2",

        clip = 30,
        tracername = "AR2Tracer",
        damage = 8,
        spread = 0.1,
        rateoffire = 0.10,
        muzzleflash = 5,
        attackanim = ACT_HL2MP_GESTURE_RANGE_ATTACK_AR2,
        attacksnd = "Weapon_AR2.Single",

        reloadtime = 1.5,
        reloadanim = ACT_HL2MP_GESTURE_RELOAD_AR2,
        reloadanimspeed = 1,
        reloadsounds = { 
            { 0, "Weapon_AR2.Reload_Rotate" },
            { 0.63, "Weapon_AR2.Reload_Push" }
        },

        OnAttack = function( self, wepent, target )
            if LambdaRNG( 75 ) != 1 then return end

            self.l_WeaponUseCooldown = ( CurTime() + LambdaRNG( 1.25, 1.5, true ) )
            wepent:EmitSound( "Weapon_CombineGuard.Special1" )

            self:SimpleWeaponTimer( 0.75, function()
                local comBall = ents_Create( "prop_combine_ball" )
                if !IsValid( comBall ) then return end 

                wepent:EmitSound( "Weapon_IRifle.Single" )
                self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_CROSSBOW )

                local wepPos = wepent:GetPos()
                local launchAng = ( IsValid( target ) and ( target:WorldSpaceCenter() - wepPos ):Angle() or self:GetAngles() )
                local launchVel = ( launchAng:Forward() * 1000 )
                
                comBall:SetSaveValue( "m_flRadius", 10 )
                comBall:SetPos( wepPos + launchAng:Forward() * 32 + launchAng:Up() * 32 )
                comBall:SetOwner( self )
                comBall:Spawn()
                comBall:SetSaveValue( "m_nState", 2 )
                comBall:SetSaveValue( "m_flSpeed", launchVel:Length() )
                comBall:Fire( "Explode", nil, 2 )

                local phys = comBall:GetPhysicsObject()
                if !IsValid( phys ) then return end

                phys:SetVelocity( launchVel )
                phys:AddGameFlag( FVPHYSICS_WAS_THROWN )
                phys:SetMass( 150 )
                phys:SetInertia( ballIntertia )
            end)
            
            return true
        end
    }
} )