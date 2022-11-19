local table_insert = table.insert
local random = math.random
local rand = math.Rand
local RandomPairs = RandomPairs
local ColorRand = ColorRand
local VectorRand = VectorRand
local IsValid = IsValid
local Round = math.Round
local NormalizeAngle = math.NormalizeAngle
local ents_Create = ents.Create
local util_Effect = util.Effect
local tobool = tobool
local table_GetKeys = table.GetKeys
local util_IsValidPhysicsObject = util.IsValidPhysicsObject
local timer = timer 
local util = util
local coroutine = coroutine
local constraint = constraint
local Clamp = math.Clamp
local angle_zero = angle_zero

local function IsNil( any )
    return any == nil or any == NULL
end


LambdaToolGunTools = {}

-- Adds a tool function to the list of tools
-- These functions will be under the Tool Chance
-- See the functions below for examples on making tools
function AddToolFunctionToLambdaTools( toolname, func )
    local convar = CreateLambdaConvar( "lambdaplayers_tool_allow" .. toolname, 1, true, false, false, "If Lambda Players can use the " .. toolname .. " tool", 0, 1, { type = "Bool", name = "Allow " .. toolname .. " Tool", category = "Limits and Tool Permissions" } )
    table_insert( LambdaToolGunTools, { toolname, convar, func } )
end



-- Helper function for gmod entities 
local function CreateGmodEntity( classname, model, pos, ang, lambda )

    local ent = ents_Create( classname )
    ent:SetPos( pos )
    ent:SetAngles( ang or angle_zero )
    ent:SetModel( model or "" )
    LambdaHijackGmodEntity( ent, lambda ) -- Make it support the Lambda
    ent:Spawn()
    ent:Activate()
    DoPropSpawnedEffect( ent )

    return ent
end



-- Helper function for the Paint Tool
-- Taken from the ignite properties in sandbox
local function CanEntityBeSetOnFire( ent )

    -- func_pushable, func_breakable & func_physbox cannot be ignited
    if ( ent:GetClass() == "item_item_crate" ) then return true end
    if ( ent:GetClass() == "simple_physics_prop" ) then return true end
    if ( ent:GetClass():match( "prop_physics*") ) then return true end
    if ( ent:GetClass():match( "prop_ragdoll*") ) then return true end
    if ( ent:IsNPC() ) then return true end

    return false

end



-- Helper function for the Paint Tool
-- Taken from the paint tool in sandbox
local function PlaceDecal( ply, ent, data )

    if ( !IsValid( ent ) and !ent:IsWorld() ) then return end

    local bone
    if ( data.bone and data.bone < ent:GetPhysicsObjectCount() ) then bone = ent:GetPhysicsObjectNum( data.bone ) end
    if ( !IsValid( bone ) ) then bone = ent:GetPhysicsObject() end
    if ( !IsValid( bone ) ) then bone = ent end

    util.Decal( data.decal, bone:LocalToWorld( data.Pos1 ), bone:LocalToWorld( data.Pos2 ), ply )

    local i = ent.DecalCount or 0
    i = i + 1
    ent.DecalCount = i

end




--[[A lot of tools here use self:Trace( position ) which here creates a line from the Lambda Player to a position provided
    This gives us a table that contains useful information for tool usage such as:
    trace.Entity - the Entity the trace collided with if any.
    trace.HitPos - the Position the trace stopped at
    trace.HitNormal - the direction of the surface that was hit
]]

local balloonnames = { "normal", "normal_skin1", "normal_skin2", "normal_skin3", "gman", "mossman", "dog", "heart", "star" }
local function UseBalloonTool( self, target )
    if !self:IsUnderLimit( "Balloon" ) then return end -- We check if the Lambda Players hasn't reached it's personal limit of Balloons
    local world = random( 0, 1 )

    -- If we choose target but the target isn't valid, we don't do anything.
    if !world and ( !IsValid( target ) or target:GetClass() == "gmod_balloon" ) then return end -- Returning nothing is equivalent to returning false

    -- We create a trace from the Lambda towards either a random place in the world or the target
    -- Here we declare the variable trace. If world is true we use the trace after the 'and' otherwise we use the trace after the 'or'
    local trace = world and self:Trace( self:WorldSpaceCenter() + VectorRand( -12600, 12600 ) ) or self:Trace( target:WorldSpaceCenter() )
    local hitpos = trace.HitPos
    local entity = trace.Entity
    local physbone = trace.PhysicsBone

    self:LookTo( hitpos, 2 ) -- We look towards the position the trace stopped at

    coroutine.wait( 1 ) -- We wait for a second

    -- Because we wait for 1 second we must make sure the target is still valid
    if !util_IsValidPhysicsObject( entity, physbone ) or entity:GetClass() == "gmod_balloon" then return end

    self:UseWeapon( hitpos ) -- Use the toolgun on the hit position of the trace to fake using a tool

    -- We randomly select a model for the Lambda to spawn. This is a special case since certain balloons have skins.
    local balloonModel = list.Get( "BalloonModels" )[balloonnames[ random( #balloonnames ) ]]

    -- We create the balloon entity "gmod_balloon" with the random model, at the HitPos of the trace, with Angles of nil and the Lambda as the owner
    local ent = CreateGmodEntity( "gmod_balloon", balloonModel.model, hitpos, nil, self )

    ent.LambdaOwner = self -- We set the owner of the entity as the Lambda Player that spawned it

    ent.IsLambdaSpawned = true -- We specify that the entity has been spawned by a Lambda Player

    self:ContributeEntToLimit( ent, "Balloon" ) -- We add the entity to the amount of similar entities the Lambda possess

    local CurPos = ent:GetPos()
    local NearestPoint = ent:NearestPoint( CurPos - ( trace.HitNormal * 512 ) )
    local Offset = CurPos - NearestPoint

    ent:SetPos( hitpos + Offset ) -- Fix for balloons being placed on ceilings
    
    local LPos = !IsNil( entity ) and entity:WorldToLocal( hitpos ) or hitpos
    entity = !IsNil( entity ) and entity or Entity( 0 ) -- If the trace manages to not hit anything, we force it to be the world

    if IsValid( entity ) then

        local phys = entity:GetPhysicsObjectNum( physbone )
        if IsValid( phys ) then
            LPos = phys:WorldToLocal( hitpos )
        end

    end

    local constr, rope = constraint.Rope( ent, entity, 0, physbone, Vector( 0, 0, 0 ), LPos, 0, random( 5, 1000 ), 0, 0.5, "cable/rope" )
    table_insert( self.l_SpawnedEntities, 1, rope )
    table_insert( self.l_SpawnedEntities, 1, ent ) -- Insert the balloon last so if the Lambda decide to undo, it will meet the balloon first

    -- Here we configure the entity we created. The settings will depend on which entity we created. Here it's a balloon so it doesn't have much.
    ent:SetPlayer( self ) -- We can safely set it to ourself since we 'hijacked' it
    if ( balloonModel.skin ) then ent:SetSkin( balloonModel.skin ) end
    if ( balloonModel.nocolor ) then ent:SetColor( Color(255, 255, 255, 255) ) else ent:SetColor( ColorRand( ) ) end -- We randomize the color of the balloon except if it tells us that it can't accept color.
    ent:SetForce( random( 50, 2000 ) ) -- While players can use negative force for balloons, we limit the Lambda to positive forces to be more fun

    return true -- Return true to let the for loop in Chance_Tool know we actually got to use the tool so it can break. All tools must do this!
end
AddToolFunctionToLambdaTools( "Balloon", UseBalloonTool )





local function UseBallsocketTool( self, target )
    if !IsValid( target ) then return end

    local world = random( 0, 1 )
    local find = self:FindInSphere( nil, 800, function( ent ) if ent != target and !ent:IsNPC() and !ent:IsPlayer() and !ent:IsNextBot() and self:CanSee( ent ) and IsValid( ent:GetPhysicsObject() ) and self:HasPermissionToEdit( ent ) then return true end end )
    local target2 = find[ random( #find ) ]

    if !IsValid( target2 ) and !world then return end
    target2 = !world and target2 or Entity( 0 )

    local lpos1 = target:WorldToLocal( self:Trace( target:WorldSpaceCenter() ).HitPos )
    local lpos2 = !world and target2:WorldToLocal( self:Trace( target2:WorldSpaceCenter() ).HitPos ) or self:Trace( self:WorldSpaceCenter() + VectorRand( -126000, 126000 ) ).HitPos

    self:LookTo( target , 2 )

    coroutine.wait( 1 )
    if !IsValid( target ) then return end
    if !util_IsValidPhysicsObject( target, target:GetPhysicsObjectCount()-1 ) then return end

    self:UseWeapon( target:WorldSpaceCenter() )

    coroutine.wait( 0.3 )

    self:LookTo( ( !world and target2 or lpos2 ), 2 )

    coroutine.wait( 1 )
    if IsNil( target2 ) or IsNil( target ) then return end
    if !util_IsValidPhysicsObject( target2, target2:GetPhysicsObjectCount()-1 ) then return end

    self:UseWeapon( ( !world and target2:WorldSpaceCenter() or lpos2 ) )

    local cons = constraint.Ballsocket( target, target2, 0, 0, lpos2, 0, 0, 0 ) -- forcelimit, unused, nocollide to other.
    
    if cons then
        cons.LambdaOwner = self
        cons.IsLambdaSpawned = true
        table_insert( self.l_SpawnedEntities, 1, cons )
    end

    return true
end
AddToolFunctionToLambdaTools( "Ballsocket", UseBallsocketTool )





local function UseColorTool( self, target )
    if !IsValid( target ) then return end -- Returning nothing is basically the same as returning false

    self:LookTo( target, 2 )

    coroutine.wait( 1 )
    if !IsValid( target ) then return end

    self:UseWeapon( target:WorldSpaceCenter() )
    target:SetColor( ColorRand( false ) )

    return true
end
AddToolFunctionToLambdaTools( "Color", UseColorTool )





local dynamitemodels = { "models/dav0r/tnt/tnt.mdl", "models/dav0r/tnt/tnttimed.mdl", "models/dynamite/dynamite.mdl" }
local function UseDynamiteTool( self, target )
    if !self:IsUnderLimit( "Dynamite" ) then return end

    local trace = self:Trace( self:WorldSpaceCenter() + VectorRand( -12600, 12600 ) )
    local hitpos = trace.HitPos

    self:LookTo( hitpos, 2 )

    coroutine.wait( 1 )

    self:UseWeapon( hitpos )
    local ent = CreateGmodEntity( "gmod_dynamite", dynamitemodels[ random( #dynamitemodels ) ], hitpos + trace.HitNormal * 10, nil, self )
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
            util_Effect( "Explosion", effectdata, true, true )
    
            if ( self:GetShouldRemove() ) then self:Remove() return end
            if ( self:GetMaxHealth() > 0 and self:Health() <= 0 ) then self:SetHealth( self:GetMaxHealth() ) end
            self:Explode( self:GetDelay(), ply )
        else
    
            timer.Simple( _delay, function() if ( !IsValid( self ) ) then return end self:Explode( 0, ply ) end )
    
        end
    end

    ent:Explode( ent:GetDelay(), self )

    return true
end
AddToolFunctionToLambdaTools( "Dynamite", UseDynamiteTool )





local ropematerials = { "cable/redlaser", "cable/cable2", "cable/rope", "cable/blue_elec", "cable/xbeam", "cable/physbeam", "cable/hydra" }
local function UseElasticTool( self, target )
    if !self:IsUnderLimit( "Rope" ) then return end -- It's technically a special rope
    if !IsValid( target ) then return end

    local world = random( 0, 1 )
    local find = self:FindInSphere( nil, 800, function( ent ) if ent != target and !ent:IsNPC() and !ent:IsPlayer() and !ent:IsNextBot() and self:CanSee( ent ) and IsValid( ent:GetPhysicsObject() ) and self:HasPermissionToEdit( ent ) then return true end end )
    local target2 = find[ random( #find ) ]

    if !IsValid( target2 ) and !world then return end
    target2 = !world and target2 or Entity( 0 )

    local lpos1 = target:WorldToLocal( self:Trace( target:WorldSpaceCenter() ).HitPos )
    local lpos2 = !world and target2:WorldToLocal( self:Trace( target2:WorldSpaceCenter() ).HitPos ) or self:Trace( self:WorldSpaceCenter() + VectorRand( -126000, 126000 ) ).HitPos

    self:LookTo( target , 2 )

    coroutine.wait( 1 )
    if !IsValid( target ) then return end
    if !util_IsValidPhysicsObject( target, target:GetPhysicsObjectCount()-1 ) then return end

    self:UseWeapon( target:WorldSpaceCenter() )

    coroutine.wait( 0.3 )

    self:LookTo( ( !world and target2 or lpos2 ), 2 )

    coroutine.wait( 1 )
    if IsNil( target2 ) or IsNil( target ) then return end
    if !util_IsValidPhysicsObject( target2, target2:GetPhysicsObjectCount()-1 ) then return end

    self:UseWeapon( ( !world and target2:WorldSpaceCenter() or lpos2 ) )

    local cons, rope = constraint.Elastic( target, target2, 0, 0, lpos1, lpos2, random( 0, 4000 ), random( 0, 50 ), rand( 0 , 1 ), ropematerials[ random( #ropematerials ) ], rand( 0, 20 ), random( 0, 1 ), ColorRand() )

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
AddToolFunctionToLambdaTools( "Elastic", UseElasticTool )





local effectlist = { "manhacksparks", "glassimpact", "striderblood", "shells", "cball_explode", "ar2impact", "bloodimpact", "sparks", "dirtywatersplash", "watersplash", "stunstickimpact", "thumperdust", "muzzleeffect", "bloodspray", "helicoptermegabomb", "rifleshells", "ar2explosion", "explosion", "cball_bounce", "shotgunshells", "underwaterexplosion", "smoke" }
local function UseEmitterTool( self, target )
    if !self:IsUnderLimit( "Emitter" ) then return end

    -- TODO : Randomly choose between world or target

    local trace = self:Trace( self:WorldSpaceCenter() + VectorRand( -12600, 12600 ) )
    local hitpos = trace.HitPos
    local entity = trace.Entity
    local physbone = trace.PhysicsBone

    local ang = trace.HitNormal:Angle()
    ang:RotateAroundAxis( trace.HitNormal, 0 )

    self:LookTo( hitpos, 2 )

    coroutine.wait( 1 )

    if !util_IsValidPhysicsObject( entity, physbone ) or entity:GetClass() == "gmod_emitter" then return end -- Check to avoid placing emitter on things they can't be attached to

    self:UseWeapon( hitpos )
    local ent = CreateGmodEntity( "gmod_emitter", "models/props_lab/tpplug.mdl", hitpos + trace.HitNormal, ang, self )
    ent.LambdaOwner = self
    ent.IsLambdaSpawned = true
    self:ContributeEntToLimit( ent, "Emitter" )
    table_insert( self.l_SpawnedEntities, 1, ent )

    if entity != NULL and !entity:IsWorld() then -- Only want to weld to props
        local weld = constraint.Weld( ent, entity, 0, physbone, 0, true, true )

        if ( IsValid( ent:GetPhysicsObject() ) ) then ent:GetPhysicsObject():EnableCollisions( false ) end
        ent.nocollide = true
    end

    ent:SetPlayer( self )
    ent:SetOn( true )
    ent:SetDelay( rand( 0.1, 2 ) )
    ent:SetScale( rand( 0, 6 ) )
    ent:SetEffect( effectlist[ random( #effectlist ) ] )

    return true
end
AddToolFunctionToLambdaTools( "Emitter", UseEmitterTool )





local function UseFaceposerTool( self, target )
    if !IsValid( target ) or target:GetClass() != "prop_ragdoll" then return end
    
    local trace = self:Trace( target:WorldSpaceCenter() )
    local entity = trace.Entity
    local physbone = trace.PhysicsBone
    self:LookTo( target, 2 )

    coroutine.wait( 1 )
    if !IsValid( target ) or !util_IsValidPhysicsObject( entity, physbone ) then return end -- it's pretty much a double IsValid but just in case

    self:UseWeapon( target:WorldSpaceCenter() )

    for i = 0, target:GetFlexNum()-1 do
        if random( 4 ) > 1 then -- 25% chance to not edit a flex, to add a bit of randomness to that
            target:SetFlexWeight(i, math.random()*math.random(5))
        end
    end

    return true
end
AddToolFunctionToLambdaTools( "Faceposer", UseFaceposerTool )






local hoverballmodels = { "models/dav0r/hoverball.mdl", "models/maxofs2d/hover_basic.mdl", "models/maxofs2d/hover_classic.mdl", "models/maxofs2d/hover_plate.mdl", "models/maxofs2d/hover_propeller.mdl", "models/maxofs2d/hover_rings.mdl" }
local function UseHoverballTool( self, target )
    if !self:IsUnderLimit( "Hoverball" ) then return end
    local world = random( 0, 1 )

    if !world and ( !IsValid( target ) or target:GetClass()=="gmod_hoverball" ) then return end

    local trace = world and self:Trace( self:WorldSpaceCenter() + VectorRand( -12600, 12600 ) ) or self:Trace( target:WorldSpaceCenter() )
    local hitpos = trace.HitPos
    local entity = trace.Entity
    local physbone = trace.PhysicsBone

    self:LookTo( hitpos , 2 )

    coroutine.wait( 1 )
    if !util_IsValidPhysicsObject( entity, physbone ) or entity:GetClass() == "gmod_hoverball" then return end -- Check to avoid placing hoverball on things they can't be attached to

    local ang = trace.HitNormal:Angle()
    ang.pitch = ang.pitch + 90

    self:UseWeapon( hitpos )
    local ent = CreateGmodEntity( "gmod_hoverball", hoverballmodels[ random( #hoverballmodels ) ], hitpos, ang, self )
    ent.LambdaOwner = self
    ent.IsLambdaSpawned = true
    self:ContributeEntToLimit( ent, "Hoverball" )
    table_insert( self.l_SpawnedEntities, 1, ent )

    local CurPos = ent:GetPos()
    local NearestPoint = ent:NearestPoint( CurPos - ( trace.HitNormal * 512 ) )
    local Offset = CurPos - NearestPoint
    ent:SetPos( hitpos + Offset )

    if entity != NULL and !entity:IsWorld() then -- Hoverballs spawned on world are not welded nor notcollided
        local const = constraint.Weld( ent, entity, 0, physbone, 0, 0, true )
        if ( IsValid( ent:GetPhysicsObject() ) ) then ent:GetPhysicsObject():EnableCollisions( false ) end
        ent:SetCollisionGroup( COLLISION_GROUP_WORLD )
    end
    
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





local lampmodels = { "models/lamps/torch.mdl", "models/maxofs2d/lamp_flashlight.mdl", "models/maxofs2d/lamp_projector.mdl" }
local lamptextures = { "effects/flashlight/caustics", "effects/flashlight/logo", "effects/flashlight001", "effects/flashlight/tech", "effects/flashlight/soft", "effects/flashlight/slit", "effects/flashlight/square", "effects/flashlight/circles", "effects/flashlight/window" }
local function UseLampTool( self, target )
    if !self:IsUnderLimit( "Lamp" ) then return end

    local trace = self:Trace( self:WorldSpaceCenter() + VectorRand( -12600, 12600 ) )

    self:LookTo( trace.HitPos, 2 )

    coroutine.wait( 1 )

    self:UseWeapon( trace.HitPos )
    local ent = CreateGmodEntity( "gmod_lamp", lampmodels[ random( 1, 3 ) ], trace.HitPos, angle_zero, self )
    ent.LambdaOwner = self
    ent.IsLambdaSpawned = true
    self:ContributeEntToLimit( ent, "Lamp" )
    table_insert( self.l_SpawnedEntities, 1, ent )

    local CurPos = ent:GetPos()
	local NearestPoint = ent:NearestPoint( CurPos - ( trace.HitNormal * 512 ) )
	local Offset = CurPos - NearestPoint

	ent:SetPos( trace.HitPos + Offset ) -- Fix to avoid lamps from being placed into things

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





local function UseLightTool( self, target )
    if !self:IsUnderLimit( "Light" ) then return end -- Can't create any more lights
    local world = random( 0, 1 )

    if !world and ( !IsValid( target ) or target:GetClass()=="gmod_light" ) then return end

    local trace = world and self:Trace( self:WorldSpaceCenter() + VectorRand( -12600, 12600 ) ) or self:Trace( target:WorldSpaceCenter() )
    local entity = trace.Entity
    local hitpos = trace.HitPos
    local physbone = trace.PhysicsBone
    
    self:LookTo( hitpos, 2 )

    coroutine.wait( 1 )

    if !util_IsValidPhysicsObject( entity, physbone ) or entity:GetClass() == "gmod_light" then return end -- Check to avoid placing light on things they can't be attached to

    self:UseWeapon( hitpos )
    local ent = CreateGmodEntity( "gmod_light", nil, hitpos + trace.HitNormal * 8, trace.HitNormal:Angle() - Angle( 90, 0, 0 ), self ) -- Create the light
    ent.LambdaOwner = self
    ent.IsLambdaSpawned = true
    self:ContributeEntToLimit( ent, "Light" )

    if random( 0, 1 ) == 1 then
        local LPos = !IsNil( entity ) and entity:WorldToLocal( hitpos ) or hitpos
        entity = !IsNil( entity ) and entity or Entity( 0 ) -- world

        if IsValid( entity ) then

            local phys = entity:GetPhysicsObjectNum( physbone )
            if IsValid( phys ) then
                LPos = phys:WorldToLocal( hitpos )
            end

        end

        local constr, rope = constraint.Rope( ent, entity, 0, physbone, Vector( 0, 0, 6.5 ), LPos, 0, random( 256 ), 0, 1, "cable/rope" )
        table_insert( self.l_SpawnedEntities, 1, rope )
    end
    table_insert( self.l_SpawnedEntities, 1, ent )

    -- We configure the entity. Some settings will depend on the entity itself.
    ent:SetPlayer( self ) -- We can safely set this to ourselves since it was "hijacked"
    ent:SetOn( true )
    ent:SetColor( ColorRand( false ) )
    ent:SetBrightness( rand( 1, 6 ) )
    ent:SetLightSize( rand( 100, 1024 ) )

    return true
end
AddToolFunctionToLambdaTools( "Light", UseLightTool )





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





local decallist = { "Eye", "Dark", "Smile", "Cross", "Nought", "Noughtsncrosses", "Light", "Blood", "YellowBlood", "Impact.Metal", "Scorch", "BeerSplash", "ExplosiveGunshot", "BirdPoop", "PaintSplatPink", "PaintSplatGreen", "PaintSplatBlue", "ManhackCut", "FadingScorch", "Antlion.Splat", "Splash.Large", "BulletProof", "GlassBreak", "Impact.Sand", "Impact.BloodyFlesh", "Impact.Antlion", "Impact.Glass", "Impact.Wood", "Impact.Concrete" }
local function UsePaintTool( self, target )
    local world = random( 0, 1 )
    if !world and !IsValid( target ) then return end

    local trace = world and self:Trace( self:WorldSpaceCenter() + VectorRand( -12600, 12600 ) ) or self:Trace( target:WorldSpaceCenter() )
    local hitpos = trace.HitPos
    local norm = trace.Normal
    local entity = trace.Entity
    local physbone = trace.PhysicsBone

    self:LookTo( hitpos, 2 )

    coroutine.wait( 1 )

    if !util_IsValidPhysicsObject( entity, physbone ) then return end

    local Pos1 = hitpos + norm
    local Pos2 = hitpos - norm

    local Bone
    if ( IsValid( entity ) and physbone and physbone < entity:GetPhysicsObjectCount() ) then Bone = entity:GetPhysicsObjectNum( physbone ) end
    if ( IsValid( entity ) and !IsValid( Bone ) ) then Bone = entity:GetPhysicsObject() end
    if ( !IsValid( Bone ) ) then Bone = entity end

    if !IsValid( Bone ) then return end

    Pos1 = Bone:WorldToLocal( Pos1 )
    Pos2 = Bone:WorldToLocal( Pos2 )

    self:UseWeapon( hitpos )

    PlaceDecal( self:GetOwner(), entity, { Pos1 = Pos1, Pos2 = Pos2, bone = physbone, decal = decallist[ random( #decallist ) ] } )

    --self:EmitSound( "SprayCan.Paint" )

    return true
end
AddToolFunctionToLambdaTools( "Paint", UsePaintTool )





local physproperties = { "metal_bouncy", "metal", "dirt", "slipperyslime", "wood", "glass", "concrete_block", "ice", "rubber", "paper", "zombieflesh", "gmod_ice", "gmod_bouncy" }
local function UsePhysPropTool( self, target )
    if !IsValid( target ) then return end
    
    local trace = self:Trace( target:WorldSpaceCenter() )
    local entity = trace.Entity
    local physbone = trace.PhysicsBone
    self:LookTo( target, 2 )

    coroutine.wait( 1 )
    if !IsValid( target ) or !util_IsValidPhysicsObject( entity, physbone ) or entity == Entity( 0 ) then return end -- it's pretty much a double IsValid but just in case

    self:UseWeapon( target:WorldSpaceCenter() )

    construct.SetPhysProp( target:GetOwner(), entity, physbone, nil, { GravityToggle = tobool( random( 0, 1 ) ), Material = physproperties[ random( #physproperties ) ] } ) -- Set the properties

    return true
end
AddToolFunctionToLambdaTools( "PhysicalProperties", UsePhysPropTool )





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
    if !util_IsValidPhysicsObject( firstent, firstent:GetPhysicsObjectCount()-1 ) then return end

    self:UseWeapon( ( firstent != world and firstent:WorldSpaceCenter() or lpos1 ) )

    coroutine.wait( 0.3 )

    self:LookTo( ( secondent != world and secondent or lpos2 ), 2 )

    coroutine.wait( 1 )
    if IsNil( secondent ) or IsNil( firstent ) then return end
    if !util_IsValidPhysicsObject( secondent, secondent:GetPhysicsObjectCount()-1 ) then return end

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





local function UseSliderTool( self, target )
    if !self:IsUnderLimit( "Rope" ) then return end -- It's technically a special rope
    if !IsValid( target ) then return end

    local world = random( 0, 1 )
    local find = self:FindInSphere( nil, 800, function( ent ) if ent != target and !ent:IsNPC() and !ent:IsPlayer() and !ent:IsNextBot() and self:CanSee( ent ) and IsValid( ent:GetPhysicsObject() ) and self:HasPermissionToEdit( ent ) then return true end end )
    local target2 = find[ random( #find ) ]

    if !IsValid( target2 ) and !world then return end
    target2 = !world and target2 or Entity( 0 )

    local lpos1 = target:WorldToLocal( self:Trace( target:WorldSpaceCenter() ).HitPos )
    local lpos2 = !world and target2:WorldToLocal( self:Trace( target2:WorldSpaceCenter() ).HitPos ) or self:Trace( self:WorldSpaceCenter() + VectorRand( -126000, 126000 ) ).HitPos

    self:LookTo( target , 2 )

    coroutine.wait( 1 )
    if !IsValid( target ) then return end
    if !util_IsValidPhysicsObject( target, target:GetPhysicsObjectCount()-1 ) then return end

    self:UseWeapon( target:WorldSpaceCenter() )

    coroutine.wait( 0.3 )

    self:LookTo( ( !world and target2 or lpos2 ), 2 )

    coroutine.wait( 1 )
    if IsNil( target2 ) or IsNil( target ) then return end
    if !util_IsValidPhysicsObject( target2, target2:GetPhysicsObjectCount()-1 ) then return end

    self:UseWeapon( ( !world and target2:WorldSpaceCenter() or lpos2 ) )

    local cons, rope = constraint.Slider( target, target2, 0, 0, lpos1, lpos2, random( 0, 10 ), ropematerials[ random( #ropematerials ) ], ColorRand() )

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
AddToolFunctionToLambdaTools( "Slider", UseSliderTool )





local thrustermodels = { "models/dav0r/thruster.mdl", "models/MaxOfS2D/thruster_projector.mdl", "models/MaxOfS2D/thruster_propeller.mdl", "models/thrusters/jetpack.mdl", "models/props_junk/plasticbucket001a.mdl", "models/props_junk/PropaneCanister001a.mdl", "models/props_junk/propane_tank001a.mdl", "models/props_junk/PopCan01a.mdl", "models/props_junk/MetalBucket01a.mdl", "models/props_lab/jar01a.mdl", "models/props_c17/lampShade001a.mdl", "models/props_c17/canister_propane01a.mdl", "models/props_c17/canister01a.mdl", "models/props_c17/canister02a.mdl", "models/props_trainstation/trainstation_ornament002.mdl", "models/props_junk/TrafficCone001a.mdl", "models/props_c17/clock01.mdl", "models/props_junk/terracotta01.mdl", "models/props_c17/TrapPropeller_Engine.mdl", "models/props_c17/FurnitureSink001a.mdl", "models/props_trainstation/trainstation_ornament001.mdl", "models/props_trainstation/trashcan_indoor001b.mdl", "models/props_phx2/garbage_metalcan001a.mdl", "models/hunter/plates/plate.mdl", "models/hunter/blocks/cube025x025x025.mdl", "models/XQM/AfterBurner1.mdl", "models/XQM/AfterBurner1Medium.mdl", "models/XQM/AfterBurner1Big.mdl", "models/XQM/AfterBurner1Huge.mdl", "models/XQM/AfterBurner1Large.mdl" }
local thrustersounds = { "", "PhysicsCannister.ThrusterLoop", "WeaponDissolve.Charge", "WeaponDissolve.Beam", "eli_lab.elevator_move", "combine.sheild_loop", "k_lab.ringsrotating", "k_lab.teleport_rings_high", "k_lab2.DropshipRotorLoop", "Town.d1_town_01_spin_loop" }
local thrustereffects = { "none", "fire", "plasma", "magic", "rings", "smoke" }
local function UseThrusterTool( self, target )
    if !self:IsUnderLimit( "Thruster" ) then return end
    local world = random( 0, 1 )

    if !world and ( !IsValid( target ) or target:GetClass()=="gmod_thruster" ) then return end

    local trace = world and self:Trace( self:WorldSpaceCenter() + VectorRand( -12600, 12600 ) ) or self:Trace( target:WorldSpaceCenter() )
    local entity = trace.Entity
    local hitpos = trace.HitPos

    self:LookTo( hitpos, 2 )

    coroutine.wait( 1 )
    if !util_IsValidPhysicsObject( entity, trace.PhysicsBone ) or entity:GetClass() == "gmod_thruster" then return end -- Check to avoid placing thruster on things they can't be attached to

    local ang = trace.HitNormal:Angle()
    ang.pitch = ang.pitch + 90

    self:UseWeapon( hitpos )
    local ent = CreateGmodEntity( "gmod_thruster", thrustermodels[ random( #thrustermodels ) ], hitpos, ang, self )
    ent.LambdaOwner = self
    ent.IsLambdaSpawned = true
    self:ContributeEntToLimit( ent, "Thruster" )
    table_insert( self.l_SpawnedEntities, 1, ent )

    local min = ent:OBBMins()
    ent:SetPos( hitpos - trace.HitNormal * min.z )

    if entity != NULL and !entity:IsWorld() then -- Thruster spawned on world are not welded
        local const = constraint.Weld( ent, entity, 0, trace.PhysicsBone, 0, 0, true )
        if ( IsValid( ent:GetPhysicsObject() ) ) then ent:GetPhysicsObject():EnableCollisions( false ) end
        if random( 0 , 1 ) == 1 then -- Randomly can be nocollided or not to the attached prop
            ent:SetCollisionGroup( COLLISION_GROUP_WORLD )
            ent:GetPhysicsObject():SetMass( Clamp( ent:GetPhysicsObject():GetMass(), 1, 20 ) ) -- Let's avoid them being too heavy
        end
    end

    ent:SetPlayer( self )
    ent:SetEffect( thrustereffects[ random( #thrustereffects ) ] )
    ent:SetForce( random( 10000 ) )
    ent:SetToggle( true )
    ent:SetSound( thrustersounds[ random( #thrustersounds ) ] )

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





local function UseWeldTool( self, target )
    if !IsValid( target ) then return end

    local world = random( 5 ) == 1 --To avoid welding to the world too much by default
    local find = self:FindInSphere( nil, 800, function( ent ) if ent != target and !ent:IsNPC() and !ent:IsPlayer() and !ent:IsNextBot() and self:CanSee( ent ) and IsValid( ent:GetPhysicsObject() ) and self:HasPermissionToEdit( ent ) then return true end end )
    local target2 = find[ random( #find ) ]

    if !IsValid( target2 ) and !world then return end
    target2 = !world and target2 or Entity( 0 )

    local lpos1 = target:WorldToLocal( self:Trace( target:WorldSpaceCenter() ).HitPos )
    local lpos2 = !world and target2:WorldToLocal( self:Trace( target2:WorldSpaceCenter() ).HitPos ) or self:Trace( self:WorldSpaceCenter() + VectorRand( -126000, 126000 ) ).HitPos

    self:LookTo( target , 2 )

    coroutine.wait( 1 )
    if !IsValid( target ) then return end
    if !util_IsValidPhysicsObject( target, target:GetPhysicsObjectCount()-1 ) then return end

    self:UseWeapon( target:WorldSpaceCenter() )

    coroutine.wait( 0.3 )

    self:LookTo( ( !world and target2 or lpos2 ), 2 )

    coroutine.wait( 1 )
    if IsNil( target2 ) or IsNil( target ) then return end
    if !util_IsValidPhysicsObject( target2, target2:GetPhysicsObjectCount()-1 ) then return end

    self:UseWeapon( ( !world and target2:WorldSpaceCenter() or lpos2 ) )

    local cons = constraint.Weld( target, target2, 0, 0, 0, true, true )
    
    if cons then
        cons.LambdaOwner = self
        cons.IsLambdaSpawned = true
        table_insert( self.l_SpawnedEntities, 1, cons ) -- Lambda Players should be able to undo Welds like players
    end

    return true
end
AddToolFunctionToLambdaTools( "Weld", UseWeldTool )





local wheelmodels = { "models/props_vehicles/apc_tire001.mdl", "models/props_vehicles/tire001a_tractor.mdl", "models/props_vehicles/tire001b_truck.mdl", "models/props_vehicles/tire001c_car.mdl", "models/props_trainstation/trainstation_clock001.mdl", "models/props_c17/pulleywheels_large01.mdl", "models/props_junk/sawblade001a.mdl", "models/props_wasteland/controlroom_filecabinet002a.mdl", "models/props_borealis/bluebarrel001.mdl", "models/props_c17/oildrum001.mdl", "models/props_c17/playground_carousel01.mdl", "models/props_c17/chair_office01a.mdl", "models/props_c17/TrapPropeller_Blade.mdl", "models/props_junk/metal_paintcan001a.mdl", "models/props_vehicles/carparts_wheel01a.mdl", "models/props_wasteland/wheel01.mdl" }
local function UseWheelTool( self, target )
    if !self:IsUnderLimit( "Wheel" ) then return end
    local world = random( 0, 1 )

    if !world and !IsValid( target ) then return end

    local trace = world and self:Trace( self:WorldSpaceCenter() + VectorRand( -12600, 12600 ) ) or self:Trace( target:WorldSpaceCenter() )
    local hitpos = trace.HitPos
    local entity = trace.Entity
    local norm = trace.HitNormal
    local physbone = trace.PhysicsBone

    self:LookTo( hitpos , 2 )

    coroutine.wait( 1 )

    if !util_IsValidPhysicsObject( entity, physbone ) then return end

    local mdl = wheelmodels[ random( #wheelmodels ) ]
    local wheelAngTab = list.Get( "WheelModels" )[mdl]
    local wheelAngle = Angle( NormalizeAngle( wheelAngTab.wheel_rx ), NormalizeAngle( wheelAngTab.wheel_ry ), NormalizeAngle( wheelAngTab.wheel_rz ) )
    local torque = random( 10, 10000 )

    self:UseWeapon( hitpos )
    local ent = CreateGmodEntity( "gmod_wheel", mdl, hitpos, norm:Angle() + wheelAngle, self )
    ent.LambdaOwner = self
    ent.IsLambdaSpawned = true
    self:ContributeEntToLimit( ent, "Wheel" )
    table_insert( self.l_SpawnedEntities, 1, ent )

    local CurPos = ent:GetPos()
    local NearestPoint = ent:NearestPoint( CurPos - ( norm * 512 ) )
    local wheelOffset = CurPos - NearestPoint

    -- Set the hinge Axis perpendicular to the trace hit surface
    local targetPhys = entity:GetPhysicsObjectNum( physbone )
    local LPos1 = ent:GetPhysicsObject():WorldToLocal( ent:GetPos() + norm )
    local LPos2 = targetPhys:WorldToLocal( hitpos )
    ent:SetPos( hitpos + wheelOffset )

    local const = constraint.Motor( ent, entity, 0, physbone, LPos1, LPos2, random( 0, 100 ), torque, 0, random( 0, 1 ), 1 )

    ent:SetPlayer( self )
    ent:SetMotor( const )
    ent:SetDirection( const.direction )
    ent:SetAxis( norm )
    ent:SetBaseTorque(torque)
    ent:DoDirectionEffect()

    local rndtime = CurTime() + rand( 1, 10 )
    ent:LambdaHookTick( "WheelRandomOnOff", function( wheel )
        if CurTime() > rndtime then
            if !IsValid( wheel ) then return true end
            wheel:Forward( tobool( random( 0, 1 ) ) )-- Randomly switch it on or off

            rndtime = CurTime() + rand( 1, 10 )
        end
    end )

    return true
end
AddToolFunctionToLambdaTools( "Wheel", UseWheelTool )





-- Called when all default tools are loaded
-- This hook can be used to add custom tool functions by using AddToolFunctionToLambdaTools()
hook.Run( "LambdaOnToolsLoaded" )