
local RandomPairs = RandomPairs
local IsValid = IsValid
local ipairs = ipairs


-- Anything Shared can go here

function ENT:DebugPrint( ... )
    print( self:GetLambdaName() .. " EntIndex = (" .. self:EntIndex() .. ")" .. ": ", ... )
end



function ENT:GetBoneTransformation( bone )
    local pos, ang = self:GetBonePosition( bone )

    if !pos or pos:IsZero() or pos == self:GetPos() then
        local matrix = self:GetBoneMatrix( bone )

        if matrix and ismatrix( matrix ) then

            return { Pos = matrix:GetTranslation(), Ang = matrix:GetAngles() }
        end

    end
    
    return { Pos = pos, Ang = ang }
end

function ENT:GetAttachmentPoint( pointtype )

    if pointtype == "hand" then
        local lookup = self:LookupAttachment( 'anim_attachment_RH' )
  
        if lookup == 0 then
            local bone = self:LookupBone( "ValveBiped.Bip01_R_Hand" )

            if !bone then
                return { Pos = self:WorldSpaceCenter(), Ang = self:GetForward():Angle() }
            else
                if isnumber( bone ) then
                    return self:GetBonePosAngs( bone )
                else
                    return { Pos = self:WorldSpaceCenter(), Ang = self:GetForward():Angle() }
                end
            end

        else
            return self:GetAttachment( lookup )
        end
  
    elseif pointtype == "eyes" then
        
        local lookup = self:LookupAttachment( 'eyes' )
    
        if lookup == 0 then
            return { Pos = self:WorldSpaceCenter() + Vector( 0, 0, 5 ), Ang = self:GetForward():Angle() + Angle( 20, 0, 0 ) }
        else
            return self:GetAttachment( lookup )
        end
    
    end
  
  end


--


if SERVER then

    local GetAllNavAreas = navmesh.GetAllNavAreas


    -- Returns a sequential table full of nav areas new the position
    function ENT:GetNavAreas( pos, dist )
        pos = pos or self:GetPos()
        dist = dist or 1500

        local areas = GetAllNavAreas()
        local neartbl = {}

        local squared = dist * dist

        for k, v in ipairs( areas ) do
            if IsValid( v ) and v:GetSizeX() > 75 and v:GetSizeY() > 75 and !v:IsUnderwater() and v:GetClosestPointOnArea( pos ):DistToSqr( pos ) <= squared then
                neartbl[ #neartbl + 1 ] = v
            end
        end

        return neartbl
    end
    
    -- Returns a random position near the position 
    function ENT:GetRandomPosition( pos, dist )
        pos = pos or self:GetPos()
        dist = dist or 1500

        local areas = self:GetNavAreas( pos, dist )

        for k, v in RandomPairs( areas ) do
            if IsValid( v ) then
                return v:GetRandomPoint()
            end
        end
    end


elseif CLIENT then


end