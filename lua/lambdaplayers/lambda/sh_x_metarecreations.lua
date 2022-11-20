-- Functions below are recreations of whatever gmod meta functions

local Trace = util.TraceLine
local eyetracetable = {}

-- Our name
function ENT:Nick()
    return self:GetLambdaName()
end

-- Returns our eye position
function ENT:EyePos()
    return self:GetAttachmentPoint( "eyes" ).Pos
end

-- Our team
function ENT:Team()
    return TEAM_UNASSIGNED
end

-- Returns our eye angles
function ENT:EyeAngles()
    return self:GetAttachmentPoint( "eyes" ).Ang
end

-- If we are alive
function ENT:Alive()
    return !self:GetIsDead() 
end

-- Returns the direction we are looking to
function ENT:GetAimVector()
    return self:GetAttachmentPoint( "eyes" ).Ang:Forward()
end

-- Returns our current armor value
function ENT:Armor()
    return self:GetArmor()
end


-- Add a certain amount to the Lambda's frag count (or kills count)
function ENT:AddFrags( count ) 
    self:SetFrags( self:GetFrags() + count )
end

-- Add a certain amount to the Lambda's death count
function ENT:AddDeaths( count ) 
    self:AddDeaths( self:GetDeaths() + count )
end


-- Returns our kill count
function ENT:Frags()
    return self:GetFrags()
end

-- Returns how much we died
function ENT:Deaths()
    return self:GetDeaths()
end

-- Returns our current ping
function ENT:Ping()
    return self:GetPing()
end

function ENT:IsAdmin()
    return false
end

function ENT:IsSuperAdmin()
    return false
end

-- Similar to Real Player's :GetEyeTrace()
function ENT:GetEyeTrace()
    local attach = self:GetAttachmentPoint( "eyes" )
    eyetracetable.start = attach.Pos
    eyetracetable.endpos = attach.Ang:Forward() * 32768
    eyetracetable.filter = self
    local result = Trace( eyetracetable )
    return result
end

if CLIENT then


    function ENT:IsMuted() 
        return false
    end

    function ENT:SetMuted()
    end

    function ENT:SetVoiceVolumeScale()
    end

    function ENT:GetVoiceVolumeScale()
        return 1
    end


end