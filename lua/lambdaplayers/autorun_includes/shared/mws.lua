local enabled = CreateLambdaConvar( "lambdaplayers_mws_enabled", 0, true, false, false, "If Lambda Players should spawn naturally via MWS (Map Wide Spawning)", 0, 1, { type = "Bool", name = "Enable MWS", category = "MWS"} )
local maxlambdacount = CreateLambdaConvar( "lambdaplayers_mws_maxlambdas", 5, true, false, false, "The amount of natural Lambdas can be spawned at once", 1, 500, { type = "Slider", decimals = 0, name = "Max Lambda Count", category = "MWS"} )
local spawnrate = CreateLambdaConvar( "lambdaplayers_mws_spawnrate", 2, true, false, false, "Time in seconds before each Lambda Player is spawned", 0.1, 500, { type = "Slider", decimals = 1, name = "Spawn Rate", category = "MWS"} )
local randomspawnrate = CreateLambdaConvar( "lambdaplayers_mws_randomspawnrate", 0, true, false, false, "If the spawn rate should be randomized between 0.1 and what ever Spawn Rate is set to", 0, 1, { type = "Bool", name = "Randomized Spawn Rate", category = "MWS"} )
local respawn = CreateLambdaConvar( "lambdaplayers_mws_respawning", 1, true, false, false, "If Lambda Players spawned by MWS should respawn", 0, 1, { type = "Bool", name = "Respawn", category = "MWS"} )
local navmeshspawning = CreateLambdaConvar( "lambdaplayers_mws_spawnonnavmesh", 1, true, false, false, "If Lambda Players spawned by MWS should spawn randomly on the map using the navmesh. Remember that the (Respawn At Player Spawns) option in Lambda Server Settings will make them respawn at player spawn points", 0, 1, { type = "Bool", name = "Random Navmesh Spawn Points", category = "MWS"} )
local navmeshspawndist = CreateLambdaConvar( "lambdaplayers_mws_navmeshspawndist", 0, true, false, false, "If (Random Navmesh Spawn Points) is enabled, sets the limit in what distance should the real player be from the area Lambda Player can spawn in. Set to zero for unlimited spawn distance", 0, 10000, { type = "Slider", decimals = 0, name = "Navmesh Spawn Distance Limit", category = "MWS"} )

local table_insert = table.insert
local rand = math.Rand
local random = math.random
local net = net
local PlaySound = ( CLIENT and surface.PlaySound )
local AddNotification = ( CLIENT and notification.AddLegacy )
local ipairs = ipairs
local SortedPairs = SortedPairs
local max = math.max

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
        self:SetVoiceChance( 60 )
        self:SetTextChance( 60 )
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
        self:SetVoiceChance( 60 )
        self:SetTextChance( 60 )
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

hook.Add( "LambdaOnModulesLoaded", "lambdaplayers_mwspersonalities", function()
    for _, v in ipairs( LambdaPersonalityConVars ) do
        local convar = CreateLambdaConvar( "lambdaplayers_mwspersonality_" .. v[ 1 ] .. "chance", 30, true, false, false, "The chance " .. v[ 1 ] .. " will be executed. Personality Preset should be set to Custom for this slider to effect newly spawned Lambda Players!", 0, 100, { type = "Slider", decimals = 0, name = v[ 1 ] .. " Chance", category = "MWS" } )
        table_insert( MWSConvars, { v[ 1 ], convar } )
    end
    CreateLambdaConvar( "lambdaplayers_mwspersonality_voicechance", 30, true, false, false, "The chance Voice will be executed. Personality Preset should be set to Custom for this slider to effect newly spawned Lambda Players!", 0, 100, { type = "Slider", decimals = 0, name = "Voice Chance", category = "MWS" } )
    CreateLambdaConvar( "lambdaplayers_mwspersonality_textchance", 30, true, false, false, "The chance Text will be executed. Personality Preset should be set to Custom for this slider to effect newly spawned Lambda Players!", 0, 100, { type = "Slider", decimals = 0, name = "Text Chance", category = "MWS" } )
end )

CreateLambdaConsoleCommand( "lambdaplayers_cmd_openmwscustompersonalitypresetpanel", function( ply ) 
    local tbl = {}
    tbl[ "lambdaplayers_mwspersonality_voicechance" ] = 30
    tbl[ "lambdaplayers_mwspersonality_textchance" ] = 30
    for _, v in ipairs( MWSConvars ) do
        tbl[ v[ 2 ]:GetName() ] = v[ 2 ]:GetDefault()
    end
    LAMBDAPANELS:CreateCVarPresetPanel( "Custom Personality Preset Editor", tbl, "custommwspersonalities", false )
end, true, "Opens a panel to allow you to create custom preset personalities and load them", { name = "Custom Personality Presets", category = "MWS" } )





local spawnWep = CreateLambdaConvar( "lambdaplayers_mws_spawnweapon", "physgun", true, false, false, "The weapon MWS spawned Lambda Players will spawn with only if the specified weapon is allowed", 0, 1 )


if SERVER then
    util.AddNetworkString( "lambdamws_selectspawnweapon" )

    net.Receive( "lambdamws_selectspawnweapon", function( len, ply )
        if !ply:IsSuperAdmin() then return end
        spawnWep:SetString( net.ReadString() )
    end )
end 

local function OpenSpawnWeaponPanel( ply ) 
    if !ply:IsSuperAdmin() then 
        AddNotification( "You must be a Super Admin in order to use this!", 1, 4 )
        PlaySound( "buttons/button10.wav" ) 
        return 
    end

    local mainframe = LAMBDAPANELS:CreateFrame( "Spawn Weapon Selection", 700, 500 )
    local mainscroll = LAMBDAPANELS:CreateScrollPanel( mainframe, true, FILL )

    local weplinelist = {}
    local weplistlist = {}

    local currentWep = spawnWep:GetString()
    if currentWep == "random" then 
        currentWep = "Random Weapon"
    else
        currentWep = _LAMBDAPLAYERSWEAPONS[ currentWep ].prettyname
    end
    LAMBDAPANELS:CreateLabel( "Currenly selected spawn weapon: " .. currentWep, mainframe, TOP )

    for weporigin, _ in pairs( _LAMBDAPLAYERSWEAPONORIGINS ) do
        local originlist = vgui.Create( "DListView", mainscroll )
        originlist:SetSize( 200, 400 )
        originlist:Dock( LEFT )
        originlist:AddColumn( weporigin, 1 )
        originlist:SetMultiSelect( false )

        function originlist:DoDoubleClick( id, line )
            net.Start( "lambdamws_selectspawnweapon" )
            net.WriteString( line:GetSortValue( 1 ) )
            net.SendToServer()
            AddNotification( "Selected " .. line:GetColumnText( 1 ) .. " from " .. weporigin .. " as a spawn weapon!", NOTIFY_GENERIC, 3 )
            PlaySound( "buttons/button15.wav" )
            mainframe:Close()
        end

        mainscroll:AddPanel( originlist )

        for name, data in pairs( _LAMBDAPLAYERSWEAPONS ) do
            if name == "none" then continue end
            if data.origin != weporigin then continue end

            local allowCvar = _LAMBDAWEAPONALLOWCONVARS[ name ]
            if allowCvar and !allowCvar:GetBool() then continue end

            local line = originlist:AddLine( data.notagprettyname )
            line:SetSortValue( 1, name )

            function line:OnSelect()
                for _, v in ipairs( weplinelist ) do
                    if v != line then v:SetSelected( false ) end
                end
            end
            
            weplinelist[ #weplinelist + 1 ] = line
        end

        if #originlist:GetLines() == 0 then
            originlist:Remove()
            continue
        end

        originlist:SortByColumn( 1 )
        weplistlist[ #weplistlist + 1 ] = originlist
    end

    if #weplistlist > 0 then
        function mainframe:OnSizeChanged( width )
            local columnWidth = max( 200, ( width - 10 ) / #weplistlist )
            for _, list in ipairs( weplistlist ) do
                list:SetWidth( columnWidth )
            end
        end

        mainframe:OnSizeChanged( mainframe:GetWide() )
    else
        LAMBDAPANELS:CreateLabel( "You currenly have every weapon restricted and disallowed to be used by Lambda Players!", mainframe, TOP )
    end

    LAMBDAPANELS:CreateButton( mainframe, BOTTOM, "Select None", function()
        net.Start( "lambdamws_selectspawnweapon" )
        net.WriteString( "none" )
        net.SendToServer()
        AddNotification( "Selected none as a spawn weapon!", NOTIFY_GENERIC, 3 )
        PlaySound( "buttons/button15.wav" )
        mainframe:Close()
    end )

    LAMBDAPANELS:CreateButton( mainframe, BOTTOM, "Select Random", function()
        net.Start( "lambdamws_selectspawnweapon" )
        net.WriteString( "random" )
        net.SendToServer()
        AddNotification( "Selected random as a spawn weapon!", NOTIFY_GENERIC, 3 )
        PlaySound( "buttons/button15.wav" )
        mainframe:Close()
    end )
end

CreateLambdaConsoleCommand( "lambdaplayers_mws_openspawnweaponpanel", OpenSpawnWeaponPanel, true, "Opens a panel that allows you to select the weapon the next MWS spawned Lambda Player will start with", { name = "Select Spawn Weapon", category = "MWS" } )






if ( CLIENT ) then return end

local CurTime = CurTime
local ipairs = ipairs
local RandomPairs = RandomPairs
local table_remove = table.remove
local IsValid = IsValid
local player_GetAll = player.GetAll
local ents_Create = ents.Create
local GetAllNavAreas = navmesh.GetAllNavAreas
local IsNavmeshLoaded = navmesh.IsLoaded

local SpawnedLambdaPlayers = {}
local shutdown = false
local pause = false
local failtimes = 0
local nextspawn = 0

-- Returns a random spawn point on the navmesh
local function GetRandomSpawnPoint()
    local plys
    local distLimit = navmeshspawndist:GetFloat()
    if distLimit > 0 then        
        plys = player_GetAll()
        distLimit = ( distLimit * distLimit )
    end

    local allAreas = GetAllNavAreas()
    local areaCount = #allAreas
    for index, area in RandomPairs( allAreas ) do
        if !IsValid( area ) or area:IsUnderwater() or area:GetSizeX() <= 50 or area:GetSizeY() <= 50 then continue end
        if plys and index != areaCount then
            local outofreach = true
            for _, ply in ipairs( plys ) do
                if !IsValid( ply ) then continue end
                local plyPos = ply:GetPos()
                if plyPos:DistToSqr( area:GetClosestPointOnArea( plyPos ) ) > distLimit then continue end
                outofreach = false; break
            end
            if outofreach then continue end
        end
        return area:GetRandomPoint()
    end
end

hook.Add( "Tick", "lambdaplayers_MWS", function()
    if shutdown then return end
    
    local curTime = CurTime()
    if curTime < 5 then return end

    local rndSpawnRate = randomspawnrate:GetBool()
    local spawnRate = spawnrate:GetFloat()

    -- Remove all spawned Lambdas and remain dormant
    if !enabled:GetBool() then
        if #SpawnedLambdaPlayers > 0 then
            for k, lambda in ipairs( SpawnedLambdaPlayers ) do
                if !IsValid( lambda ) then continue end
                lambda:Remove() 
                table_remove( SpawnedLambdaPlayers, k ) 
            end
        end

        nextspawn = ( curTime + ( rndSpawnRate and rand( 0.1, spawnRate ) or spawnRate ) )
        return
    end

    if pause then return end
    local useNavmesh = navmeshspawning:GetBool()
    if useNavmesh and ( failtimes > 100 or !IsNavmeshLoaded() ) then return end

    if curTime > nextspawn then 
        if #SpawnedLambdaPlayers < maxlambdacount:GetInt() then
            local pos, ang

            -- Spawning at player spawn points
            if !useNavmesh then
                local spawns = LambdaGetPossibleSpawns()

                local point = spawns[ random( #spawns ) ]
                if !IsValid( point ) then failtimes = failtimes + 1; return end

                pos = point:GetPos()
                ang = point:GetAngles()
            else
                pos = GetRandomSpawnPoint()
                ang = Angle( 0, random( -180, 180 ), 0 )
            end

            local lambda = ents_Create( "npc_lambdaplayer" )
            lambda:SetPos( pos )
            lambda:SetAngles( ang )
            lambda.l_MWSspawned = true
            lambda:Spawn()
            lambda:SetRespawn( respawn:GetBool() )
            lambda.l_SpawnWeapon = spawnWep:GetString() 
            lambda:SwitchToSpawnWeapon()

            table_insert( SpawnedLambdaPlayers, 1, lambda )

            local personality = perspreset:GetString()
            if personality != "random" then lambda:BuildPersonalityTable( personalitypresets[ personality ]( lambda ) ) end

            nextspawn = curTime + ( rndSpawnRate and rand( 0.1, spawnRate ) or spawnRate )
        end
    elseif #SpawnedLambdaPlayers > maxlambdacount:GetInt() then
        local lambda = SpawnedLambdaPlayers[ #SpawnedLambdaPlayers ]
        if IsValid( lambda ) then lambda:Remove(); table_remove( SpawnedLambdaPlayers, #SpawnedLambdaPlayers ) end
    end
end )

-- These hooks will prevent MWS from over shooting its limits
hook.Add( "LambdaPreRecreated", "lambdaplayers_MWS_prerecreation", function( self )
    if self.l_MWSspawned then 
        self:SetExternalVar( "l_mwsprerecreation", true ) 
        pause = true 
        timer.Simple( 1, function() pause = false end ) 
    end
end ) 

hook.Add( "LambdaPostRecreated", "lambdaplayers_MWS_postrecreation", function( self )
    timer.Simple( 0.2, function()
        if IsValid( self ) and self:GetExternalVar( "l_mwsprerecreation" ) then
            self.l_MWSspawned = true
            table_insert( SpawnedLambdaPlayers, 1, self )
            pause = false
        end
    end )
end )
--

-- Remove self from the MWS table
hook.Add( "LambdaOnRemove", "lambdaplayers_MWS_OnRemove", function( self )
    for k, v in ipairs( SpawnedLambdaPlayers ) do
        if v == self then table_remove( SpawnedLambdaPlayers, k ) break end
    end
end )

hook.Add( "LambdaOnRespawn", "lambdaplayers_MWS_OnRespawn", function( self )
    if !self.l_MWSspawned or !navmeshspawning:GetBool() or !IsNavmeshLoaded() then return end

    local pos = GetRandomSpawnPoint()
    self:SetPos( pos )
    self.l_SpawnPos = pos
    
    local ang = Angle( 0, random( -180, 180 ), 0 )
    self:SetAngles( ang )
    self.l_SpawnAngles = ang
end )