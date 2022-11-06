
--[[ 

    VALID WEAPON SETTINGS

    Var name | TYPE | Description


    --- Possible Melee settings ---

    model | String | The model of the weapon
    prettyname | String | The name that will show in settings and ect
    origin | String | The game or whatever the weapon originates from
    nodraw | Bool | If the weapon should not draw
    islethal | Bool | If the weapon is capable of hurting anything
    holdtype | String | The animation set lambda should use. See globals.lua and the _LAMBDAPLAYERSHoldTypeAnimations table
    ismelee | Bool | If the weapon is considered a melee weapon. False for ranged
    keepdistance | Number | The distance the lambda will keep from the target
    attackrange | Number | The range the lambda can attack from
    damage  | Number | The amount of damage the weapon can deal
    rateoffire | Number | How fast the weapon is fired/used
    attackanim | Number | The ACT Gesture to play when used
    Draw | Function | A Client side function that allows you to make render effects in 3d space
    callback | function | A function that will be called when the weapon is used. Return true if you are making a custom shooting/swinging code
    OnEquip | function | A function that will be called when the weapon is equipped
    OnUnequip | function | a function that will be called when the weapon is unequipped




    ---------------------------------


    --- Possible Ranged Settings ---
    model | String | The model of the weapon
    prettyname | String | The name that will show in settings and ect
    origin | String | The game or whatever the weapon originates from
    nodraw | Bool | If the weapon should not draw
    islethal | Bool | If the weapon is capable of hurting anything
    holdtype | String | The animation set lambda should use. See globals.lua and the _LAMBDAPLAYERSHoldTypeAnimations table
    ismelee | Bool | If the weapon is considered a melee weapon. False for ranged
    keepdistance | Number | The distance the lambda will keep from the target
    attackrange | Number | The range the lambda can attack from
    damage  | Number | The amount of damage the weapon can deal
    rateoffire | Number | How fast the weapon is fired/used
    attackanim | Number | The ACT Gesture to play when used
    Draw | Function | A Client side function that allows you to make render effects in 3d space
    callback | function | A function that will be called when the weapon is used. Return true if you are making a custom shooting/swinging code
    OnEquip | function | A function that will be called when the weapon is equipped
    OnUnequip | function | a function that will be called when the weapon is unequipped
    bulletcount | Number | The amount of bullets to fire when used
    tracername | String | Tracer name. Valid entries are Tracer, AR2Tracer, LaserTracer, AirboatGunHeavyTracer, and ToolTracer
    clip | Number | The amount of times the weapon can be shot before reloading.
    muzzleflash | Number | The muzzle flash type. 1 = Regular 5 = Combine 7 = Regular but bigger
    shelleject | String | Shell type valid types are ShellEject, RifleShellEject, ShotgunShellEject
            

    reloadtime | Number | The time it takes to reload
    reloadanim | Number | Reload Gesture animation
    reloadanimationspeed | Number | The speed of the reload animation
    reloadsounds | Table | A table of tables that each have their 1 index as the time the sound will play and the 2 index being the sound path. Example reloadsounds = { { 0.5, "somesound1" }, { 1, "somesound2" } }

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