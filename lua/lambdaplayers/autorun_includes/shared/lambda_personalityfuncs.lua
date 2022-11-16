local table_insert = table.insert
local random = math.random
local RandomPairs = RandomPairs

LambdaPersonalities = {}

-- Creates a "Personality" type for the specific function. Every Personality gets created with a chance that will be tested with every other chances ordered from highest to lowest
-- Personalities are called when a Lambda Player is idle and wants to test a chance

-- Later, I will make convars and whatever to allow override of certain personality chances or so. Not sure what that will look like just yet
function LambdaCreatePersonalityType( personalityname, func )
    table_insert( LambdaPersonalities, { personalityname, func } )
end



local function Chance_Build( self )
    self:PreventWeaponSwitch( true )

    for index, buildtable in RandomPairs( self.l_BuildingFunctions ) do
        if !buildtable[ 2 ]:GetBool() then continue end
        local result 

        local ok, msg = pcall( function() result = buildtable[ 3 ]( self ) end )

        if !ok then if buildtable[ 1 ] != "entity" and buildtable[ 1 ] != "npc" then ErrorNoHaltWithStack( buildtable[ 1 ] .. " Building function had a error! If this is from a addon, report it to the author!", msg ) end end
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
    
    for index, tooltable in RandomPairs( self.l_ToolgunTools ) do
        if !tooltable[ 2 ]:GetBool() then continue end -- If the tool is allowed
        local result
        
        local ok, msg = pcall( function() result = tooltable[ 3 ]( self, target ) end )

        if !ok then ErrorNoHaltWithStack( tooltable[ 1 ] .. " Tool had a error! If this is from a addon, report it to the author!", msg ) end
        if result then self:DebugPrint( "Used " .. tooltable[ 1 ] .. " Tool" ) break end
    end


    self:PreventWeaponSwitch( false )
end


local function Chance_Combat( self ) 
    self:SetState( "FindTarget" )
end

LambdaCreatePersonalityType( "Build", Chance_Build )
LambdaCreatePersonalityType( "Tool", Chance_Tool )
LambdaCreatePersonalityType( "Combat", Chance_Combat )


-- Called when all default personality types are loaded
-- This hook can be used to create custom personality types using LambdaCreatePersonalityType()
hook.Run( "LambdaOnPersonalitiesLoaded" )