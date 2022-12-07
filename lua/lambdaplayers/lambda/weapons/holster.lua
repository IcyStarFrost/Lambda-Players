
--[[ 

    VALID WEAPON SETTINGS

    Var name        | TYPE |        Description


    --- Possible Melee settings ---

    model           | String |      The model of the weapon
    prettyname      | String |      The name that will show in settings and ect
    origin          | String |      The game or whatever the weapon originates from
    killicon        | String |      The file path to a material ( without the file extension ) to use as the kill icon for this weapon or the alias name of a existing kill icon, example weapon_ar2 is a existing kill icon    | OPTIONAL
    nodraw          | Bool |        If the weapon should not draw   | OPTIONAL
    islethal        | Bool |        If the weapon is capable of hurting anything
    holdtype        | String |      The animation set Lambda should use. See globals.lua and the _LAMBDAPLAYERSHoldTypeAnimations table
    ismelee         | Bool |        If the weapon is considered a melee weapon. False for ranged
    offpos          | Vector |      The offset position of the weapon local to the Lambda's considered hand position    | OPTIONAL
    offang          | Angle |       The offset angle of the weapon local to the Lambda  | OPTIONAL

    addspeed        | Number |      The amount to add to speed while in combat  | OPTIONAL
    keepdistance    | Number |      The distance the Lambda will keep from the target
    attackrange     | Number |      The range the Lambda can attack from
    damage          | Number |      The amount of damage the weapon can deal
    rateoffire      | Number |      How fast the weapon is fired/used
    attacksnd       | String |      The sound that will play when the weapon is used
    hitsnd          | String |      The sound that will play when the weapon hits our enemy
    attackanim      | Number |      The ACT Gesture to play when used

    OnDamage        | Function |    A function that will be called when the Lambda Player is hurt while holding this weapon | OPTIONAL
    Draw            | Function |    A client side function that allows you to make render effects in 3d space   | OPTIONAL
    callback        | Function |    A function that will be called when the weapon is used. Return true if you are making a custom shooting/swinging code   | OPTIONAL
    OnEquip         | Function |    A function that will be called when the weapon is equipped  | OPTIONAL
    OnUnequip       | Function |    A function that will be called when the weapon is unequipped    | OPTIONAL
    OnDrop          | Function |    A client side function that will be called when weapon's dropped prop is created | OPTIONAL
    OnThink         | Function |    A function that runs every tick on server while the weapon is held by Lambda Player. Returning a number in the function will add a cooldown | OPTIONAL



    ---------------------------------



    --- Possible Ranged Settings ---
    model           | String |      The model of the weapon
    prettyname      | String |      The name that will show in settings and ect
    origin          | String |      The game or whatever the weapon originates from
    killicon        | String |      The file path to a material ( without the file extension ) to use as the kill icon for this weapon or the alias name of a existing kill icon, example weapon_ar2 is a existing kill icon    | OPTIONAL
    nodraw          | Bool |        If the weapon should not draw   | OPTIONAL
    islethal        | Bool |        If the weapon is capable of hurting anything
    holdtype        | String |      The animation set Lambda should use. See autorun_includes/server/globals.lua and the _LAMBDAPLAYERSHoldTypeAnimations table
    ismelee         | Bool |        If the weapon is considered a melee weapon. False for ranged
    offpos          | Vector |      The offset position of the weapon local to the Lambda's considered hand position    | OPTIONAL
    offang          | Angle |       The offset angle of the weapon local to the Lambda  | OPTIONAL

    addspeed        | Number |      The amount to add to speed while in combat
    keepdistance    | Number |      The distance the Lambda will keep from the target
    attackrange     | Number |      The range the Lambda can attack from
    damage          | Number |      The amount of damage the weapon can deal
    rateoffire      | Number |      How fast the weapon is fired/used
    attackanim      | Number |      The ACT Gesture to play when used
    bulletcount     | Number |      The amount of bullets to fire when used
    attacksnd       | String |      The sound that will play when the weapon is fired
    tracername      | String |      Tracer name. Valid entries are Tracer, AR2Tracer, LaserTracer, AirboatGunHeavyTracer, and ToolTracer
    clip            | Number |      The amount of times the weapon can be shot before reloading.

    muzzleflash     | Number |      The muzzle flash type. 1 = Regular 5 = Combine 7 = Regular but bigger   | OPTIONAL
    muzzleoffpos    | Vector |      The offset postion of the muzzleflash local to the weapon   | OPTIONAL
    muzzleoffang    | Angle |       The offset angle of the muzzleflash local to the weapon | OPTIONAL

    shelleject      | String |      Shell type valid types are ShellEject, RifleShellEject, ShotgunShellEject    | OPTIONAL
    shelloffpos     | Vector |      The offset postion of the shell eject local to the weapon   | OPTIONAL
    shelloffang     | Angle |       The offset angles of the shell eject local to the weapon    | OPTIONAL

    reloadtime      | Number |      The time it takes to reload
    reloadanim      | Number |      Reload Gesture animation
    reloadanimspeed | Number |      The speed of the reload animation   | OPTIONAL
    reloadsounds    | Table |       A table of tables that each have their 1 index as the time the sound will play and the 2 index being the sound path. Example reloadsounds = { { 0.5, "somesound1" }, { 1, "somesound2" } }  | OPTIONAL
   
    OnDamage        | Function |    A function that will be called when the Lambda Player is hurt while holding this weapon | OPTIONAL
    Draw            | Function |    A client side function that allows you to make render effects in 3d space   | OPTIONAL
    callback        | Function |    A function that will be called when the weapon is used. Return true if you are making a custom shooting/swinging code   | OPTIONAL
    OnEquip         | Function |    A function that will be called when the weapon is equipped  | OPTIONAL
    OnUnequip       | Function |    A function that will be called when the weapon is unequipped    | OPTIONAL
    OnReload        | Function |    A function that will be called when the weapon's reload is started  | OPTIONAL
    OnDrop          | Function |    A client side function that will be called when weapon's dropped prop is created | OPTIONAL
    OnThink         | Function |    A function that runs every tick on server while the weapon is held by Lambda Player. Returning a number in the function will add a cooldown | OPTIONAL

    ---------------------------------
]]

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    none = {
        model = "models/hunter/plates/plate.mdl",
        origin = "Misc",
        prettyname = "Holster",
        holdtype = "normal",

        nodraw = true,

        islethal = false,

    }

})