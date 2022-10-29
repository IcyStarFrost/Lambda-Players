

local IsValid = IsValid
local dev = GetConVar( "developer" )

-- Start off simple
function ENT:MoveToPos( pos, options )
    local isent = !isvector( pos )
    if isent and !IsValid( isent ) then return "failed" end

	local options = options or {}

	local path = Path( "Follow" )
	path:SetMinLookAheadDistance( options.lookahead or 300 )
	path:SetGoalTolerance( options.tol or 20 )
	path:Compute( self, ( isent and pos:GetPos() or pos) )

    self.loco:SetDesiredSpeed( options.speed or 200 )

	if ( !path:IsValid() ) then return "failed" end

    self.IsMoving = true

	while ( path:IsValid() ) do
        if self.AbortMovement then self.AbortMovement = false self.IsMoving = false return "aborted" end

		path:Update( self )

        if dev:GetBool() then
            path:Draw()
        end

		if ( self.loco:IsStuck() ) then

			self:HandleStuck()
            self.IsMoving = false
			return "stuck"
		end

		if options.timeout then
			if path:GetAge() > options.timeout then self.IsMoving = false return "timeout" end
		end

		if options.update then
			if path:GetAge() > options.update then path:Compute( self, ( isent and pos:GetPos() or pos ) ) end
		end

		coroutine.yield()

	end

    self.IsMoving = false

	return "ok"

end

function ENT:CancelMovement()
    self.AbortMovement = self.IsMoving
end


function ENT:PathGenerator()
    local stepHeight = self.loco:GetStepHeight()
    local jumpHeight = self.loco:GetJumpHeight()
    local deathHeight = -self.loco:GetDeathDropHeight()

    return function(area, fromArea, ladder, elevator, length)
        if !IsValid(fromArea) then return 0 end
        if !self.loco:IsAreaTraversable(area) then return -1 end

        local dist = 0
        if IsValid(ladder) then
            dist = ladder:GetBottom():DistToSqr(ladder:GetTop())
        elseif length > 0 then
            dist = length
        else
            dist = fromArea:GetCenter():DistToSqr(area:GetCenter())
        end

        local cost = (dist + fromArea:GetCostSoFar())
        if !IsValid(ladder) then
            local deltaZ = fromArea:ComputeAdjacentConnectionHeightChange(area)
            if deltaZ > stepHeight then
                if deltaZ > jumpHeight then return -1 end
                local jumpPenalty = 10
                cost = cost + jumpPenalty * dist
            elseif deltaZ < deathHeight then
                return -1
            end
        end

        return cost
    end
end