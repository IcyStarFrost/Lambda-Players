
_LAMBDAPLAYERSDEFAULTMDLS = {
    'models/player/alyx.mdl',
    'models/player/arctic.mdl',
    'models/player/barney.mdl',
    'models/player/breen.mdl',
    'models/player/charple.mdl',
    'models/player/combine_soldier.mdl',
    'models/player/combine_soldier_prisonguard.mdl',
    'models/player/combine_super_soldier.mdl',
    'models/player/corpse1.mdl',
    'models/player/dod_american.mdl',
    'models/player/dod_german.mdl',
    'models/player/eli.mdl',
    'models/player/gasmask.mdl',
    'models/player/gman_high.mdl',
    'models/player/guerilla.mdl',
    'models/player/kleiner.mdl',
    'models/player/leet.mdl',
    'models/player/odessa.mdl',
    'models/player/phoenix.mdl',
    'models/player/police.mdl',
    'models/player/riot.mdl',
    'models/player/skeleton.mdl',
    'models/player/soldier_stripped.mdl',
    'models/player/swat.mdl',
    'models/player/urban.mdl',
    'models/player/group01/female_01.mdl',
    'models/player/group01/female_02.mdl',
    'models/player/group01/female_03.mdl',
    'models/player/group01/female_04.mdl',
    'models/player/group01/female_05.mdl',
    'models/player/group01/female_06.mdl',
    'models/player/group01/male_01.mdl',
    'models/player/group01/male_02.mdl',
    'models/player/group01/male_03.mdl',
    'models/player/group01/male_04.mdl',
    'models/player/group01/male_05.mdl',
    'models/player/group01/male_06.mdl',
    'models/player/group01/male_07.mdl',
    'models/player/group01/male_08.mdl',
    'models/player/group01/male_09.mdl',
    'models/player/group02/male_02.mdl',
    'models/player/group02/male_04.mdl',
    'models/player/group02/male_06.mdl',
    'models/player/group02/male_08.mdl',
    'models/player/group03/female_01.mdl',
    'models/player/group03/female_02.mdl',
    'models/player/group03/female_03.mdl',
    'models/player/group03/female_04.mdl',
    'models/player/group03/female_05.mdl',
    'models/player/group03/female_06.mdl',
    'models/player/group03/male_01.mdl',
    'models/player/group03/male_02.mdl',
    'models/player/group03/male_03.mdl',
    'models/player/group03/male_04.mdl',
    'models/player/group03/male_05.mdl',
    'models/player/group03/male_06.mdl',
    'models/player/group03/male_07.mdl',
    'models/player/group03/male_08.mdl',
    'models/player/group03/male_09.mdl',
    'models/player/group03m/female_01.mdl',
    'models/player/group03m/female_02.mdl',
    'models/player/group03m/female_03.mdl',
    'models/player/group03m/female_04.mdl',
    'models/player/group03m/female_05.mdl',
    'models/player/group03m/female_06.mdl',
    'models/player/group03m/male_01.mdl',
    'models/player/group03m/male_02.mdl',
    'models/player/group03m/male_03.mdl',
    'models/player/group03m/male_04.mdl',
    'models/player/group03m/male_05.mdl',
    'models/player/group03m/male_06.mdl',
    'models/player/group03m/male_07.mdl',
    'models/player/group03m/male_08.mdl',
    'models/player/group03m/male_09.mdl',
    "models/player/zombie_soldier.mdl",
    "models/player/p2_chell.mdl",
    "models/player/mossman.mdl",
    "models/player/mossman_arctic.mdl",
    "models/player/magnusson.mdl",
    "models/player/monk.mdl",
    "models/player/zombie_fast.mdl"
}

for k, v in ipairs( _LAMBDAPLAYERSDEFAULTMDLS ) do
    util.PrecacheModel( v )
end

local table_Copy = table.Copy
local table_ClearKeys = table.ClearKeys
local models = table_Copy( player_manager.AllValidModels() )
_LAMBDAPLAYERS_Allplayermodels = table_ClearKeys( models )


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

_LAMBDAPLAYERSHoldTypeAnimations = {
    ["pistol"] = {
        idle = ACT_HL2MP_IDLE_PISTOL,
        run = ACT_HL2MP_RUN_PISTOL,
        walk = ACT_HL2MP_WALK_PISTOL,
        jump = ACT_HL2MP_JUMP_PISTOL,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_PISTOL,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_PISTOL
    },
    ["smg"] = {
        idle = ACT_HL2MP_IDLE_SMG1,
        run = ACT_HL2MP_RUN_SMG1,
        walk = ACT_HL2MP_WALK_SMG1,
        jump = ACT_HL2MP_JUMP_SMG1,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_SMG1,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_SMG1
    },
    ["ar2"] = {
        idle = ACT_HL2MP_IDLE_AR2,
        run = ACT_HL2MP_RUN_AR2,
        walk = ACT_HL2MP_WALK_AR2,
        jump = ACT_HL2MP_JUMP_AR2,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_AR2,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_AR2
    },
    ["shotgun"] = {
        idle = ACT_HL2MP_IDLE_SHOTGUN,
        run = ACT_HL2MP_RUN_SHOTGUN,
        walk = ACT_HL2MP_WALK_SHOTGUN,
        jump = ACT_HL2MP_JUMP_SHOTGUN,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_SHOTGUN,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_SHOTGUN
    },
    ["revolver"] = {
        idle = ACT_HL2MP_IDLE_REVOLVER,
        run = ACT_HL2MP_RUN_REVOLVER,
        walk = ACT_HL2MP_WALK_REVOLVER,
        jump = ACT_HL2MP_JUMP_REVOLVER,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_REVOLVER,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_REVOLVER
    },
    ["melee"] = {
        idle = ACT_HL2MP_IDLE_MELEE,
        run = ACT_HL2MP_RUN_MELEE,
        walk = ACT_HL2MP_WALK_MELEE,
        jump = ACT_HL2MP_JUMP_MELEE,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_MELEE,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_MELEE
    },
    ["melee2"] = {
        idle = ACT_HL2MP_IDLE_MELEE2,
        run = ACT_HL2MP_RUN_MELEE2,
        walk = ACT_HL2MP_WALK_MELEE2,
        jump = ACT_HL2MP_JUMP_MELEE2,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_MELEE2,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_MELEE2
    },
    ["grenade"] = {
        idle = ACT_HL2MP_IDLE_GRENADE,
        run = ACT_HL2MP_RUN_GRENADE,
        walk = ACT_HL2MP_WALK_GRENADE,
        jump = ACT_HL2MP_JUMP_GRENADE,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_GRENADE,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_GRENADE
    },
    ["slam"] = {
        idle = ACT_HL2MP_IDLE_SLAM,
        run = ACT_HL2MP_RUN_SLAM,
        walk = ACT_HL2MP_WALK_SLAM,
        jump = ACT_HL2MP_JUMP_SLAM,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_SLAM,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_SLAM
    },
    ["normal"] = {
        idle = ACT_HL2MP_IDLE,
        run = ACT_HL2MP_RUN,
        walk = ACT_HL2MP_WALK,
        jump = ACT_HL2MP_JUMP_SLAM,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH,
        crouchWalk = ACT_HL2MP_WALK_CROUCH
    },
    ["rpg"] = {
        idle = ACT_HL2MP_IDLE_RPG,
        run = ACT_HL2MP_RUN_RPG,
        walk = ACT_HL2MP_WALK_RPG,
        jump = ACT_HL2MP_JUMP_RPG,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_RPG,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_RPG
    },
    ["fist"] = {
        idle = ACT_HL2MP_IDLE_FIST,
        run = ACT_HL2MP_RUN_FIST,
        walk = ACT_HL2MP_WALK_FIST,
        jump = ACT_HL2MP_JUMP_FIST,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_FIST,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_FIST
    },
    ["camera"] = {
        idle = ACT_HL2MP_IDLE_CAMERA,
        run = ACT_HL2MP_RUN_CAMERA,
        walk = ACT_HL2MP_WALK_CAMERA,
        jump = ACT_HL2MP_JUMP_CAMERA,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_CAMERA,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_CAMERA
    },
    ["duel"] = {
        idle = ACT_HL2MP_IDLE_DUEL,
        run = ACT_HL2MP_RUN_DUEL,
        walk = ACT_HL2MP_WALK_DUEL,
        jump = ACT_HL2MP_JUMP_DUEL,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_DUEL,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_DUEL
    },
    ["magic"] = {
        idle = ACT_HL2MP_IDLE_MAGIC,
        run = ACT_HL2MP_RUN_MAGIC,
        walk = ACT_HL2MP_WALK_MAGIC,
        jump = ACT_HL2MP_JUMP_MAGIC,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_MAGIC,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_MAGIC
    },
    ["physgun"] = {
        idle = ACT_HL2MP_IDLE_PHYSGUN,
        run = ACT_HL2MP_RUN_PHYSGUN,
        walk = ACT_HL2MP_WALK_PHYSGUN,
        jump = ACT_HL2MP_JUMP_PHYSGUN,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_PHYSGUN,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_PHYSGUN
    },
    ["zombie"] = {
        idle = ACT_HL2MP_IDLE_ZOMBIE,
        run = ACT_HL2MP_RUN_ZOMBIE,
        walk = ACT_HL2MP_WALK_ZOMBIE,
        jump = ACT_ZOMBIE_LEAPING,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_ZOMBIE,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_ZOMBIE_03
    },
    ["knife"] = {
        idle = ACT_HL2MP_IDLE_KNIFE,
        run = ACT_HL2MP_RUN_KNIFE,
        walk = ACT_HL2MP_WALK_KNIFE,
        jump = ACT_HL2MP_JUMP_KNIFE,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_KNIFE,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_KNIFE
    },
    ["crossbow"] = {
        idle = ACT_HL2MP_IDLE_CROSSBOW,
        run = ACT_HL2MP_RUN_CROSSBOW,
        walk = ACT_HL2MP_WALK_CROSSBOW,
        jump = ACT_HL2MP_JUMP_CROSSBOW,
        crouchIdle = ACT_HL2MP_IDLE_CROUCH_CROSSBOW,
        crouchWalk = ACT_HL2MP_WALK_CROUCH_CROSSBOW
    }
}


_LAMBDAPLAYERSEnemyRelations = {
    
    ['npc_combine_s'] = true,
    ['npc_metropolice'] = true,
    ['npc_zombie'] = true,
    ['npc_fastzombie'] = true,
    ['npc_fastzombie_torso'] = true,
    ['npc_headcrab_fast'] = true,
    ['npc_zombie_torso'] = true,
    ['npc_poisonzombie'] = true,
    ['npc_headcrab_black'] = true,
    ['npc_headcrab'] = true,
    ['npc_zombine'] = true,
    ['npc_antlion'] = true,
    ['npc_antlionguard'] = true,
    ['npc_antlionguardian'] = true,
    ['npc_antlion_worker'] = true,
    ['npc_manhack'] = true,
    ['npc_rollermine'] = true,
    ['npc_turret_floor'] = true,
    ['npc_turret_ceiling'] = true,
    ['npc_combine_camera'] = true,
    ['npc_combinegunship'] = true,
    ['npc_helicopter'] = true,
    ['npc_cscanner'] = true,
    ['npc_clawscanner'] = true,
    ['npc_hunter'] = true,
    ['npc_strider'] = true,


  }


function LambdaPlayers_Notify( ply, text, notifynum, snd )
    if !IsValid( ply ) then return end
    net.Start( "lambdaplayers_notification" )
    net.WriteString( text )
    net.WriteUInt( notifynum or NOTIFY_GENERIC, 3 )
    net.WriteString( snd or "" )
    net.Send( ply )
end

local TableToJSON = util.TableToJSON
function LambdaPlayers_ChatAdd( ply, ... )
    net.Start( "lambdaplayers_chatadd" )
    net.WriteString( TableToJSON( { ... } ) )
    if ply == nil then net.Broadcast() else net.Send( ply ) end
end


local FindByClass = ents.FindByClass
local table_Add = table.Add
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
    table_Add(info_player_starts,info_player_teamspawns)
    table_Add(info_player_starts,info_player_terrorist)
    table_Add(info_player_starts,info_player_counterterrorist)
    table_Add(info_player_starts,info_player_combine)
    table_Add(info_player_starts,info_player_rebel)
    table_Add(info_player_starts,info_player_allies)
    table_Add(info_player_starts,info_player_axis)
    table_Add(info_player_starts,info_coop_spawn)
    table_Add(info_player_starts,info_survivor_position)
    return info_player_starts
end

hook.Add( "InitPostEntity", "lambdaplayersgetspawns", function() LambdaSpawnPoints = LambdaGetPossibleSpawns() end )


function LambdaKillFeedAdd( victim, attacker, inflictor )
    local attackername = attacker.IsLambdaPlayer and attacker:GetLambdaName() or attacker.IsZetaPlayer and attacker.zetaname or attacker:IsPlayer() and attacker:Name() or "#" .. attacker:GetClass()
    local victimname = victim.IsLambdaPlayer and victim:GetLambdaName() or victim.IsZetaPlayer and victim.zetaname or victim:IsPlayer() and victim:Name() or "#" .. victim:GetClass()
    local inflictorname = IsValid( inflictor ) and ( ( inflictor.IsLambdaWeapon and inflictor.l_killiconname ) or ( inflictor == attacker and IsValid( attacker ) and attacker.GetActiveWeapon and IsValid( attacker:GetActiveWeapon() ) and attacker:GetActiveWeapon():GetClass() ) or IsValid( inflictor ) and inflictor:GetClass() ) or "suicide"
    local attackerteam = attacker.IsLambdaPlayer and 0 or attacker:IsPlayer() and attacker:Team() or -1
    local victimteam = victim.IsLambdaPlayer and 0 or victim:IsPlayer() and victim:Team() or -1

    net.Start( "lambdaplayers_addtokillfeed" )
        net.WriteString( attackername )
        net.WriteInt( attackerteam, 8 )
        net.WriteString( victimname )
        net.WriteInt( victimteam, 8 )
        net.WriteString( inflictorname )
    net.Broadcast()
end