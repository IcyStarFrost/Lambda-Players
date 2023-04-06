local IsValid = IsValid
local random = math.random
local math_min = math.min
local util_Effect = util.Effect
local tracetbl = {}

-- Effects for gravity gun idle
local ggunGlowSprite = Material("sprites/glow04_noz")

-- Effects for pulling and grabbing active
--local ggunCapSprite = Material("sprites/orangeflare1")
--local ggunCoreSprite = Material("sprites/orangecore1")

local punted = false
local blastStart, smoothBlast, smoothBlastA = 0, 0, 255
local blastTarget = false
local color = Color(255,255,255,255)
local attachtab = { "fork1m", "fork1t", "fork2m", "fork2t", "fork3m", "fork3t" }

local LerpVector = LerpVector
local Angle = Angle
local random = math.random
local min = math.min
local max = math.max
local lambda = nil
local wepDmgScale = GetConVar( "lambdaplayers_combat_weapondmgmultiplier" )

local propGrabbed = false 
local canShoot = false

local pickables = {
    [ "prop_physics" ] = true,
    --[ "gb_bomb_sc100" ] = true,
    --[ "grenade_helicopter" ] = true,
    --[ "sent_tnt" ] = true,
}
local spawnableProps = {
	
    "models/props_c17/oildrum001_explosive.mdl",
	"models/props_c17/oildrum001.mdl",
	"models/props_c17/FurnitureRadiator001a.mdl",
	"models/props_c17/FurnitureChair001a.mdl",
	"models/props_c17/canister01a.mdl",
	"models/props_c17/canister_propane01a.mdl",
	"models/Combine_Helicopter/helicopter_bomb01.mdl",
	"models/props_interiors/Furniture_Couch02a.mdl",
	"models/props_junk/sawblade001a.mdl",
	"models/props_junk/gascan001a.mdl",
	"models/props_junk/CinderBlock01a.mdl",
	"models/props_junk/harpoon002a.mdl",
	"models/props_junk/PopCan01a.mdl",
	"models/props_junk/metal_paintcan001a.mdl",
	"models/props_junk/propane_tank001a.mdl",
	"models/props_junk/PropaneCanister001a.mdl",
	"models/props_junk/TrafficCone001a.mdl",
	"models/props_junk/wood_crate001a.mdl",
	"models/props_junk/wood_crate002a.mdl",
	"models/props_junk/wood_pallet001a.mdl",
	"models/props_lab/filecabinet02.mdl",
	"models/props_trainstation/BenchOutdoor01a.mdl",
	"models/props_trainstation/TrackSign02.mdl",
	"models/props_trainstation/trainstation_post001.mdl",
	"models/props_trainstation/trashcan_indoor001b.mdl",
	"models/props_vehicles/tire001a_tractor.mdl",
	"models/props_vehicles/tire001c_car.mdl",
	"models/props_wasteland/barricade001a.mdl",
	"models/props_wasteland/barricade002a.mdl",
	"models/props_wasteland/kitchen_counter001b.mdl",
	"models/props_junk/watermelon01.mdl",
	"models/props_junk/terracotta01.mdl",
	"models/props_lab/cactus.mdl",
	"models/props_combine/breenbust.mdl",
	"models/props_interiors/Furniture_chair01a.mdl",
	"models/props_interiors/Furniture_Desk01a.mdl",
	"models/props_junk/GlassBottle01a.mdl",
	"models/props_junk/garbage_coffeemug001a.mdl",
	"models/props_junk/garbage_metalcan002a.mdl",
	"models/props_junk/bicycle01a.mdl",
	"models/props_wasteland/prison_toilet01.mdl",
}


local function SpawnProp(self)
	if !self:IsUnderLimit( "Prop" ) then self:UndoLastSpawnedEnt() end
	local mdl = spawnableProps[ random( #spawnableProps ) ]

	if !mdl then return end

	self:EmitSound( "ui/buttonclickrelease.wav", 60 )

	local prop = ents.Create( "prop_physics" )
	prop:SetPos( self:GetPos() + self:GetForward()*25 )
	prop:SetAngles( Angle( 0, self:GetAngles()[ 2 ], 0 ) )
	prop:SetModel( mdl )
	prop.selfOwner = self
	prop.IsselfSpawned = true
	prop:Spawn()
	DoPropSpawnedEffect( prop ) -- Make the prop do the spawn effect

	local mins = prop:GetModelBounds()
	local proppos = prop:GetPos()
	proppos[ 3 ] = proppos[ 3 ] - mins[ 3 ]
	prop:SetPos( proppos )

	self:DebugPrint( "spawned a prop while fighting ", prop )

	self:ContributeEntToLimit( prop, "Prop" )
	table.insert( self.l_SpawnedEntities, 1, prop )
	return prop
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    gravgun = {
        model = "models/weapons/w_physics.mdl",
        origin = "Half-Life 2",
        prettyname = "Gravity Gun",
        killicon = "weapon_physcannon", -- No idea if this is needed but why not
        bonemerge = true,
        holdtype = "physgun",
        keepdistance = 500,
        attackrange = 600,
		
        OnDraw = function( lambda, wepent )
			
			lambda = lambda
            if IsValid( wepent ) then
                for i = 1, #attachtab do
                    local atID = wepent:LookupAttachment( attachtab[i] )
                    if atID == -1 or atID == 0 then return end

                    local at = wepent:GetAttachment( atID )
                    render.SetMaterial( ggunGlowSprite )
                    render.DrawSprite( at.Pos, 6, 6, Color(255, 128, 0, 64) )
                end

                -- For pulling and grabbing active effect
                --[[render.SetMaterial( ggunCapSprite )
                render.DrawSprite( wepent:GetAttachment( wepent:LookupAttachment( "fork1t" ) ).Pos, size, size, Color(255,255,255,255) )
                render.DrawSprite( wepent:GetAttachment( wepent:LookupAttachment( "fork2t" ) ).Pos, size, size, Color(255,255,255,255) )
                render.DrawSprite( wepent:GetAttachment( wepent:LookupAttachment( "fork3t" ) ).Pos, size, size, Color(255,255,255,255) )
                
                render.SetMaterial( ggunCoreSprite )
                render.DrawSprite( wepent:GetAttachment( wepent:LookupAttachment( "core" ) ).Pos, 13, 13, Color(255,255,255,255) )
                ]]
			end
		end,
		
		
        OnDeploy = function( lambda, wepent )
			propGrabbed = false
			canShoot = false
			lambda.attachedProp = nil
			
			lambda:Thread( function() -- Look for props and pick em up, or spawn some if there are none nearby.

				while true do
					
					
					-- Check that we don't have a prop (it may have been destroyed)
					-- Important to keep this up here so we can benefeit from coroutine.wait()
					if (!IsValid(lambda.attachedProp)) then
						propGrabbed = false
					end
					
					
					-- We don't have a prop
					if propGrabbed == false then
						print("we don't have a prop")
						
						-- Find a prop around us to pick it up
						local find = lambda:FindInSphere( lambda:GetPos(), 150, function( ent ) if !ent:IsNPC() and ent:GetClass() == "prop_physics" and !ent:IsPlayer() and !ent:IsNextBot() and lambda:CanSee( ent ) and IsValid( ent:GetPhysicsObject() ) and lambda:HasPermissionToEdit( ent ) and ent:GetPhysicsObject():IsMoveable() then return true end end )
						local prop = find[ random( #find ) ]
						
						-- We couldn't find a prop, spawn one
						if prop == nil then prop = SpawnProp(lambda) end 
						
						-- Still no prop, abort
						if prop == nil then continue end
						
						-- Ignore prop if it doesn't have a physics object
						if (prop:GetPhysicsObject() == nil) then continue end
						-- If the prop is frozen, ignore it
						if (prop:GetPhysicsObject():IsMotionEnabled() == false) then continue end
						-- If the prop is not in the normal collision group (another bot has it, for example), ignore it
						if (prop:GetCollisionGroup() != 0) then prop = nil end 
						
						
						
						if IsValid(prop) and prop != nil then
							-- Short delay between spawning the prop and picking it up
							lambda:LookTo( prop, 0.5 )
							
							-- Check if prop is still valid
							if IsValid(prop) and prop != nil then 
								-- Set this prop as ours
								lambda.attachedProp = prop
								-- Unfreeze prop just in case
								lambda.attachedProp:GetPhysicsObject():EnableMotion( true )
								-- Set the prop's collision group so it doesn't collide with the world and causes constant bot deaths
								lambda.attachedProp:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
								-- Set ourselves as having a prop
								propGrabbed = true
								print("we have a prop now")
								print(propGrabbed)
								print(lambda.attachedProp)
								-- Shorten combat distances as we're ready to pummel others!
								keepdistance = 100
								attackrange = 500
								canShoot = true
							end
						end
					end
					
					
					-- while loop delay, don't remove this if you don't like freezing
					coroutine.wait(1)
				end
			end, "PhysgunThread" )
			
			-- Hook that keeps the grabbed prop attached to the lambda
			lambda:Hook( "Think", "physgunthink", function()
				-- Check validity of prop while we have it
				if IsValid( lambda.attachedProp ) and propGrabbed == true then
					-- Set prop's position
					lambda.attachedProp:GetPhysicsObject():SetPos(lambda:GetPos() + lambda:GetForward() * 75 + lambda:GetUp() * 36)
				end
			end )
        end,

        OnHolster = function( lambda, wepent )
			-- Reset prop's collision groups
			if IsValid(lambda.attachedProp) and (lambda.attachedProp != nil) then lambda.attachedProp:SetCollisionGroup(COLLISION_GROUP_NONE) end
			lambda.attachedProp = nil
            lambda:KillThread( "PhysgunThread" )
			propGrabbed = false
			canShoot = false
			keepdistance = 500
			attackrange = 600
        end,
		
		
        OnAttack = function( self, wepent, target )
		
			-- Weapon cooldown
			self.l_WeaponUseCooldown = CurTime() + 1
			-- Look at our next victim >:)
			self:LookTo( target, 1)
		
		
			if canShoot == true then
				print("we're shooting a prop")
				
				-- Check for prop integrity and if we're carrying one
				if IsValid( self.attachedProp ) and self.attachedProp != nil and propGrabbed == true then
				
					wepent:EmitSound( "weapons/physcannon/superphys_launch"..random( 1, 4 )..".wav", 70, random( 110, 120 ) )

					local mainPhys = self.attachedProp:GetPhysicsObject()
					local trace = self:Trace( self.attachedProp:WorldSpaceCenter() )
					local randt1 = self:Trace( self.attachedProp:WorldSpaceCenter() + VectorRand(-5, 15) )

					mainPhys:ApplyForceCenter( self:GetAimVector() * (100000*wepDmgScale:GetFloat()) + self:GetUp()*2500)

					local core = wepent:GetAttachment( wepent:LookupAttachment( "core" ) )


					self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_PHYSGUN )
					self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_PHYSGUN )
					-- Reset prop weapon group
					if IsValid(self.attachedProp) and (self.attachedProp != nil) then self.attachedProp:SetCollisionGroup(COLLISION_GROUP_NONE) end
					-- Unset the prop as ours
					self.attachedProp = nil
					-- We are no longer carrying a prop
					propGrabbed = false
					print("prop was shot")
				else
					wepent:EmitSound( "weapons/physcannon/physcannon_dryfire.wav", 70 )
				end
				return true
			end
        end,

        islethal = true

    }

})
