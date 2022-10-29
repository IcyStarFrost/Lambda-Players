-- Will be used for presets
_LAMBDAPLAYERSCONVARS = {}

-- A multi purpose function for both client and server convars
function CreateLambdaConvar( name, val, shouldsave, isclient, userinfo, desc, min, max )
    isclient = isclient == nil and false or isclient
    shouldsave = shouldsave == nil and true or shouldsave

    if isclient and SERVER then return end


    if isclient then
        CreateClientConVar( name, tostring( val ), shouldsave, userinfo, desc, min, max )
    else
        CreateConVar( name, tostring( val ), shouldsave and FCVAR_ARCHIVE or FCVAR_NONE, desc, min, max )
    end

    _LAMBDAPLAYERSCONVARS[ name ] = tostring( val )

end

-- Why not?
local CreateLambdaConvar = CreateLambdaConvar 


CreateLambdaConvar( "lambdaplayers_voicevolume", 1, true, true, false, "The volume of the lambda player voices", 0, 10 )
CreateLambdaConvar( "lambdaplayers_globalvoice", 0, true, true, false, "If the lambda player voices should be heard globally", 0, 1 )