-- Gmod's internal function for creating NPCs. Used by the Spawnmenu
-- We edit this function for Lambda Players

-- Lot's of changes have been done to this function. I personally do not like ( && over and ) and ( || over or )

local ents_Create = ents.Create
local random = math.random
local IsValid = IsValid

function LambdaInternalSpawnNPC( lambda, Position, Normal, Class, SpawnFlagsSaved )

	local NPCList = list.Get( "NPC" )
	local NPCData = NPCList[ Class ]

	if !NPCData then
		return
	end

	local bDropToFloor = false

	-- This NPC has to be spawned on a ceiling ( Barnacle )
	if NPCData.OnCeiling then
		if ( Vector( 0, 0, -1 ):Dot( Normal ) < 0.95 ) then
			return nil
		end

	-- This NPC has to be spawned on a floor ( Turrets )
	elseif NPCData.OnFloor and Vector( 0, 0, 1 ):Dot( Normal ) < 0.95 then
		return nil
	else
		bDropToFloor = true
	end

	if NPCData.NoDrop then bDropToFloor = false end

	-- Create NPC
	local NPC = ents_Create( NPCData.Class )
	if !IsValid( NPC ) then return end

	--
	-- Offset the position
	--
	local Offset = NPCData.Offset or 32
	NPC:SetPos( Position + Normal * Offset )

	-- Rotate to face player (expected behaviour)
	local Angles = Angle( 0, 0, 0 )

	if IsValid( lambda ) then
		Angles = lambda:GetAngles()
	end

	Angles.pitch = 0
	Angles.roll = 0
	Angles.yaw = Angles.yaw + 180

	if NPCData.Rotate then Angles = Angles + NPCData.Rotate end

	NPC:SetAngles( Angles )

	--
	-- This NPC has a special model we want to define
	--
	if NPCData.Model then
		NPC:SetModel( NPCData.Model )
	end

	--
	-- This NPC has a special texture we want to define
	--
	if NPCData.Material then
		NPC:SetMaterial( NPCData.Material )
	end

	--
	-- Spawn Flags
	--
	local SpawnFlags = bit.bor( SF_NPC_FADE_CORPSE, SF_NPC_ALWAYSTHINK )
	if NPCData.SpawnFlags then SpawnFlags = bit.bor( SpawnFlags, NPCData.SpawnFlags ) end
	if NPCData.TotalSpawnFlags then SpawnFlags = NPCData.TotalSpawnFlags end
	if SpawnFlagsSaved then SpawnFlags = SpawnFlagsSaved end
	NPC:SetKeyValue( "spawnflags", SpawnFlags )
	NPC.SpawnFlags = SpawnFlags

	--
	-- Optional Key Values
	--
	if NPCData.KeyValues then
		for k, v in pairs( NPCData.KeyValues ) do
			NPC:SetKeyValue( k, v )
		end
	end

	--
	-- This NPC has a special skin we want to define
	--
	if NPCData.Skin then
		NPC:SetSkin( NPCData.Skin )
	end

	--
	-- What weapon should this mother be carrying
	--
    

    local weaponlist = list.Get( "NPCUsableWeapons" )
    local chosenweapon = weaponlist[ random( #weaponlist ) ].class
	NPC:SetKeyValue( "additionalequipment", chosenweapon )
	NPC.Equipment = chosenweapon

	DoPropSpawnedEffect( NPC )

	NPC:Spawn()
	NPC:Activate()

	-- For those NPCs that set their model in Spawn function
	-- We have to keep the call above for NPCs that want a model set by Spawn() time
	-- BAD: They may adversly affect entity collision bounds
	if NPCData.Model and NPC:GetModel():lower() != NPCData.Model:lower() then
		NPC:SetModel( NPCData.Model )
	end

	if bDropToFloor then
		NPC:DropToFloor()
	end

	if NPCData.Health then
		NPC:SetHealth( NPCData.Health )
	end

	-- Body groups
	if NPCData.BodyGroups then
		for k, v in pairs( NPCData.BodyGroups ) do
			NPC:SetBodygroup( k, v )
		end
	end

	return NPC

end