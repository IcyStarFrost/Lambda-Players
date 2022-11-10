local table_insert = table.insert
local table_ClearKeys = table.ClearKeys

ENT.l_UniversalActions = {}

-- Adds a function the Universal Actions
function AddUActionToLambdaUA( func )
    table_insert( ENT.l_UniversalActions, func )
end


-- Random weapon switching
AddUActionToLambdaUA( function( self )
    if self:GetState() != "Idle" then return end
    self:SwitchToRandomWeapon()
end )


-- Called when all default UA actions have been made
-- This hook can be used to add UActions with AddUActionToLambdaUA()
hook.Run( "LambdaOnUAloaded" )