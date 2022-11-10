local table_insert = table.insert
local random = math.random
local rand = math.Rand
local ColorRand = ColorRand
local VectorRand = VectorRand
local ents_Create = ents.Create
local zeroangle = Angle()

LambdaToolGunTools = {}

-- Adds a tool function to the list of tools
-- See the functions below for examples on making tools
function AddToolFunctionToLambdaTools( toolname, func )
    local convar = CreateLambdaConvar( "lambdaplayers_tool_allow" .. toolname, 1, true, false, false, "If lambda players can use the " .. toolname .. " tool", 0, 1, { type = "Bool", name = "Allow " .. toolname .. " Tool", category = "Limits and Tool Permissions" } )
    table_insert( LambdaToolGunTools, { toolname, convar, func } )
end


-- Helper function for gmod entities 

local function CreateGmodEntity( classname, pos, ang, lambda )

    local ent = ents_Create( classname )
    ent:SetPos( pos )
    ent:SetAngles( ang or zeroangle )
    LambdaHijackGmodEntity( ent, lambda ) -- Make it support the lambda
    ent:Spawn()
    ent:Activate()

    return ent
end




local function UseColorTool( self, target )
    if !IsValid( target ) then return end -- Returning nothing is basically the same as returning false

    self:LookTo( target, 2 )

    coroutine.wait( 1 )
    if !IsValid( target ) then return end -- Because we wait 1 second we must make sure the target is valid

    self:UseWeapon( target:WorldSpaceCenter() ) -- Use the toolgun on the target to fake using a tool
    target:SetColor( ColorRand( false ) )

    return true -- Return true to let the for loop in Chance_Tool know we actually got to use the tool so it can break. All tools must do this
end
AddToolFunctionToLambdaTools( "Color", UseColorTool )

local function UsematerialTool( self, target )
    if !IsValid( target ) then return end

    self:LookTo( target, 2 )

    coroutine.wait( 1 )
    if !IsValid( target ) then return end

    self:UseWeapon( target:WorldSpaceCenter() )
    target:SetMaterial( LambdaPlayerMaterials[ random( #LambdaPlayerMaterials ) ] )

    return true
end
AddToolFunctionToLambdaTools( "Material", UsematerialTool )


local function UseLightTool( self, target )
    if !self:IsUnderLimit( "Light" ) then return end -- Can't create any more lights

    local pos = self:Trace( self:WorldSpaceCenter() + VectorRand( -600, 600 ) ).HitPos
    
    self:LookTo( pos, 2 )

    coroutine.wait( 1 )

    self:UseWeapon( pos )
    local ent = CreateGmodEntity( "gmod_light", pos, nil, self ) -- Create the light
    self:ContributeEntToLimit( ent, "Light" )
    table_insert( self.l_SpawnedEntities, 1, ent )

    -- Aaannd configure it
    ent:SetPlayer( self ) -- We can safely set this to ourselves since it was "hijacked"
    ent:SetOn( true )
    ent:SetColor( ColorRand( false ) )
    ent:SetBrightness( rand( 1, 6 ) )
    ent:SetLightSize( rand( 100, 1024 ) )

    return true
end
AddToolFunctionToLambdaTools( "Light", UseLightTool )

-- Called when all default tools are loaded
-- This hook can be used to add custom tool functions by using AddToolFunctionToLambdaTools()
hook.Run( "LambdaOnToolsLoaded" )