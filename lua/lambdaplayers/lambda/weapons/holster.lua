
--[[ 

    VALID WEAPON SETTINGS

    Var name | TYPE | Description


    model | String | The model of the weapon
    nodraw | Bool | If the weapon should not draw
    islethal | Bool | If the weapon is capable of hurting anything
    holdtype | String | The animation set lambda should use. See globals.lua and the _LAMBDAPLAYERSHoldTypeAnimations table

 ]]

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    NONE = {
        model = "models/hunter/plates/plate.mdl",
        holdtype = "normal",

        nodraw = true,

        islethal = false,

    }

})