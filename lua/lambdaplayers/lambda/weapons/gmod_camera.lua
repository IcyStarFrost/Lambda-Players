local EffectData = EffectData
local util_Effect = util.Effect
local random = math.random
local Rand = math.Rand
local VectorRand = VectorRand

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    gmod_camera = {
        model = "models/maxofs2d/camera.mdl",
        origin = "Garry's Mod",
        prettyname = "Camera",
        holdtype = "camera",
        keepdistance = 300,
        attackrange = 600,
        islethal = false,
        bonemerge = true,

        OnThink = function( self, wepent, dead )
            if !dead and random( 3 ) != 1 then 
                self:LookTo( self:GetAttachmentPoint( "eyes" ).Pos + VectorRand( -400, 400 ), 1.25 )
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
        
            return true
        end
    }
} )