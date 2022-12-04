local enabled = CreateLambdaConvar( "lambdaplayers_mws_enabled", 0, true, false, false, "If Lambda Players should spawn naturally via MWS (Map Wide Spawning)", 0, 1, { type = "Bool", name = "Enable MWS", category = "MWS"} )
local maxlambdacount = CreateLambdaConvar( "lambdaplayers_mws_maxlambdas", 5, true, false, false, "The amount of natural Lambdas can be spawned at once", 1, 500, { type = "Slider", decimals = 0, name = "Max Lambda Count", category = "MWS"} )
local spawnrate = CreateLambdaConvar( "lambdaplayers_mws_spawnrate", 2, true, false, false, "Time in seconds before each Lambda Player is spawned", 0.1, 500, { type = "Slider", decimals = 1, name = "Spawn Rate", category = "MWS"} )
local randomspawnrate = CreateLambdaConvar( "lambdaplayers_mws_randomspawnrate", 0, true, false, false, "If the spawn rate should be randomized between 0.1 and what ever Spawn Rate is set to", 0, 1, { type = "Bool", name = "Randomized Spawn Rate", category = "MWS"} )
local respawn = CreateLambdaConvar( "lambdaplayers_mws_respawning", 1, true, false, false, "If Lambda Players spawned by MWS should respawn", 0, 1, { type = "Bool", name = "Respawn", category = "MWS"} )


local table_insert = table.insert
local rand = math.Rand
local random = math.random


local personalitypresets = {
    [ "custom" ] = function( self ) -- Custom Personality set by Sliders
        local tbl = {}
        for k, v in ipairs( LambdaPersonalityConVars ) do
            tbl[ v[ 1 ] ] = GetConVar( "lambdaplayers_mwspersonality_" .. v[ 1 ] .. "chance" ):GetInt()
        end
        self:SetVoiceChance( GetConVar( "lambdaplayers_personality_voicechance" ):GetInt() )
        self:SetTextChance( GetConVar( "lambdaplayers_personality_textchance" ):GetInt() )
        return  tbl
    end,
    [ "customrandom" ] = function( self ) -- Same thing as Custom except the values from Sliders are used in RNG
        local tbl = {}
        for k, v in ipairs( LambdaPersonalityConVars ) do
            tbl[ v[ 1 ] ] = random( GetConVar( "lambdaplayers_personality_" .. v[ 1 ] .. "chance" ):GetInt() )
        end
        self:SetVoiceChance( random( 0, GetConVar( "lambdaplayers_personality_voicechance" ):GetInt() ) )
        self:SetTextChance( random( 0, GetConVar( "lambdaplayers_personality_textchance" ):GetInt() ) )
        return tbl
    end,
    [ "fighter" ] = function( self ) -- Focused on Combat
        local tbl = {}
        for k, v in ipairs( LambdaPersonalityConVars ) do
            tbl[ v[ 1 ] ] = 0
        end
        tbl[ "Build" ] = 5
        tbl[ "Combat" ] = 80
        tbl[ "Tool" ] = 5
        self:SetVoiceChance( 30 )
        self:SetTextChance( 30 )
        return tbl
    end,
    [ "builder" ] = function( self ) -- Focused on Building
        local tbl = {}
        for k, v in ipairs( LambdaPersonalityConVars ) do
            tbl[ v[ 1 ] ] = random( 1, 100 )
        end
        tbl[ "Build" ] = 80
        tbl[ "Combat" ] = 5
        tbl[ "Tool" ] = 80
        self:SetVoiceChance( 30 )
        self:SetTextChance( 30 )
        return tbl
    end
} 


local presettbl = {
    [ "Random" ] = "random",
    [ "Builder" ] = "builder",
    [ "Fighter" ] = "fighter",
    [ "Custom" ] = "custom",
    [ "Custom Random" ] = "customrandom"
}

local perspreset = CreateLambdaConvar( "lambdaplayers_mwspersonality_preset", "random", true, false, false, "The preset MWS Spawned Lambda Personalities should use. Set this to Custom to make use of the chance sliders", nil, nil, { type = "Combo", options = presettbl, name = "Personality Preset", category = "MWS" } )


local MWSConvars = {}
for k, v in ipairs( LambdaPersonalityConVars ) do
    local convar = CreateLambdaConvar( "lambdaplayers_mwspersonality_" .. v[ 1 ] .. "chance", 30, true, false, false, "The chance " .. v[ 1 ] .. " will be executed. Personality Preset should be set to Custom for this slider to effect newly spawned Lambda Players!", 0, 100, { type = "Slider", decimals = 0, name = v[ 1 ] .. " Chance", category = "MWS" } )
    table_insert( MWSConvars, { v[ 1 ], convar } )
end
CreateLambdaConvar( "lambdaplayers_mwspersonality_voicechance", 30, true, false, false, "The chance Voice will be executed. Personality Preset should be set to Custom for this slider to effect newly spawned Lambda Players!", 0, 100, { type = "Slider", decimals = 0, name = "Voice Chance", category = "MWS" } )
CreateLambdaConvar( "lambdaplayers_mwspersonality_textchance", 30, true, false, false, "The chance Text will be executed. Personality Preset should be set to Custom for this slider to effect newly spawned Lambda Players!", 0, 100, { type = "Slider", decimals = 0, name = "Text Chance", category = "MWS" } )


CreateLambdaConsoleCommand( "lambdaplayers_cmd_openmwscustompersonalitypresetpanel", function( ply ) 
    local tbl = {}
    tbl[ "lambdaplayers_mwspersonality_voicechance" ] = 30
    tbl[ "lambdaplayers_mwspersonality_textchance" ] = 30
    for k, v in ipairs( MWSConvars ) do
        tbl[ v[ 2 ]:GetName() ] = v[ 2 ]:GetDefault()
    end
    LAMBDAPANELS:CreateCVarPresetPanel( "Custom Personality Preset Editor", tbl, "custommwspersonalities", false )
end, true, "Opens a panel to allow you to create custom preset personalities and load them", { name = "Custom Personality Presets", category = "MWS" } )


if CLIENT then return end

local CurTime = CurTime
local ipairs = ipairs
local table_remove = table.remove
local IsValid = IsValid

local navmesh_GetAllNavAreas = navmesh.GetAllNavAreas

local SpawnedLambdaPlayers = {}
local shutdown = false
local pause = false
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

    if pause then return end

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
        lambda.l_MWSspawned = true
        lambda:Spawn()
        lambda:SetRespawn( respawn:GetBool() )
        table_insert( SpawnedLambdaPlayers, 1, lambda )

        if perspreset:GetString() != "random" then
            lambda:BuildPersonalityTable( personalitypresets[ perspreset:GetString() ]( lambda ) )
        end

        

        nextspawn = randomspawnrate:GetBool() and CurTime() + rand( 0.1, spawnrate:GetFloat() ) or CurTime() + spawnrate:GetFloat()

    elseif #SpawnedLambdaPlayers > maxlambdacount:GetInt() then
        local lambda = SpawnedLambdaPlayers[ #SpawnedLambdaPlayers ]
        if IsValid( lambda ) then lambda:Remove() table_remove( SpawnedLambdaPlayers, #SpawnedLambdaPlayers ) end
    end


end )



-- These hooks will prevent MWS from over shooting its limits
hook.Add( "LambdaOnInternalKilled", "lambdaplayers_MWS_prerecreation", function( self )
    if self.l_MWSspawned then 
        self:SetExternalVar( "l_mwsprerecreation", true ) 
        pause = true 
        timer.Simple( 1, function() pause = false end ) 
    end
end ) 

hook.Add( "LambdaOnRecreated", "lambdaplayers_MWS_postrecreation", function( self )
    if self:GetExternalVar( "l_mwsprerecreation" ) then
        self.l_MWSspawned = true
        table_insert( SpawnedLambdaPlayers, 1, self )
        pause = false
    end
end )
--

-- Remove self from the MWS table
hook.Add( "LambdaOnRemove", "lambdaplayers_MWS_OnRemove", function( self )
    for k, v in ipairs( SpawnedLambdaPlayers ) do
        if v == self then table_remove( SpawnedLambdaPlayers, k ) break end
    end
end )