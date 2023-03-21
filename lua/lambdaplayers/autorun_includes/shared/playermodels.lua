if ( CLIENT ) then return end

local table_remove = table.remove
local table_Copy = table.Copy
local table_RemoveByValue = table.RemoveByValue
local table_ClearKeys = table.ClearKeys
local table_Count = table.Count
local ipairs = ipairs
local PrecacheModel = util.PrecacheModel


function LambdaUpdatePlayerModels()
    local models = table_ClearKeys( table_Copy( player_manager.AllValidModels() ) )
    _LAMBDAPLAYERS_AllPlayermodels = models
    _LAMBDAPLAYERS_DefaultPlayermodels = {
        "models/player/alyx.mdl",
        "models/player/arctic.mdl",
        "models/player/barney.mdl",
        "models/player/breen.mdl",
        "models/player/charple.mdl",
        "models/player/combine_soldier.mdl",
        "models/player/combine_soldier_prisonguard.mdl",
        "models/player/combine_super_soldier.mdl",
        "models/player/corpse1.mdl",
        "models/player/dod_american.mdl",
        "models/player/dod_german.mdl",
        "models/player/eli.mdl",
        "models/player/gasmask.mdl",
        "models/player/gman_high.mdl",
        "models/player/guerilla.mdl",
        "models/player/kleiner.mdl",
        "models/player/leet.mdl",
        "models/player/odessa.mdl",
        "models/player/phoenix.mdl",
        "models/player/police.mdl",
        "models/player/police_fem.mdl",
        "models/player/riot.mdl",
        "models/player/skeleton.mdl",
        "models/player/soldier_stripped.mdl",
        "models/player/swat.mdl",
        "models/player/urban.mdl",
        "models/player/hostage/hostage_01.mdl",
        "models/player/hostage/hostage_02.mdl",
        "models/player/hostage/hostage_03.mdl",
        "models/player/hostage/hostage_04.mdl",
        "models/player/Group01/female_01.mdl",
        "models/player/Group01/female_02.mdl",
        "models/player/Group01/female_03.mdl",
        "models/player/Group01/female_04.mdl",
        "models/player/Group01/female_05.mdl",
        "models/player/Group01/female_06.mdl",
        "models/player/Group01/male_01.mdl",
        "models/player/Group01/male_02.mdl",
        "models/player/Group01/male_03.mdl",
        "models/player/Group01/male_04.mdl",
        "models/player/Group01/male_05.mdl",
        "models/player/Group01/male_06.mdl",
        "models/player/Group01/male_07.mdl",
        "models/player/Group01/male_08.mdl",
        "models/player/Group01/male_09.mdl",
        "models/player/Group02/male_02.mdl",
        "models/player/Group02/male_04.mdl",
        "models/player/Group02/male_06.mdl",
        "models/player/Group02/male_08.mdl",
        "models/player/Group03/female_01.mdl",
        "models/player/Group03/female_02.mdl",
        "models/player/Group03/female_03.mdl",
        "models/player/Group03/female_04.mdl",
        "models/player/Group03/female_05.mdl",
        "models/player/Group03/female_06.mdl",
        "models/player/Group03/male_01.mdl",
        "models/player/Group03/male_02.mdl",
        "models/player/Group03/male_03.mdl",
        "models/player/Group03/male_04.mdl",
        "models/player/Group03/male_05.mdl",
        "models/player/Group03/male_06.mdl",
        "models/player/Group03/male_07.mdl",
        "models/player/Group03/male_08.mdl",
        "models/player/Group03/male_09.mdl",
        "models/player/Group03m/female_01.mdl",
        "models/player/Group03m/female_02.mdl",
        "models/player/Group03m/female_03.mdl",
        "models/player/Group03m/female_04.mdl",
        "models/player/Group03m/female_05.mdl",
        "models/player/Group03m/female_06.mdl",
        "models/player/Group03m/male_01.mdl",
        "models/player/Group03m/male_02.mdl",
        "models/player/Group03m/male_03.mdl",
        "models/player/Group03m/male_04.mdl",
        "models/player/Group03m/male_05.mdl",
        "models/player/Group03m/male_06.mdl",
        "models/player/Group03m/male_07.mdl",
        "models/player/Group03m/male_08.mdl",
        "models/player/Group03m/male_09.mdl",
        "models/player/zombie_soldier.mdl",
        "models/player/p2_chell.mdl",
        "models/player/mossman.mdl",
        "models/player/mossman_arctic.mdl",
        "models/player/magnusson.mdl",
        "models/player/monk.mdl",
        "models/player/zombie_classic.mdl",
        "models/player/zombie_fast.mdl"
    }

    _LAMBDAPLAYERS_AddonPlayermodels = table_Copy( models )
    for _, v in ipairs( _LAMBDAPLAYERS_DefaultPlayermodels ) do
        PrecacheModel( v ) -- Precache every default model
        for k, j in ipairs( _LAMBDAPLAYERS_AddonPlayermodels ) do
            if j == v then table_remove( _LAMBDAPLAYERS_AddonPlayermodels, k ) end
        end
    end

    local blockdata = LAMBDAFS:ReadFile( "lambdaplayers/pmblockdata.json", "json" )

    if blockdata and istable( blockdata ) then
        for k, mdl in ipairs( blockdata ) do 
            table_RemoveByValue( _LAMBDAPLAYERS_DefaultPlayermodels, mdl )
            table_RemoveByValue( _LAMBDAPLAYERS_AddonPlayermodels, mdl )
            table_RemoveByValue( _LAMBDAPLAYERS_AllPlayermodels, mdl )
        end
    end

    local defaultcount = table_Count( _LAMBDAPLAYERS_DefaultPlayermodels )
    local allcount = table_Count( _LAMBDAPLAYERS_AllPlayermodels )
    local addoncount = table_Count( _LAMBDAPLAYERS_AddonPlayermodels )

    if defaultcount == 0 then 
        _LAMBDAPLAYERS_DefaultPlayermodels[ 1 ] = "models/player/kleiner.mdl"
        print( "Lambda Players Warning: All Default Playermodels were blocked! Adding Kleiner model to default models to prevent issues!")
    end

    if allcount == 0 then 
        _LAMBDAPLAYERS_DefaultPlayermodels[ 1 ] = "models/player/kleiner.mdl"
    end

    if addoncount == 0 then 
        _LAMBDAPLAYERS_AddonPlayermodels[ 1 ] = "models/player/kleiner.mdl"
        print( "Lambda Players Warning: All Playermodels were blocked! Adding Kleiner model to addon models to prevent issues!")
    end

end

hook.Add( "PostGamemodeLoaded", "lambdaplayers-loadplayermodels", LambdaUpdatePlayerModels )
