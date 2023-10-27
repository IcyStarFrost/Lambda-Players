local table_insert = table.insert
local ents_GetAll = ents.GetAll
local ents_FindInSphere = ents.FindInSphere
local ipairs = ipairs
local random = math.random
local abs = math.abs
local undo = undo
local ents_Create = ents.Create
local IsValid = IsValid
local RandomPairs = RandomPairs
local distance = GetConVar( "lambdaplayers_force_radius" )
local spawnatplayerpoints = GetConVar( "lambdaplayers_lambda_spawnatplayerspawns" )
local plyradius = GetConVar( "lambdaplayers_force_spawnradiusply" )

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
    LambdaQuickNades = LambdaQuickNades or LAMBDAFS:GetQuickNadeWeapons()
    
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

CreateLambdaConsoleCommand( "lambdaplayers_cmd_cacheplayermodels", function( ply )
    if IsValid( ply ) and !ply:IsAdmin() then return end

    for k,v in pairs(player_manager.AllValidModels()) do util.PrecacheModel(v) end
    LambdaPlayers_Notify( ply, "Playermodels cached!", 0, "plats/elevbell1.wav" )
end, false, "WARNING: Your game will freeze for a few seconds. This will vary on the amount of playermodels you have installed.", { name = "Cache Playermodels", category = "Utilities" } )

CreateLambdaConsoleCommand( "lambdaplayers_cmd_debugtogglegod", function( ply ) 

    if IsValid( ply ) and !ply:IsAdmin() then return end
    ply.l_godmode = !ply.l_godmode
    LambdaPlayers_ChatAdd( ply, ( ply.l_godmode and "Enabled" or "Disabled" ) .. " the God Mode for themself" )

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

-- Force stuff

local navmesh_IsLoaded = ( SERVER and navmesh.IsLoaded )
local navmesh_GetAllNavAreas = ( SERVER and navmesh.GetAllNavAreas )
local forceSpawnAng = Angle()

local function FindRandomPositions( pos, radius, height )
    radius = ( radius * radius )

    for _, area in RandomPairs( navmesh_GetAllNavAreas() ) do
        if !IsValid( area ) or area:GetSizeX() <= 32 or area:GetSizeY() <= 32 then continue end

        local closePos = area:GetClosestPointOnArea( pos )
        if abs( pos.z - closePos.z ) > height or closePos:DistToSqr( pos ) > radius then continue end

        return area:GetRandomPoint()
    end

    return false
end

CreateLambdaConsoleCommand( "lambdaplayers_cmd_forcespawnlambda", function( ply ) 
    if IsValid( ply ) and !ply:IsSuperAdmin() then return end
    if !navmesh_IsLoaded() then return end

    local pos = vector_origin
    forceSpawnAng.y = random( -180, 180 )

    LambdaSpawnPoints = ( LambdaSpawnPoints or LambdaGetPossibleSpawns() )
    local plyRadius = plyradius:GetInt()
    local rndPos = FindRandomPositions( ply:GetPos(), ( plyRadius > 0 and plyRadius or 32756 ), ( plyRadius > 0 and ( plyRadius / 2.5 ) or 32756 ) )

    -- Spawning at player spawn points
    if LambdaSpawnPoints and #LambdaSpawnPoints > 0 and ( !rndPos or spawnatplayerpoints:GetBool() ) then
        pos = LambdaSpawnPoints[ random( #LambdaSpawnPoints ) ]:GetPos()
    elseif rndPos then
        pos = rndPos
    else
        return
    end

    local lambda = ents_Create( "npc_lambdaplayer" )
    lambda:SetPos( pos )
    lambda:SetAngles( forceSpawnAng )
    lambda:SetCreator( ply )
    lambda:Spawn()
    lambda:OnSpawnedByPlayer( ply )

    local undoName = "Lambda Player ( " .. lambda:GetLambdaName() .. " )"
    undo.Create( undoName )
        undo.SetPlayer( ply )
        undo.AddEntity( lambda )
        undo.SetCustomUndoText( "Undone " .. undoName )
    undo.Finish( undoName )
end, false, "Spawns a Lambda Player at a random area. NOTE: Requires the map to have a navmesh to work!", { name = "Spawn Lambda Player At Random Area", category = "Force Menu" } )

CreateLambdaConsoleCommand( "lambdaplayers_cmd_forcecombat", function( ply ) 

    if IsValid( ply ) and !ply:IsSuperAdmin() then return end

    local dist = distance:GetInt()
    for _, lambda in ipairs( GetLambdaPlayers() ) do
        if !lambda:IsInRange( ply, dist ) then continue end
        lambda:AttackTarget( ply, true )
    end

end, false, "Forces all Lambda Players in the radius set to attack you", { name = "Lambda Players Attack You", category = "Force Menu" } )

CreateLambdaConsoleCommand( "lambdaplayers_cmd_forcecombatlambda", function( ply ) 

    if IsValid( ply ) and !ply:IsSuperAdmin() then return end

    local dist = distance:GetInt()
    for _, lambda in ipairs( GetLambdaPlayers() ) do
        if !lambda:IsInRange( ply, dist ) then continue end
        local npcs = lambda:FindInSphere( nil, math.huge, function( ent ) return ( lambda:CanTarget( ent ) ) end )
        if #npcs == 0 then continue end
        lambda:AttackTarget( npcs[ random( #npcs ) ] )
    end

end, false, "Forces all Lambda Players in the radius set to attack anything that they can target", { name = "Lambda Players Attack Anything", category = "Force Menu" } )

CreateLambdaConsoleCommand( "lambdaplayers_cmd_forcekill", function( ply ) 

    if IsValid( ply ) and !ply:IsSuperAdmin() then return end

    local dist = distance:GetInt()
    for _, lambda in ipairs( GetLambdaPlayers() ) do
        if !lambda:IsInRange( ply, dist ) then continue end
        lambda:Kill()
    end

end, false, "Kill any Lambda Players in the radius set", { name = "Kill Nearby Lambda Players", category = "Force Menu" } )

CreateLambdaConsoleCommand( "lambdaplayers_cmd_forcepanic", function( ply ) 

    if IsValid( ply ) and !ply:IsSuperAdmin() then return end

    local dist = distance:GetInt()
    for _, lambda in ipairs( GetLambdaPlayers() ) do
        if !lambda:IsInRange( ply, dist ) then continue end
        lambda:RetreatFrom()
    end

end, false, "Forces any Lambda Players in the radius set to panic", { name = "Lambda Players Panic Nearby", category = "Force Menu" } )