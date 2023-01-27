--- Include files in the corresponding folders
-- Autorun files are seperated in folders unlike the ENT include lua files

if SERVER then

    local serversidefiles = file.Find( "lambdaplayers/autorun_includes/server/*", "LUA", "nameasc" )

    for k, luafile in ipairs( serversidefiles ) do
        include( "lambdaplayers/autorun_includes/server/" .. luafile )
        print( "Lambda Players: Included Server Side Lua File [ " .. luafile .. " ]" )
    end

end

print("\n")

local sharedfiles = file.Find( "lambdaplayers/autorun_includes/shared/*", "LUA", "nameasc" )

for k, luafile in ipairs( sharedfiles ) do
    if SERVER then
        AddCSLuaFile( "lambdaplayers/autorun_includes/shared/" .. luafile )
    end
    include( "lambdaplayers/autorun_includes/shared/" .. luafile )
    print( "Lambda Players: Included Shared Lua File [ " .. luafile .. " ]" )
end

print("\n")


local clientsidefiles = file.Find( "lambdaplayers/autorun_includes/client/*", "LUA", "nameasc" )

for k, luafile in ipairs( clientsidefiles ) do
    if SERVER then
        AddCSLuaFile( "lambdaplayers/autorun_includes/client/" .. luafile )
    elseif CLIENT then
        include( "lambdaplayers/autorun_includes/client/" .. luafile )
        print( "Lambda Players: Included Client Side Lua File [ " .. luafile .. " ]" )
    end
end

LambdaFilesReloaded = LambdaFilesReloaded or true
---


-- Initialize these globals --
LambdaPersonalProfiles = LambdaPersonalProfiles or file.Exists( "lambdaplayers/profiles.json", "DATA" ) and LAMBDAFS:ReadFile( "lambdaplayers/profiles.json", "json" ) or nil
LambdaPlayerNames = LambdaPlayerNames or LAMBDAFS:GetNameTable()
LambdaPlayerProps = LambdaPlayerProps or LAMBDAFS:GetPropTable()
LambdaPlayerMaterials = LambdaPlayerMaterials or LAMBDAFS:GetMaterialTable()
Lambdaprofilepictures = Lambdaprofilepictures or LAMBDAFS:GetProfilePictures()
LambdaVoiceLinesTable = LambdaVoiceLinesTable or LAMBDAFS:GetVoiceLinesTable()
LambdaVoiceProfiles = LambdaVoiceProfiles or LAMBDAFS:GetVoiceProfiles()
LambdaPlayerSprays = LambdaPlayerSprays or LAMBDAFS:GetSprays()
LambdaTextTable = LambdaTextTable or LAMBDAFS:GetTextTable()
LambdaTextProfiles = LambdaTextProfiles or LAMBDAFS:GetTextProfiles()
--