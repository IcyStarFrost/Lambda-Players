
EFFECT.Mat = Material("sprites/physcannon_blast")

function EFFECT:Init( data )

	local pos = data:GetOrigin()
	local att = data:GetAttachment()
	local ent = data:GetEntity()

	self:SetRenderBounds( Vector( -8, -8, -8 ), Vector( 8, 8, 8 ) )
	self:SetPos( pos )

	if ( IsValid( ent ) ) then
		self:SetParentPhysNum( att )
		self:SetParent( ent )
	end

	self.Size = 13
	self.Alpha = 255
end

function EFFECT:Think()

	self.Alpha = self.Alpha - 255 * FrameTime()*4
	if(self.Size < 50) then
		self.Size = self.Size + 600 * FrameTime()
	else
		self.Size = self.Size + 50 * FrameTime()
	end
	if ( self.Alpha < 0 ) then return false end
	return true

end

function EFFECT:Render()

	if ( self.Alpha < 1 ) then return end

	render.SetMaterial( self.Mat )

	render.DrawSprite( self:GetPos(), self.Size, self.Size, Color( 255, 255, 255, self.Alpha ) )
end