

local LambdaIsValid = LambdaIsValid
local dev = GetConVar( "developer" )
local aidisable = GetConVar( "ai_disabled" )
local math_max = math.max

-- Start off simple
function ENT:MoveToPos( pos, options )
    local isent = !isvector( pos )
    if isent and !LambdaIsValid( pos ) then return "failed" end

	local options = options or {}
    local timeout = options.timeout
    local update = options.update
    local callback = options.callback

	local path = Path( "Follow" )
	path:SetMinLookAheadDistance( options.lookahead or 300 )
	path:SetGoalTolerance( options.tol or 20 )
	path:Compute( self, ( isent and pos:GetPos() or pos), self:PathGenerator() )

    self.loco:SetDesiredSpeed( options.speed or 200 )

	if ( !path:IsValid() ) then return "failed" end

    self.IsMoving = true

	while ( path:IsValid() ) do
        if isent and !LambdaIsValid( pos ) then return "invalid" end
        if self:GetIsDead() then return "dead" end
        if self.AbortMovement then self.AbortMovement = false self.IsMoving = false return "aborted" end

        local goal = path:GetCurrentGoal()


        if !aidisable:GetBool() then
            if callback and isfunction( callback ) then callback( goal ) end 
            path:Update( self )
        end

        

        if dev:GetBool() then
            path:Draw()
        end

		if ( self.loco:IsStuck() ) then

			self:HandleStuck()
            self.IsMoving = false
			return "stuck"
		end

		if timeout then
			if path:GetAge() > timeout then self.IsMoving = false return "timeout" end
		end

		if update then
            local updateTime = math_max( update, update * ( path:GetLength() / 400 ) )
			if path:GetAge() > updateTime then path:Compute( self, ( isent and pos:GetPos() or pos ), self:PathGenerator() ) end
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
        if !LambdaIsValid(fromArea) then return 0 end
        if !self.loco:IsAreaTraversable(area) then return -1 end

        local dist = 0
        if LambdaIsValid(ladder) then
            dist = ladder:GetBottom():DistToSqr(ladder:GetTop())
        elseif length > 0 then
            dist = length
        else
            dist = fromArea:GetCenter():DistToSqr(area:GetCenter())
        end

        local cost = (dist + fromArea:GetCostSoFar())
        if !LambdaIsValid(ladder) then
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