local table_insert = table.insert
local random = math.random
local rand = math.Rand
local RandomPairs = RandomPairs
local ColorRand = ColorRand
local VectorRand = VectorRand
local IsValid = IsValid
local Round = math.Round
local ents_Create = ents.Create
local util_Effect = util.Effect
local tobool = tobool
local table_GetKeys = table.GetKeys
local timer = timer 
local util = util
local coroutine = coroutine
local constraint = constraint
local Clamp = math.Clamp
local zeroangle = Angle()

local function IsNil( any )
    return any == nil or any == NULL
end


LambdaToolGunTools = {}

-- Adds a tool function to the list of tools
-- These functions will be under the Tool Chance
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

    local trace = self:Trace( self:WorldSpaceCenter() + VectorRand( -126000, 126000 ) )
    local pos = trace.HitPos
    
    self:LookTo( pos, 2 )

    coroutine.wait( 1 )

    if IsValid( trace.Entity ) and ( trace.Entity:GetClass()=="gmod_light" or trace.Entity:IsNextBot() or trace.Entity:IsNPC() or trace.Entity:IsPlayer() )  then return end -- Check to avoid placing light on things they shouldn't be on

    self:UseWeapon( pos )
    local ent = CreateGmodEntity( "gmod_light", nil, pos + trace.HitNormal * 8, trace.HitNormal:Angle() - Angle( 90, 0, 0 ), self ) -- Create the light
    ent.LambdaOwner = self
    ent.IsLambdaSpawned = true
    self:ContributeEntToLimit( ent, "Light" )
    table_insert( self.l_SpawnedEntities, 1, ent )

    if random( 1, 2 ) == 1 then
        local traceent = trace.Entity

        local LPos1 = Vector( 0, 0, 6.5 )
        local LPos2 = !IsNil( traceent ) and traceent:WorldToLocal( trace.HitPos ) or trace.HitPos

        traceent = !IsNil( traceent ) and traceent or Entity( 0 ) -- world

        if IsValid( traceent ) then

            local phys = traceent:GetPhysicsObjectNum( trace.PhysicsBone )
            if IsValid( phys ) then
                LPos2 = phys:WorldToLocal( trace.HitPos )
            end

        end

        local constr, rope = constraint.Rope( ent, traceent, 0, trace.PhysicsBone, LPos1, LPos2, 0, random( 256 ), 0, 1, "cable/rope" )
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
    ent:SetDelay( random( 1, 60 ) )
    
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
    if !IsValid( target ) then return end

    self:LookTo( target, 2 )

    coroutine.wait( 1 )
    if !IsValid( target ) then return end

    self:UseWeapon( target:WorldSpaceCenter() )
    
    constraint.RemoveAll( target ) -- Removes all constraints

    timer.Simple( 1, function() if ( IsValid( target ) ) then target:Remove() end end ) -- Actually remove the entity after a second

    target:SetNotSolid( true ) -- Make it not solid and invisible to pretend it's deleted for those 1 seconds
    target:SetMoveType( MOVETYPE_NONE )
    target:SetNoDraw( true )

    local effect = EffectData()
        effect:SetOrigin( target:GetPos() )
        effect:SetEntity( target )
    util_Effect( "entity_remove", effect, true, true ) -- Play the remove effect

    return true
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

    if IsValid( trace.Entity ) and ( trace.Entity:GetClass()=="gmod_balloon" or trace.Entity:IsNextBot() or trace.Entity:IsNPC() or trace.Entity:IsPlayer() ) then return end -- Check to avoid placing balloon on things they shouldn't be on

    self:UseWeapon( pos )
    local ent = CreateGmodEntity( "gmod_balloon", balloonModel.model, pos, nil, self ) -- Create the balloon
    ent.LambdaOwner = self
    ent.IsLambdaSpawned = true
    self:ContributeEntToLimit( ent, "Balloon" )
    table_insert( self.l_SpawnedEntities, 1, ent )

    local traceent = trace.Entity

    local LPos1 = Vector( 0, 0, 6.5 )
    local LPos2 = !IsNil( traceent ) and traceent:WorldToLocal( trace.HitPos ) or trace.HitPos

    traceent = !IsNil( traceent ) and traceent or Entity( 0 ) -- world

    if IsValid( trace.Entity ) then

        local phys = traceent:GetPhysicsObjectNum( trace.PhysicsBone )
        if IsValid( phys ) then
            LPos2 = phys:WorldToLocal( trace.HitPos )
        end

    end

    local constr, rope = constraint.Rope( ent, traceent, 0, trace.PhysicsBone, LPos1, LPos2, 0, random( 5, 1000 ), 0, 0.5, "cable/rope" )
    table_insert( self.l_SpawnedEntities, 1, rope )

    ent:SetPlayer( self )
    ent:SetColor( ColorRand( true ) )
    if ( balloonModel.skin ) then ent:SetSkin( balloonModel.skin ) end
    if ( balloonModel.nocolor ) then ent:SetColor( Color(255, 255, 255, 255) ) else ent:SetColor( ColorRand( ) ) end
    ent:SetForce( random( 50, 2000 ) ) -- While players can use negative force for balloons it kinda looks less fun

    return true
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





local lampmodels = { "models/lamps/torch.mdl", "models/maxofs2d/lamp_flashlight.mdl", "models/maxofs2d/lamp_projector.mdl" }
local lamptextures = { "effects/flashlight/caustics", "effects/flashlight/logo", "effects/flashlight001", "effects/flashlight/tech", "effects/flashlight/soft", "effects/flashlight/slit", "effects/flashlight/square", "effects/flashlight/circles", "effects/flashlight/window" }
local function UseLampTool( self, target )
    if !self:IsUnderLimit( "Lamp" ) then return end

    local trace = self:Trace( self:WorldSpaceCenter() + VectorRand( -12600, 12600 ) )
    local ang = self:GetAngles()
    ang[ 1 ] = 0
    ang[ 3 ] = 0
    local pos = trace.HitPos

    self:LookTo( pos, 2 )

    coroutine.wait( 1 )

    self:UseWeapon( pos )
    local ent = CreateGmodEntity( "gmod_lamp", lampmodels[ random( 1, 3 ) ], pos, ang, self )
    ent.LambdaOwner = self
    ent.IsLambdaSpawned = true
    self:ContributeEntToLimit( ent, "Lamp" )
    table_insert( self.l_SpawnedEntities, 1, ent )

    ent:SetColor( ColorRand( false ) )
    ent:SetFlashlightTexture( lamptextures[ random( #lamptextures) ] )
    ent:SetPlayer( self )
    ent:SetOn( true )
    ent:SetLightFOV( random( 10, 170 ) )
    ent:SetDistance( random( 64, 2048 ) )
    ent:SetBrightness( rand( 0.5, 8 ) )
    ent.flashlight:SetKeyValue( "enableshadows", 0 )

    return true
end
AddToolFunctionToLambdaTools( "Lamp", UseLampTool )





local effectlist = { "manhacksparks", "glassimpact", "striderblood", "shells", "cball_explode", "ar2impact", "bloodimpact", "sparks", "dirtywatersplash", "watersplash", "stunstickimpact", "thumperdust", "muzzleeffect", "bloodspray", "helicoptermegabomb", "rifleshells", "ar2explosion", "explosion", "cball_bounce", "shotgunshells", "underwaterexplosion", "smoke" }
local function UseEmitterTool( self, target )
    if !self:IsUnderLimit( "Emitter" ) then return end

    local trace = self:Trace( self:WorldSpaceCenter() + VectorRand( -12600, 12600 ) )

    local pos = trace.HitPos

    self:LookTo( pos, 2 )

    coroutine.wait( 1 )

    if IsValid( trace.Entity ) and ( trace.Entity:GetClass()=="gmod_emitter" or trace.Entity:IsNextBot() or trace.Entity:IsNPC() or trace.Entity:IsPlayer()  ) then return end -- Check to avoid placing emitter on things they shouldn't be on
    
    self:UseWeapon( pos )
    local ent = CreateGmodEntity( "gmod_emitter", "models/props_lab/tpplug.mdl", pos + trace.HitNormal, trace.HitNormal:Angle() - Angle( 0, 90, 90 ), self )
    ent.LambdaOwner = self
    ent.IsLambdaSpawned = true
    self:ContributeEntToLimit( ent, "Emitter" )
    table_insert( self.l_SpawnedEntities, 1, ent )

    ent:SetPlayer( self )
    ent:SetOn( true )
    ent:SetDelay( rand( 0.1, 2 ) )
    ent:SetScale( rand( 0, 6 ) )
    ent:SetEffect( effectlist[ random( #effectlist ) ] )

    return true
end
AddToolFunctionToLambdaTools( "Emitter", UseEmitterTool )





local ropematerials = { "cable/redlaser", "cable/cable2", "cable/rope", "cable/blue_elec", "cable/xbeam", "cable/physbeam", "cable/hydra" }
local function UseRopeTool( self, target )
    if !self:IsUnderLimit( "Rope" ) then return end

    local firstent
    local secondent
    local world = Entity( 0 )
    local firstuseworld = tobool( random( 0, 1 ) ) -- Choose if we want to rope the world or not
    local seconduseworld = tobool( random( 0, 1 ) )
    local find = self:FindInSphere( nil, 800, function( ent ) if !ent:IsNPC() and !ent:IsPlayer() and !ent:IsNextBot() and self:CanSee( ent ) and IsValid( ent:GetPhysicsObject() ) and self:HasPermissionToEdit( ent ) then return true end end )

    for k, v in RandomPairs( find ) do
        if !IsValid( firstent ) and IsValid( v ) and !firstuseworld then firstent = v continue end
        if !IsValid( secondent ) and IsValid( v ) and !seconduseworld then secondent = v continue end
        break
    end

    -- If the entities are valid then use them. If not use the world
    firstent = IsValid( firstent ) and firstent or world
    secondent = IsValid( secondent ) and secondent or world

    -- Local Positions
    -- For entities, this would be a position local to them
    -- For the world, it's just the regular map coords
    local lpos1 = firstent != world and firstent:WorldToLocal( self:Trace( firstent:WorldSpaceCenter() ).HitPos ) or self:Trace( self:WorldSpaceCenter() + VectorRand( -126000, 126000 ) ).HitPos
    local lpos2 = secondent != world and secondent:WorldToLocal( self:Trace( secondent:WorldSpaceCenter() ).HitPos ) or self:Trace( self:WorldSpaceCenter() + VectorRand( -126000, 126000 ) ).HitPos

    self:LookTo( ( firstent != world and firstent or lpos1 ), 2 )

    coroutine.wait( 1 )
    if IsNil( firstent ) then return end 

    self:UseWeapon( ( firstent != world and firstent:WorldSpaceCenter() or lpos1 ) )

    coroutine.wait( 0.3 )

    self:LookTo( ( secondent != world and secondent or lpos2 ), 2 )

    coroutine.wait( 1 )
    if IsNil( secondent ) or IsNil( firstent ) then return end

    self:UseWeapon( ( secondent != world and secondent:WorldSpaceCenter() or lpos2 ) )

    local dist = ( firstent == world and lpos1 or firstent:GetPos() ):Distance( ( secondent == world and lpos2 or secondent:GetPos() ) )

    local cons, rope = constraint.Rope( firstent, secondent, 0, 0, lpos1, lpos2, 0, random( 0, 500 ), dist, rand( 0.5, 10 ), ropematerials[ random( #ropematerials ) ], false, ColorRand( false ) )
    
    -- Weird situation here but we'll do this just to make sure something gets in the tables
    if IsValid( cons ) then
        cons.LambdaOwner = self
        cons.IsLambdaSpawned = true
        self:ContributeEntToLimit( cons, "Rope" )
        table_insert( self.l_SpawnedEntities, 1, cons )
    elseif IsValid( rope ) then
        rope.LambdaOwner = self
        rope.IsLambdaSpawned = true
        self:ContributeEntToLimit( rope, "Rope" )
        table_insert( self.l_SpawnedEntities, 1, rope )
    end


    return true
end
AddToolFunctionToLambdaTools( "Rope", UseRopeTool )





local hoverballmodels = { "models/dav0r/hoverball.mdl", "models/maxofs2d/hover_basic.mdl", "models/maxofs2d/hover_classic.mdl", "models/maxofs2d/hover_plate.mdl", "models/maxofs2d/hover_propeller.mdl", "models/maxofs2d/hover_rings.mdl" }
local function UseHoverballTool( self, target )
    if !self:IsUnderLimit( "Hoverball" ) or !IsValid( target ) or target:GetClass()=="gmod_hoverball" then return end

    self:LookTo( target, 2 )

    coroutine.wait( 1 )
    if !IsValid( target ) then return end

    local trace = self:Trace( target:WorldSpaceCenter() )

    if IsValid( trace.Entity ) and trace.Entity:GetClass()=="gmod_hoverball" then return end -- Check to avoid placing hoverball on hoverball using trace

    local pos = trace.HitPos

    self:UseWeapon( target:WorldSpaceCenter() )
    local ent = CreateGmodEntity( "gmod_hoverball", hoverballmodels[ random( #hoverballmodels ) ], pos, nil, self )
    ent.LambdaOwner = self
    ent.IsLambdaSpawned = true
    self:ContributeEntToLimit( ent, "Hoverball" )
    table_insert( self.l_SpawnedEntities, 1, ent )

    local const = constraint.Weld( ent, target, 0, trace.PhysicsBone, 0, 0, true )

    if IsValid( ent:GetPhysicsObject() ) then ent:GetPhysicsObject():EnableCollisions( false ) end
    ent:SetCollisionGroup( COLLISION_GROUP_WORLD )

    local ang = trace.HitNormal:Angle()
	ang.pitch = ang.pitch + 90
	ent:SetAngles( ang )

	local CurPos = ent:GetPos()
	local NearestPoint = ent:NearestPoint( CurPos - ( trace.HitNormal * 512 ) )
	local Offset = CurPos - NearestPoint
	ent:SetPos( trace.HitPos + Offset )

    ent:SetPlayer( self )
    ent:SetEnabled( true )
    ent:SetSpeed( random( 1, 10 ) )
    ent:SetAirResistance( Round( rand( 0, 10 ), 2 ) )
    ent:SetStrength( random( 1, 10 ) )

    local rndtime = CurTime() + rand( 1, 10 )
    ent:LambdaHookTick( "Hoverballrandommovement", function( hoverball )
        if CurTime() > rndtime then
            if !IsValid( hoverball ) then return true end
            hoverball:SetZVelocity( random( -1, 1 ) )

            rndtime = CurTime() + rand( 1, 10 )
        end
    end )

    return true
end
AddToolFunctionToLambdaTools( "Hoverball", UseHoverballTool )





local thrustermodels = { "models/dav0r/thruster.mdl", "models/MaxOfS2D/thruster_projector.mdl", "models/MaxOfS2D/thruster_propeller.mdl", "models/thrusters/jetpack.mdl", "models/props_junk/plasticbucket001a.mdl", "models/props_junk/PropaneCanister001a.mdl", "models/props_junk/propane_tank001a.mdl", "models/props_junk/PopCan01a.mdl", "models/props_junk/MetalBucket01a.mdl", "models/props_lab/jar01a.mdl", "models/props_c17/lampShade001a.mdl", "models/props_c17/canister_propane01a.mdl", "models/props_c17/canister01a.mdl", "models/props_c17/canister02a.mdl", "models/props_trainstation/trainstation_ornament002.mdl", "models/props_junk/TrafficCone001a.mdl", "models/props_c17/clock01.mdl", "models/props_junk/terracotta01.mdl", "models/props_c17/TrapPropeller_Engine.mdl", "models/props_c17/FurnitureSink001a.mdl", "models/props_trainstation/trainstation_ornament001.mdl", "models/props_trainstation/trashcan_indoor001b.mdl", "models/props_phx2/garbage_metalcan001a.mdl", "models/hunter/plates/plate.mdl", "models/hunter/blocks/cube025x025x025.mdl", "models/XQM/AfterBurner1.mdl", "models/XQM/AfterBurner1Medium.mdl", "models/XQM/AfterBurner1Big.mdl", "models/XQM/AfterBurner1Huge.mdl", "models/XQM/AfterBurner1Large.mdl" }
local thrustersounds = { "", "PhysicsCannister.ThrusterLoop", "WeaponDissolve.Charge", "WeaponDissolve.Beam", "eli_lab.elevator_move", "combine.sheild_loop", "k_lab.ringsrotating", "k_lab.teleport_rings_high", "k_lab2.DropshipRotorLoop", "Town.d1_town_01_spin_loop" }
local thrustereffects = { "none", "fire", "plasma", "magic", "rings", "smoke" }
local function UseThrusterTool( self, target )
    if !self:IsUnderLimit( "Thruster" ) or !IsValid( target ) or target:GetClass()=="gmod_thruster" then return end

    self:LookTo( target, 2 )

    coroutine.wait( 1 )
    if !IsValid( target ) then return end

    local trace = self:Trace( target:WorldSpaceCenter() )

    if IsValid( trace.Entity ) and trace.Entity:GetClass()=="gmod_thruster" then return end -- Check to avoid placing thruster on thruster using trace

    local pos = trace.HitPos
    local ang = trace.HitNormal:Angle()
	ang.pitch = ang.pitch + 90

    self:UseWeapon( target:WorldSpaceCenter() )
    local ent = CreateGmodEntity( "gmod_thruster", thrustermodels[ random( #thrustermodels ) ], pos, ang, self )
    ent.LambdaOwner = self
    ent.IsLambdaSpawned = true
    self:ContributeEntToLimit( ent, "Thruster" )
    table_insert( self.l_SpawnedEntities, 1, ent )

    local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )

    local const = constraint.Weld( ent, target, 0, trace.PhysicsBone, 0, 0, true )

    ent:SetPlayer( self )
    ent:SetEffect( thrustereffects[ random( #thrustereffects ) ] )
    ent:SetForce( random( 10000 ) )
    ent:SetToggle( true )
    ent:SetSound( thrustersounds[ random( #thrustersounds ) ] )

    if random( 0, 1 ) == 1 then
        if ( IsValid( ent:GetPhysicsObject() ) ) then ent:GetPhysicsObject():EnableCollisions( false ) end
        ent:SetCollisionGroup( COLLISION_GROUP_WORLD ) -- Only nocollide to world if attached to something
        ent:GetPhysicsObject():SetMass( Clamp( ent:GetPhysicsObject():GetMass(), 1, 20 ) ) -- If they are nocollided to the world, let's avoid them being too heavy
    end

    local rndtime = CurTime() + rand( 1, 10 )
    ent:LambdaHookTick( "ThrusterRandomOnOff", function( thruster )
        if CurTime() > rndtime then
            if !IsValid( thruster ) then return true end
            thruster:Switch( random( 0, 1 ) == 1 )-- Randomly switch it on or off

            rndtime = CurTime() + rand( 1, 10 )
        end
    end )

    return true
end
AddToolFunctionToLambdaTools( "Thruster", UseThrusterTool )





local physproperties = { "metal_bouncy", "metal", "dirt", "slipperyslime", "wood", "glass", "concrete_block", "ice", "rubber", "paper", "zombieflesh", "gmod_ice", "gmod_bouncy" }
local function UsePhysPropTool( self, target )
    if !IsValid( target ) then return end
    
    self:LookTo( target, 2 )

    coroutine.wait( 1 )
    if !IsValid( target ) then return end

    local trace = self:Trace( target:WorldSpaceCenter() )
    local pos = trace.HitPos

    local ent = trace.Entity
    if !IsValid( ent ) or ent!=target then return end

    self:UseWeapon( target:WorldSpaceCenter() )

    construct.SetPhysProp( target:GetOwner(), ent, trace.PhysicsBone, nil, { GravityToggle = random( 0, 1 ) == 1, Material = physproperties[ random( #physproperties ) ] } ) -- Set the properties

    return true
end
AddToolFunctionToLambdaTools( "PhysicalProperties", UsePhysPropTool )





local function CanEntityBeSetOnFire( ent ) -- Taken from the ignite properties

	-- func_pushable, func_breakable & func_physbox cannot be ignited
	if ( ent:GetClass() == "item_item_crate" ) then return true end
	if ( ent:GetClass() == "simple_physics_prop" ) then return true end
	if ( ent:GetClass():match( "prop_physics*") ) then return true end
	if ( ent:GetClass():match( "prop_ragdoll*") ) then return true end
	if ( ent:IsNPC() ) then return true end

	return false

end
local function UseIgniteTool( self, target ) -- Technically only a context menu right click tool
    if !IsValid( target ) then return end

    self:LookTo( target, 2 )

    coroutine.wait( 1 )
    if !IsValid( target ) or !CanEntityBeSetOnFire( target ) then return end
    if target:IsOnFire() then target:Extinguish() else target:Ignite( 360 ) end


    self:UseWeapon( target:WorldSpaceCenter() ) -- Not a 'real' tool but still want to see it happen

    return true
end
AddToolFunctionToLambdaTools( "Ignite", UseIgniteTool )





local function UseKeepUprightTool( self, target ) -- Technically only a context menu right click tool
    if !IsValid( target ) or target:GetClass() != "prop_physics" then return end -- Only target props

    self:LookTo( target, 2 )

    coroutine.wait( 1 )
    if !IsValid( target ) then return end
    
    local phys = target:GetPhysicsObjectNum( 0 )
    if ( !IsValid( phys ) ) then return end

    if target:GetNWBool( "IsUpright" ) then-- If we target a prop already keptupright, remove the constraint
        constraint.RemoveConstraints( target, "Keepupright" )
    else -- Otherwise apply the keepupright constraint
        local const = constraint.Keepupright( target, phys:GetAngles(), 0, 999999 )
        if const then target:SetNWBool( "IsUpright", true ) end
    end

    self:UseWeapon( target:WorldSpaceCenter() ) -- Not a 'real' tool but still want to see it happen

    return true
end
AddToolFunctionToLambdaTools( "KeepUpright", UseKeepUprightTool )





-- Called when all default tools are loaded
-- This hook can be used to add custom tool functions by using AddToolFunctionToLambdaTools()
hook.Run( "LambdaOnToolsLoaded" )