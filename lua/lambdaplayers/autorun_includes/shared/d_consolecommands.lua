local table_insert = table.insert
local ents_GetAll = ents.GetAll
local ents_FindInSphere = ents.FindInSphere
local ipairs = ipairs
local random = math.random
local IsValid = IsValid
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
    LambdaModelVoiceProfiles = LAMBDAFS:GetModelVoiceProfiles()
    LambdaPersonalProfiles = file.Exists( "lambdaplayers/profiles.json", "DATA" ) and LAMBDAFS:ReadFile( "lambdaplayers/profiles.json", "json" ) or nil
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

CreateLambdaConsoleCommand( "lambdaplayers_cmd_forcespawnlambda", function( ply ) 
	if IsValid( ply ) and !ply:IsSuperAdmin() then return end
    if !navmesh.IsLoaded() then return end

    local function GetRandomNavmesh()
        local FindAllNavMesh_NearPly = navmesh.Find( ply:GetPos(), plyradius:GetInt(), 30, 50 )
        local NavMesh_NearPly = FindAllNavMesh_NearPly[ random( #FindAllNavMesh_NearPly ) ]

        local FindAllNavMesh_Random = navmesh.Find( ply:GetPos(), random( 250, 99999 ), 30, 50 )
        local NavMesh_Random = FindAllNavMesh_Random[ random( #FindAllNavMesh_Random ) ]
        
        -- Once we got all nearby NavMesh areas near the player, pick out a random
        -- navmesh spot to spawn around with the set radius.
        -- BUG: it doesn't get different heights, unless our player is on that level
        if plyradius:GetInt() > 1 then
            for k, v in ipairs( FindAllNavMesh_NearPly ) do
                if IsValid( v ) and v:GetSizeX() > 35 and v:GetSizeY() > 35 then -- We don't want to spawn them in smaller nav areas, or water.
                    return NavMesh_NearPly:GetRandomPoint() -- We found a suitable location, spawn it!
                end
            end
        else -- If the radius is 0, find a random navmesh around the player at any range
            for k, v in ipairs( FindAllNavMesh_Random ) do
                if IsValid( v ) and v:GetSizeX() > 35 and v:GetSizeY() > 35 then
                    return NavMesh_Random:GetRandomPoint()
                end
            end
        end
    end

    local pos
    local ang
    local spawns

    -- Spawning at player spawn points
    if spawnatplayerpoints:GetBool() then
		spawns = LambdaGetPossibleSpawns()
		local spawn = spawns[ random( #spawns ) ]
        
        pos = spawn:GetPos()
        ang = Angle( 0, random( -180, 180 ), 0 )
    else -- We spawn at a random navmesh
        pos = GetRandomNavmesh()
        ang = Angle( 0, random( -180, 180 ), 0 )
    end


	local lambda = ents.Create( "npc_lambdaplayer" )
	lambda:SetPos( pos )
	lambda:SetAngles( ang )
	lambda:Spawn()

    lambda.l_SpawnWeapon = ply:GetInfo( "lambdaplayers_lambda_spawnweapon" )
    lambda:SwitchToSpawnWeapon()

	undo.Create( "Lambda Player ( " .. lambda:GetLambdaName() .. " )" )
		undo.SetPlayer( ply )
		undo.SetCustomUndoText( "Undone " .. "Lambda Player ( " .. lambda:GetLambdaName() .. " )" )
		undo.AddEntity( lambda )
	undo.Finish( "Lambda Player ( " .. lambda:GetLambdaName() .. " )" )

	local dynLight = ents.Create( "light_dynamic" )
	dynLight:SetKeyValue( "brightness", "2" )
	dynLight:SetKeyValue( "distance", "90" )
	dynLight:SetPos( lambda:GetPos() )
	dynLight:SetLocalAngles( lambda:GetAngles() )
	dynLight:Fire( "Color", "255 145 0" )
	dynLight:Spawn()
	dynLight:Activate()
	dynLight:Fire( "TurnOn", "", 0 )
	dynLight:Fire( "Kill", "", 0.75 )

end, false, "Spawns a Lambda Player at a random area", { name = "Spawn Lambda Player At Random Area", category = "Force Menu" } )

CreateLambdaConsoleCommand( "lambdaplayers_cmd_forcecombat", function( ply ) 
    if IsValid( ply ) and !ply:IsSuperAdmin() then return end

    for k, v in ipairs( ents_FindInSphere( ply:GetPos(), distance:GetInt() ) ) do
        if IsValid( v ) and v.IsLambdaPlayer then v:AttackTarget( ply ) end
    end

end, false, "Forces all Lambda Players to attack you", { name = "Lambda Players Attack You", category = "Force Menu" } )

CreateLambdaConsoleCommand( "lambdaplayers_cmd_forcecombatlambda", function( ply ) 
    if IsValid( ply ) and !ply:IsSuperAdmin() then return end

    for k, v in ipairs( ents_FindInSphere( ply:GetPos(), distance:GetInt() ) ) do
        if IsValid( v ) and v.IsLambdaPlayer then
			local npcs = v:FindInSphere( nil, 25000, function( ent ) return ( ent:IsNPC() or ent:IsNextBot() ) end )
			v:AttackTarget( npcs[ random( #npcs ) ] )
		end
    end

end, false, "Forces all Lambda Players to attack anything", { name = "Lambda Players Attack Anything", category = "Force Menu" } )

CreateLambdaConsoleCommand( "lambdaplayers_cmd_forcekill", function( ply ) 
    if IsValid( ply ) and !ply:IsSuperAdmin() then return end

    for k, v in ipairs( ents_FindInSphere( ply:GetPos(), distance:GetInt() ) ) do
        if v.IsLambdaPlayer then
            local dmginfo = DamageInfo()
            dmginfo:SetDamage( 1000 )
            dmginfo:SetDamageForce( v:GetForward()*2000 or v:GetForward()*500 )
            dmginfo:SetAttacker( v )
            dmginfo:SetInflictor( v )
            v:TakeDamageInfo( dmginfo )
        end
    end

end, false, "Kill any Lambda Players in the radius set", { name = "Kill Nearby Lambda Players", category = "Force Menu" } )

CreateLambdaConsoleCommand( "lambdaplayers_cmd_forcepanic", function( ply ) 
    if IsValid( ply ) and !ply:IsSuperAdmin() then return end

    for k, v in ipairs( ents_FindInSphere( ply:GetPos(), distance:GetInt() ) ) do
        if v.IsLambdaPlayer then
            v:RetreatFrom( ply )
        end
    end

end, false, "Forces any Lambda Players around will panic", { name = "Lambda Players Panic Nearby", category = "Force Menu" } )

CreateLambdaConsoleCommand( "lambdaplayers_cmd_debugtogglegod", function( ply ) 
    if IsValid( ply ) and !ply:IsAdmin() then return end

    ply.l_godmode = !ply.l_godmode

    LambdaPlayers_ChatAdd( ply, ply.l_godmode and "Enabled God mode" or "Disabled God mode" )
end, false, "Toggles God Mode, preventing any further damage to you", { name = "Toggle God Mode", category = "Debugging" } )


if CLIENT then
    local r = GetConVar( "lambdaplayers_displaycolor_r" )
    local g = GetConVar( "lambdaplayers_displaycolor_g" )
    local b = GetConVar( "lambdaplayers_displaycolor_b" )

    _LambdaDisplayColor = Color( r:GetInt(), g:GetInt(), b:GetInt() )
end

CreateLambdaConsoleCommand( "lambdaplayers_cmd_updatedisplaycolor", function( ply ) 
    local r = GetConVar( "lambdaplayers_displaycolor_r" )
    local g = GetConVar( "lambdaplayers_displaycolor_g" )
    local b = GetConVar( "lambdaplayers_displaycolor_b" )

    _LambdaDisplayColor = Color( r:GetInt(), g:GetInt(), b:GetInt() )

end, true, "Applies any changes done to Display Color", { name = "Update Display Color", category = "Misc" } )
