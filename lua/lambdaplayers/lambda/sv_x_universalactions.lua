local table_insert = table.insert
local table_ClearKeys = table.ClearKeys
ENT.l_UniversalActions = {}


local function SwitchWeaponIfIdle( self )
    if self:GetState() != "idle" then return end
    self:SwitchToRandomWeapon()
end
table_insert( ENT.l_UniversalActions, SwitchWeaponIfIdle )


-- Called when all default UA actions have been made
-- This hook can be used to insert custom UA functions into the l_UniversalActions table
-- Custom functions should be added by table.insert
hook.Run( "LambdaOnUAloaded", ENT.l_UniversalActions )

ENT.l_UniversalActions = table_ClearKeys( ENT.l_UniversalActions )