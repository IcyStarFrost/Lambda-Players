--- Include files in the corresponding folders
-- Autorun files are seperated in folders unlike the ENT include lua files

LambdaIsForked = true -- For some things...

local redundantFiles = {
    [ "lambda-nextbotfear-module.lua" ] = true
}

-- Base Addon includes --

function LambdaReloadAddon( ply )

    if SERVER and IsValid( ply ) then
        if !ply:IsSuperAdmin() then return end -- No lol
        PrintMessage( HUD_PRINTTALK, "SERVER is reloading all Lambda Lua files.." )
    end

    if SERVER then

        local serversidefiles = file.Find( "lambdaplayers/autorun_includes/server/*", "LUA", "nameasc" )

        for k, luafile in ipairs( serversidefiles ) do
            if redundantFiles[ luafile ] then
                print( "Lambda Players: Ignored The Following Lua File: " .. luafile )
                continue
            end

            include( "lambdaplayers/autorun_includes/server/" .. luafile )
            print( "Lambda Players: Included Server Side Lua File [ " .. luafile .. " ]" )
        end

    end

    print("\n")

    local sharedfiles = file.Find( "lambdaplayers/autorun_includes/shared/*", "LUA", "nameasc" )

    for k, luafile in ipairs( sharedfiles ) do
        if redundantFiles[ luafile ] then
            print( "Lambda Players: Ignored The Following Lua File: " .. luafile )
            continue
        end

        if SERVER then
            AddCSLuaFile( "lambdaplayers/autorun_includes/shared/" .. luafile )
        end
        include( "lambdaplayers/autorun_includes/shared/" .. luafile )
        print( "Lambda Players: Included Shared Lua File [ " .. luafile .. " ]" )
    end

    print("\n")


    local clientsidefiles = file.Find( "lambdaplayers/autorun_includes/client/*", "LUA", "nameasc" )

    for k, luafile in ipairs( clientsidefiles ) do
        if redundantFiles[ luafile ] then
            print( "Lambda Players: Ignored The Following Lua File: " .. luafile )
            continue
        end

        if SERVER then
            AddCSLuaFile( "lambdaplayers/autorun_includes/client/" .. luafile )
        elseif CLIENT then
            include( "lambdaplayers/autorun_includes/client/" .. luafile )
            print( "Lambda Players: Included Client Side Lua File [ " .. luafile .. " ]" )
        end
    end
    --

    print( "Lambda Players: Preparing to load External Addon Lua Files.." )

    -- External Addon Includes --
    if SERVER then

        local serversidefiles = file.Find( "lambdaplayers/extaddon/server/*", "LUA", "nameasc" )

        for k, luafile in ipairs( serversidefiles ) do
            if redundantFiles[ luafile ] then
                print( "Lambda Players: Ignored The Following Lua File: " .. luafile )
                continue
            end

            include( "lambdaplayers/extaddon/server/" .. luafile )
            print( "Lambda Players: Included Server Side External Lua File [ " .. luafile .. " ]" )
        end

    end

    print("\n")

    local sharedfiles = file.Find( "lambdaplayers/extaddon/shared/*", "LUA", "nameasc" )

    for k, luafile in ipairs( sharedfiles ) do
        if redundantFiles[ luafile ] then
            print( "Lambda Players: Ignored The Following Lua File: " .. luafile )
            continue
        end

        if SERVER then
            AddCSLuaFile( "lambdaplayers/extaddon/shared/" .. luafile )
        end
        include( "lambdaplayers/extaddon/shared/" .. luafile )
        print( "Lambda Players: Included Shared External Lua File [ " .. luafile .. " ]" )
    end

    print("\n")


    local clientsidefiles = file.Find( "lambdaplayers/extaddon/client/*", "LUA", "nameasc" )

    for k, luafile in ipairs( clientsidefiles ) do
        if redundantFiles[ luafile ] then
            print( "Lambda Players: Ignored The Following Lua File: " .. luafile )
            continue
        end

        if SERVER then
            AddCSLuaFile( "lambdaplayers/extaddon/client/" .. luafile )
        elseif CLIENT then
            include( "lambdaplayers/extaddon/client/" .. luafile )
            print( "Lambda Players: Included Client Side External Lua File [ " .. luafile .. " ]" )
        end
    end

    print( "Lambda Players: Loaded all External Addon Lua Files!")
    hook.Run( "LambdaOnModulesLoaded" )
    --

    if SERVER and IsValid( ply ) then
        PrintMessage( HUD_PRINTTALK, "SERVER has reloaded all Lambda Lua files" )
    end

    if SERVER and LambdaHasFirstInit then
        net.Start( "lambdaplayers_reloadaddon" )
        net.Broadcast()
    end


    LambdaHasFirstInit = true
end
---

LambdaReloadAddon()


-- Initialize these globals --
-- These will be run after external addon lua files have been run so it is ensured anything they add is included here
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
LambdaModelVoiceProfiles = LambdaModelVoiceProfiles or LAMBDAFS:GetModelVoiceProfiles()
LambdaPlayermodelBodySkinSets = LambdaPlayermodelBodySkinSets or LAMBDAFS:GetPlayermodelBodySkinSets()
LambdaQuickNades = LambdaQuickNades or LAMBDAFS:GetQuickNadeWeapons()
LambdaEntsToFearFrom = LambdaEntsToFearFrom or LAMBDAFS:GetEntsToFearFrom()
--

-- Voice Profiles --
-- Had to move these here for code order reason
local combotable = {}

for k, v in pairs( LambdaVoiceProfiles ) do
    combotable[ k ] = k
end
combotable[ "None" ] = ""

CreateLambdaConvar( "lambdaplayers_lambda_voiceprofile", "", true, true, true, "The Voice Profile your newly spawned Lambda Players should spawn with. Note: This will only work if the server has the specified Voice Profile", 0, 1, { type = "Combo", options = combotable, name = "Voice Profile", category = "Lambda Player Settings" } )
--

-- Text Profiles --
combotable = {}

for k, v in pairs( LambdaTextProfiles ) do
    combotable[ k ] = k
end
combotable[ "None" ] = ""

CreateLambdaConvar( "lambdaplayers_lambda_textprofile", "", true, true, true, "The Text Profile your newly spawned Lambda Players should spawn with. Note: This will only work if the server has the specified Text Profile", 0, 1, { type = "Combo", options = combotable, name = "Text Profile", category = "Lambda Player Settings" } )
--

-- This will reload the Lambda addon ingame without having to resave this lua file and trigger a lua refresh
concommand.Add( "lambdaplayers_dev_reloadaddon", LambdaReloadAddon )