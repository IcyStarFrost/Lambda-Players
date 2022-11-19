local table_insert = table.insert
local ents_GetAll = ents.GetAll
local ents_FindInSphere = ents.FindInSphere
local ipairs = ipairs
local random = math.random
local IsValid = IsValid
local distance = GetConVar('lambdaplayers_force_radius'):GetInt() or 750
local spawnatplayerpoints = GetConVar( "lambdaplayers_lambda_spawnatplayerspawns" )

-- The reason this lua file has a d_ in its filename is because of the order on how lua files are loaded.
-- If we didn't do this, we wouldn't have _LAMBDAConVarSettings 
-- are ya learnin son?

-- settingstbl is just about the same as the convar's settingstbl
function CreateLambdaConsoleCommand( name, func, isclient, helptext, settingstbl )
    
    if isclient and SERVER then return end

    concommand.Add( name, func, nil, helptext )

    if CLIENT and settingstbl then
        settingstbl.concmd = name
        settingstbl.isclient = isclient
        settingstbl.type = "Button"
        settingstbl.desc = ( isclient and "Client-Side | " or "Server-Side | " ) .. helptext .. "\nConsole Command: " .. name
        table_insert( _LAMBDAConVarSettings, settingstbl )
    end

end


CreateLambdaConsoleCommand( "lambdaplayers_cmd_updatedata", function( ply ) 
    if IsValid( ply ) and !ply:IsSuperAdmin() then return end
    print( "Lambda Players: Updated data via console command. Ran by ", ( IsValid( ply ) and ply:Name() .. " | " .. ply:SteamID() or "Console" )  )

    LambdaPlayerNames = LAMBDAFS:GetNameTable()
    LambdaPlayerProps = LAMBDAFS:GetPropTable()
    LambdaPlayerMaterials = LAMBDAFS:GetMaterialTable()
    Lambdaprofilepictures = LAMBDAFS:GetProfilePictures()
    LambdaVoiceLinesTable = LAMBDAFS:GetVoiceLinesTable()
    LambdaVoiceProfiles = LAMBDAFS:GetVoiceProfiles()
    LambdaPersonalProfiles = file.Exists( "lambdaplayers/profiles.json", "DATA" ) and LAMBDAFS:ReadFile( "lambdaplayers/profiles.json", "json" ) or nil

    LambdaPlayers_Notify( ply, "Updated Lambda Data", NOTIFY_HINT, "buttons/button15.wav" )

end, false, "Updates data such as names, props, ect. ", { name = "Update Lambda Data", category = "Utilities" } )

CreateLambdaConsoleCommand( "lambdaplayers_cmd_cleanupclientsideents", function( ply ) 

    for k, v in ipairs( _LAMBDAPLAYERS_ClientSideEnts ) do
        if IsValid( v ) then v:Remove() end
    end

    surface.PlaySound( "buttons/button15.wav" )
    notification.AddLegacy( "Cleaned up Client Side Entities!", NOTIFY_CLEANUP, 3 )

end, true, "Removes Lambda client side entities such as ragdolls and dropped weapons", { name = "Remove Lambda Client Side ents", category = "Utilities" } )

CreateLambdaConsoleCommand( "lambdaplayers_cmd_cleanuplambdaents", function( ply ) 
    if IsValid( ply ) and !ply:IsAdmin() then return end

    for k, v in ipairs( ents_GetAll() ) do
        if IsValid( v ) and v.IsLambdaSpawned then v:Remove() end
    end

    LambdaPlayers_Notify( ply, "Cleaned up all Lambda entities!", NOTIFY_CLEANUP, "buttons/button15.wav" )
end, false, "Removes all entities that were spawned by Lambda Players", { name = "Cleanup Lambda Entities", category = "Utilities" } )


CreateLambdaConsoleCommand( "lambdaplayers_cmd_forcespawnlambda", function( ply ) 
    if IsValid( ply ) and !ply:IsSuperAdmin() then return end

    local areas = navmesh.GetAllNavAreas()
    local area
    local point

    local spawns = LambdaGetPossibleSpawns()

    if !spawnatplayerpoints:GetBool() then

        //need a cleaner way for this navmesh stuff

        area = areas[ random( #areas ) ]
        if !area or !area:IsValid() then
            areas = navmesh.GetAllNavAreas()
            area = areas[ random( #areas ) ]
        end

        if !area or !area:IsValid() then
            return
        end
        
        if area:IsUnderwater() then return end
        point = area:GetRandomPoint()
    else
        spawns = LambdaGetPossibleSpawns()

        local spawn = spawns[ random( #spawns ) ]
        if IsValid( spawn ) then
            point = spawn:GetPos()
        else
            print( "RANDOM LAMBDA SPAWN: Player Spawn Is not Valid!" )
            ply:EmitSound( "buttons/button8.wav", 50 )
            PrintMessage( HUD_PRINTTALK, "Spawn Failed! Check Console" )
            print( "Player Spawns not valid. Couldn't find any info_player_start on map. Using random navmesh area." )
            return
        end
    end

    local lambda = ents.Create( "npc_lambdaplayer" )
    lambda:SetPos( point )
    lambda:SetAngles( Angle( 0, random( 0, 360, 0 ), 0 ) )
    lambda:Spawn()

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

end, false, "Spawns a random Lambda Player at a random Navmesh area", { name = "Spawn Random Lambda Player", category = "Force Menu" } )

CreateLambdaConsoleCommand( "lambdaplayers_cmd_forcecombat", function( ply ) 
    if IsValid( ply ) and !ply:IsSuperAdmin() then return end

    for k, v in ipairs( ents_FindInSphere( ply:GetPos(), distance ) ) do
        if IsValid( v ) and v.IsLambdaPlayer then v:AttackTarget( ply ) end
    end

end, false, "Forces all Lambda Players to attack you", { name = "Lambda Players Attack You", category = "Force Menu" } )

CreateLambdaConsoleCommand( "lambdaplayers_cmd_forcekill", function( ply ) 
    if IsValid( ply ) and !ply:IsSuperAdmin() then return end

    for k, v in ipairs( ents_FindInSphere( ply:GetPos(), distance ) ) do
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

CreateLambdaConsoleCommand( "lambdaplayers_cmd_debugtogglegod", function( ply ) 
    if IsValid( ply ) and !ply:IsAdmin() then return end

    ply.l_debuggodmode = !ply.l_debuggodmode

    LambdaPlayers_ChatAdd( ply, ply.l_debuggodmode and "Enabled God mode" or "Disabled God mode" )
end, false, "Toggles God Mode, preventing any further damage to you", { name = "Toggle God Mode", category = "Debugging" } )


-- Calls this hook when all default console commands have been created.
-- This hook can be used to ensure the CreateLambdaConsoleCommand() function exists so custom console commands can be made
hook.Run( "LambdaOnConCommandsCreated" )