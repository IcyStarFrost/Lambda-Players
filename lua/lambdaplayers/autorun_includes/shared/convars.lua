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

    _LAMBDAPLAYERSCONVARS[ name ] = tostring( val )

    if isclient and SERVER then return end


    if isclient then
        convar = CreateClientConVar( name, tostring( val ), shouldsave, userinfo, desc, min, max )
    else
        convar = CreateConVar( name, tostring( val ), shouldsave and FCVAR_ARCHIVE or FCVAR_NONE, desc, min, max )
    end

    

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

function CreateLambdaColorConvar( name, defaultcolor, isclient, userinfo, desc, settingstbl )
    CreateLambdaConvar( name .. "_r", defaultcolor.r, true, isclient, userinfo, desc, 0, 255, nil )
    CreateLambdaConvar( name .. "_g", defaultcolor.g, true, isclient, userinfo, desc, 0, 255, nil )
    CreateLambdaConvar( name .. "_b", defaultcolor.b, true, isclient, userinfo, desc, 0, 255, nil )


    if CLIENT then
        settingstbl.red = name .. "_r"
        settingstbl.green = name .. "_g"
        settingstbl.blue = name .. "_b"

        settingstbl.default = "Red = " .. tostring( defaultcolor.r ) .. " | " .. "Green = " .. tostring( defaultcolor.g ) .. " | " .. "Blue = " .. tostring( defaultcolor.b )
        settingstbl.type = "Color"

        settingstbl.isclient = isclient
        settingstbl.desc = ( isclient and "Client-Side | " or "Server-Side | " ) .. desc .. ( isclient and "" or "\nConVar: " .. name )
        settingstbl.max = max
        table_insert( _LAMBDAConVarSettings, settingstbl )
    end
end


-- Why not?
local CreateLambdaConvar = CreateLambdaConvar 

-- These Convar Functions are capable of creating spawnmenu settings automatically.

---------- Valid Table options ----------
-- type | String | Must be one of the following: Slider, Bool, Text, Combo. For Colors, you must use CreateLambdaColorConvar()
-- name | String | Pretty name
-- decimals | Number | Slider only! How much decimals the slider should have
-- category | String | The Lambda Settings category to place the convar into. Will create one if one doesn't exist already
-- options | Table | Combo only! A table with its keys being the text and values being the data

-- Other Convars. Client-side only
CreateLambdaConvar( "lambdaplayers_drawflashlights", 1, true, true, false, "If Lambda Player flashlights should be rendered", 0, 1, { type = "Bool", name = "Draw Flashlights", category = "Lambda Player Settings" } )
CreateLambdaConvar( "lambdaplayers_uiscale", 0, true, true, false, "How much to scale UI such as Voice popups, name pop ups, ect.", ( CLIENT and -ScrW() or 1 ), ( CLIENT and ScrW() or 1 ), { type = "Slider", name = "UI Scale", decimals = 1, category = "Utilities" } )
CreateLambdaConvar( "lambdaplayers_corpsecleanuptime", 15, true, true, false, "The amount of time before a corpse is removed. Set to zero to disable this", 0, 190, { type = "Slider", name = "Corpse Cleanup Time", decimals = 0, category = "Utilities" } )
CreateLambdaConvar( "lambdaplayers_corpsecleanupeffect", 0, true, true, false, "If corpses should have a disintegration effect before they are removed", 0, 1, { type = "Bool", name = "Corpse Disintegration Effect", category = "Utilities" } )
CreateLambdaConvar( "lambdaplayers_removecorpseonrespawn", 0, true, true, false, "If corpses should be removed after their owner had respawned.", 0, 1, { type = "Bool", name = "Remove Corpse On Respawn", category = "Utilities" } )
CreateLambdaConvar( "lambdaplayers_voice_warnvoicestereo", 0, true, true, false, "If console should warn you about voice lines that have stereo channels", 0, 1, { type = "Bool", name = "Warn Stereo Voices", category = "Utilities" } )
CreateLambdaConvar( "lambdaplayers_displayarmor", 0, true, true, false, "If Lambda Player's current armor should be displayed when we're looking at it and it's above zero", 0, 1, { type = "Bool", name = "Display Armor", category = "Lambda Player Settings" } )

CreateLambdaConvar( "lambdaplayers_useplayermodelcolorasdisplaycolor", 0, true, true, true, "If Lambda Player's Playermodel Color should be its Display Color. This has priority over the Display Color below", 0, 1, { type = "Bool", name = "Playermodel Color As Display Color", category = "Misc" } )
CreateLambdaColorConvar( "lambdaplayers_displaycolor", Color( 255, 136, 0 ), true, true, "The display color to use for Name Display and others", { name = "Display Color", category = "Misc" } )
--

-- Lambda Player Server Convars
CreateLambdaConvar( "lambdaplayers_lambda_infwanderdistance", 0, true, false, false, "If Lambda Players should be able to walk anywhere on the navmesh instead of only walking within 1500 source units", 0, 1, { type = "Bool", name = "Unlimited Walk Distance", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_allownoclip", 1, true, false, false, "If Lambda Players are allowed to Noclip", 0, 1, { type = "Bool", name = "Allow Noclip", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_allowkillbind", 0, true, false, false, "If Lambda Players are allowed to randomly use their Killbind", 0, 1, { type = "Bool", name = "Allow Killbind", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_fakeisplayer", 0, true, false, false, "If the addon should make Lua think Lambda Players are real players. This is required for SWEP support! This will make addons think Lambdas are real players. WARNING!!!! THIS MAY OR MAY NOT WORK AS INTENDED AND THIS MAY CAUSE ISSUES WITH OTHER ADDONS. IF YOU ENCOUNTER ISSUES WITH THIS, DO NOT BE SURPRISED. THIS IS DOING THE BEST IT CAN!", 0, 1, { type = "Bool", name = "Fake IsPlayer", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_allowswepmerging", 0, true, false, false, "If the addon should add registered SWEPs to Lambda's weapons. You must have Fake IsPlayer turned on! You must restart the server for changes to take effect! WARNING!!!! THIS MAY OR MAY NOT WORK AS INTENDED. IF YOU ENCOUNTER ISSUES WITH THIS, DO NOT BE SURPRISED. THIS IS DOING THE BEST IT CAN!", 0, 1, { type = "Bool", name = "Merge Registered SWEPs", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_allowrandomaddonsmodels", 0, true, false, false, "If Lambda Players can use random addon playermodels", 0, 1, { type = "Bool", name = "Addon Playermodels", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_onlyaddonmodels", 0, true, false, false, "If Lambda Players should only use playermodels that are from addons. Addon Playermodels should be enabled to work.", 0, 1, { type = "Bool", name = "Only Addon Playermodels", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_allowrandomskinsandbodygroups", 0, true, false, false, "If Lambda Players can have their model's skins and bodygroups randomized", 0, 1, { type = "Bool", name = "Addon Random Skins & Bodygroups", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_voiceprofileusechance", 0, true, false, false, "The chance a Lambda Player will use a random Voice Profile if one exists. Set to 0 to disable", 0, 100, { type = "Slider", decimals = 0, name = "VP Use Chance", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_textprofileusechance", 0, true, false, false, "The chance a Lambda Player will use a random Text Profile if one exists. Set to 0 to disable", 0, 100, { type = "Slider", decimals = 0, name = "TP Use Chance", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_profileusechance", 0, true, false, false, "The chance a Lambda will spawn with a profile that isn't being used. Normally profile Lambda Players only spawn when a Lambda Player has the profile's name. This chance can make profiles appear more often. Do not confuse this with Voice Profiles!", 0, 100, { type = "Slider", decimals = 0, name = "Profile Use Chance", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_realisticfalldamage", 0, true, false, false, "If Lambda Players should take fall damage similar to Realistic Fall Damage", 0, 1, { type = "Bool", name = "Realistic Fall Damage", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_respawntime", 2, true, false, false, "The amount of seconds Lambda Player will take before respawning after dying.", 0.1, 10, { type = "Slider", decimals = 1, name = "Respawn Time", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_respawnatplayerspawns", 0, true, false, false, "If Lambda Players should respawn at player spawn points", 0, 1, { type = "Bool", name = "Respawn At Player Spawns", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_dontrespawnifspeaking", 0, true, false, false, "If Lambda Players should wait for their currently spoken voiceline to finish before respawning.", 0, 1, { type = "Bool", name = "Don't Respawn If Speaking", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_obeynavmeshattributes", 0, true, false, false, "If Lambda Players should obey navmesh attributes such as, Avoid, Walk, Run, Jump, and Crouch", 0, 1, { type = "Bool", name = "Obey Navigation Mesh", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_overridegamemodehooks", 1, true, false, false, "If the addon is allowed to override the following GAMEMODE hooks to support Lambda Players: GM:PlayerDeath() GM:PlayerStartVoice() GM:PlayerEndVoice() GM:OnNPCKilled() Default SandBox Scoreboard : Changing this requires you to restart the server/game for the changes to apply!", 0, 1, { type = "Bool", name = "Override Gamemode Hooks", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_callonnpckilledhook", 0, true, false, false, "If killed Lambda Players should call the OnNPCKilled hook. Best used with the Override Gamemode Hooks option!", 0, 1, { type = "Bool", name = "Call OnNPCKilled Hook On Death", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_singleplayerthinkdelay", 0, true, false, false, "The amount of seconds Lambda Players will execute their next Think. 0.1 is a good value. Increasing this will increase performance at the cost of delays and decreasing this may decrease performance but have less delays. This only applies to singleplayer since multiplayer automatically adjusts think time", 0, 0.24, { type = "Slider", decimals = 2, name = "Think Delay", category = "Lambda Server Settings" } )
--

-- Combat Convars 
CreateLambdaConvar( "lambdaplayers_combat_allowtargetyou", 1, true, true, true, "If Lambda Players are allowed to attack you", 0, 1, { type = "Bool", name = "Target You", category = "Combat" } )
CreateLambdaConvar( "lambdaplayers_combat_allowretreating", 1, true, false, false, "If Lambda Players are allowed to retreat from enemy if they're low on health", 0, 1, { type = "Bool", name = "Allow Retreating", category = "Combat" } )
--

-- Lambda Player Convars
CreateLambdaConvar( "lambdaplayers_lambda_shouldrespawn", 0, true, true, true, "If Lambda Players should respawn when they die. Note: Changing this will only apply to newly spawned Lambda Players AND only if the server allows the respawn option for non admins", 0, 1, { type = "Bool", name = "Respawn", category = "Lambda Player Settings" } )
---- lambdaplayers_lambda_voiceprofile Located in shared/voiceprofiles.lua
---- lambdaplayers_lambda_spawnweapon  Located in shared/globals.lua due to code order
--

-- Building Convars
CreateLambdaConvar( "lambdaplayers_building_caneditworld", 1, true, false, false, "If the Lambda Players are allowed to use the Physgun and Toolgun on world entities", 0, 1, { type = "Bool", name = "Allow Edit World", category = "Building" } )
CreateLambdaConvar( "lambdaplayers_building_caneditnonworld", 1, true, false, false, "If the Lambda Players are allowed to use the Physgun and Toolgun on non world entities. Typically player spawned entities and addon spawned entities", 0, 1, { type = "Bool", name = "Allow Edit Non World", category = "Building" } )
CreateLambdaConvar( "lambdaplayers_building_canedityourents", 1, true, true, true, "If the Lambda Players are allowed to use the Physgun and Toolgun on your props and entities", 0, 1, { type = "Bool", name = "Allow Edit Your Entities", category = "Building" } )
CreateLambdaConvar( "lambdaplayers_lambda_allowphysgunpickup", 1, true, false, false, "If Lambda Players are able to pickup things with their physgun", 0, 1, { type = "Bool", name = "Allow Physgun Pickup", category = "Building" } )
CreateLambdaConvar( "lambdaplayers_building_freezeprops", 0, true, false, false, "If props spawned by Lambda Players should spawn with either of these effects that lead them to being frozen: Spawn Frozen, Spawn unfrozen and freeze 10 seconds later. This can help with performance", 0, 1, { type = "Bool", name = "Handle Freezing Props", category = "Building" } )
CreateLambdaConvar( "lambdaplayers_building_alwaysfreezelargeprops", 0, true, false, false, "If large props spawned by Lambda Players should always spawn frozen. This can help with performance", 0, 1, { type = "Bool", name = "Freeze Large Props", category = "Building" } )
--

-- Voice Related Convars
CreateLambdaConvar( "lambdaplayers_voice_globalvoice", 0, true, true, false, "If the Lambda Player voices should be heard globally", 0, 1, { type = "Bool", name = "Global Voices", category = "Voice Options" } )
CreateLambdaConvar( "lambdaplayers_voice_voicepopups", 1, true, true, false, "If Lambda Players who are speaking should have a Voice Popup", 0, 1, { type = "Bool", name = "Draw Voice Popups", category = "Voice Options" } )
CreateLambdaConvar( "lambdaplayers_voice_usegmodvoicepopups", 0, true, false, false, "If Lambda Players should use Garry's Mod's Voice Pop up system instead of their own system. This requires Gamemode override setting to be turned on! Go to Lambda Server Settings and the Override Gamemode Hooks option and read the info on that. Note changing this will not take effect instantly. When all Lambdas speaking at the time you change this stops speaking, the change will take place", 0, 1, { type = "Bool", name = "Use Gmod Voice Popups", category = "Voice Options" } )
CreateLambdaConvar( "lambdaplayers_voice_talklimit", 0, true, true, false, "The amount of Lambda Players that can speak at a time. 0 for infinite", 0, 20, { type = "Slider", decimals = 0, name = "Speak Limit", category = "Voice Options" } )
CreateLambdaConvar( "lambdaplayers_voice_voicevolume", 1, true, true, false, "The volume of the Lambda Player voices", 0, 10, { type = "Slider", name = "Voice Volume", decimals = 2, category = "Voice Options" } )
CreateLambdaConvar( "lambdaplayers_voice_voicepopupxpos", 278, true, true, false, "The position of the voice popups on the x axis of your screen", 0, ( CLIENT and ScrW() or 1 ), { type = "Slider", decimals = 0, name = "Voice Popup X", category = "Voice Options" } )
CreateLambdaConvar( "lambdaplayers_voice_voicepopupypos", 150, true, true, false, "The position of the voice popups on the y axis of your screen", 0, ( CLIENT and ScrH() or 1 ), { type = "Slider", decimals = 0, name = "Voice Popup Y", category = "Voice Options" } )
CreateLambdaConvar( "lambdaplayers_voice_voicepitchmax", 100, true, false, false, "The highest pitch a Lambda Voice can get", 100, 255, { type = "Slider", decimals = 0, name = "Voice Pitch Max", category = "Voice Options" } )
CreateLambdaConvar( "lambdaplayers_voice_voicepitchmin", 100, true, false, false, "The lowest pitch a Lambda Voice can get", 10, 100, { type = "Slider", decimals = 0, name = "Voice Pitch Min", category = "Voice Options" } )
CreateLambdaConvar( "lambdaplayers_voice_mergeaddonvoicelines", 1, true, false, false, "If custom voice lines added by addons should be included. Make sure you update Lambda Data after you change this!", 0, 1, { type = "Bool", name = "Include Addon Voicelines", category = "Voice Options" } )
CreateLambdaConvar( "lambdaplayers_voice_alwaysplaydeathsnds", 0, true, false, false, "If Lambda Players should always play their death sounds instead of it being based on their voice chance. Keep in mind that this won't override their death text lines!", 0, 1, { type = "Bool", name = "Always Play Death Voicelines", category = "Voice Options" } )
--

-- Text Chat Convars --
CreateLambdaConvar( "lambdaplayers_text_enabled", 1, true, false, false, "If Lambda Players are allowed to use text chat to communicate with others.", 0, 1, { type = "Bool", name = "Enable Text Chatting", category = "Text Chat Options" } )
CreateLambdaConvar( "lambdaplayers_text_usedefaultlines", 1, true, false, false, "If Lambda Players are able to use the default text chat lines. Disable this if you only want your custom text lines. Make sure you Update Lambda Data after changing this!", 0, 1, { type = "Bool", name = "Use Default Lines", category = "Text Chat Options" } )
CreateLambdaConvar( "lambdaplayers_text_useaddonlines", 1, true, false, false, "If Lambda Players are able to use text chat lines added by addons. Make sure you Update Lambda Data after changing this!", 0, 1, { type = "Bool", name = "Use Addon Lines", category = "Text Chat Options" } )
CreateLambdaConvar( "lambdaplayers_text_chatlimit", 1, true, false, false, "The amount of Lambda Players that can type a message at a time. Set to 0 for no limit", 0, 60, { type = "Slider", decimals = 0, name = "Chat Limit", category = "Text Chat Options" } )
CreateLambdaConvar( "lambdaplayers_text_sentencemixing", 0, true, false, false, "If Lambda text chat lines should be randomly sentence mixed. This yields interesting results", 0, 1, { type = "Bool", name = "Sentence Mixing", category = "Text Chat Options" } )
--

-- Force Related Convars
CreateLambdaConvar( "lambdaplayers_force_radius", 750, true, false, false, "Radius for forcing certain actions on Lambda Players", 250, 10000, { type = "Slider", name = "Force Radius", decimals = 0, category = "Force Menu" } )
CreateLambdaConvar( "lambdaplayers_lambda_spawnatplayerspawns", 0, true, false, false, "If spawned Lambda Players should spawn at player spawn points", 0, 1, { type = "Bool", name = "Spawn at Player Spawns", category = "Force Menu" } )
--

-- DEBUGGING CONVARS. Server-side only
CreateLambdaConvar( "lambdaplayers_debug", 0, false, false, false, "Enables the debugging features", 0, 1, { type = "Bool", name = "Enable Debug", category = "Debugging" } )
AddSourceConVarToSettings( "developer", "Enables Source's Developer mode", { type = "Bool", name = "Developer", category = "Debugging" } )
--

-- Calls this hook when all default convars have been created.
-- This hook can be used to ensure the CreateLambdaConvar() function exists so custom convars can be made

if !LambdaFilesReloaded then -- This is so when the game is loading, the hook is created and if we are already in-game and reload the lua files, the hook will be forced to run
    hook.Add( "PreGamemodeLoaded", "lambdaconvarinit", function()
        hook.Run( "LambdaOnConvarsCreated" )
    end )
else
    hook.Run( "LambdaOnConvarsCreated" )
end

-- Note, Weapon allowing convars are located in the shared/globals.lua