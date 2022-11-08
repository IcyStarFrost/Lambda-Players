local random = math.random
local IsValid = IsValid
local CreateEnt = ents.Create
local ipairs = ipairs
local table_insert = table.insert
local table_remove = table.remove
local tobool = tobool
local Angle = Angle
local caneditworld = GetConVar( "lambdaplayers_building_caneditworld" )
local caneditnonworld = GetConVar( "lambdaplayers_building_caneditnonworld" )

-- Building Helper functions --

-- Removes every entity we spawned
function ENT:CleanSpawnedEntities()
    self:DebugPrint( "cleaned up all their entities" )
    for k, v in ipairs( self.l_SpawnedEntities ) do
        if IsValid( v ) then v:Remove() self.l_SpawnedEntities[ k ] = nil end
    end
end

-- Removes the last entity we spawned
function ENT:UndoLastSpawnedEnt()
    local ent = self.l_SpawnedEntities[ 1 ]
    table_remove( self.l_SpawnedEntities, 1 )
    if IsValid( ent ) then ent:Remove() self:DebugPrint( "undone", ent ) self:EmitSound( "buttons/button15.wav", 60 ) end
end

-- If we are able to do whatever on the specified entity
function ENT:HasPermissionToEdit( ent )
    if !ent:GetPhysicsObject():IsValid() then return false end
    if ent.IsLambdaPlayer then return false end
    if ent.LambdaOwner == self then return true end
    if caneditworld:GetBool() and ent:CreatedByMap() then return true end
    local creator = ent:GetCreator()
    if IsValid( creator ) and creator:IsPlayer() then return tobool( creator:GetInfoNum( "lambdaplayers_building_canedityourents", 0 ) ) end 
    if caneditnonworld:GetBool() and !ent:CreatedByMap() then return true end
    return false
end

-- Building Functions --

-- Spawns a prop to where we are looking
function ENT:SpawnProp()
    if !self:IsUnderLimit( "Prop" ) then return end

    self:EmitSound( "ui/buttonclickrelease.wav", 60 )

    local trace = self:GetEyeTrace()
    local mdl = LambdaPlayerProps[ random( #LambdaPlayerProps ) ]

    local prop = CreateEnt( "prop_physics" )
    prop:SetPos( trace.HitPos )
    prop:SetAngles( Angle( 0, self:GetAngles()[ 2 ], 0 ) )
    prop:SetModel( mdl )
    prop.LambdaOwner = self
    prop.IsLambdaSpawned = true
    prop:Spawn()

    local mins, maxs = prop:GetModelBounds()
    local proppos = prop:GetPos()
    proppos[ 3 ] = proppos[ 3 ] - mins[ 3 ]
    prop:SetPos( proppos )

    self:DebugPrint( "spawned a prop ", prop )

    self:ContributeEntToLimit( prop, "Prop" )
    table_insert( self.l_SpawnedEntities, 1, prop )

    return prop
end

------