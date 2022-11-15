local GetKeys = table.GetKeys
local pairs = pairs

local combotable = {}

for k, v in pairs( LAMBDAFS:GetVoiceProfiles() ) do
    combotable[ k ] = k
end
combotable[ "None" ] ="" 

CreateLambdaConvar( "lambdaplayers_lambda_voiceprofile", "", true, true, true, "The Voice Profile your newly spawned Lambda Players should spawn with. Note: This will only work if the server has the specified Voice Profile", 0, 1, { type = "Combo", options = combotable, name = "Voice Profile", category = "Lambda Player Settings" } )
