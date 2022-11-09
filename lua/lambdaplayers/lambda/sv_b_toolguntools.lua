local IsValid = IsValid

function ENT:UseColorTool( target )
    if !IsValid( target ) then return end

    self:LookTo( target, 2 )

    coroutine.wait( 1 )

    self:UseWeapon( target:WorldSpaceCenter() )
    target:SetColor( ColorRand( false ) )

end