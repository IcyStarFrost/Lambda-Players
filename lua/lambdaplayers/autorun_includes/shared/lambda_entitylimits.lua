
LambdaEntityLimits = {}

-- Creates a entity limit for keeping track of whatever entities
-- See lambda/sv_entitylimits.lua for functions to add to the limit and check
function CreateLambdaEntLimit( name, default, max )
    CreateLambdaConvar( "lambdaplayers_limits_" .. name .. "limit", default, true, false, false, "The max amount of " .. name .. "s a lambda player is allowed to have", 0, max, { type = "Slider", name = name .. " Limit", decimals = 0, category = "Limits and Tool Permissions" } )
    if SERVER then LambdaEntityLimits[ #LambdaEntityLimits + 1 ] = name end
end


CreateLambdaEntLimit( "Prop", 300, 50000 )
CreateLambdaEntLimit( "Light", 5, 200 )
CreateLambdaEntLimit( "Lamp", 5, 200 )
CreateLambdaEntLimit( "Balloon", 10, 200 )
CreateLambdaEntLimit( "Dynamite", 5, 200 )
CreateLambdaEntLimit( "Hoverball", 5, 200 )
CreateLambdaEntLimit( "Emitter", 5, 200 )
CreateLambdaEntLimit( "Thruster", 5, 200 )
CreateLambdaEntLimit( "Rope", 5, 200 )

-- Called when all default entity limits are created.
-- This hook can be used to create entity limits with CreateLambdaEntLimit()
hook.Run( "LambdaOnEntLimitsCreated" )