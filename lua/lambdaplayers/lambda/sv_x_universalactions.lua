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
local rand = math.Rand

-- Random weapon switching
AddUActionToLambdaUA( function( self )
    if self:GetState() == "Idle" then
        self:SwitchToRandomWeapon()
    elseif self:GetState() == "Combat" then
        self:SwitchToLethalWeapon()
    end
end )

-- Use a random act
AddUActionToLambdaUA( function( self )
    if self:GetState() != "Idle" or random( 1, 2 ) != 1 then return end
    self:CancelMovement()
    self:SetState( "UsingAct" )
end )

-- Undo entities
AddUActionToLambdaUA( function( self )
    if self:GetState() != "Idle" then return end
    self:NamedTimer( "Undoentities", rand( 0.3, 0.6 ), random( 1, 6 ), function() self:UndoLastSpawnedEnt() end )
end )


-- Crouch
AddUActionToLambdaUA( function( self )
    self:SetCrouch( true )
    self:NamedTimer( "UnCrouch", rand( 1, 30 ), 1, function() self:SetCrouch( false ) end )
end )



-- Called when all default UA actions have been made
-- This hook can be used to add UActions with AddUActionToLambdaUA()
hook.Run( "LambdaOnUAloaded" )