local table_insert = table.insert
local random = math.random
local RandomPairs = RandomPairs

LambdaPersonalities = {}
LambdaPersonalityConVars = {}
-- Creates a "Personality" type for the specific function. Every Personality gets created with a chance that will be tested with every other chances ordered from highest to lowest
-- Personalities are called when a Lambda Player is idle and wants to test a chance

local presettbl = {
    [ "Random" ] = "random",
    [ "Builder" ] = "builder",
    [ "Fighter" ] = "fighter",
    [ "Custom" ] = "custom",
    [ "Custom Random" ] = "customrandom"
}

CreateLambdaConvar( "lambdaplayers_personality_preset", "random", true, true, true, "The preset Lambda Personalities should use. Set this to Custom to make use of the chance sliders", nil, nil, { type = "Combo", options = presettbl, name = "Personality Preset", category = "Lambda Player Settings" } )

function LambdaCreatePersonalityType( personalityname, func )
    local convar = CreateLambdaConvar( "lambdaplayers_personality_" .. personalityname .. "chance", 30, true, true, true, "The chance " .. personalityname .. " will be executed. Personality Preset should be set to Custom for this slider to effect newly spawned Lambda Players!", 0, 100, { type = "Slider", decimals = 0, name = personalityname .. " Chance", category = "Lambda Player Settings" } )
    table_insert( LambdaPersonalities, { personalityname, func } )
    table_insert( LambdaPersonalityConVars, { personalityname, convar } )
end


local function Chance_Build( self )
    self:PreventWeaponSwitch( true )

    for index, buildtable in RandomPairs( LambdaBuildingFunctions ) do
        if !buildtable[ 2 ]:GetBool() then continue end
        if LambdaRunHook( "LambdaOnUseBuildFunction", self, buildtable[ 1 ] ) == true then return end
        local result 

        local ok, msg = pcall( function() result = buildtable[ 3 ]( self ) end )

        if !ok and buildtable[ 1 ] != "entity" and buildtable[ 1 ] != "npc" then ErrorNoHaltWithStack( buildtable[ 1 ] .. " Building function had a error! If this is from a addon, report it to the author!", msg ) end
        if result then self:DebugPrint( "Used a building function: " .. buildtable[ 1 ] ) break end
    end

    self:PreventWeaponSwitch( false )
end



local function Chance_Tool( self )
    self:SwitchWeapon( "toolgun" )
    if self.l_Weapon != "toolgun" then return end

    self:PreventWeaponSwitch( true )

    local find = self:FindInSphere( nil, 400, function( ent ) if self:HasVPhysics( ent ) and self:CanSee( ent ) and self:HasPermissionToEdit( ent ) then return true end end )
    local target = find[ random( #find ) ]

    -- Loops through random tools and only stops if a tool tells us it actually got used by returning true 
    
    for index, tooltable in RandomPairs( LambdaToolGunTools ) do
        if !tooltable[ 2 ]:GetBool() then continue end -- If the tool is allowed
        if LambdaRunHook( "LambdaOnToolUse", self, tooltable[ 1 ] ) == true then return end
        local result
        
        local ok, msg = pcall( function() result = tooltable[ 3 ]( self, target ) end )

        if !ok then ErrorNoHaltWithStack( tooltable[ 1 ] .. " Tool had a error! If this is from a addon, report it to the author!", msg ) end
        if result then self:DebugPrint( "Used " .. tooltable[ 1 ] .. " Tool" ) break end
    end


    self:PreventWeaponSwitch( false )
end

local spawnEntities
local spawnMedkits = GetConVar( "lambdaplayers_combat_spawnmedkits" )
local spawnBatteries = GetConVar( "lambdaplayers_combat_spawnbatteries" )
local function Chance_Combat( self )     
    spawnEntities = spawnEntities or GetConVar( "lambdaplayers_building_allowentity" )
    local allowEntities = spawnEntities:GetBool()
    
    local rndCombat = random( 1, 4 )
    if rndCombat == 1 and allowEntities and spawnBatteries:GetBool() and self:Armor() < self:GetMaxArmor() then
        self:SetState( "ArmorUp" )
    elseif rndCombat == 2 and allowEntities and spawnMedkits:GetBool() and self:Health() < self:GetMaxHealth() then
        self:SetState( "HealUp" )
    else
        self:SetState( "FindTarget" )
    end
end

local ignorePlys = GetConVar( "ai_ignoreplayers" )
local function Chance_Friendly( self )
    if self:InCombat() or !self:CanEquipWeapon( "gmod_medkit" ) then return end

    local nearbyEnts = self:FindInSphere( nil, 1000, function( ent )
        if !LambdaIsValid( ent ) or !ent.Health or !ent:IsNPC() and !ent:IsNextBot() and ( !ent:IsPlayer() or !ent:Alive() or ignorePlys:GetBool() ) then return false end
        return ( ent:Health() < ent:GetMaxHealth() and self:CanSee( ent ) )
    end )
    
    if #nearbyEnts > 0 then
        self.l_HealTarget = nearbyEnts[ random( #nearbyEnts ) ]
        self:SetState( "HealSomeone" )
    end
end

CreateLambdaConsoleCommand( "lambdaplayers_cmd_opencustompersonalitypresetpanel", function( ply ) 
    local tbl = {}
    tbl[ "lambdaplayers_personality_voicechance" ] = 30
    tbl[ "lambdaplayers_personality_textchance" ] = 30
    for k, v in ipairs( LambdaPersonalityConVars ) do
        tbl[ v[ 2 ]:GetName() ] = v[ 2 ]:GetDefault()
    end
    LAMBDAPANELS:CreateCVarPresetPanel( "Custom Personality Preset Editor", tbl, "custompersonalities", true )
end, true, "Opens a panel to allow you to create custom preset personalities and load them", { name = "Custom Personality Presets", category = "Lambda Player Settings" } )


LambdaCreatePersonalityType( "Build", Chance_Build )
LambdaCreatePersonalityType( "Tool", Chance_Tool )
LambdaCreatePersonalityType( "Combat", Chance_Combat )
LambdaCreatePersonalityType( "Friendly", Chance_Friendly )
CreateLambdaConvar( "lambdaplayers_personality_voicechance", 30, true, true, true, "The chance Voice will be executed. Personality Preset should be set to Custom for this slider to effect newly spawned Lambda Players!", 0, 100, { type = "Slider", decimals = 0, name = "Voice Chance", category = "Lambda Player Settings" } )
CreateLambdaConvar( "lambdaplayers_personality_textchance", 30, true, true, true, "The chance Text will be executed. Personality Preset should be set to Custom for this slider to effect newly spawned Lambda Players!", 0, 100, { type = "Slider", decimals = 0, name = "Text Chance", category = "Lambda Player Settings" } )

