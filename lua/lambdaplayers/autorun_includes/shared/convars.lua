local table_insert = table.insert
local GetConVar = GetConVar
local tostring = tostring
local CreateConVar = CreateConVar
local CreateClientConVar = CreateClientConVar
local defDisplayClr = Color( 255, 136, 0 )

-- Will be used for presets
_LAMBDAPLAYERSCONVARS = {}

if CLIENT then
    _LAMBDAConVarNames = {}
    _LAMBDAConVarSettings = {}
elseif SERVER then
    _LAMBDAEntLimits = {}
end

-- A multi purpose function for both client and server convars
function CreateLambdaConvar( name, val, shouldsave, isclient, userinfo, desc, min, max, settingstbl )
    isclient = isclient or false
    if isclient and SERVER then return end

    local strVar = tostring( val )
    if !_LAMBDAPLAYERSCONVARS[ name ] then _LAMBDAPLAYERSCONVARS[ name ] = strVar end

    local convar = GetConVar( name ) 
    if !convar then
        shouldsave = shouldsave or true
        if isclient then
            convar = CreateClientConVar( name, strVar, shouldsave, userinfo, desc, min, max )
        else
            convar = CreateConVar( name, strVar, ( shouldsave and ( FCVAR_ARCHIVE + FCVAR_REPLICATED ) or ( FCVAR_NONE + FCVAR_REPLICATED ) ), desc, min, max )
        end
    end

    if CLIENT and settingstbl and !_LAMBDAConVarNames[ name ] then
        settingstbl.convar = name
        settingstbl.min = min
        settingstbl.default = val
        settingstbl.isclient = isclient
        settingstbl.desc = ( isclient and "Client-Side | " or "Server-Side | " ) .. desc .. ( isclient and "" or "\nConVar: " .. name )
        settingstbl.max = max

        _LAMBDAConVarNames[ name ] = true
        table_insert( _LAMBDAConVarSettings, settingstbl )
    end

    return convar
end

local function AddSourceConVarToSettings( cvarname, desc, settingstbl )
    if CLIENT and settingstbl and !_LAMBDAConVarNames[ cvarname ] then
        settingstbl.convar = cvarname
        settingstbl.isclient = false
        settingstbl.desc = "Server-Side | " .. desc .. "\nConVar: " .. cvarname

        _LAMBDAConVarNames[ cvarname ] = true
        table_insert( _LAMBDAConVarSettings, settingstbl )
    end
end

function CreateLambdaColorConvar( name, defaultcolor, isclient, userinfo, desc, settingstbl )
    local nameR = name .. "_r"
    local nameG = name .. "_g"
    local nameB = name .. "_b"

    local redCvar = GetConVar( nameR )
    if !redCvar then redCvar = CreateLambdaConvar( nameR, defaultcolor.r, true, isclient, userinfo, desc, 0, 255, nil ) end

    local greenCvar = GetConVar( nameG )
    if !greenCvar then greenCvar = CreateLambdaConvar( nameG, defaultcolor.r, true, isclient, userinfo, desc, 0, 255, nil ) end

    local blueCvar = GetConVar( nameB )
    if !blueCvar then blueCvar = CreateLambdaConvar( nameB, defaultcolor.r, true, isclient, userinfo, desc, 0, 255, nil ) end

    if CLIENT and !_LAMBDAConVarNames[ name ] then
        settingstbl.red = nameR
        settingstbl.green = nameG
        settingstbl.blue = nameB

        settingstbl.default = "Red = " .. tostring( defaultcolor.r ) .. " | " .. "Green = " .. tostring( defaultcolor.g ) .. " | " .. "Blue = " .. tostring( defaultcolor.b )
        settingstbl.type = "Color"

        settingstbl.isclient = isclient
        settingstbl.desc = ( isclient and "Client-Side | " or "Server-Side | " ) .. desc .. ( isclient and "" or "\nConVar: " .. name )
        settingstbl.max = max

        _LAMBDAConVarNames[ name ] = true
        table_insert( _LAMBDAConVarSettings, settingstbl )
    end

    return redCvar, greenCvar, blueCvar
end

-- These Convar Functions are capable of creating spawnmenu settings automatically.

---------- Valid Table options ----------
-- type | String | Must be one of the following: Slider, Bool, Text, Combo. For Colors, you must use CreateLambdaColorConvar()
-- name | String | Pretty name
-- decimals | Number | Slider only! How much decimals the slider should have
-- category | String | The Lambda Settings category to place the convar into. Will create one if one doesn't exist already
-- options | Table | Combo only! A table with its keys being the text and values being the data

-- Other Convars
CreateLambdaConvar( "lambdaplayers_drawflashlights", 1, true, true, false, "If Lambda Player flashlights should be rendered", 0, 1, { type = "Bool", name = "Draw Flashlights", category = "Lambda Player Settings" } )
CreateLambdaConvar( "lambdaplayers_uiscale", 0, true, true, false, "How much to scale UI such as Voice popups, name pop ups, ect.", ( CLIENT and -ScrW() or 1 ), ( CLIENT and ScrW() or 1 ), { type = "Slider", name = "UI Scale", decimals = 1, category = "Utilities" } )
CreateLambdaConvar( "lambdaplayers_corpsecleanuptime", 15, true, true, false, "The amount of time before a corpse is removed. Set to zero to disable this", 0, 190, { type = "Slider", name = "Corpse Cleanup Time", decimals = 0, category = "Utilities" } )
CreateLambdaConvar( "lambdaplayers_corpsecleanupeffect", 0, true, true, false, "If corpses should have a disintegration effect before they are removed", 0, 1, { type = "Bool", name = "Corpse Disintegration Effect", category = "Utilities" } )
CreateLambdaConvar( "lambdaplayers_removecorpseonrespawn", 0, true, true, false, "If corpses should be removed after their owner had respawned.", 0, 1, { type = "Bool", name = "Remove Corpse On Respawn", category = "Utilities" } )
CreateLambdaConvar( "lambdaplayers_lambda_serversideragdolls", 0, true, false, false, "If Lambda Player ragdolls should be server side. This will allow addons to interact with the ragdolls. You may lose more FPS because of that!", 0, 1, { type = "Bool", name = "Server-Side Ragdolls", category = "Utilities" } )
CreateLambdaConvar( "lambdaplayers_lambda_serversideragdollcleanuptime", 15, true, false, false, "The time before Server-side Lambda ragdolls are removed. Set to zero to disable this", 0, 190, { type = "Slider", decimals = 0, name = "Ragdoll Cleanup Time", category = "Utilities" } )
CreateLambdaConvar( "lambdaplayers_lambda_serversideragdollcleanupeffect", 0, true, false, false, "If Server-side corpses should have a disintegration effect before they are removed", 0, 1, { type = "Bool", name = "Corpse Disintegration Effect", category = "Utilities" } )
CreateLambdaConvar( "lambdaplayers_lambda_serversideremovecorpseonrespawn", 0, true, false, false, "If Server-side corpses should be removed after their owner had respawned.", 0, 1, { type = "Bool", name = "Remove Corpse On Respawn", category = "Utilities" } )
CreateLambdaConvar( "lambdaplayers_voice_warnvoicestereo", 0, true, true, false, "If console should warn you about voice lines that have stereo channels", 0, 1, { type = "Bool", name = "Warn Stereo Voices", category = "Utilities" } )
CreateLambdaConvar( "lambdaplayers_displayarmor", 0, true, true, false, "If Lambda Player's current armor should be displayed when we're looking at it and it's above zero", 0, 1, { type = "Bool", name = "Display Armor", category = "Lambda Player Settings" } )

CreateLambdaConvar( "lambdaplayers_useplayermodelcolorasdisplaycolor", 0, true, true, true, "If Lambda Player's Playermodel Color should be its Display Color. This has priority over the Display Color below", 0, 1, { type = "Bool", name = "Playermodel Color As Display Color", category = "Misc" } )
CreateLambdaColorConvar( "lambdaplayers_displaycolor", defDisplayClr, true, true, "The display color to use for Name Display and others", { name = "Display Color", category = "Misc" } )
CreateLambdaConvar( "lambdaplayers_animatedpfpsprayframerate", 10, true, true, false, "The frame rate of animated Spray VTFs and animated Profile Picture VTFs", 1, 60, { type = "Slider", decimals = 0, name = "Animated VTF Frame Rate", category = "Misc" } )
CreateLambdaConvar( "lambdaplayers_randomizepathingcost", 0, true, false, false, "Randomizes Pathfinding in a way that will make Lambdas try different approaches to reaching their destination rather than finding the fastest and closest route", 0, 1, { type = "Bool", name = "Randomize PathFinding Cost", category = "Misc" } )
--

-- Lambda Player Server Convars
CreateLambdaConvar( "lambdaplayers_lambda_infwanderdistance", 0, true, false, false, "If Lambda Players should be able to walk anywhere on the navmesh instead of only walking within 1500 source units", 0, 1, { type = "Bool", name = "Unlimited Walk Distance", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_avoid", 0, true, false, false, "If enabled, Lambdas will try their best to avoid obstacles. Note: This will decrease performance", 0, 1, { type = "Bool", name = "Obstacle Avoiding", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_maxhealth", 100, true, false, false, "Max Lamda Player Health", 1, 10000, { type = "Slider", decimals = 0, name = "Max Health", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_spawnhealth", 100, true, false, false, "The amount of health Lambda Players will spawn with", 1, 10000, { type = "Slider", decimals = 0, name = "Spawning Health", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_maxarmor", 100, true, false, false, "Max Lambda Player Armor", 0, 10000, { type = "Slider", decimals = 0, name = "Max Armor", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_spawnarmor", 0, true, false, false, "The amount of armor Lambda Players will spawn with", 0, 10000, { type = "Slider", decimals = 0, name = "Spawning Armor", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_walkspeed", 200, true, false, false, "Lambda Players walking speed (200 Def)", 100, 1500, { type = "Slider", decimals = 0, name = "Walk Speed", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_runspeed", 400, true, false, false, "Lambda Players running speed (400 Def)", 100, 1500, { type = "Slider", decimals = 0, name = "Run Speed", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_allownoclip", 1, true, false, false, "If Lambda Players are allowed to Noclip", 0, 1, { type = "Bool", name = "Allow Noclip", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_allowkillbind", 0, true, false, false, "If Lambda Players are allowed to randomly use their Killbind", 0, 1, { type = "Bool", name = "Allow Killbind", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_allowrandomaddonsmodels", 0, true, false, false, "If Lambda Players can use random addon playermodels", 0, 1, { type = "Bool", name = "Addon Playermodels", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_onlyaddonmodels", 0, true, false, false, "If Lambda Players should only use playermodels that are from addons. Addon Playermodels should be enabled to work.", 0, 1, { type = "Bool", name = "Only Addon Playermodels", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_allowrandomskinsandbodygroups", 0, true, false, false, "If Lambda Players can have their model's skins and bodygroups randomized", 0, 1, { type = "Bool", name = "Random Skins & Bodygroups", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_voiceprofileusechance", 0, true, false, false, "The chance a Lambda Player will use a random Voice Profile if one exists. Set to 0 to disable", 0, 100, { type = "Slider", decimals = 0, name = "VP Use Chance", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_textprofileusechance", 0, true, false, false, "The chance a Lambda Player will use a random Text Profile if one exists. Set to 0 to disable", 0, 100, { type = "Slider", decimals = 0, name = "TP Use Chance", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_profileusechance", 0, true, false, false, "The chance a Lambda will spawn with a profile that isn't being used. Normally profile Lambda Players only spawn when a Lambda Player has the profile's name. This chance can make profiles appear more often. Do not confuse this with Voice Profiles!", 0, 100, { type = "Slider", decimals = 0, name = "Profile Use Chance", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_realisticfalldamage", 0, true, false, false, "If Lambda Players should take fall damage similar to Realistic Fall Damage", 0, 1, { type = "Bool", name = "Realistic Fall Damage", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_respawntime", 2, true, false, false, "The amount of seconds Lambda Player will take before respawning after dying.", 0.1, 30, { type = "Slider", decimals = 1, name = "Respawn Time", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_respawnatplayerspawns", 0, true, false, false, "If Lambda Players should respawn at player spawn points", 0, 1, { type = "Bool", name = "Respawn At Player Spawns", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_dontrespawnifspeaking", 0, true, false, false, "If Lambda Players should wait for their currently spoken voiceline to finish before respawning.", 0, 1, { type = "Bool", name = "Don't Respawn If Speaking", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_obeynavmeshattributes", 0, true, false, false, "If Lambda Players should obey navmesh attributes such as, Avoid, Walk, Run, Jump, and Crouch", 0, 1, { type = "Bool", name = "Obey Navigation Mesh", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_overridegamemodehooks", 1, true, false, false, "If the addon is allowed to override the following GAMEMODE hooks to support Lambda Players: GM:PlayerDeath() GM:PlayerStartVoice() GM:PlayerEndVoice() GM:OnNPCKilled() GM:CreateEntityRagdoll() Default SandBox Scoreboard : Changing this requires you to restart the server/game for the changes to apply!", 0, 1, { type = "Bool", name = "Override Gamemode Hooks", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_callonnpckilledhook", 0, true, false, false, "If killed Lambda Players should call the OnNPCKilled hook. Best used with the Override Gamemode Hooks option!", 0, 1, { type = "Bool", name = "Call OnNPCKilled Hook On Death", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_singleplayerthinkdelay", 0, true, false, false, "The amount of seconds Lambda Players will execute their next Think. 0.1 is a good value. Increasing this will increase performance at the cost of delays and decreasing this may decrease performance but have less delays. This only applies to singleplayer since multiplayer automatically adjusts think time", 0, 0.24, { type = "Slider", decimals = 2, name = "Think Delay", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_noplycollisions", 0, true, false, false, "If Lambda Players can pass through players (Useful in small corridors/areas)", 0, 1, { type = "Bool", name = "Disable Player Collisions", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_panicanimations", 0, true, false, false, "If panicking Lambda Players should use Panic Animations", 0, 1, { type = "Bool", name = "Use Panic Animations", category = "Lambda Server Settings" } )
CreateLambdaConvar( "lambdaplayers_lambda_physupdatetime", 0.5, true, false, false, "The time it takes for Lambda Player to update its physics object. Lower the value if you have problems with projectiles not colliding with them", 0, 1, { type = "Slider", decimals = 2, name = "Physics Update Time", category = "Lambda Server Settings" } )
--

-- Combat Convars 
CreateLambdaConvar( "lambdaplayers_combat_allowtargetyou", 1, true, true, true, "If Lambda Players are allowed to attack you", 0, 1, { type = "Bool", name = "Target You", category = "Combat" } )
CreateLambdaConvar( "lambdaplayers_combat_retreatonlowhealth", 1, true, false, false, "If Lambda Players should start retreating if they are low on health, or witnessed/committed RDM", 0, 1, { type = "Bool", name = "Retreat On Low Health", category = "Combat" } )
CreateLambdaConvar( "lambdaplayers_combat_spawnbehavior", 0, true, false, false, "If Lambda Players should  behavior when spawned. 0 - Nothing, 1 - Attack you, 2 - Random", 0 , 2, { type = "Slider", decimals = 0, name = "Spawn Behavior Modifier", category = "Combat" } )
CreateLambdaConvar( "lambdaplayers_combat_spawnmedkits", 1, true, false, false, "If Lambda Players are allowed to spawn medkits to heal themselves when low on health. Make sure that 'Allow Entity Spawning' setting is enabled", 0 , 1, { type = "Bool", name = "Spawn Medkits", category = "Combat" } )
CreateLambdaConvar( "lambdaplayers_combat_spawnbatteries", 1, true, false, false, "If Lambda Players are allowed to spawn armor batteries to themselves when low on armor. Make sure that 'Allow Entity Spawning' setting is enabled", 0 , 1, { type = "Bool", name = "Spawn Armor Batteries", category = "Combat" } )
CreateLambdaConvar( "lambdaplayers_combat_weapondmgmultiplier", 1, true, false, false, "Multiplies the damage that Lambda Player deals with its weapon", 0, 5, { type = "Slider", decimals = 2, name = "Weapon Damage Multiplier", category = "Lambda Weapons" } )
--

-- Lambda Player Convars
CreateLambdaConvar( "lambdaplayers_lambda_shouldrespawn", 0, true, true, true, "If Lambda Players should respawn when they die. Note: Changing this will only apply to newly spawned Lambda Players", 0, 1, { type = "Bool", name = "Respawn", category = "Lambda Player Settings" } )
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
CreateLambdaConvar( "lambdaplayers_building_cleanupondeath", 0, true, false, false, "If entities spawned by a respawning Lambda Player should be cleaned up after their death. This might help with performance", 0, 1, { type = "Bool", name = "Cleanup On Death", category = "Building" } )
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
CreateLambdaConvar( "lambdaplayers_text_markovgenerate", 0, true, false, false, "If Lambda text chat lines should be used to generate random text lines using a Markov Chain Generator", 0, 1, { type = "Bool", name = "Use Markov Chain Generator", category = "Text Chat Options" } )
--

-- Force Related Convars
CreateLambdaConvar( "lambdaplayers_force_radius", 750, true, false, false, "The Distance for which Lambda Players are affected by Force Menu options.", 250, 25000, { type = "Slider", name = "Force Radius", decimals = 0, category = "Force Menu" } )
CreateLambdaConvar( "lambdaplayers_force_spawnradiusply", 3000, true, false, false, "The Distance for which Lambda Players can spawn around the player. Set to 0 to disable.", 0, 25000, { type = "Slider", name = "Spawn Around Player Radius", decimals = 0, category = "Force Menu" } )
CreateLambdaConvar( "lambdaplayers_lambda_spawnatplayerspawns", 0, true, false, false, "If spawned Lambda Players should spawn at player spawn points", 0, 1, { type = "Bool", name = "Spawn at Player Spawns", category = "Force Menu" } )
--

-- DEBUGGING CONVARS. Server-side only
CreateLambdaConvar( "lambdaplayers_debug", 0, false, false, false, "Enables the debugging features", 0, 1, { type = "Bool", name = "Enable Debug", category = "Debugging" } )
CreateLambdaConvar( "lambdaplayers_debughelper_drawscale", 0.1, true, true, false, "The Scale the Debug Helper should size at", 0, 1, { type = "Slider", decimals = 2, name = "Debug Helper Scale", category = "Debugging" } )
CreateLambdaConvar( "lambdaplayers_debug_path", 0, false, false, false, "Draws Lambda Player's current path they're moving through.", 0, 1, { type = "Bool", name = "Enable Path Drawing", category = "Debugging" } )
CreateLambdaConvar( "lambdaplayers_debug_eyetracing", 0, false, false, false, "Draws a line from Lambda Player's eye position to where they're looking at. Developer mode should be enabled.", 0, 1, { type = "Bool", name = "Enable Eyetracing Line", category = "Debugging" } )
AddSourceConVarToSettings( "developer", "Enables Source's Developer mode", { type = "Bool", name = "Developer", category = "Debugging" } )
--

-- Note, Weapon allowing convars are located in the shared/globals.lua