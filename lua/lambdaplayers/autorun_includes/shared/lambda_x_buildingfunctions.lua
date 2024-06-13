local IsValid = IsValid
local table_insert = table.insert
local VectorRand = VectorRand
local coroutine = coroutine
local Trace = util.TraceLine

LambdaBuildingFunctions = {}

-- This system is pretty much the same exact as the toolgun system
-- Adds a function to the list of building functions Lambda Players can use
-- These functions will be under the Build Chance

-- This function has its args different from the toolgun system since that could be many things that could be considered building. So the developer needs to ability to customize the setting name and description
function AddBuildFunctionToLambdaBuildingFunctions( spawnname, settingname, desc, func )
    local convar = CreateLambdaConvar( "lambdaplayers_building_allow" .. spawnname, 1, true, false, false, desc, 0, 1, { type = "Bool", name = settingname, category = "Building" } )
    table_insert( LambdaBuildingFunctions, { spawnname, convar, func } )
end


local function SpawnAProp( self )
    if !self:IsUnderLimit( "Prop" ) then return end

    for i=1, LambdaRNG( 4 ) do
        if !self:IsUnderLimit( "Prop" ) then return end

        self:LookTo( self:GetPos() + VectorRand( -100, 100 ), 2 )
        coroutine.wait( LambdaRNG( 0.2, 1, true ) )

        self:SpawnProp()

        coroutine.wait( LambdaRNG( 0.2, 1, true ) )

    end

    return true -- Just like for toolguns, we return true to let the for loop know we completed what we wanted to do and it can break
end

-- Spawns a prop and picks it up the Physgun if we can use the physgun
local function SpawnAPropandPickUp( self )
    if !self:IsUnderLimit( "Prop" ) or !self:CanEquipWeapon( "physgun" ) then return end
    self:PreventWeaponSwitch( false )

    self:SwitchWeapon( "physgun" )

    self:LookTo( self:GetPos() + VectorRand( -100, 100 ), 2 )
    coroutine.wait( LambdaRNG( 0.2, 1, true ) )

    local prop = self:SpawnProp()
    self:LookTo( prop, 2 )
    coroutine.wait( LambdaRNG( 0.2, 1, true ) )

    self:UseWeapon( prop )

    return true
end


local function SpawnNPC( self )
    if !self:IsUnderLimit( "NPC" ) then return end
    
    self:LookTo( self:WorldSpaceCenter() + VectorRand( -200, 200 ), 2 )

    local npc = self:SpawnNPC()
    if !IsValid( npc ) then return end

    coroutine.wait( LambdaRNG( 0.2, 1, true ) )

    return true
end


local function SpawnEntity( self )
    if !self:IsUnderLimit( "Entity" ) then return end
    
    self:LookTo( self:WorldSpaceCenter() + VectorRand( -200, 200 ), 2 )

    coroutine.wait( LambdaRNG( 0.2, 1, true ) )

    local entity = self:SpawnEntity()
    if !IsValid( entity ) then return end

    coroutine.wait( LambdaRNG( 0.2, 1, true ) )

    return true
end

local spraytbl = { collisiongroup = COLLISION_GROUP_WORLD }
local function Spray( self )
    if #LambdaPlayerSprays == 0 or CurTime() <= self.l_NextSprayUseTime then return end
    self.l_NextSprayUseTime = ( CurTime() + 10 )

    local targetpos = self:WorldSpaceCenter() + VectorRand( -200, 200 )
    self:LookTo( targetpos, 1 )
    coroutine.wait( LambdaRNG( 0.2, 0.6, true ) )

    spraytbl.start = self:WorldSpaceCenter()
    spraytbl.endpos = targetpos
    spraytbl.filter = self

    local trace = Trace( spraytbl )
    if !trace.Hit then return end

    LambdaPlayers_Spray( LambdaPlayerSprays[ LambdaRNG( #LambdaPlayerSprays ) ], trace.HitPos, trace.HitNormal )
    self:EmitSound( "player/sprayer.wav", 65 )

    coroutine.wait( LambdaRNG( 0.2, 0.6, true ) )
    return true
end

-- Makes the Lambda create a doodad.
-- Similar in function to the Zeta's "Build onto props" feature.
local function CreateDoohickey( self )
    if !self:IsUnderLimit( "Prop" ) or !self:CanEquipWeapon( "physgun" ) or !self:CanEquipWeapon( "toolgun" ) or !GetConVar( "lambdaplayers_building_allowprop" ):GetBool() then return end
    
    local unfrozen = LambdaRNG( 1, 2 ) == 1 -- Whether the props should be unfrozen

    -- Find a target
    self:PreventWeaponSwitch( false )
    self:SwitchWeapon( "physgun" )
    self:PreventWeaponSwitch( true )
    local find = self:FindInSphere( nil, 400, function( ent ) if self:HasVPhysics( ent ) and self:CanSee( ent ) and self:HasPermissionToEdit( ent ) then return true end end )
    local target = find[ LambdaRNG( #find ) ]

    if !IsValid( target ) and self:IsUnderLimit( "Prop" ) then 
        self:LookTo( self:GetPos() + Vector( LambdaRNG( -100, 100 ), LambdaRNG( -100, 100 ), LambdaRNG( -30, 30 ) ), 2 )
        coroutine.wait( LambdaRNG( 0.2, 1, true ) )

        target = self:SpawnProp()

        target:GetPhysicsObject():EnableMotion( unfrozen )
    elseif !self:IsUnderLimit( "Prop" ) then 
        return 
    end

    coroutine.wait( 1 )

    -- Place and weld 1-10 props on the target
    for i = 1, LambdaRNG( 1, 10 ) do
        if !IsValid( target ) then continue end

        -- Walk around the target sometimes to get better angles
        if LambdaRNG( 1, 2 ) == 1 then
            local radius = target:GetModelRadius()
            self:MoveToPos( target:GetPos() + Vector( LambdaRNG( -100 - radius, 100 + radius), LambdaRNG( -100 - radius, 100 + radius ), 0 ) )
        end

        self:PreventWeaponSwitch( false )
        self:SwitchWeapon( "physgun" )
        self:PreventWeaponSwitch( true )

        self:LookTo( self:GetPos() + Vector( LambdaRNG( -200, 200 ), LambdaRNG( -200, 200 ), LambdaRNG( -30, 30 ) ), 2 )
        coroutine.wait( LambdaRNG( 0.2, 1, true ) )

        local prop = self:SpawnProp()

        coroutine.wait( 1 )
        if !IsValid( prop ) or !IsValid( target ) then continue end
        
        self:UseWeapon( prop )

        coroutine.wait( 0.2 )
        if !IsValid( prop ) or !IsValid( target ) then continue end
        local look = true

        -- Keep the prop on the target for a little while
        self.l_physholdang = AngleRand( -360, 360 )
        LambdaCreateThread( function()
            while look do 
                if !LambdaIsValid( self ) then return end
                if !IsValid( target ) then
                    self.l_physholdpos = nil
                    self.l_physholdang = nil
                    return
                end
                local pos = util.TraceLine( { start = self:EyePos(), endpos = target:GetPos(), filter = self } ).HitPos
                self:LookTo( pos, 2 )
                self.l_physholdpos = pos
                coroutine.yield()
            end
        end )

        coroutine.wait( 1 )
        if !IsValid( prop ) or !IsValid( target ) then continue end
        look = false
        self.l_physholdpos = nil
        self.l_physholdang = nil

        self:UseWeapon()
        prop:GetPhysicsObject():EnableMotion( false )

        coroutine.wait( 0.5 )
        if !IsValid( prop ) or !IsValid( target ) then continue end

        self:PreventWeaponSwitch( false )
        self:SwitchWeapon( "toolgun" )
        self:PreventWeaponSwitch( true )
        
        self:LookTo( prop, 2 )

        coroutine.wait( LambdaRNG( 0.5, 1, true ) )
        if !IsValid( prop ) or !IsValid( target ) then continue end

        self:UseWeapon( prop )
        self:LookTo( target, 2 )

        coroutine.wait( LambdaRNG( 0.5, 1, true ) )
        if !IsValid( prop ) or !IsValid( target ) then continue end
        
        self:UseWeapon( target )

        constraint.Weld( target, prop, 0, 0, 0, true )
        prop:GetPhysicsObject():EnableMotion( unfrozen )

        coroutine.wait( 0.5 )
        if !IsValid( prop ) or !IsValid( target ) then continue end

        -- Sometimes use random toolgun tools on the props
        if LambdaRNG( 1, 2 ) == 1 then
            for i = 1, LambdaRNG( 1, 4 ) do
                self:UseRandomToolOn( LambdaRNG( 1, 2 ) == 1 and target or prop )
            end
        end

    end
    
    self:PreventWeaponSwitch( false )
    self.l_physholdpos = nil
    self.l_physholdang = nil
    return true
end

AddBuildFunctionToLambdaBuildingFunctions( "doohickey", "Allow Building onto Props", "If Lambda Players are allowed to add and weld props onto existing props. Or in other words, create doohickeys.\n\nRequires Allow Prop Spawning to be on and Lambdas should be allowed to have the Physgun and the Toolgun!", CreateDoohickey )
AddBuildFunctionToLambdaBuildingFunctions( "prop", "Allow Prop Spawning", "If Lambda Players are allowed to spawn props", SpawnAProp )
AddBuildFunctionToLambdaBuildingFunctions( "npc", "Allow NPC Spawning", "If Lambda Players are allowed to spawn NPCs", SpawnNPC )
AddBuildFunctionToLambdaBuildingFunctions( "entity", "Allow Entity Spawning", "If Lambda Players are allowed to spawn Entities", SpawnEntity )
AddBuildFunctionToLambdaBuildingFunctions( "spray", "Allow Sprays", "If Lambda Players are allowed to place Sprays", Spray )
table_insert( LambdaBuildingFunctions, { "prop", GetConVar( "lambdaplayers_building_allowprop" ), SpawnAPropandPickUp } ) -- Pretty much made this be connected to the prop spawning option
