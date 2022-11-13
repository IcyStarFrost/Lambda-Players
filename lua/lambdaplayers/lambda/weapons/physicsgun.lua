

local physgunGlowMat = Material("sprites/physg_glow1")
local physgunGlowMat2 = Material("sprites/physg_glow2")
local random = math.random

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    physgun = {
        model = "models/weapons/w_physics.mdl",
        origin = "Garry's Mod",
        prettyname = "Physics Gun",
        bonemerge = true,
        holdtype = "physgun",

        OnEquip = function( lambda, wepent )
            wepent:SetSkin( 1 )
            wepent:SetSubMaterial( 1, "lambdaplayers/physgun/w_physics_sheet2")
        end,

        -- Custom rendering effects
        Draw = function( lambda, wepent )

            if IsValid( wepent ) then
                
                local size = random( 30, 50 )
                local drawPos = ( wepent:GetPos() + wepent:GetUp() * 2 )
                local color = lambda:GetPhysColor()

                render.SetMaterial( physgunGlowMat )
                render.DrawSprite( drawPos + wepent:GetForward() * 25, size, size, color:ToColor() )

                render.SetMaterial( physgunGlowMat2 )
                render.DrawSprite( drawPos + wepent:GetForward() * 30, size, size, color:ToColor() )

            end

        end,

        OnUnequip = function( lambda, wepent )
            wepent:SetSkin( 0 )
            wepent:SetSubMaterial( 1 )
        end,


        islethal = false,

    }

})