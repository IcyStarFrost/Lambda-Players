local navmesh_IsLoaded = ( SERVER and navmesh.IsLoaded )
local navmesh_GetAllNavAreas = ( SERVER and navmesh.GetAllNavAreas )

local ents_Create = ents.Create
local RandomPairs = RandomPairs
local abs = math.abs
local undo = undo
local IsValid = IsValid
local distance = GetConVar( "lambdaplayers_force_radius" )
local spawnatplayerpoints = GetConVar( "lambdaplayers_lambda_spawnatplayerspawns" )
local plyradius = GetConVar( "lambdaplayers_force_spawnradiusply" )
local forceSpawnAng = Angle()
local util_TraceHull = util.TraceHull
local stuckTr = {
    mins = Vector( -16, -16, 0 ),
    maxs = Vector( 16, 16, 72 ),
    mask = MASK_PLAYERSOLID
}

local function FindRandomPositions( pos, radius, height )
    radius = ( radius * radius )

    for _, area in RandomPairs( navmesh_GetAllNavAreas() ) do
        if !IsValid( area ) or area:GetSizeX() <= 32 or area:GetSizeY() <= 32 then continue end

        local closePos = area:GetClosestPointOnArea( pos )
        if abs( pos.z - closePos.z ) > height or closePos:DistToSqr( pos ) > radius then continue end

        -- Attempt to find a spot that doesn't get them stuck
        local rndPos = area:GetRandomPoint()
        stuckTr.start = ( rndPos + vector_up * 1 )
        stuckTr.endpos = ( rndPos + vector_up * 2 )

        local tr = util_TraceHull( stuckTr )
        if !tr.Hit then return rndPos end
    end

    return false
end

CreateLambdaConsoleCommand( "lambdaplayers_cmd_forcespawnlambda", function( ply )
    if IsValid( ply ) and !ply:IsSuperAdmin() then return end
    if !navmesh_IsLoaded() then return end

    local pos = vector_origin
    forceSpawnAng.y = LambdaRNG( -180, 180 )

    LambdaSpawnPoints = ( LambdaSpawnPoints or LambdaGetPossibleSpawns() )
    local plyRadius = plyradius:GetInt()
    local spawnAtPlayerHeight = GetConVar( "lambdaplayers_lambda_spawnatplyheight" ):GetBool()
    local height = spawnAtPlayerHeight and 64 or ( plyRadius > 0 and plyRadius / 2.5 or 32756 )
    local spawnAmount = GetConVar( "lambdaplayers_lambda_spawnamount" ):GetInt()

    for i = 1, spawnAmount do
        local rndPos = FindRandomPositions( ply:GetPos(), ( plyRadius > 0 and plyRadius or 32756 ), height )

        -- Spawning at player spawn points
        if LambdaSpawnPoints and #LambdaSpawnPoints > 0 and ( !rndPos or spawnatplayerpoints:GetBool() ) then
            pos = LambdaSpawnPoints[ LambdaRNG( #LambdaSpawnPoints ) ]:GetPos()
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

        local effect = EffectData()
        effect:SetEntity( lambda )
        util.Effect( "propspawn", effect )

        lambda:OnSpawnedByPlayer( ply )

        local undoName = "Lambda Player ( " .. lambda:GetLambdaName() .. " )"
        undo.Create( undoName )
            undo.SetPlayer( ply )
            undo.AddEntity( lambda )
            undo.SetCustomUndoText( "Undone " .. undoName )
        undo.Finish( undoName )
    end
end, false, "Spawns a Lambda Player at a random area. NOTE: Requires a navmesh.", { name = "Randomly Spawn Lambda Player", category = "Force Menu" } )

CreateLambdaConsoleCommand( "lambdaplayers_cmd_forcecombat", function( ply ) 
    if IsValid( ply ) and !ply:IsSuperAdmin() then return end

    local dist = distance:GetInt()
    for _, lambda in ipairs( GetLambdaPlayers() ) do
        if !lambda:IsInRange( ply, dist ) then continue end
        lambda:AttackTarget( ply, true )
    end
end, false, "Forces all Lambda Players in the given radius to attack you", { name = "Lambda Players Attack You", category = "Force Menu" } )

CreateLambdaConsoleCommand( "lambdaplayers_cmd_forcecombatlambda", function( ply ) 
    if IsValid( ply ) and !ply:IsSuperAdmin() then return end

    local dist = distance:GetInt()
    for _, lambda in ipairs( GetLambdaPlayers() ) do
        if !lambda:IsInRange( ply, dist ) then continue end
        local npcs = lambda:FindInSphere( nil, math.huge, function( ent ) return ( lambda:CanTarget( ent ) ) end )
        if #npcs == 0 then continue end
        lambda:AttackTarget( npcs[ LambdaRNG( #npcs ) ] )
    end
end, false, "Forces all Lambda Players in the given radius to attack anything that they consider a target", { name = "Lambda Players Attack Anything", category = "Force Menu" } )

CreateLambdaConsoleCommand( "lambdaplayers_cmd_forcekill", function( ply ) 
    if IsValid( ply ) and !ply:IsSuperAdmin() then return end

    local dist = distance:GetInt()
    for _, lambda in ipairs( GetLambdaPlayers() ) do
        if !lambda:IsInRange( ply, dist ) then continue end
        lambda:Kill()
    end
end, false, "Kill all Lambda Players in the given radius", { name = "Kill Nearby Lambda Players", category = "Force Menu" } )

CreateLambdaConsoleCommand( "lambdaplayers_cmd_forcepanic", function( ply ) 
    if IsValid( ply ) and !ply:IsSuperAdmin() then return end

    local dist = distance:GetInt()
    for _, lambda in ipairs( GetLambdaPlayers() ) do
        if !lambda:IsInRange( ply, dist ) then continue end
        lambda:RetreatFrom()
    end
end, false, "Forces all Lambda Players in the given radius to start panicking and retreat", { name = "Lambda Players Panic Nearby", category = "Force Menu" } )