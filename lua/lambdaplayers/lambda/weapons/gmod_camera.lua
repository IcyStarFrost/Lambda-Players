local EffectData = EffectData
local util_Effect = util.Effect


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
            if !dead and LambdaRNG( 3 ) != 1 then
                self:LookTo( self:EyePos() + VectorRand( -400, 400 ), 1.25 )
                self:SimpleWeaponTimer( 0.8, function() self:UseWeapon() end )
            end

            return LambdaRNG( 0.55, 10, true )
        end,

        OnAttack = function( self, wepent )
            wepent:EmitSound( "NPC_CScanner.TakePhoto" )
            self.l_WeaponUseCooldown = ( CurTime() + 0.5 )

            local attach = wepent:GetAttachment( 1 )
            if takeViewShots:GetBool() then self:TakeViewShot( attach.Pos ) end

            local effectData = EffectData()
            effectData:SetOrigin( attach.Pos )
            util_Effect( "camera_flash", effectData, true )

            return true
        end
    }
} )