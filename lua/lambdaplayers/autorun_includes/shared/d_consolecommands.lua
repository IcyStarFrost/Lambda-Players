local table_insert = table.insert
local ents_GetAll = ents.GetAll
local ipairs = ipairs
local pairs = pairs
local IsValid = IsValid
local util_PrecacheModel = util.PrecacheModel

-- The reason this lua file has a d_ in its filename is because of the order on how lua files are loaded.
-- If we didn't do this, we wouldn't have _LAMBDAConVarSettings
-- are ya learnin son?

-- settingstbl is just about the same as the convar's settingstbl
function CreateLambdaConsoleCommand( name, func, isclient, helptext, settingstbl )

    if isclient and SERVER then return end

    if isclient then
        concommand.Add( name, func, nil, helptext )
    elseif !isclient and SERVER then
        concommand.Add( name, func, nil, helptext )
    end

    if CLIENT and settingstbl and !_LAMBDAConVarNames[ name ] then
        settingstbl.concmd = name
        settingstbl.isclient = isclient
        settingstbl.type = "Button"
        settingstbl.desc = ( isclient and "Client-Side | " or "Server-Side | " ) .. helptext .. "\nConsole Command: " .. name

        _LAMBDAConVarNames[ name ] = true
        table_insert( _LAMBDAConVarSettings, settingstbl )
    end

end

function AddConsoleCommandToLambdaSettings( cmd, isclient, helptext, settingstbl )
    if SERVER or _LAMBDAConVarNames[ cmd ] then return end
    settingstbl.concmd = cmd
    settingstbl.isclient = isclient
    settingstbl.type = "Button"
    settingstbl.desc = ( isclient and "Client-Side | " or "Server-Side | " ) .. helptext .. "\nConsole Command: " .. cmd

    _LAMBDAConVarNames[ cmd ] = true
    table_insert( _LAMBDAConVarSettings, settingstbl )
end

local cooldown = 0

CreateLambdaConsoleCommand( "lambdaplayers_cmd_updatedata", function( ply )
    if IsValid( ply ) and !ply:IsSuperAdmin() then return end
    if CurTime() < cooldown then LambdaPlayers_Notify( ply, "Command is on cooldown! Please wait 3 seconds before trying again", 1, "buttons/button10.wav" ) return end
    print( "Lambda Players: Updated data via console command. Ran by ", ( IsValid( ply ) and ply:Name() .. " | " .. ply:SteamID() or "Console" )  )

    LambdaPlayerNames = LAMBDAFS:GetNameTable()
    LambdaPlayerProps = LAMBDAFS:GetPropTable()
    LambdaPlayerMaterials = LAMBDAFS:GetMaterialTable()
    Lambdaprofilepictures = LAMBDAFS:GetProfilePictures()
    LambdaVoiceLinesTable = LAMBDAFS:GetVoiceLinesTable()
    LambdaVoiceProfiles = LAMBDAFS:GetVoiceProfiles()
    LambdaPlayerSprays = LAMBDAFS:GetSprays()
    LambdaTextTable = LAMBDAFS:GetTextTable()
    LambdaTextProfiles = LAMBDAFS:GetTextProfiles()
    LambdaPersonalProfiles = file.Exists( "lambdaplayers/profiles.json", "DATA" ) and LAMBDAFS:ReadFile( "lambdaplayers/profiles.json", "json" ) or nil
    LambdaModelVoiceProfiles = LAMBDAFS:GetModelVoiceProfiles()
    LambdaPlayermodelBodySkinSets = LAMBDAFS:GetPlayermodelBodySkinSets()
    LambdaQuickNades = LAMBDAFS:GetQuickNadeWeapons()
    LambdaEntsToFearFrom = LAMBDAFS:GetEntsToFearFrom()

    LambdaUpdatePlayerModels()
    LambdaPlayers_Notify( ply, "Updated Lambda Data", 3, "buttons/button15.wav" )

    net.Start( "lambdaplayers_updatedata" )
    net.Broadcast()

    cooldown = CurTime() + 3

    LambdaRunHook( "LambdaOnDataUpdate" )

end, false, "Updates data such as names, props, ect. You must use this after any changes to custom content for changes to take effect!", { name = "Update Lambda Data", category = "Utilities" } )

CreateLambdaConsoleCommand( "lambdaplayers_cmd_cleanupclientsideents", function( ply )

    for k, v in ipairs( _LAMBDAPLAYERS_ClientSideEnts ) do
        if IsValid( v ) then v:Remove() end
    end

    surface.PlaySound( "buttons/button15.wav" )
    notification.AddLegacy( "Cleaned up Client Side Entities!", 4, 3 )

end, true, "Removes Lambda client side entities such as ragdolls and dropped weapons", { name = "Remove Lambda Client Side ents", category = "Utilities" } )

CreateLambdaConsoleCommand( "lambdaplayers_cmd_cleanuplambdaents", function( ply )
    if IsValid( ply ) and !ply:IsAdmin() then return end

    for k, v in ipairs( ents_GetAll() ) do
        if IsValid( v ) and v.IsLambdaSpawned then v:Remove() end
    end

    LambdaPlayers_Notify( ply, "Cleaned up all Lambda entities!", 4, "buttons/button15.wav" )
end, false, "Removes all entities that were spawned by Lambda Players", { name = "Cleanup Lambda Entities", category = "Utilities" } )

AddConsoleCommandToLambdaSettings( "r_cleardecals", true, "Removes all decals in the map for yourself. This does not remove decals premade in the map", { name = "Clean Decals", category = "Utilities" } )

CreateLambdaConsoleCommand( "lambdaplayers_cmd_cacheassets", function( ply )
    if IsValid( ply ) and !ply:IsAdmin() then return end

    -- Cache player models
    for _, mdl in ipairs( _LAMBDAPLAYERS_AllPlayermodels ) do
        util_PrecacheModel( mdl )
    end

    -- Cache weapon assets
    for _, data in pairs( _LAMBDAPLAYERSWEAPONS ) do
        if data.nodraw then continue end

        local mdl = data.model
        if !mdl then continue end

        util_PrecacheModel( mdl )
    end

    LambdaPlayers_Notify( ply, "Lambda assets cached!", 0, "plats/elevbell1.wav" )
end, false, "WARNING: Your game will freeze for a few seconds. This will vary on the amount of assets you have installed.", { name = "Cache Assets", category = "Utilities" } )

CreateLambdaConsoleCommand( "lambdaplayers_cmd_debugtogglegod", function( ply )
    if IsValid( ply ) and !ply:IsAdmin() then return end
    ply.l_godmode = !ply.l_godmode
    LambdaPlayers_ChatAdd( ply, ( ply.l_godmode and "Enabled" or "Disabled" ) .. " the God Mode" )
end, false, "Toggles God Mode, preventing any further damage to you", { name = "Toggle God Mode", category = "Debugging" } )

local dispClrR, dispClrG, dispClrB
if ( CLIENT ) then
    dispClrR = GetConVar( "lambdaplayers_displaycolor_r" )
    dispClrG = GetConVar( "lambdaplayers_displaycolor_g" )
    dispClrB = GetConVar( "lambdaplayers_displaycolor_b" )

    _LambdaDisplayColor = Color( dispClrR:GetInt(), dispClrG:GetInt(), dispClrB:GetInt() )
end

CreateLambdaConsoleCommand( "lambdaplayers_cmd_updatedisplaycolor", function( ply )

    _LambdaDisplayColor.r = dispClrR:GetInt()
    _LambdaDisplayColor.g = dispClrG:GetInt()
    _LambdaDisplayColor.b = dispClrB:GetInt()

end, true, "Applies any changes done to Display Color", { name = "Update Display Color", category = "Misc" } )