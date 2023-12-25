local EffectData = EffectData
local util_Effect = util.Effect
local random = math.random
local Rand = math.Rand
local VectorRand = VectorRand
local takeViewShots = CreateLambdaConvar( "lambdaplayers_weapons_cameraviewshots", 0, true, false, false, "If the camera should take view shots on its capture.", 0, 1, { type = "Bool", name = "Camera - Take View Shots", category = "Weapon Utilities" } )

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    gmod_camera = {
        model = "models/maxofs2d/camera.mdl",
        origin = "Garry's Mod",
        prettyname = "Camera",
        holdtype = "camera",
        keepdistance = 400,
        attackrange = 900,
        islethal = false,
        bonemerge = true,

        OnThink = function( self, wepent, dead )
            if !dead and random( 3 ) != 1 then 
                self:LookTo( self:EyePos() + VectorRand( -400, 400 ), 1.25 )
                self:SimpleWeaponTimer( 0.8, function() self:UseWeapon() end )
            end

            return Rand( 0.55, 10 )
        end,

        OnAttack = function( self, wepent )
            wepent:EmitSound( "NPC_CScanner.TakePhoto" )
            self.l_WeaponUseCooldown = ( CurTime() + 0.5 )

            local effectData = EffectData()
            effectData:SetOrigin( wepent:GetAttachment( 1 ).Pos )
            util_Effect( "camera_flash", effectData, true )
            
            if takeViewShots:GetBool() then self:TakeViewShot() end
            return true
        end
    }
} )