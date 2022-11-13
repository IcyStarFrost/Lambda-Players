AddCSLuaFile()

ENT.Base = "base_anim"

local physgunglow1 = Material( "sprites/physg_glow1" )
local physgunglow2 = Material( "sprites/physg_glow2" )
local physgunbeam = Material( "sprites/physbeama" )

function ENT:Initialize()

    self:SetModel( "models/hunter/plates/plate.mdl" )

    if CLIENT then
        local render_SetMaterial = render.SetMaterial
        local render_StartBeam = render.StartBeam
        local render_AddBeam = render.AddBeam
        local render_EndBeam = render.EndBeam
        local render_DrawSprite = render.DrawSprite
        local random = math.random
        local IsValid = IsValid
        local LerpVector = LerpVector


        self:SetRenderBounds( Vector( -100000, -100000, -100000 ), Vector( 100000, 100000, 100000 ) )


        hook.Add( "PreDrawEffects", self, function()

            if self:GetDrawBeam() then

                local s = self:GetStartPos()
                local e = self:GetEndPos()
                local forward = self:GetForward()
                local target = self:GetTargetEnt()
                local segments = 15
                local color = self:GetPhysColor():ToColor()
                local size = random( 10, 15 )
        
                -- Apparently this how we make the pointer and beam "Stick" to a certain spot of the target with a localized endpos to them
                if IsValid( target ) then
                    e = target:GetPos() + target:GetForward() * self:GetEndPos()[ 1 ] + target:GetRight() * -self:GetEndPos()[ 2 ] + target:GetUp() * self:GetEndPos()[ 3 ]
                end
        
                render_SetMaterial( physgunbeam )
        
                render_StartBeam( segments + 2 )
        
                    render_AddBeam( s, random( 1, 2 ), random( 1, 10 ), color )
        
                    for i=1, segments do
                        
                        -- This actually makes a pretty decent beam
                        local lerp = LerpVector( i / 15, s + forward * ( 2 + i * 10 ), e )
        
                        render_AddBeam( lerp, random( 1, 2 ), random( 1, 10 ), color )
        
                    end
        
                    render_AddBeam( e, random( 1, 2 ), random( 1, 10 ), color )
        
                render_EndBeam()
        
                -- End of the beam glowy bit
                render_SetMaterial( physgunglow1 )
                render_DrawSprite( e, size, size, color )
        
        
            end
            
        end )


    end

end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

function ENT:SetupDataTables()

    self:NetworkVar( "Bool", 0, "DrawBeam" )

    self:NetworkVar( "Vector", 0, "StartPos" )
    self:NetworkVar( "Vector", 1, "EndPos" )
    self:NetworkVar( "Vector", 2, "PhysColor" )

    self:NetworkVar( "Entity", 0, "TargetEnt" )

    self:SetPhysColor( Vector( 1, 1, 1 ) )

end

-- Don't draw model
function ENT:Draw() end