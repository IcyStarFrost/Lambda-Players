local table_insert = table.insert
local rand = math.Rand
local coroutine = coroutine

LambdaBuildingFunctions = {}

-- This system is pretty much the same exact as the toolgun system
-- Adds a function to the list of building functions Lambda Players can use
-- These functions will be under the Build Chance

-- This function has its args different from the toolgun system since that could be many things that could be considered building. So the developer needs to ability to customize the setting name and description
function AddBuildFunctionToLambdaBuildingFunctions( spawnname, settingname, desc, func )
    local convar = CreateLambdaConvar( "lambdaplayers_building_allow" .. spawnname, 1, true, false, false, desc, 0, 1, { type = "Bool", name = settingname, category = "Building" } )
    table_insert( LambdaBuildingFunctions, { spawnname, convar, func } )
end


local function SpawnAProp( self )
    if !self:IsUnderLimit( "Prop" ) then return end
    
    self.Face = self:GetPos() + VectorRand( -100, 100 )
    coroutine.wait( rand( 0.2, 1 ) )
    self:SpawnProp()
    coroutine.wait( rand( 0.2, 1 ) )
    self.Face = nil

    return true -- Just like for toolguns, we return true to let the for loop know we completed what we wanted to do and it can break
end
AddBuildFunctionToLambdaBuildingFunctions( "prop", "Allow Prop Spawning", "If Lambda Players are allowed to spawn props", SpawnAProp )


-- Called when all default building functions above have been loaded.
-- This hook can be used to add more building functions with AddBuildFunctionToLambdaBuildingFunctions()
hook.Run( "LambdaOnBuildFunctionsLoaded" )