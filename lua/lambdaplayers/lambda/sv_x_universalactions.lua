local table_insert = table.insert
local table_ClearKeys = table.ClearKeys
-- Universal actions are functions that are randomly called during run time.
-- This means Lambda players could randomly change weapons or randomly look at something and ect

ENT.l_UniversalActions = {}

-- Adds a function to the Universal Actions
function AddUActionToLambdaUA( func )
    table_insert( ENT.l_UniversalActions, func )
end

local random = math.random

-- Random weapon switching
AddUActionToLambdaUA( function( self )
    if self:GetState() != "Idle" then return end
    self:SwitchToRandomWeapon()
end )


-- Called when all default UA actions have been made
-- This hook can be used to add UActions with AddUActionToLambdaUA()
hook.Run( "LambdaOnUAloaded" )