LambdaSupportedSweps = {}
_LAMBDAWEAPONCLASSANDPRINTS = {}

-- classorbase      | String |      The weapon class name or base name to register. Registering a base will include every weapon that derives from the base
-- origin           | String |          Where the weapons come from
-- islethal         | String |          if the weapon is lethal
-- handlefunction   | Function |        The function used to setup Combat data for Lambda

function LambdaRegisterSWEP( classorbase, origin, islethal, handlefunction )
    local IsBase = string.find( classorbase, "base" )

    if IsBase then

        for k, v in ipairs( weapons.GetList() ) do
            if weapons.IsBasedOn( v.ClassName, classorbase ) and !string.find( v.ClassName, "base" ) then

                local convar = CreateLambdaConvar( "lambdaplayers_weapons_allow" .. v.ClassName, 1, true, false, false, "Allows the Lambda Players to equip " .. v.PrintName, 0, 1 )
                _LAMBDAWEAPONALLOWCONVARS[ v.ClassName ] = convar

                _LAMBDAPLAYERSWEAPONS[ v.ClassName ] = { origin = origin, prettyname = "[" .. origin .. "] " .. v.PrintName, islethal = islethal }

                LambdaSupportedSweps[ v.ClassName ] = { handlefunction }
                if CLIENT then _LAMBDAPLAYERSWEAPONORIGINS[ origin ] = origin end
            end
        end

    else
        local weptbl = weapons.Get( classorbase )

        if !weptbl then return end

        local convar = CreateLambdaConvar( "lambdaplayers_weapons_allow" .. classorbase, 1, true, false, false, "Allows the Lambda Players to equip " .. weptbl.PrintName, 0, 1 )
        _LAMBDAWEAPONALLOWCONVARS[ classorbase ] = convar

        _LAMBDAPLAYERSWEAPONS[ classorbase ] = { origin = origin, prettyname = "[" .. origin .. "] " .. weptbl.PrintName, islethal = islethal }
        
        LambdaSupportedSweps[ classorbase ] = { handlefunction }
        if CLIENT then _LAMBDAPLAYERSWEAPONORIGINS[ origin ] = origin end
    end


end


-- These functions are called when the weapon is equipped. We use this to pretty much configure the Lambda's combat 
local function HandleARCCW( self, wep )

    -- The variables below are important

    self.l_HasLethal = true -- If the weapon is lethal
    self.l_HasMelee = false -- If the weapon is a melee weapon
    self.l_CombatKeepDistance = 400 -- How far to stay away from the target
    self.l_CombatAttackRange = 5000 -- How far to shoot from
    self.l_WeaponSpeedMultiplier = 1 -- How much to multiply our movement speed
    self.l_swepreloadtime = wep.Animations[ "reload_empty" ] and wep.Animations[ "reload_empty" ].Time or wep.Animations[ "reload" ] and wep.Animations[ "reload" ].Time or 1.5 -- The time it will take to reload the weapon
    self.l_swepspread = wep:GetNPCBulletSpread( WEAPON_PROFICIENCY_VERY_GOOD ) -- The spread in degrees
    wep:NPC_Initialize()
    wep:NPC_SetupAttachments() -- Attachment stuff
    wep:AddEffects( EF_BONEMERGE ) -- The weapons from ARCCW typically can be bone merged

end

local function HandleM9k( self, wep )

    -- Simple to set up M9k as well

    self.l_HasLethal = true
    self.l_HasMelee = false
    self.l_CombatKeepDistance = 400
    self.l_CombatAttackRange = 5000 
    self.l_WeaponSpeedMultiplier = 1
    self.l_swepreloadtime = 2
    self.l_swepspread = wep.Primary.Spread + 2
    
end


local canmerge = GetConVar( "lambdaplayers_lambda_allowswepmerging" )
local function LoadSWEPS()

    if canmerge:GetBool() then
        LambdaRegisterSWEP( "arccw_base", "ARCCW", true, HandleARCCW )
        LambdaRegisterSWEP( "bobs_gun_base", "M9k", true, HandleM9k )
        hook.Run( "LambdaOnRegisterSWEPS" )
        print( "Lambda Players: Registered all supported SWEPS")
    end


    for k, v in pairs( _LAMBDAPLAYERSWEAPONS ) do
        _LAMBDAWEAPONCLASSANDPRINTS[ v.prettyname ] = k
    end
    
    CreateLambdaConvar( "lambdaplayers_lambda_spawnweapon", "physgun", true, true, true, "The weapon Lambda Players will spawn with only if the specified weapon is allowed", 0, 1, { type = "Combo", options = _LAMBDAWEAPONCLASSANDPRINTS, name = "Spawn Weapon", category = "Lambda Player Settings" } )
    
end


LoadSWEPS()

