
--[[ 

    VALID WEAPON SETTINGS

    Var name | TYPE | Description


    model | String | The model of the weapon
    prettyname | String | The name that will show in settings and ect
    nodraw | Bool | If the weapon should not draw
    islethal | Bool | If the weapon is capable of hurting anything
    holdtype | String | The animation set lambda should use. See globals.lua and the _LAMBDAPLAYERSHoldTypeAnimations table
    ismelee | Bool | If the weapon is considered a melee weapon. False for ranged
    keepdistance | Number | The distance the lambda will keep from the target
    attackrange | Number | The range the lambda can attack from
    damage  | Number | The amount of damage the weapon can deal
    rateoffire | Number | How fast the weapon is fired/used
    attackanim | Number | The ACT Gesture to play when used
    callback | function | A function that will be called when the weapon is used. Return true if you are making a custom shooting/swinging code
    OnEquip | function | A function that will be called when the weapon is equipped
    OnUnequip | function | a function that will be called when the weapon is unequipped
    bulletcount | Number | The amount of bullets to fire when used
    tracername | String | Tracer name. Valid entries are Tracer, AR2Tracer, LaserTracer, AirboatGunHeavyTracer, and ToolTracer
]]

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    NONE = {
        model = "models/hunter/plates/plate.mdl",
        prettyname = "Holster",
        holdtype = "normal",

        nodraw = true,

        islethal = false,

    }

})