local table_insert = table.insert
local pairs = pairs
local table_GetKeys = table.GetKeys

-- Will be used for presets
_LAMBDAPLAYERSCONVARS = {}

if CLIENT then
    _LAMBDAConVarSettings = {}
elseif SERVER then
    _LAMBDAEntLimits = {}
end



-- A multi purpose function for both client and server convars
function CreateLambdaConvar( name, val, shouldsave, isclient, userinfo, desc, min, max, settingstbl )
    isclient = isclient == nil and false or isclient
    shouldsave = shouldsave == nil and true or shouldsave
    local convar

    if isclient and SERVER then return end


    if isclient then
        convar = CreateClientConVar( name, tostring( val ), shouldsave, userinfo, desc, min, max )
    elseif SERVER then
        convar = CreateConVar( name, tostring( val ), shouldsave and FCVAR_ARCHIVE or FCVAR_NONE, desc, min, max )
    end

    _LAMBDAPLAYERSCONVARS[ name ] = tostring( val )

    if CLIENT and settingstbl then
        settingstbl.convar = name
        settingstbl.min = min
        settingstbl.default = val
        settingstbl.isclient = isclient
        settingstbl.desc = ( isclient and "Client-Side | " or "Server-Side | " ) .. desc .. ( isclient and "" or "\nConVar: " .. name )
        settingstbl.max = max
        table_insert( _LAMBDAConVarSettings, settingstbl )
    end

    return convar
end


local function AddSourceConVarToSettings( cvarname, desc, settingstbl )
    if CLIENT and settingstbl then
        settingstbl.convar = cvarname
        settingstbl.isclient = false
        settingstbl.desc = "Server-Side | " .. desc .. "\nConVar: " .. cvarname
        table_insert( _LAMBDAConVarSettings, settingstbl )
    end
end



-- Why not?
local CreateLambdaConvar = CreateLambdaConvar 

-- These Convar Functions are capable of creating spawnmenu settings automatically.

---------- Valid Table options ----------
-- type | String | Must be one of the following: Slider, Bool, Text, Combo
-- name | String | Pretty name
-- decimals | Number | Slider only! How much decimals the slider should have
-- category | String | The Lambda Settings category to place the convar into. Will create one if one doesn't exist already
-- options | Table | Combo only! A table with its keys being the data and values being the text

-- Other Convars. Client-side only
CreateLambdaConvar( "lambdaplayers_corpsecleanuptime", 15, true, true, false, "The amount of time before a corpse is removed. Set to zero to disable this", 0, 190, { type = "Slider", name = "Corpse Cleanup Time", decimals = 0, category = "Utilities" } )
CreateLambdaConvar( "lambdaplayers_drawflashlights", 1, true, true, false, "If lambda player flashlights should be rendered", 0, 1, { type = "Bool", name = "Draw Flashlights", category = "Lambda Player Settings" } )
CreateLambdaConvar( "lambdaplayers_uiscale", 0, true, true, false, "How much to scale UI such as Voice popups, name pop ups, ect.", ( CLIENT and -ScrW() or 1 ), ( CLIENT and ScrW() or 1 ), { type = "Slider", name = "UI Scale", decimals = 1, category = "Utilities" } )
CreateLambdaConvar( "lambdaplayers_corpsecleanupeffect", 0, true, true, false, "If corpses should have a disintegration effect before they are removed", 0, 1, { type = "Bool", name = "Corpse Disintegration Effect", category = "Utilities" } )
CreateLambdaConvar( "lambdaplayers_voice_warnvoicestereo", 0, true, true, false, "If console should warn you about voice lines that have stereo channels", 0, 1, { type = "Bool", name = "Warn Stereo Voices", category = "Utilities" } )
--

-- Lambda Player Server Convars
CreateLambdaConvar( "lambdaplayers_lambda_allownonadminrespawn", 0, true, false, false, "If Non Admins are allowed to spawn respawning lambda players. If off, only admins can spawn respawning lambda players", 0, 1, { type = "Bool", name = "Allow Non Admin Respawn", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_allowrandomaddonsmodels", 0, true, false, false, "If lambda players can use random addon playermodels", 0, 1, { type = "Bool", name = "Addon Playermodels", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_voiceprofileusechance", 0, true, false, false, "The chance a Lambda Player will use a random Voice Profile if one exists. Set to 0 to disable", 0, 100, { type = "Slider", decimals = 0, name = "VP Use Chance", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_realisticfalldamage", 0, true, false, false, "If lambda players should take fall damage similar to Realistic Fall Damage", 0, 1, { type = "Bool", name = "Realistic Fall Damage", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_respawnatplayerspawns", 0, true, false, false, "If lambda players should respawn at player spawn points", 0, 1, { type = "Bool", name = "Respawn At Player Spawns", category = "Lambda Server Settings" } )
--

-- Lambda Player Convars
CreateLambdaConvar( "lambdaplayers_lambda_shouldrespawn", 0, true, true, true, "If lambda players should respawn when they die. Note: Changing this will only apply to newly spawned lambda players AND only if the server allows the respawn option for non admins", 0, 1, { type = "Bool", name = "Respawn", category = "Lambda Player Settings" } )
---- lambdaplayers_lambda_voiceprofile Located in shared/voiceprofiles.lua
---- lambdaplayers_lambda_spawnweapon  Located in shared/globals.lua due to code order
--

-- Building Convars
CreateLambdaConvar( "lambdaplayers_building_caneditworld", 1, true, false, false, "If the lambda players are allowed to use the Physgun and Toolgun on world entities", 0, 1, { type = "Bool", name = "Allow Edit World", category = "Building" } )
CreateLambdaConvar( "lambdaplayers_building_caneditnonworld", 1, true, false, false, "If the lambda players are allowed to use the Physgun and Toolgun on non world entities. Typically player spawned entities and addon spawned entities", 0, 1, { type = "Bool", name = "Allow Edit Non World", category = "Building" } )
CreateLambdaConvar( "lambdaplayers_building_canedityourents", 1, true, true, true, "If the lambda players are allowed to use the Physgun and Toolgun on your props and entities", 0, 1, { type = "Bool", name = "Allow Edit Your Entities", category = "Building" } )
CreateLambdaConvar( "lambdaplayers_lambda_allowphysgunpickup", 1, true, false, false, "If lambda players are able to pickup things with their physgun", 0, 1, { type = "Bool", name = "Allow Physgun Pickup", category = "Building" } )
--

-- Voice Related Convars
CreateLambdaConvar( "lambdaplayers_voice_globalvoice", 0, true, true, false, "If the lambda player voices should be heard globally", 0, 1, { type = "Bool", name = "Global Voices", category = "Voice Options" } )
CreateLambdaConvar( "lambdaplayers_voice_voicepopups", 1, true, true, false, "If Lambda Players who are speaking should have a Voice Popup", 0, 1, { type = "Bool", name = "Allow Voice Popups", category = "Voice Options" } )
CreateLambdaConvar( "lambdaplayers_voice_talklimit", 0, true, true, false, "The amount of Lambda Players that can speak at a time. 0 for infinite", 0, 20, { type = "Slider", decimals = 0, name = "Speak Limit", category = "Voice Options" } )
CreateLambdaConvar( "lambdaplayers_voice_voicevolume", 1, true, true, false, "The volume of the lambda player voices", 0, 10, { type = "Slider", name = "Voice Volume", decimals = 2, category = "Voice Options" } )
CreateLambdaConvar( "lambdaplayers_voice_voicepopupxpos", 278, true, true, false, "The position of the voice popups on the x axis of your screen", 0, ( CLIENT and ScrW() or 1 ), { type = "Slider", decimals = 0, name = "Voice Popup X", category = "Voice Options" } )
CreateLambdaConvar( "lambdaplayers_voice_voicepopupypos", 150, true, true, false, "The position of the voice popups on the y axis of your screen", 0, ( CLIENT and ScrH() or 1 ), { type = "Slider", decimals = 0, name = "Voice Popup Y", category = "Voice Options" } )
CreateLambdaConvar( "lambdaplayers_voice_voicepitchmax", 100, true, false, false, "The highest pitch a Lambda Voice can get", 100, 255, { type = "Slider", decimals = 0, name = "Voice Pitch Max", category = "Voice Options" } )
CreateLambdaConvar( "lambdaplayers_voice_voicepitchmin", 100, true, false, false, "The lowest pitch a Lambda Voice can get", 10, 100, { type = "Slider", decimals = 0, name = "Voice Pitch Min", category = "Voice Options" } )
CreateLambdaConvar( "lambdaplayers_voice_mergeaddonvoicelines", 1, true, false, false, "If custom voice lines added by addons should be included. Make sure you update Lambda Data after you change this!", 0, 1, { type = "Bool", name = "Include Addon Voicelines", category = "Voice Options" } )
CreateLambdaConvar( "lambdaplayers_voice_idledir", "randomengine", true, false, false, "The directory to get idle voice lines from. These are voice lines that play randomly. Make sure you update Lambda Data after you change this!", nil, nil, { type = "Text", name = "Idle Directory", category = "Voice Options" } )
CreateLambdaConvar( "lambdaplayers_voice_tauntdir", "lambdaplayers/vo/taunt", true, false, false, "The directory to get taunt voice lines from. These are voice lines that play when a lambda player is about to attack something. Make sure you update Lambda Data after you change this!", nil, nil, { type = "Text", name = "Taunt Directory", category = "Voice Options" } )
CreateLambdaConvar( "lambdaplayers_voice_deathdir", "lambdaplayers/vo/death", true, false, false, "The directory to get death voice lines from. These are voice lines that play when a lambda player dies. Make sure you update Lambda Data after you change this!", nil, nil, { type = "Text", name = "Death Directory", category = "Voice Options" } )
CreateLambdaConvar( "lambdaplayers_voice_killdir", "lambdaplayers/vo/kill", true, false, false, "The directory to get kill voice lines from. These are voice lines that play when a lambda player kills their enemy. Make sure you update Lambda Data after you change this!", nil, nil, { type = "Text", name = "Kill Directory", category = "Voice Options" } )
CreateLambdaConvar( "lambdaplayers_voice_laughdir", "lambdaplayers/vo/laugh", true, false, false, "The directory to get laughing voice lines from. These are voice lines that play when a lambda player laughs at someone. Make sure you update Lambda Data after you change this!", nil, nil, { type = "Text", name = "Laugh Directory", category = "Voice Options" } )
--


-- DEBUGGING CONVARS. Server-side only
CreateLambdaConvar( "lambdaplayers_debug", 0, false, false, false, "Enables the debugging features", 0, 1, { type = "Bool", name = "Enable Debug", category = "Debugging" } )
AddSourceConVarToSettings( "developer", "Enables Source's Developer mode", { type = "Bool", name = "Developer", category = "Debugging" } )
--

-- Calls this hook when all default convars have been created.
-- This hook can be used to ensure the CreateLambdaConvar() function exists so custom convars can be made
hook.Run( "LambdaOnConvarsCreated" )

-- Note, Weapon allowing convars are located in the shared/globals.lua