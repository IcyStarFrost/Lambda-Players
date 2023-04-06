local TraceLine = util.TraceLine
local util_Effect = util.Effect
local random = math.random
local tracetbl = {}

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    toolgun = {
        model = "models/weapons/w_toolgun.mdl",
        origin = "Garry's Mod",
        prettyname = "Toolgun",
        holdtype = "revolver",
        bonemerge = true,

        OnAttack = function( self, wepent, target )

            wepent:EmitSound( "weapons/airboat/airboat_gun_lastshot" .. random( 1, 2 ) .. ".wav", 70, 100, 1, CHAN_WEAPON )

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_REVOLVER )

            local muzzle = wepent:GetAttachment( 1 )

            tracetbl.start = muzzle.Pos
            tracetbl.endpos = ( isentity( target ) and target:WorldSpaceCenter() or target )
            tracetbl.filter = self
            
            local result = TraceLine( tracetbl )

            local effect = EffectData()
            effect:SetStart( muzzle.Pos )
            effect:SetOrigin( result.HitPos )
            effect:SetEntity( wepent )
            effect:SetScale( 4000 )
            util_Effect( "ToolTracer", effect, true, true)

            local effect = EffectData()
            effect:SetStart( result.HitPos )
            effect:SetOrigin( result.HitPos )
            effect:SetEntity( result.Entity )
            effect:SetNormal( result.HitNormal )
            util_Effect( "selection_indicator", effect, true, true)

            return true
        end,

        islethal = false,

    }

})