-- Functions below are gmod's function for creating entities. Used by the spawnmenu
-- We edit these functions for Lambda Players
-- The comments below not made by me (StarFrost)


local Trace = util.TraceLine
local Vector = Vector
local pairs = pairs
local tracetable = {}
local list = list
local scripted_ents = scripted_ents
local ents_Create = ents.Create

-- A little hacky function to help prevent spawning props partially inside walls
-- Maybe it should use physics object bounds, not OBB, and use physics object bounds to initial position too
local function fixupProp( lambda, ent, hitpos, mins, maxs )
	local entPos = ent:GetPos()
	local endposD = ent:LocalToWorld( mins )
	
	tracetable.start = entPos
	tracetable.endpos = endposD
	tracetable.filter = { ent, lambda }

    local tr_down = Trace( tracetable )

	local endposU = ent:LocalToWorld( maxs )
	
	tracetable.start = entPos
	tracetable.endpos = endposU
	tracetable.filter = { ent, lambda }

    local tr_up = Trace( tracetable)

	-- Both traces hit meaning we are probably inside a wall on both sides, do nothing
	if ( tr_up.Hit and tr_down.Hit ) then return end

	if ( tr_down.Hit ) then ent:SetPos( entPos + ( tr_down.HitPos - endposD ) ) end
	if ( tr_up.Hit ) then ent:SetPos( entPos + ( tr_up.HitPos - endposU ) ) end
end

local function TryFixPropPosition( lambda, ent, hitpos )
	fixupProp( lambda, ent, hitpos, Vector( ent:OBBMins().x, 0, 0 ), Vector( ent:OBBMaxs().x, 0, 0 ) )
	fixupProp( lambda, ent, hitpos, Vector( 0, ent:OBBMins().y, 0 ), Vector( 0, ent:OBBMaxs().y, 0 ) )
	fixupProp( lambda, ent, hitpos, Vector( 0, 0, ent:OBBMins().z ), Vector( 0, 0, ent:OBBMaxs().z ) )
end

function LambdaSpawn_SENT( ply, EntityName, tr )

	local entity = nil
	local PrintName = nil
	local sent = scripted_ents.GetStored( EntityName )

	if ( sent ) then

		local sent = sent.t

		ClassName = EntityName

			local SpawnFunction = scripted_ents.GetMember( EntityName, "SpawnFunction" )
			if ( !SpawnFunction ) then return end -- Fallback to default behavior below?

			entity = SpawnFunction( sent, ply, tr, EntityName )

			if ( IsValid( entity ) ) then
				entity:SetCreator( ply )
			end

		ClassName = nil

		PrintName = sent.PrintName

	else

		-- Spawn from list table
		local SpawnableEntities = list.Get( "SpawnableEntities" )
		if ( !SpawnableEntities ) then return end

		local EntTable = SpawnableEntities[ EntityName ]
		if ( !EntTable ) then return end

		PrintName = EntTable.PrintName

		local SpawnPos = tr.HitPos + tr.HitNormal * 16
		if ( EntTable.NormalOffset ) then SpawnPos = SpawnPos + tr.HitNormal * EntTable.NormalOffset end

		-- Make sure the spawn position is not out of bounds
		
		tracetable.start = tr.HitPos
		tracetable.endpos = SpawnPos
		tracetable.mask = MASK_SOLID_BRUSHONLY
        local oobTr = Trace( tracetable )

		if ( oobTr.Hit ) then
			SpawnPos = oobTr.HitPos + oobTr.HitNormal * ( tr.HitPos:Distance( oobTr.HitPos ) / 2 )
		end

		entity = ents_Create( EntTable.ClassName )
		entity:SetPos( SpawnPos )

		if ( EntTable.KeyValues ) then
			for k, v in pairs( EntTable.KeyValues ) do
				entity:SetKeyValue( k, v )
			end
		end

		if ( EntTable.Material ) then
			entity:SetMaterial( EntTable.Material )
		end

		entity:Spawn()
		entity:Activate()

		DoPropSpawnedEffect( entity )

		if ( EntTable.DropToFloor ) then
			entity:DropToFloor()
		end

	end

	if ( !IsValid( entity ) ) then return end

	TryFixPropPosition( ply, entity, tr.HitPos )
	
    entity:SetVar( "Player", lambda )

    return entity
end