local table_insert = table.insert

-- Will be used for presets
_LAMBDAPLAYERSCONVARS = {}

if CLIENT then
    _LAMBDAConVarSettings = {}
end

-- A multi purpose function for both client and server convars
function CreateLambdaConvar( name, val, shouldsave, isclient, userinfo, desc, min, max, settingstbl )
    isclient = isclient == nil and false or isclient
    shouldsave = shouldsave == nil and true or shouldsave

    if isclient and SERVER then return end


    if isclient then
        CreateClientConVar( name, tostring( val ), shouldsave, userinfo, desc, min, max )
    else
        CreateConVar( name, tostring( val ), shouldsave and FCVAR_ARCHIVE or FCVAR_NONE, desc, min, max )
    end

    _LAMBDAPLAYERSCONVARS[ name ] = tostring( val )

    if CLIENT and settingstbl then
        settingstbl.convar = name
        settingstbl.min = min
        settingstbl.desc = desc
        settingstbl.max = max
        table_insert( _LAMBDAConVarSettings, settingstbl )
    end

end

-- Why not?
local CreateLambdaConvar = CreateLambdaConvar 

-- These Convar Functions are capable of creating spawnmenu settings automatically.

---------- Valid Table options ----------
-- type | String | Must be one of the following: Slider, Bool
-- name | String | Pretty name
-- decimals | Number | Slider only! How much decimals the slider should have
-- category | String | The Lambda Settings category to place the convar into. Will create one if one doesn't exist already

-- Other Convars. Client-side only
CreateLambdaConvar( "lambdaplayers_corpsecleanuptime", 15, true, true, false, "The amount of time before a corpse is removed. Set to zero to disable this", 0, 190, { type = "Slider", name = "Corpse Cleanup Time", decimals = 0, category = "Utilities" } )
--

-- Voice Related Convars. Client-side only
CreateLambdaConvar( "lambdaplayers_voicevolume", 1, true, true, false, "The volume of the lambda player voices", 0, 10, { type = "Slider", name = "Voice Volume", decimals = 2, category = "Voice Options" } )
CreateLambdaConvar( "lambdaplayers_globalvoice", 0, true, true, false, "If the lambda player voices should be heard globally", 0, 1, { type = "Bool", name = "Global Voices", category = "Voice Options" } )
--

-- DEBUGGING CONVARS. Server-side only
CreateLambdaConvar( "lambdaplayers_debug", 0, false, false, false, "Enables the debugging features", 0, 1, { type = "Bool", name = "Enable Debug", category = "Debugging" } )
--