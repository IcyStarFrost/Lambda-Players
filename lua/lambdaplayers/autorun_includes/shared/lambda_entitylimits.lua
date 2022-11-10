
LambdaEntityLimits = {}

function CreateLambdaEntLimit( name, default, max )
    CreateLambdaConvar( "lambdaplayers_limits_" .. name .. "limit", default, true, false, false, "The max amount of " .. name .. "s a lambda player is allowed to have", 0, max, { type = "Slider", name = name .. " Limit", decimals = 0, category = "Limits and Tool Permissions" } )
    if SERVER then LambdaEntityLimits[ #LambdaEntityLimits + 1 ] = name end
end


CreateLambdaEntLimit( "Prop", 300, 50000 )


-- Called when all default entity limits are created.
-- This hook can be used to create entity limits with CreateLambdaEntLimit()
hook.Run( "LambdaOnEntLimitsCreated" )