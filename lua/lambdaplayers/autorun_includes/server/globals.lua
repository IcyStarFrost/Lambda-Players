local net = net
local IsValid = IsValid
local ipairs = ipairs
local string_StartWith = string.StartWith
local file_Find = file.Find
local table_Empty = table.Empty
local table_insert = table.insert

_LAMBDAPLAYERSFootstepMaterials = {
    [MAT_ANTLION] = {"physics/flesh/flesh_impact_hard1.wav","physics/flesh/flesh_impact_hard2.wav","physics/flesh/flesh_impact_hard3.wav","physics/flesh/flesh_impact_hard4.wav","physics/flesh/flesh_impact_hard5.wav","physics/flesh/flesh_impact_hard6.wav"},
    [MAT_BLOODYFLESH] = {"physics/flesh/flesh_impact_hard1.wav","physics/flesh/flesh_impact_hard2.wav","physics/flesh/flesh_impact_hard3.wav","physics/flesh/flesh_impact_hard4.wav","physics/flesh/flesh_impact_hard5.wav","physics/flesh/flesh_impact_hard6.wav"},
    [MAT_CONCRETE] = {"player/footsteps/concrete1.wav","player/footsteps/concrete2.wav","player/footsteps/concrete3.wav","player/footsteps/concrete4.wav"},
    [MAT_DIRT] = {"player/footsteps/dirt1.wav","player/footsteps/dirt2.wav","player/footsteps/dirt3.wav","player/footsteps/dirt4.wav"},
    [MAT_FLESH] = {"physics/flesh/flesh_impact_hard1.wav","physics/flesh/flesh_impact_hard2.wav","physics/flesh/flesh_impact_hard3.wav","physics/flesh/flesh_impact_hard4.wav","physics/flesh/flesh_impact_hard5.wav","physics/flesh/flesh_impact_hard6.wav"},
    [MAT_GRATE] = {"player/footsteps/metalgrate1.wav","player/footsteps/metalgrate2.wav","player/footsteps/metalgrate3.wav","player/footsteps/metalgrate4.wav"},
    [MAT_ALIENFLESH] = {"physics/flesh/flesh_impact_hard1.wav","physics/flesh/flesh_impact_hard2.wav","physics/flesh/flesh_impact_hard3.wav","physics/flesh/flesh_impact_hard4.wav","physics/flesh/flesh_impact_hard5.wav","physics/flesh/flesh_impact_hard6.wav"},
    [MAT_SNOW] = {"player/footsteps/sand1.wav","player/footsteps/sand2.wav","player/footsteps/sand3.wav","player/footsteps/sand4.wav"},
    [MAT_PLASTIC] = {"physics/plaster/drywall_footstep1.wav","physics/plaster/drywall_footstep2.wav","physics/plaster/drywall_footstep3.wav","physics/plaster/drywall_footstep4.wav"},
    [MAT_METAL] = {"player/footsteps/metal1.wav","player/footsteps/metal2.wav","player/footsteps/metal3.wav","player/footsteps/metal4.wav"},
    [MAT_SAND] = {"player/footsteps/sand1.wav","player/footsteps/sand2.wav","player/footsteps/sand3.wav","player/footsteps/sand4.wav"},
    [MAT_FOLIAGE] = {"player/footsteps/grass1.wav","player/footsteps/grass2.wav","player/footsteps/grass3.wav","player/footsteps/grass4.wav"},
    [MAT_COMPUTER] = {"physics/plaster/drywall_footstep1.wav","physics/plaster/drywall_footstep2.wav","physics/plaster/drywall_footstep3.wav","physics/plaster/drywall_footstep4.wav"},
    [MAT_SLOSH] = {"player/footsteps/slosh1.wav","player/footsteps/slosh2.wav","player/footsteps/slosh3.wav","player/footsteps/slosh4.wav"},
    [MAT_TILE] = {"player/footsteps/tile1.wav","player/footsteps/tile2.wav","player/footsteps/tile3.wav","player/footsteps/tile4.wav"},
    [MAT_GRASS] = {"player/footsteps/grass1.wav","player/footsteps/grass2.wav","player/footsteps/grass3.wav","player/footsteps/grass4.wav"},
    [MAT_VENT] = {"player/footsteps/duct1.wav","player/footsteps/duct2.wav","player/footsteps/duct3.wav","player/footsteps/duct4.wav"},
    [MAT_WOOD] = {"player/footsteps/wood1.wav","player/footsteps/wood2.wav","player/footsteps/wood3.wav","player/footsteps/wood4.wav","player/footsteps/woodpanel1.wav","player/footsteps/woodpanel2.wav","player/footsteps/woodpanel3.wav","player/footsteps/woodpanel4.wav"},
    [MAT_GLASS] = {"physics/glass/glass_sheet_step1.wav","physics/glass/glass_sheet_step2.wav","physics/glass/glass_sheet_step3.wav","physics/glass/glass_sheet_step4.wav"},
    [MAT_DEFAULT] = {"player/footsteps/concrete1.wav","player/footsteps/concrete2.wav","player/footsteps/concrete3.wav","player/footsteps/concrete4.wav"},
    [MAT_WARPSHIELD] = {"physics/glass/glass_sheet_step1.wav","physics/glass/glass_sheet_step2.wav","physics/glass/glass_sheet_step3.wav","physics/glass/glass_sheet_step4.wav"}
}

local foundSnow = false
for _, v in ipairs( file_Find( "sound/player/footsteps/*", "GAME" ) ) do
    if string_StartWith( v, "snow" ) then
        if !foundSnow then
            foundSnow = true
            table_Empty( _LAMBDAPLAYERSFootstepMaterials[ MAT_SNOW ] )
        end
        table_insert( _LAMBDAPLAYERSFootstepMaterials[ MAT_SNOW ], "player/footsteps/" .. v )
    end
end

_LAMBDAPLAYERSHoldTypeAnimations = {
    ["pistol"] = {
        idle = ACT_HL2MP_IDLE_PISTOL,
        run = ACT_HL2MP_RUN_PISTOL,
        walk = ACT_HL2MP_WALK_PISTOL,
        jump = ACT_HL2MP_JUMP_PISTOL,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_PISTOL,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_PISTOL,
        reload = ACT_HL2MP_GESTURE_RELOAD_PISTOL,
        swimIdle = ACT_HL2MP_SWIM_IDLE_PISTOL,
        swimMove = ACT_HL2MP_SWIM_PISTOL
    },
    ["smg"] = {
        idle = ACT_HL2MP_IDLE_SMG1,
        run = ACT_HL2MP_RUN_SMG1,
        walk = ACT_HL2MP_WALK_SMG1,
        jump = ACT_HL2MP_JUMP_SMG1,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_SMG1,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_SMG1,
        reload = ACT_HL2MP_GESTURE_RELOAD_SMG1,
        swimIdle = ACT_HL2MP_SWIM_IDLE_SMG1,
        swimMove = ACT_HL2MP_SWIM_SMG1
    },
    ["ar2"] = {
        idle = ACT_HL2MP_IDLE_AR2,
        run = ACT_HL2MP_RUN_AR2,
        walk = ACT_HL2MP_WALK_AR2,
        jump = ACT_HL2MP_JUMP_AR2,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_AR2,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_AR2,
        reload = ACT_HL2MP_GESTURE_RELOAD_AR2,
        swimIdle = ACT_HL2MP_SWIM_IDLE_AR2,
        swimMove = ACT_HL2MP_SWIM_AR2
    },
    ["shotgun"] = {
        idle = ACT_HL2MP_IDLE_SHOTGUN,
        run = ACT_HL2MP_RUN_SHOTGUN,
        walk = ACT_HL2MP_WALK_SHOTGUN,
        jump = ACT_HL2MP_JUMP_SHOTGUN,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_SHOTGUN,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_SHOTGUN,
        reload = ACT_HL2MP_GESTURE_RELOAD_SHOTGUN,
        swimIdle = ACT_HL2MP_SWIM_IDLE_SHOTGUN,
        swimMove = ACT_HL2MP_SWIM_SHOTGUN
    },
    ["revolver"] = {
        idle = ACT_HL2MP_IDLE_REVOLVER,
        run = ACT_HL2MP_RUN_REVOLVER,
        walk = ACT_HL2MP_WALK_REVOLVER,
        jump = ACT_HL2MP_JUMP_REVOLVER,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_REVOLVER,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_REVOLVER,
        reload = ACT_HL2MP_GESTURE_RELOAD_REVOLVER,
        swimIdle = ACT_HL2MP_SWIM_IDLE_REVOLVER,
        swimMove = ACT_HL2MP_SWIM_REVOLVER
    },
    ["melee"] = {
        idle = ACT_HL2MP_IDLE_MELEE,
        run = ACT_HL2MP_RUN_MELEE,
        walk = ACT_HL2MP_WALK_MELEE,
        jump = ACT_HL2MP_JUMP_MELEE,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_MELEE,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_MELEE,
        swimIdle = ACT_HL2MP_SWIM_IDLE_MELEE,
        swimMove = ACT_HL2MP_SWIM_MELEE
    },
    ["melee2"] = {
        idle = ACT_HL2MP_IDLE_MELEE2,
        run = ACT_HL2MP_RUN_MELEE2,
        walk = ACT_HL2MP_WALK_MELEE2,
        jump = ACT_HL2MP_JUMP_MELEE2,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_MELEE2,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_MELEE2,
        swimIdle = ACT_HL2MP_SWIM_IDLE_MELEE2,
        swimMove = ACT_HL2MP_SWIM_MELEE2
    },
    ["grenade"] = {
        idle = ACT_HL2MP_IDLE_GRENADE,
        run = ACT_HL2MP_RUN_GRENADE,
        walk = ACT_HL2MP_WALK_GRENADE,
        jump = ACT_HL2MP_JUMP_GRENADE,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_GRENADE,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_GRENADE,
        swimIdle = ACT_HL2MP_SWIM_IDLE_GRENADE,
        swimMove = ACT_HL2MP_SWIM_GRENADE
    },
    ["slam"] = {
        idle = ACT_HL2MP_IDLE_SLAM,
        run = ACT_HL2MP_RUN_SLAM,
        walk = ACT_HL2MP_WALK_SLAM,
        jump = ACT_HL2MP_JUMP_SLAM,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_SLAM,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_SLAM,
        swimIdle = ACT_HL2MP_SWIM_IDLE_SLAM,
        swimMove = ACT_HL2MP_SWIM_SLAM
    },
    ["normal"] = {
        idle = ACT_HL2MP_IDLE,
        run = ACT_HL2MP_RUN,
        walk = ACT_HL2MP_WALK,
        jump = ACT_HL2MP_JUMP_SLAM,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH,
        crouchWalk = ACT_HL2MP_WALK_CROUCH,
        swimIdle = ACT_HL2MP_SWIM_IDLE,
        swimMove = ACT_HL2MP_SWIM
    },
    ["rpg"] = {
        idle = ACT_HL2MP_IDLE_RPG,
        run = ACT_HL2MP_RUN_RPG,
        walk = ACT_HL2MP_WALK_RPG,
        jump = ACT_HL2MP_JUMP_RPG,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_RPG,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_RPG,
        swimIdle = ACT_HL2MP_SWIM_IDLE_RPG,
        swimMove = ACT_HL2MP_SWIM_RPG
    },
    ["fist"] = {
        idle = ACT_HL2MP_IDLE_FIST,
        run = ACT_HL2MP_RUN_FIST,
        walk = ACT_HL2MP_WALK_FIST,
        jump = ACT_HL2MP_JUMP_FIST,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_FIST,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_FIST,
        swimIdle = ACT_HL2MP_SWIM_IDLE_FIST,
        swimMove = ACT_HL2MP_SWIM_FIST
    },
    ["camera"] = {
        idle = ACT_HL2MP_IDLE_CAMERA,
        run = ACT_HL2MP_RUN_CAMERA,
        walk = ACT_HL2MP_WALK_CAMERA,
        jump = ACT_HL2MP_JUMP_CAMERA,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_CAMERA,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_CAMERA,
        swimIdle = ACT_HL2MP_SWIM_IDLE_CAMERA,
        swimMove = ACT_HL2MP_SWIM_CAMERA
    },
    ["duel"] = {
        idle = ACT_HL2MP_IDLE_DUEL,
        run = ACT_HL2MP_RUN_DUEL,
        walk = ACT_HL2MP_WALK_DUEL,
        jump = ACT_HL2MP_JUMP_DUEL,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_DUEL,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_DUEL,
        reload = ACT_HL2MP_GESTURE_RELOAD_DUEL,
        swimIdle = ACT_HL2MP_SWIM_IDLE_DUEL,
        swimMove = ACT_HL2MP_SWIM_DUEL
    },
    ["magic"] = {
        idle = ACT_HL2MP_IDLE_MAGIC,
        run = ACT_HL2MP_RUN_MAGIC,
        walk = ACT_HL2MP_WALK_MAGIC,
        jump = ACT_HL2MP_JUMP_MAGIC,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_MAGIC,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_MAGIC,
        swimIdle = ACT_HL2MP_SWIM_IDLE_MAGIC,
        swimMove = ACT_HL2MP_SWIM_MAGIC
    },
    ["physgun"] = {
        idle = ACT_HL2MP_IDLE_PHYSGUN,
        run = ACT_HL2MP_RUN_PHYSGUN,
        walk = ACT_HL2MP_WALK_PHYSGUN,
        jump = ACT_HL2MP_JUMP_PHYSGUN,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_PHYSGUN,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_PHYSGUN,
        swimIdle = ACT_HL2MP_SWIM_IDLE_PHYSGUN,
        swimMove = ACT_HL2MP_SWIM_PHYSGUN
    },
    ["zombie"] = {
        idle = ACT_HL2MP_IDLE_ZOMBIE,
        run = ACT_HL2MP_RUN_ZOMBIE,
        walk = ACT_HL2MP_WALK_ZOMBIE,
        jump = ACT_ZOMBIE_LEAPING,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_ZOMBIE,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_ZOMBIE_03,
        swimIdle = ACT_HL2MP_SWIM_IDLE_ZOMBIE,
        swimMove = ACT_ZOMBIE_LEAPING
    },
    ["knife"] = {
        idle = ACT_HL2MP_IDLE_KNIFE,
        run = ACT_HL2MP_RUN_KNIFE,
        walk = ACT_HL2MP_WALK_KNIFE,
        jump = ACT_HL2MP_JUMP_KNIFE,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_KNIFE,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_KNIFE,
        swimIdle = ACT_HL2MP_SWIM_IDLE_KNIFE,
        swimMove = ACT_HL2MP_SWIM_KNIFE
    },
    ["crossbow"] = {
        idle = ACT_HL2MP_IDLE_CROSSBOW,
        run = ACT_HL2MP_RUN_CROSSBOW,
        walk = ACT_HL2MP_WALK_CROSSBOW,
        jump = ACT_HL2MP_JUMP_CROSSBOW,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_CROSSBOW,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_CROSSBOW,
        reload = ACT_HL2MP_GESTURE_RELOAD_CROSSBOW,
        swimIdle = ACT_HL2MP_SWIM_IDLE_CROSSBOW,
        swimMove = ACT_HL2MP_SWIM_CROSSBOW
    },
    ["panic"] = {
        idle = ACT_HL2MP_IDLE_SCARED,
        run = ACT_HL2MP_RUN_PANICKED,
        walk = ACT_HL2MP_RUN_PANICKED,
        jump = ACT_HL2MP_JUMP_SLAM,
        crouchIdle = ACT_HL2MP_IDLE_SCARED,
        crouchWalk = ACT_HL2MP_RUN_PANICKED,
        swimIdle = ACT_HL2MP_SWIM_IDLE,
        swimMove = ACT_HL2MP_SWIM
    }
}


_LAMBDAPLAYERSEnemyRelations = {
    -- Half-Life 2
    [ "npc_combine_s" ] = true,
    [ "npc_metropolice" ] = true,
    [ "npc_zombie" ] = true,
    [ "npc_fastzombie" ] = true,
    [ "npc_fastzombie_torso" ] = true,
    [ "npc_headcrab_fast" ] = true,
    [ "npc_zombie_torso" ] = true,
    [ "npc_poisonzombie" ] = true,
    [ "npc_headcrab_black" ] = true,
    [ "npc_headcrab" ] = true,
    [ "npc_zombine" ] = true,
    [ "npc_antlion" ] = true,
    [ "npc_antlionguard" ] = true,
    [ "npc_antlionguardian" ] = true,
    [ "npc_antlion_worker" ] = true,
    [ "npc_manhack" ] = true,
    [ "npc_rollermine" ] = true,
    [ "npc_turret_floor" ] = true,
    [ "npc_turret_ceiling" ] = true,
    [ "npc_combine_camera" ] = true,
    [ "npc_combinegunship" ] = true,
    [ "npc_helicopter" ] = true,
    [ "npc_cscanner" ] = true,
    [ "npc_clawscanner" ] = true,
    [ "npc_hunter" ] = true,
    [ "npc_strider" ] = true,

    -- Half-Life: Source
    [ "monster_alien_grunt" ] = true,
    [ "monster_alien_slave" ] = true,
    [ "monster_human_assassin" ] = true,
    [ "monster_bullchicken" ] = true,
    [ "monster_alien_controller" ] = true,
    [ "monster_gargantua" ] = true,
    [ "monster_bigmomma" ] = true,
    [ "monster_human_grunt" ] = true,
    [ "monster_headcrab" ] = true,
    [ "monster_turret" ] = true,
    [ "monster_houndeye" ] = true,
    [ "monster_miniturret" ] = true,
    [ "monster_nihilanth" ] = true,
    [ "monster_sentry" ] = true,
    [ "monster_snark" ] = true,
    [ "monster_tentacle" ] = true,
    [ "monster_zombie" ] = true,
}


local min = math.min
_LAMBDAPLAYERSItemPickupFunctions = {
    [ "item_healthvial" ] = function( self, ent )
        if self:Health() >= self:GetMaxHealth() then return end
        self:SetHealth( min( self:Health() + 10, self:GetMaxHealth() ) )
        ent:EmitSound( "HealthKit.Touch" ); ent:Remove()
    end,
    [ "item_healthkit" ] = function( self, ent )
        if self:Health() >= self:GetMaxHealth() then return end
        self:SetHealth( min( self:Health() + 25, self:GetMaxHealth() ) )
        ent:EmitSound( "HealthKit.Touch" ); ent:Remove()
    end,
    [ "item_battery" ] = function( self, ent )
        if self:GetArmor() >= self:GetMaxArmor() then return end
        self:SetArmor( min( self:GetArmor() + 15, self:GetMaxArmor() ) )
        ent:EmitSound( "ItemBattery.Touch" ); ent:Remove()
    end,
    [ "sent_ball" ] = function( self, ent )
        self:SetHealth( self:Health() + 5 )
        ent:Remove()
    end,
    [ "hl1_item_healthkit" ] = function( self, ent )
        if self:Health() >= self:GetMaxHealth() then return end
        self:SetHealth( min( self:Health() + 25, self:GetMaxHealth() ) )
        ent:EmitSound( "HealthKit.Touch" ); ent:Remove()
    end,
    [ "hl1_item_battery" ] = function( self, ent )
        if self:GetArmor() >= self:GetMaxArmor() then return end
        self:SetArmor( min( self:GetArmor() + 15, self:GetMaxArmor() ) )
        ent:EmitSound( "Item.Pickup" ); ent:Remove()
    end
}

-- Adds a new item to pickup and use for Lambda Players
-- class = The class of an entity
-- func = A function to run as soon as the entity is picked up
function LambdaPlayers_AddItemPickup( class, func )
    _LAMBDAPLAYERSItemPickupFunctions[ class ] = func
end

--[[ Just an example of adding new item pickups:
    LambdaPlayers_AddItemPickup( "sent_vj_adminhealthkit", function( self, ent )
        self:LookTo( ent:GetPos(), 1 )
        self:SetHealth( self:Health() + 1000000 )
        ent:EmitSound( "HealthKit.Touch" ); ent:Remove()
    end )
]]


-- Sends a notification to the player
function LambdaPlayers_Notify( ply, text, notifynum, snd )
    if !IsValid( ply ) then return end
    net.Start( "lambdaplayers_notification" )
    net.WriteString( text )
    net.WriteUInt( notifynum or 0, 3 )
    net.WriteString( snd or "" )
    net.Send( ply )
end

local TableToJSON = util.TableToJSON

-- Sends a text message to a player or every player
function LambdaPlayers_ChatAdd( ply, ... )
    net.Start( "lambdaplayers_chatadd" )
    net.WriteString( TableToJSON( { ... } ) )
    if ply == nil then net.Broadcast() else net.Send( ply ) end
end

local FindByClass = ents.FindByClass
local table_Add = table.Add

-- Gets every possible spawn points 
function LambdaGetPossibleSpawns()
    local info_player_starts = FindByClass( "info_player_start" )
    local info_player_teamspawns = FindByClass( "info_player_teamspawn" )
    local info_player_terrorist = FindByClass( "info_player_terrorist" )
    local info_player_counterterrorist = FindByClass( "info_player_counterterrorist" )
    local info_player_combine = FindByClass( "info_player_combine" )
    local info_player_rebel = FindByClass( "info_player_rebel" )
    local info_player_allies = FindByClass( "info_player_allies" )
    local info_player_axis = FindByClass( "info_player_axis" )
    local info_coop_spawn = FindByClass( "info_coop_spawn" )
    local info_survivor_position = FindByClass( "info_survivor_position" )


    table_Add( info_player_starts, info_player_teamspawns )
    table_Add( info_player_starts, info_player_terrorist )
    table_Add( info_player_starts, info_player_counterterrorist )
    table_Add( info_player_starts, info_player_combine )
    table_Add( info_player_starts, info_player_rebel )
    table_Add( info_player_starts, info_player_allies )
    table_Add( info_player_starts, info_player_axis )
    table_Add( info_player_starts, info_coop_spawn )
    table_Add( info_player_starts, info_survivor_position )

    if #info_player_starts == 0 then ErrorNoHaltWithStack( "LAMBDA PLAYERS: ATTEMPT TO GET SPAWN POINTS IN A MAP WITH NO PLAYER SPAWNS!" ) end
    return info_player_starts
end

hook.Add( "InitPostEntity", "lambdaplayersgetspawns", function() LambdaSpawnPoints = LambdaGetPossibleSpawns() end )

-- Adds to the default killfeed
function LambdaKillFeedAdd( victim, attacker, inflictor )
    if !attacker:IsWorld() and !IsValid( attacker ) then return end 
        
    local victimname = ( ( victim.IsLambdaPlayer or victim:IsPlayer() ) and victim:Nick() or ( victim.IsZetaPlayer and victim.zetaname or "#" .. victim:GetClass() ) )
    local attackername = ( ( attacker.IsLambdaPlayer or attacker:IsPlayer() ) and attacker:Nick() or ( attacker.IsZetaPlayer and attacker.zetaname or "#" .. attacker:GetClass() ) )

    local victimteam = ( ( victim.IsLambdaPlayer or victim:IsPlayer() ) and victim:Team() or -1 )
    local attackerteam = ( ( attacker.IsLambdaPlayer or attacker:IsPlayer() ) and attacker:Team() or -1 )

    local attackerWep = attacker.GetActiveWeapon
    local inflictorname = ( !IsValid( inflictor ) and "suicide" or ( inflictor.IsLambdaWeapon and inflictor.l_killiconname or ( ( inflictor == attacker and attackerWep and IsValid( attackerWep( attacker ) ) ) and attackerWep( attacker ):GetClass() or inflictor:GetClass() ) ) )    

    net.Start( "lambdaplayers_addtokillfeed" )
        net.WriteString( attackername )
        net.WriteInt( attackerteam, 8 )
        net.WriteString( victimname )
        net.WriteInt( victimteam, 8 )
        net.WriteString( inflictorname )
    net.Broadcast()
end

-- Sprays the path relative to the materials folder to the position.
function LambdaPlayers_Spray( path, tracehitpos, tracehitnormal, index )
    net.Start( "lambdaplayers_spray" )
        net.WriteString( path )
        net.WriteVector( tracehitpos )
        net.WriteNormal( tracehitnormal )
        net.WriteUInt( index, 32 )
    net.Broadcast()
end

_LambdaPlayerBirthdays = {}

function LambdaGetPlayerBirthday( ply, callback )
    net.Start( "lambdaplayers_getplybirthday" )
    net.Send( ply )

    print( "Lambda Players: Requesting " .. ply:Name() .. "'s birthday.." )

    net.Receive( "lambdaplayers_returnplybirthday", function( len, ply )
        local month = net.ReadString()
        local day = net.ReadUInt( 5 )
        if month == "NIL" then print( "Lambda Players: " .. ply:Name() .. " has not set up their birthday for Lambda" ) return end
        print( "Lambda Players: Successfully received " .. ply:Name() .. "'s birthday!")
        callback( ply, month, day )
    end )
end

-- Called when Lambda's state is changed.
function LambdaPlayers_OnStateChanged( lambda, name, oldState, newState )
    if newState == oldState then return end
    lambda:DebugPrint( "Changed state from " .. oldState .. " to " .. newState )
    lambda:SetLastState( oldState )
end