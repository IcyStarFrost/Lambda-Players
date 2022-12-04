local enabled = CreateLambdaConvar( "lambdaplayers_mws_enabled", 0, true, false, false, "If Lambda Players should spawn naturally via MWS (Map Wide Spawning)", 0, 1, { type = "Bool", name = "Enable MWS", category = "MWS"} )
local maxlambdacount = CreateLambdaConvar( "lambdaplayers_mws_maxlambdas", 5, true, false, false, "The amount of natural Lambdas can be spawned at once", 1, 500, { type = "Slider", decimals = 0, name = "Max Lambda Count", category = "MWS"} )
local spawnrate = CreateLambdaConvar( "lambdaplayers_mws_spawnrate", 2, true, false, false, "Time in seconds before each Lambda Player is spawned", 0.1, 500, { type = "Slider", decimals = 1, name = "Spawn Rate", category = "MWS"} )
local randomspawnrate = CreateLambdaConvar( "lambdaplayers_mws_randomspawnrate", 0, true, false, false, "If the spawn rate should be randomized between 0.1 and what ever Spawn Rate is set to", 0, 1, { type = "Bool", name = "Randomized Spawn Rate", category = "MWS"} )

if CLIENT then return end

local CurTime = CurTime
local ipairs = ipairs
local table_remove = table.remove
local table_insert = table.insert
local IsValid = IsValid
local rand = math.Rand
local random = math.random
local navmesh_GetAllNavAreas = navmesh.GetAllNavAreas

local SpawnedLambdaPlayers = {}
local shutdown = false
local failtimes = 0
local nextspawn = 0
hook.Add( "Tick", "lambdaplayers_MWS", function()
    if shutdown then return end

    -- Remove all spawned Lambdas and remain dormant
    if !enabled:GetBool() then

        nextspawn = randomspawnrate:GetBool() and CurTime() + rand( 0.1, spawnrate:GetFloat() ) or CurTime() + spawnrate:GetFloat()

        if #SpawnedLambdaPlayers > 0 then
            for k, lambda in ipairs( SpawnedLambdaPlayers ) do
                if IsValid( lambda ) then lambda:Remove() table_remove( SpawnedLambdaPlayers, k ) end
            end
        end

        
        return
    end

    if CurTime() > nextspawn and #SpawnedLambdaPlayers < maxlambdacount:GetInt() then
        local spawns = LambdaGetPossibleSpawns()
        local point = spawns[ random( #spawns ) ]
        local pos
        local ang

        -- Massive fallback chain
        if IsValid( point ) then 
            pos = point:GetPos()
            ang = point:GetAngles()
        else
            local navareas = navmesh_GetAllNavAreas()
            local area = navareas[ random( #navareas ) ]

            if IsValid( area ) then
                pos = area:GetRandomPoint()
                ang = Angle( 0, random( 360 ), 0 )
            else
                failtimes = failtimes + 1
                pos = Vector( 0, 0, 0 )
                ang = Angle( 0, random( 360 ), 0 )

                -- We failed too many times trying to set a proper position. Shutdown.
                if failtimes >= 7 then
                    shutdown = true
                    ErrorNoHalt( "Lambda Players MWS: Couldn't find a proper place for Lambdas to spawn " .. failtimes .. " times! Either play a map that has spawn points/has a Navigation Mesh or just manually spawn Lambda Players. MWS will now shutdown for the rest of the session." )
                end
            end
        end

        local lambda = ents.Create( "npc_lambdaplayer" )
        lambda:SetPos( pos )
        lambda:SetAngles( ang )
        lambda:Spawn()

        table_insert( SpawnedLambdaPlayers, 1, lambda )

        nextspawn = randomspawnrate:GetBool() and CurTime() + rand( 0.1, spawnrate:GetFloat() ) or CurTime() + spawnrate:GetFloat()

    elseif #SpawnedLambdaPlayers > maxlambdacount:GetInt() then
        local lambda = SpawnedLambdaPlayers[ #SpawnedLambdaPlayers ]
        if IsValid( lambda ) then lambda:Remove() table_remove( SpawnedLambdaPlayers, #SpawnedLambdaPlayers ) end
    end


end )

-- Remove self from the MWS table
hook.Add( "LambdaOnRemove", "lambdaplayers_MWS_OnRemove", function( self )
    for k, v in ipairs( SpawnedLambdaPlayers ) do
        if v == self then table_remove( SpawnedLambdaPlayers, k ) break end
    end
end )