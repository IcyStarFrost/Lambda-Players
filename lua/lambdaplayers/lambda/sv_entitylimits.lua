local table_remove = table.remove
local table_insert = table.insert
local IsValid = IsValid
local ipairs = ipairs
local pairs = pairs

-- This is a nice and easy way of setting up a limit like Prop Limits, NPC limits, and ect

-- Limits are created in shared/convars.lua
for k, name in pairs( _LAMBDAEntLimits ) do
    ENT[ "l_Spawned" .. name ] = {}
end

-- Gets the limit
function ENT:GetLimit( name )
    return GetConVar( "lambdaplayers_limits_" .. name .. "limit" ):GetInt()
end


-- Adds a entity to a limit
function ENT:ContributeEntToLimit( ent, name )
    table_insert( self[ "l_Spawned" .. name ], ent )
end

-- Returns the number of valid entities in the specified name
function ENT:GetSpawnedEntCount( name )
    for k, v in ipairs( self[ "l_Spawned" .. name ] ) do
        if !IsValid( v ) then table_remove( self[ "l_Spawned" .. name ], k ) end
    end
    return #self[ "l_Spawned" .. name ]
end

-- Returns if we are under the max limit of the specified name
function ENT:IsUnderLimit( name )
    return self:GetSpawnedEntCount( name ) < self:GetLimit( name )
end


