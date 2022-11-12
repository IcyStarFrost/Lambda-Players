AddCSLuaFile()

ENT.Base = "base_anim"

local physgunglow1 = Material( "sprites/physg_glow1" )
local physgunglow2 = Material( "sprites/physg_glow2" )
local physgunbeam = Material( "sprites/physbeama" )

function ENT:Initialize()

    self:SetModel( "models/hunter/plates/plate.mdl" )

end

function ENT:SetupDataTables()

    self:NetworkVar( "Bool", "DrawBeam" )

    self:NetworkVar( "Vector", 0, "StartPos" )
    self:NetworkVar( "Vector", 1, "EndPos" )
    self:NetworkVar( "Vector", 2, "PhysColor" )

    self:NetworkVar( "Entity", 0, "TargetEnt" )

end


if SERVER then return end

local render = render
local random = math.random
local IsValid = IsValid

function ENT:Draw()

    if self:GetDrawBeam() then

        local s = self:GetStartPos()
        local e = self:GetEndPos()
        local target = self:GetTargetEnt()
        local segments = 2

        if IsValid( target ) then
            e = target:GetPos() + self:GetEndPos() 
        end

        render.SetMaterial( physgunbeam )
        
        render.StartBeam( segments )

            render.AddBeam( s, random( 1, 2 ), random( 1, 10 ), self:GetPhysColor() )



            render.AddBeam( e, random( 1, 2 ), random( 1, 10 ), self:GetPhysColor() )

        render.EndBeam()

    end

end