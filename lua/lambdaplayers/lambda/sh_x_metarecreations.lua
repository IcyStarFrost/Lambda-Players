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
    return 0
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
    eyetracetable.endpos = attach.Ang:Forward() * 30000
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