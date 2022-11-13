
EFFECT.Mat = Material("sprites/physcannon_beam")

function EFFECT:Init( data )

	self.Position = data:GetStart()
	self.WeaponEnt = data:GetEntity()
	self.Attachment = data:GetAttachment()
	

	-- Keep the start and end pos - we're going to interpolate between them
	self.StartPos = self:GetTracerShootPos( self.Position, self.WeaponEnt, self.Attachment )
	self.EndPos = data:GetOrigin()

	self.Alpha = 255
	self.Life = 0

	self:SetPos(data:GetStart())

	self:SetRenderBoundsWS( self.StartPos, self.EndPos )

	if ( IsValid( self.WeaponEnt ) ) then
		self:SetParentPhysNum( self.Attachment )
		self:SetParent( self.WeaponEnt )
	end

end

function EFFECT:Think()

	self.Life = self.Life + FrameTime() * 5
	self.Alpha = 255 * ( 1 - self.Life )

	return ( self.Life < 1 )

end

function EFFECT:Render()

	if ( self.Alpha < 1 ) then return end

	render.SetMaterial( self.Mat )

	local norm = (self.StartPos - self.EndPos) * self.Life

	self.Length = norm:Length()

	render.DrawBeam( self:GetPos(),
					self.EndPos,
					20,
					0 + self.Life / 9,
					1 - self.Life / 9, --Just to get that tiny movement to make it less static
					Color( 255, 255, 255 ) )

end
