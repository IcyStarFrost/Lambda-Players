local IsValid = IsValid
local table_insert = table.insert

ENT.l_ToolgunTools = {}

local function UseColorTool( self, target )
    if !IsValid( target ) then return end

    self:LookTo( target, 2 )

    coroutine.wait( 1 )

    self:DebugPrint( "Used Color Tool" )
    self:UseWeapon( target:WorldSpaceCenter() )
    target:SetColor( ColorRand( false ) )

end
table_insert( ENT.l_ToolgunTools, UseColorTool )