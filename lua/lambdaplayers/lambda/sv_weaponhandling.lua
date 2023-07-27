local EffectData = EffectData
local IsFirstTimePredicted = IsFirstTimePredicted
local isfunction = isfunction
local istable = istable
local isstring = isstring
local random = math.random
local RandomPairs = RandomPairs
local Rand = math.Rand
local ipairs = ipairs
local Effect = util.Effect
local CurTime = CurTime
local string_find = string.find

function ENT:WeaponDataExists( weaponname )
    return _LAMBDAPLAYERSWEAPONS[ weaponname ] != nil
end

-- Switch to a weapon with the provided name.
-- See the lambda/weapons folder for weapons. Check out the holster.lua file to see the current valid weapon settings
function ENT:SwitchWeapon( weaponname, forceswitch )
    if !self:CanEquipWeapon( weaponname ) and !forceswitch or self.l_NoWeaponSwitch then return end
    if !self:WeaponDataExists( weaponname ) then return end
    local wepent = self:GetWeaponENT()
    
    local oldweaponname = self.l_Weapon
    local oldwepdata = _LAMBDAPLAYERSWEAPONS[ oldweaponname ]
    if oldwepdata then 
        local onHolsterFunc = ( oldwepdata.OnHolster or oldwepdata.OnUnequip )
        if onHolsterFunc and onHolsterFunc( self, wepent, oldweaponname, weaponname ) == true then return end
    end

    local weapondata = _LAMBDAPLAYERSWEAPONS[ weaponname ]

    self.l_Weapon = weaponname
    self.l_WeaponOrigin = weapondata.origin
    self:SetNW2String( "lambda_spawnweapon", weaponname )
    self:SetNW2String( "lambda_weaponprettyname", weapondata.notagprettyname )
    self.l_WeaponPrettyName = weapondata.notagprettyname
    self.l_HasLethal = weapondata.islethal
    self.l_HasMelee = weapondata.ismelee 
    self.l_HoldType = weapondata.holdtype or "normal"
    self.l_CombatKeepDistance = weapondata.keepdistance
    self.l_CombatAttackRange = weapondata.attackrange
    self.l_OnDamagefunction = ( weapondata.OnTakeDamage or weapondata.OnDamage )
    self.l_OnDeathfunction = weapondata.OnDeath
    self.l_OnDealDamagefunction = weapondata.OnDealDamage
    self.l_WeaponNoDraw = weapondata.nodraw or false
    self.l_WeaponSpeedMultiplier = weapondata.speedmultiplier or 1
    self.l_Clip = weapondata.clip or 0
    self.l_MaxClip = weapondata.clip or 0
    self.l_WeaponUseCooldown = CurTime() + ( weapondata.deploydelay or 0.1 )
    self.l_DropWeaponOnDeath = ( weapondata.dropondeath == nil and true or weapondata.dropondeath )
    self.l_WeaponThinkFunction = CurTime()
    self.l_WeaponDropEntity = weapondata.dropentity

    local killicon_ = weapondata.killicon
    if killicon_ then
        local ispath = string_find( killicon_, "/" )
        if ispath then
            wepent.l_killiconname = "lambdaplayers_weaponkillicons_" .. weaponname
        else
            wepent.l_killiconname = killicon_
        end
    else
        wepent.l_killiconname = nil
    end

    self:ClientSideNoDraw( self.WeaponEnt, weapondata.nodraw )
    
    local drawFunc = ( weapondata.OnDraw or weapondata.Draw )
    self:SetHasCustomDrawFunction( isfunction( drawFunc ) )

    self:SetWeaponName( weaponname )
    wepent:SetNoDraw( weapondata.nodraw )
    wepent:DrawShadow( !weapondata.nodraw )

    wepent:SetLocalPos( weapondata.offpos or vector_origin )
    wepent:SetLocalAngles( weapondata.offang or angle_zero )

    wepent:SetModel( weapondata.model )
    wepent:SetModelScale( ( weapondata.weaponscale or 1 ), 0 )

    if weapondata.bonemerge then 
        wepent:AddEffects( EF_BONEMERGE ) 
    else 
        wepent:RemoveEffects( EF_BONEMERGE ) 
    end

    self.l_WeaponThinkFunction = weapondata.OnThink

    local onDeployFunc = ( weapondata.OnDeploy or weapondata.OnEquip )
    if onDeployFunc then onDeployFunc( self, wepent ) end

    local deploySnd = weapondata.deploysound
    if deploySnd then
        if istable( deploySnd ) then
            for _, tbl in ipairs( snds ) do
                self:SimpleWeaponTimer( tbl[ 1 ], function()
                    wep:EmitSound( tbl[ 2 ], 65, 100, 1, CHAN_WEAPON )
                end )
            end
        else
            wep:EmitSound( deploySnd, 65, 100, 1, CHAN_WEAPON )
        end
    end

    self:SetIsReloading( false )

    LambdaRunHook( "LambdaOnSwitchWeapon", self, wepent, weapondata )
end

local string_find = string.find
local string_Explode = string.Explode
local function TranslateRandomization( string )
    local hasstar = string_find( string, "*" )

    if hasstar then
        local exp = string_Explode( "*", string )
        local firsthalf = exp[ 1 ]
        local num = exp[ 2 ]
        local secondhalf = exp[ 3 ]
        return ( firsthalf .. random( num ) .. secondhalf )
    else
        return string
    end
end

local bullettbl = {
    HullSize = 5,
    Spread = Vector()
}

-- I like this way more than before 
local function DefaultRangedWeaponFire( self, wepent, target, weapondata, disabletbl )
    if self.l_Clip <= 0 then self:ReloadWeapon() return end
    
    disabletbl = disabletbl or {}
    
    local fireRate = ( disabletbl.cooldown or weapondata.rateoffire or Rand( weapondata.rateoffiremin, weapondata.rateoffiremax ) )
    if fireRate and fireRate != true then 
        local cooldown = weapondata.rateoffire or Rand( weapondata.rateoffiremin, weapondata.rateoffiremax )
        self.l_WeaponUseCooldown = CurTime() + cooldown
    end

    local fireSnd = ( disabletbl.sound or weapondata.attacksnd )
    if fireSnd and fireSnd != true then 
        wepent:EmitSound( TranslateRandomization( fireSnd ), 80, random( 98, 102 ), 1, CHAN_WEAPON ) 
    end
    
    local muzzleFlash = ( disabletbl.muzzleflash or weapondata.muzzleflash )
    if muzzleFlash and muzzleFlash != true then 
        self:HandleMuzzleFlash( muzzleFlash, weapondata.muzzleoffpos, weapondata.muzzleoffang ) 
    end

    local shellEject = ( disabletbl.shell or weapondata.shelleject )
    if shellEject and shellEject != true then 
        self:HandleShellEject( shellEject, weapondata.shelloffpos, weapondata.shelloffang ) 
    end

    local fireAnim = ( disabletbl.anim or weapondata.attackanim )
    if fireAnim and fireAnim != true then
        self:RemoveGesture( fireAnim )
        self:AddGesture( fireAnim )
    end

    local clipCost = ( disabletbl.clipdrain or 1 )
    if clipCost and clipCost != true then self.l_Clip = ( self.l_Clip - clipCost ) end

    local bulletData = ( disabletbl.damage or {} )
    if bulletData != true then
        bullettbl.Attacker = self
        bullettbl.IgnoreEntity = self

        bullettbl.Damage = ( bulletData.Damage or weapondata.damage )
        bullettbl.Force = ( bulletData.Force or weapondata.damage )
        bullettbl.Num = ( bulletData.Num or weapondata.bulletcount or 1 )
        bullettbl.TracerName = ( bulletData.TracerName or weapondata.tracername or "Tracer" )
        bullettbl.Dir = ( bulletData.Dir or ( target:WorldSpaceCenter() - wepent:GetPos() ):GetNormalized() )
        bullettbl.Src = ( bulletData.Src or wepent:GetPos() )

        local spread = ( bulletData.Spread or weapondata.spread )
        bullettbl.Spread.x = spread
        bullettbl.Spread.y = spread

        wepent:FireBullets( bullettbl )
    end    
end

local function DefaultMeleeWeaponUse( self, wepent, target, weapondata, disabletbl )
    disabletbl = disabletbl or {}

    local fireRate = ( disabletbl.cooldown or weapondata.rateoffire or Rand( weapondata.rateoffiremin, weapondata.rateoffiremax ) )
    if fireRate and fireRate != true then 
        local cooldown = weapondata.rateoffire or Rand( weapondata.rateoffiremin, weapondata.rateoffiremax )
        self.l_WeaponUseCooldown = CurTime() + cooldown
    end

    local attackSnd = ( disabletbl.sound or weapondata.attacksnd )
    if attackSnd and attackSnd != true then 
        wepent:EmitSound( TranslateRandomization( attackSnd ), 75, random( 98, 102 ), 1, CHAN_WEAPON ) 
    end

    local hitSnd = ( disabletbl.hitsound or weapondata.hitsnd )
    if hitSnd and hitSnd != true then 
        target:EmitSound( TranslateRandomization( hitSnd ), 70 ) 
    end

    local attackAnim = ( disabletbl.anim or weapondata.attackanim )
    if attackAnim and attackAnim != true then
        self:RemoveGesture( attackAnim )
        self:AddGesture( attackAnim )
    end

    local dmgData = ( disabletbl.damage or {} )
    if dmgData != true then
        local dmg = DamageInfo() 
        dmg:SetDamage( dmgData.Damage or weapondata.damage )
        dmg:SetAttacker( dmgData.Attacker or self )
        dmg:SetInflictor( dmgData.Inflictor or wepent )
        dmg:SetDamageType( dmgData.DamageType or DMG_CLUB )
        dmg:SetDamageForce( dmgData.DamageForce or ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * dmg:GetDamage() )

        target:TakeDamageInfo( dmg )
    end
end

function ENT:UseWeapon( target )
    if CurTime() < self.l_WeaponUseCooldown or self:GetIsReloading() or self.l_CurrentPlayedGesture != -1 then return end
    local weapondata = _LAMBDAPLAYERSWEAPONS[ self.l_Weapon ]

    local wepent = self:GetWeaponENT()
    if !IsValid( wepent ) then return end 
    
    local callback = ( weapondata.OnAttack or weapondata.callback )
    
    local result
    if callback then result = callback( self, wepent, target ) end

    if result != true then
        local ismelee = ( weapondata.ismelee or false )
        local defaultfunc = ( ismelee and DefaultMeleeWeaponUse or DefaultRangedWeaponFire )
        defaultfunc( self, wepent, target, weapondata, result )
    end
end

function ENT:ReloadWeapon()
    if self.l_HasMelee or self.l_Clip == self.l_MaxClip or self:GetIsReloading() or self.l_CurrentPlayedGesture != -1 then return end

    local wep = self:GetWeaponENT()
    if !IsValid( wep ) then return end
 
    local weapondata = _LAMBDAPLAYERSWEAPONS[ self.l_Weapon ]
    
    local onReloadFunc = weapondata.OnReload
    if onReloadFunc and onReloadFunc( self, wep, weapondata ) == true then return end

    local snds = weapondata.reloadsounds
    if snds then 
        if istable( snds ) and #snds > 0 then
            for k, tbl in ipairs( snds ) do
                self:SimpleWeaponTimer( tbl[ 1 ], function()
                    wep:EmitSound( tbl[ 2 ], 65, 100, 1, CHAN_WEAPON )
                end )
            end
        else
            wep:EmitSound( tbl[ 2 ], 65, 100, 1, CHAN_WEAPON )
        end
    end

    local anim = weapondata.reloadanim
    if anim then
        local id = ( isstring( anim ) and self:AddGestureSequence( anim ) or self:AddGesture( anim ) )
        self:SetLayerPlaybackRate( id, ( weapondata.reloadanimspeed or 1 ) )
    end

    self:SetIsReloading( true )

    self:NamedWeaponTimer( "Reload", ( weapondata.reloadtime or 1 ), 1, function()
        if !self:GetIsReloading() then return end
        self.l_Clip = self.l_MaxClip
        self:SetIsReloading( false )
    end )
end

-- 1 = Regular
-- 5 = Combine
-- 7 Regular but bigger
function ENT:HandleMuzzleFlash( type, offpos, offang, attachIndex )
    if !type or !IsFirstTimePredicted() then return end

    local wepent = self:GetWeaponENT()
    if !IsValid( wepent ) then return end

    local attach = wepent:GetAttachment( attachIndex or 1 )
    if !attach then
        if offpos and offang then 
            attach = { Pos = offpos, Ang = offang }
        else
            return 
        end
    end

    local effect = EffectData()
    effect:SetOrigin( attach.Pos )
    effect:SetStart( attach.Pos )
    effect:SetAngles( attach.Ang )
    effect:SetFlags( type )
    effect:SetEntity( wepent )
    Effect( "MuzzleFlash", effect, true )
end

function ENT:HandleShellEject( name, offpos, offang )
    if !name or !IsFirstTimePredicted() then return end

    local wepent = self:GetWeaponENT()
    if !IsValid( wepent ) then return end
    
    offpos = offpos or vector_origin
    offang = offang or angle_zero

    local effect = EffectData()
    effect:SetOrigin( wepent:WorldSpaceCenter() + offpos )
    effect:SetAngles( wepent:GetAngles() + Angle( 0, 90, 0 ) + offang )
    effect:SetEntity( wepent )
    Effect( name, effect, true )
end

-- If the Lambda's weapon data has nodraw enabled
function ENT:IsWeaponMarkedNodraw()
    return ( self.l_WeaponNoDraw )
end

-- If we can equip the specified weapon name
function ENT:CanEquipWeapon( weaponname )
    if weaponname != self.l_Weapon then
        local allowTbl = _LAMBDAWEAPONALLOWCONVARS[ weaponname ]
        return ( !allowTbl or allowTbl:GetBool() )
    end

    return false
end

function ENT:SwitchToRandomWeapon( returnOnly )
    local wepList = {}
    local curWep = self.l_Weapon

    local favWep = self.l_FavoriteWeapon
    local hasFavWep = false

    for name, data in pairs( _LAMBDAPLAYERSWEAPONS ) do
        if name == curWep or data.cantbeselected or !self:CanEquipWeapon( name ) then continue end
        if LambdaRunHook( "LambdaCanSwitchWeapon", self, name, data ) then continue end

        if !hasFavWep then hasFavWep = ( name == favWep ) end
        wepList[ #wepList + 1 ] = name
    end

    local rndWeapon = ( ( hasFavWep and random( #wepList * 2 ) >= #wepList ) and favWep or wepList[ random( #wepList ) ] )
    if !returnOnly then self:SwitchWeapon( returnOnly, true ) end
    return rndWeapon
end

function ENT:SwitchToLethalWeapon()
    local wepList = {}
    local curWep = self.l_Weapon

    local favWep = self.l_FavoriteWeapon
    local hasFavWep = false

    for name, data in pairs( _LAMBDAPLAYERSWEAPONS ) do
        if name == curWep or !data.islethal or data.cantbeselected or !self:CanEquipWeapon( name ) then continue end
        if LambdaRunHook( "LambdaCanSwitchWeapon", self, name, data ) then continue end

        if !hasFavWep then hasFavWep = ( name == favWep ) end
        wepList[ #wepList + 1 ] = name
    end

    self:SwitchWeapon( ( hasFavWep and random( #wepList * 2 ) >= #wepList ) and favWep or wepList[ random( #wepList ) ] )
end

function ENT:SwitchToSpawnWeapon()
    local weapon = self.l_SpawnWeapon
    if weapon == "random" then 
        weapon = self:SwitchToRandomWeapon( true ) 
    elseif !self:WeaponDataExists( weapon ) then
        weapon = "physgun"
        self.l_SpawnWeapon = weapon
    end
    
    self:SwitchWeapon( weapon ) 
end