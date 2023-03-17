
--[[ 

    VALID WEAPON SETTINGS

    Var name        | TYPE |        Description


    --- Possible Melee settings ---

    model           | String |          The model of the weapon
    prettyname      | String |          The name that will show in settings and ect
    origin          | String |          The game or whatever the weapon originates from
    killicon        | String |          The file path to a material ( without the file extension ) to use as the kill icon for this weapon or the alias name of a existing kill icon, example weapon_ar2 is a existing kill icon    | OPTIONAL
    nodraw          | Bool |            If the weapon should not draw   | OPTIONAL
    islethal        | Bool |            If the weapon is capable of hurting anything
    bonemerge       | Bool |            If the weapon should be bone merged if possible  | OPTIONAL
    holdtype        | String or Table | The animation set Lambda should use. Can be either a string or a table with animations. See globals.lua and the _LAMBDAPLAYERSHoldTypeAnimations table
    ismelee         | Bool |            If the weapon is considered a melee weapon. False for ranged
    offpos          | Vector |          The offset position of the weapon local to the Lambda's considered hand position    | OPTIONAL
    offang          | Angle |           The offset angle of the weapon local to the Lambda's considered hand angle  | OPTIONAL
    weaponscale     | Number |          The multiplier on scaling the Lambda's weapon model size. NOTE! This will NOT work while bonemerge is set true!   | OPTIONAL

    deploydelay     | Number |          Time delay before Lambda starts using the weapon after equiping it
    speedmultiplier | Number |          Multiplies the Lambda's movement speed to this value while the weapon is held
    keepdistance    | Number |          The distance the Lambda will keep from the target
    attackrange     | Number |          The range the Lambda can attack from
    damage          | Number |          The amount of damage the weapon can deal
    rateoffire      | Number |          How fast the weapon is fired/used in seconds
    rateoffiremin   | Number |          The minimum amount of time this weapon can be fired/used. These two are used to make random fire delays  Won't work if the normal rateoffire variable is set    | OPTIONAL
    rateoffiremax   | Number |          The maximum amount of time this weapon can be fired/used. These two are used to make random fire delays. Won't work if the normal rateoffire variable is set     | OPTIONAL
    attacksnd       | String |          The sound that will play when the weapon is used
    hitsnd          | String |          The sound that will play when the weapon hits our enemy
    attackanim      | Number |          The ACT Gesture to play when used

    SERVERSIDE | OnTakeDamage( Entity lambda, Entity wepent, DMGINFO dmginfo )                                                  | Function |    A function that will be called when the Lambda Player is taking damage while holding this weapon. Return true to block dealing damage | OPTIONAL
    CLIENTSIDE | OnDraw( Entity lambda, Entity wepent )                                                                         | Function |    A function that allows you to make render effects in 3D space | OPTIONAL
    SERVERSIDE | OnAttack( Entity lambda, Entity wepent, Entity target )                                                        | Function |    A function that will be called when the weapon is used. Return true if you are making a custom shooting/swinging code | OPTIONAL
    SERVERSIDE | OnDeploy( Entity lambda, Entity wepent )                                                                       | Function |    A function that will be called when the weapon is equipped by the Lambda Player | OPTIONAL
    SERVERSIDE | OnHolster( Entity lambda, Entity wepent, String oldWep, String newWep )                                        | Function |    A function that will be called when the weapon being unequipped by the Lambda Player. Return true to prevent Lambda Player from holstering this weapon | OPTIONAL
    CLIENTSIDE | OnDrop( Entity lambda, Entity wepent, Entity cs_prop )                                                         | Function |    A function that will be called when weapon's dropped prop is created | OPTIONAL
    SERVERSIDE | OnThink( Entity lambda, Entity wepent, Bool dead )                                                             | Function |    A function that runs everytime while this weapon is currently held by the Lambda Player. Returning any positive number in the function will add a cooldown | OPTIONAL 
    SERVERSIDE | OnDeath( Entity lambda, Entity wepent, DMGINFO dmginfo )                                                       | Function |    A function that will be called when the Lambda Player dies while holding this weapon | OPTIONAL
    SERVERSIDE | OnDealDamage( Entity lambda, Entity wepent, Entity target, DMGINFO dmginfo, Bool dealtDamage, Bool lethal )    | Function |    A function that will be called when the Lambda Player deals damage to something with this weapon | OPTIONAL



    ---------------------------------



    --- Possible Ranged Settings ---
    model           | String |          The model of the weapon
    prettyname      | String |          The name that will show in settings and ect
    origin          | String |          The game or whatever the weapon originates from
    killicon        | String |          The file path to a material ( without the file extension ) to use as the kill icon for this weapon or the alias name of a existing kill icon, example weapon_ar2 is a existing kill icon    | OPTIONAL
    nodraw          | Bool |            If the weapon should not draw   | OPTIONAL
    islethal        | Bool |            If the weapon is capable of hurting anything
    bonemerge       | Bool |            If the weapon should be bone merged if possible  | OPTIONAL
    holdtype        | String or Table | The animation set Lambda should use. Can be either a string or a table with animations. See globals.lua and the _LAMBDAPLAYERSHoldTypeAnimations table
    ismelee         | Bool |            If the weapon is considered a melee weapon. False for ranged
    offpos          | Vector |          The offset position of the weapon local to the Lambda's considered hand position    | OPTIONAL
    offang          | Angle |           The offset angle of the weapon local to the Lambda's considered hand angle  | OPTIONAL
    weaponscale     | Number |          The multiplier on scaling the Lambda's weapon model size. NOTE! This will NOT work while bonemerge is set true!   | OPTIONAL

    deploydelay     | Number |          Time delay before Lambda starts using the weapon after equiping it
    speedmultiplier | Number |          Multiplies the Lambda's movement speed to this value while the weapon is held
    keepdistance    | Number |          The distance the Lambda will keep from the target
    attackrange     | Number |          The range the Lambda can attack from
    damage          | Number |          The amount of damage the weapon can deal
    rateoffire      | Number |          How fast the weapon is fired/used in seconds
    rateoffiremin   | Number |          The minimum amount of time this weapon can be fired/used. These two are used to make random fire delays  Won't work if the normal rateoffire variable is set    | OPTIONAL
    rateoffiremax   | Number |          The maximum amount of time this weapon can be fired/used. These two are used to make random fire delays. Won't work if the normal rateoffire variable is set     | OPTIONAL
    attackanim      | Number |          The ACT Gesture to play when used
    bulletcount     | Number |          The amount of bullets to fire when used
    attacksnd       | String |          The sound that will play when the weapon is fired
    tracername      | String |          Tracer name. Valid entries are Tracer, AR2Tracer, LaserTracer, AirboatGunHeavyTracer, and ToolTracer
    clip            | Number |          The amount of times the weapon can be shot before reloading.

    muzzleflash     | Number |          The muzzle flash type. 1 = Regular 5 = Combine 7 = Regular but bigger   | OPTIONAL
    muzzleoffpos    | Vector |          The offset postion of the muzzleflash local to the weapon   | OPTIONAL
    muzzleoffang    | Angle |           The offset angle of the muzzleflash local to the weapon | OPTIONAL

    shelleject      | String |          Shell type valid types are ShellEject, RifleShellEject, ShotgunShellEject    | OPTIONAL
    shelloffpos     | Vector |          The offset postion of the shell eject local to the weapon   | OPTIONAL
    shelloffang     | Angle |           The offset angles of the shell eject local to the weapon    | OPTIONAL

    reloadtime      | Number |          The time it takes to reload
    reloadanim      | Number |          Reload Gesture animation
    reloadanimspeed | Number |          The speed of the reload animation   | OPTIONAL
    reloadsounds    | Table |           A table of tables that each have their 1 index as the time the sound will play and the 2 index being the sound path. Example reloadsounds = { { 0.5, "somesound1" }, { 1, "somesound2" } }  | OPTIONAL

    CLIENTSIDE | OnDraw( Entity lambda, Entity wepent )                                                                         | Function |    A function that allows you to make render effects in 3D space | OPTIONAL
    SERVERSIDE | OnAttack( Entity lambda, Entity wepent, Entity target )                                                        | Function |    A function that will be called when the weapon is used. Return true if you are making a custom shooting/swinging code | OPTIONAL
    SERVERSIDE | OnDeploy( Entity lambda, Entity wepent )                                                                       | Function |    A function that will be called when the weapon is equipped by the Lambda Player | OPTIONAL
    SERVERSIDE | OnHolster( Entity lambda, Entity wepent, String oldWep, String newWep )                                        | Function |    A function that will be called when the weapon being unequipped by the Lambda Player. Return true to prevent Lambda Player from holstering this weapon | OPTIONAL
    CLIENTSIDE | OnDrop( Entity lambda, Entity wepent, Entity cs_prop )                                                         | Function |    A function that will be called when weapon's dropped prop is created | OPTIONAL
    SERVERSIDE | OnThink( Entity lambda, Entity wepent, Bool dead )                                                             | Function |    A function that runs everytime while this weapon is currently held by the Lambda Player. Returning any positive number in the function will add a cooldown | OPTIONAL 
    SERVERSIDE | OnReload( Entity lambda, Entity wepent )                                                                       | Function |    A function that will be called when this weapon's reload is started. Return true if you are making a custom reloading code | OPTIONAL
    SERVERSIDE | OnDeath( Entity lambda, Entity wepent, DMGINFO dmginfo )                                                       | Function |    A function that will be called when the Lambda Player dies while holding this weapon | OPTIONAL
    SERVERSIDE | OnDealDamage( Entity lambda, Entity wepent, Entity target, DMGINFO dmginfo, Bool dealtDamage, Bool lethal )    | Function |    A function that will be called when the Lambda Player deals damage to something with this weapon | OPTIONAL

    ---------------------------------
]]

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    none = {
        model = "models/hunter/plates/plate.mdl",
        origin = "Misc",
        prettyname = "Holster",
        holdtype = "normal",

        nodraw = true,
        dropondeath = false,
        islethal = false,
    }
} )