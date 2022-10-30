

function ENT:UseColorTool( target )

    self:LookTo( target, 2 )

    coroutine.wait( 1 )

    self:UseWeapon( target:WorldSpaceCenter() )
    target:SetColor( ColorRand( false ) )

end