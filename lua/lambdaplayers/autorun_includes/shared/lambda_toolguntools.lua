local table_insert = table.insert
local random = math.random
local rand = math.Rand
local ColorRand = ColorRand
local VectorRand = VectorRand
local IsValid = IsValid
local ents_Create = ents.Create
local util_Effect = util.Effect
local tobool = tobool
local timer = timer 
local util = util
local Clamp = math.Clamp
local zeroangle = Angle()

LambdaToolGunTools = {}

-- Adds a tool function to the list of tools
-- See the functions below for examples on making tools
function AddToolFunctionToLambdaTools( toolname, func )
    local convar = CreateLambdaConvar( "lambdaplayers_tool_allow" .. toolname, 1, true, false, false, "If lambda players can use the " .. toolname .. " tool", 0, 1, { type = "Bool", name = "Allow " .. toolname .. " Tool", category = "Limits and Tool Permissions" } )
    table_insert( LambdaToolGunTools, { toolname, convar, func } )
end


-- Helper function for gmod entities 

local function CreateGmodEntity( classname, model, pos, ang, lambda )

    local ent = ents_Create( classname )
    ent:SetPos( pos )
    ent:SetAngles( ang or zeroangle )
    ent:SetModel( model or "" )
    LambdaHijackGmodEntity( ent, lambda ) -- Make it support the lambda
    ent:Spawn()
    ent:Activate()
    DoPropSpawnedEffect( ent )

    return ent
end

local function UseColorTool( self, target )
    if !IsValid( target ) then return end -- Returning nothing is basically the same as returning false

    self:LookTo( target, 2 )

    coroutine.wait( 1 )
    if !IsValid( target ) then return end -- Because we wait 1 second we must make sure the target is valid

    self:UseWeapon( target:WorldSpaceCenter() ) -- Use the toolgun on the target to fake using a tool
    target:SetColor( ColorRand( false ) )

    return true -- Return true to let the for loop in Chance_Tool know we actually got to use the tool so it can break. All tools must do this
end
AddToolFunctionToLambdaTools( "Color", UseColorTool )

local function UseMaterialTool( self, target )
    if !IsValid( target ) then return end

    self:LookTo( target, 2 )

    coroutine.wait( 1 )
    if !IsValid( target ) then return end

    self:UseWeapon( target:WorldSpaceCenter() )
    target:SetMaterial( LambdaPlayerMaterials[ random( #LambdaPlayerMaterials ) ] )

    return true
end
AddToolFunctionToLambdaTools( "Material", UseMaterialTool )

local function UseLightTool( self, target )
    if !self:IsUnderLimit( "Light" ) then return end -- Can't create any more lights

    local trace = self:Trace( self:WorldSpaceCenter() + VectorRand( -12600, 12600 ) )
    local pos = trace.HitPos
    
    self:LookTo( pos, 2 )

    coroutine.wait( 1 )

    self:UseWeapon( pos )
    local ent = CreateGmodEntity( "gmod_light", nil, pos, nil, self ) -- Create the light
    ent.LambdaOwner = self
    ent.IsLambdaSpawned = true
    self:ContributeEntToLimit( ent, "Light" )
    table_insert( self.l_SpawnedEntities, 1, ent )

    if random( 1, 2 ) == 1 then
        local LPos1 = Vector( 0, 0, 6.5 )
        local LPos2 = trace.Entity:WorldToLocal( trace.HitPos )

        if IsValid( trace.Entity ) then

            local phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
            if IsValid( phys ) then
                LPos2 = phys:WorldToLocal( trace.HitPos )
            end

        end

        local constr, rope = constraint.Rope( ent, trace.Entity, 0, trace.PhysicsBone, LPos1, LPos2, 0, random( 256 ), 0, 1, "cable/rope" )
        table_insert( self.l_SpawnedEntities, 1, rope )
    end

    -- Aaannd configure it
    ent:SetPlayer( self ) -- We can safely set this to ourselves since it was "hijacked"
    ent:SetOn( true )
    ent:SetColor( ColorRand( false ) )
    ent:SetBrightness( rand( 1, 6 ) )
    ent:SetLightSize( rand( 100, 1024 ) )

    return true
end
AddToolFunctionToLambdaTools( "Light", UseLightTool )

local dynamitemodels = { "models/dav0r/tnt/tnt.mdl", "models/dav0r/tnt/tnttimed.mdl", "models/dynamite/dynamite.mdl" }

local function UseDynamiteTool( self, target )
    if !self:IsUnderLimit( "Dynamite" ) then return end

    local trace = self:Trace( self:WorldSpaceCenter() + VectorRand( -12600, 12600 ) )
    local pos = trace.HitPos + trace.HitNormal * 10
    
    self:LookTo( pos, 2 )

    coroutine.wait( 1 )

    self:UseWeapon( pos )
    local ent = CreateGmodEntity( "gmod_dynamite", dynamitemodels[ random( #dynamitemodels ) ], pos, nil, self )
    ent.LambdaOwner = self
    ent.IsLambdaSpawned = true
    self:ContributeEntToLimit( ent, "Dynamite" )
    table_insert( self.l_SpawnedEntities, 1, ent )

    ent:SetPlayer( self )
    ent:SetDamage( random( 1, 500 ) )
    ent:SetShouldRemove( tobool( random( 0, 1 ) ) )
    ent:SetDelay( random( 0, 60 ) )
    
    function ent:Explode( delay, ply ) -- Override the old Explode function with our own. Although we don't change much we just make the explosion repeat it self if it isn't set for removal

        if ( !IsValid( self ) ) then return end

        if ( !IsValid( ply ) ) then ply = self end
    
        local _delay = delay or self:GetDelay()
    
        if ( _delay == 0 ) then
    
            local radius = 300
    
            util.BlastDamage( self, ply, self:GetPos(), radius, Clamp( self:GetDamage(), 0, 1500 ) )
    
            local effectdata = EffectData()
            effectdata:SetOrigin( self:GetPos() )
            util.Effect( "Explosion", effectdata, true, true )
    
            if ( self:GetShouldRemove() ) then self:Remove() return end
            if ( self:GetMaxHealth() > 0 && self:Health() <= 0 ) then self:SetHealth( self:GetMaxHealth() ) end
            self:Explode( self:GetDelay(), ply )
        else
    
            timer.Simple( _delay, function() if ( !IsValid( self ) ) then return end self:Explode( 0, ply ) end )
    
        end
    end

    ent:Explode( ent:GetDelay(), self )

    return true
end
AddToolFunctionToLambdaTools( "Dynamite", UseDynamiteTool )

local function UseRemoverTool( self, target )
    if !IsValid( target ) then return end -- Returning nothing is basically the same as returning false

    self:LookTo( target, 2 )

    coroutine.wait( 1 )
    if !IsValid( target ) then return end -- Because we wait 1 second we must make sure the target is valid

    self:UseWeapon( target:WorldSpaceCenter() ) -- Use the toolgun on the target to fake using a tool
    
    constraint.RemoveAll( target ) -- Removes all constraints

    timer.Simple( 1, function() if ( IsValid( target ) ) then target:Remove() end end ) -- Actually remove the entity after a second

    target:SetNotSolid( true ) -- Make it not solid and invisible to pretend it's deleted for those 1 seconds
    target:SetMoveType( MOVETYPE_NONE )
    target:SetNoDraw( true )

    local effect = EffectData()
        effect:SetOrigin( target:GetPos() )
        effect:SetEntity( target )
    util_Effect( "entity_remove", effect, true, true ) -- Play the remove effect

    return true -- Return true to let the for loop in Chance_Tool know we actually got to use the tool so it can break. All tools must do this
end
AddToolFunctionToLambdaTools( "Remover", UseRemoverTool )

local balloonnames = { "normal", "normal_skin1", "normal_skin2", "normal_skin3", "gman", "mossman", "dog", "heart", "star" }

local function UseBalloonTool( self, target )
    if !self:IsUnderLimit( "Balloon" ) then return end -- Can't create any more balloons

    local trace = self:Trace( self:WorldSpaceCenter() + VectorRand( -12600, 12600 ) )
    local pos = trace.HitPos
    local randBalloon = balloonnames[ random( #balloonnames ) ]
    local balloonModel = list.Get( "BalloonModels" )[randBalloon] -- Directly get model from Sandbox. Needed since some have skins.

    self:LookTo( pos, 2 )

    coroutine.wait( 1 )

    self:UseWeapon( pos )
    local ent = CreateGmodEntity( "gmod_balloon", balloonModel.model, pos, nil, self ) -- Create the balloon
    ent.LambdaOwner = self
    ent.IsLambdaSpawned = true
    self:ContributeEntToLimit( ent, "Balloon" )
    table_insert( self.l_SpawnedEntities, 1, ent )

    local LPos1 = Vector( 0, 0, 6.5 )
    local LPos2 = trace.Entity:WorldToLocal( trace.HitPos )

    if IsValid( trace.Entity ) then

        local phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
        if IsValid( phys ) then
            LPos2 = phys:WorldToLocal( trace.HitPos )
        end

    end

    local constr, rope = constraint.Rope( ent, trace.Entity, 0, trace.PhysicsBone, LPos1, LPos2, 0, random( 5, 1000 ), 0, 0.5, "cable/rope" )
    table_insert( self.l_SpawnedEntities, 1, rope )

    -- Configure it
    ent:SetPlayer( self ) -- We can safely set this to ourselves since it was "hijacked"
    ent:SetColor( ColorRand( true ) )
    if ( balloonModel.skin ) then ent:SetSkin( balloonModel.skin ) end
    if ( balloonModel.nocolor ) then ent:SetColor( Color(255, 255, 255, 255) ) else ent:SetColor( ColorRand( ) ) end
    ent:SetForce( random( 50, 2000 ) ) -- While players can use negative force for balloons it kinda looks less fun

    return true -- Return true to let the for loop in Chance_Tool know we actually got to use the tool so it can break. All tools must do this
end
AddToolFunctionToLambdaTools( "Balloon", UseBalloonTool )

local trailMats = { "trails/plasma", "trails/tube", "trails/electric", "trails/smoke", "trails/laser", "trails/love", "trails/physbeam", "trails/lol" }

local function UseTrailTool( self, target )
    if !IsValid( target ) then return end

    self:LookTo( target, 2 )

    coroutine.wait( 1 )
    if !IsValid( target ) then return end

    self:UseWeapon( target:WorldSpaceCenter() )
    if ( IsValid( target.SToolTrail ) ) then -- If target already has trail, remove old one
		target.SToolTrail:Remove()
		target.SToolTrail = nil
	end

    local trailStartSize, trailEndSize = random(128), random(128)

    local trail_entity = util.SpriteTrail( target, 0, ColorRand(), false, trailStartSize, trailEndSize, random(10), 1 / ( ( trailStartSize + trailEndSize ) * 0.5 ), trailMats[ random( #trailMats ) ] .. ".vmt" )
    target.SToolTrail = trail_entity

    return true
end
AddToolFunctionToLambdaTools( "Trail", UseTrailTool )

-- Called when all default tools are loaded
-- This hook can be used to add custom tool functions by using AddToolFunctionToLambdaTools()
hook.Run( "LambdaOnToolsLoaded" )