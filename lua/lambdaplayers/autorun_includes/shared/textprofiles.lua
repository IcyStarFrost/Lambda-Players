local GetKeys = table.GetKeys
local pairs = pairs

local combotable = {}

for k, v in pairs( LAMBDAFS:GetTextProfiles() ) do
    combotable[ k ] = k
end
combotable[ "None" ] = "" 

CreateLambdaConvar( "lambdaplayers_lambda_textprofile", "", true, true, true, "The Text Profile your newly spawned Lambda Players should spawn with. Note: This will only work if the server has the specified Text Profile", 0, 1, { type = "Combo", options = combotable, name = "Text Profile", category = "Lambda Player Settings" } )
