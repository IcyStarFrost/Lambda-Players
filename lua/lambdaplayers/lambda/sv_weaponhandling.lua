
local isfunction = isfunction
local random = math.random
local RandomPairs = RandomPairs
local ipairs = ipairs
local Effect = util.Effect
local CurTime = CurTime
local string_find = string.find
local origin = Vector()
local angle_zero = Angle()
local isplayerfaked = GetConVar( "lambdaplayers_lambda_fakeisplayer" )


local function IsSWEP( weaponname )
    return weapons.Get( weaponname ) != nil
end

function ENT:WeaponDataExists( weaponname )
    return !IsSWEP( weaponname ) and _LAMBDAPLAYERSWEAPONS[ weaponname ] != nil or isplayerfaked:GetBool() and LambdaSupportedSweps[ weaponname ] != nil
end

-- Switch to a weapon with the provided name.
-- See the lambda/weapons folder for weapons. Check out the holster.lua file to see the current valid weapon settings
function ENT:SwitchWeapon( weaponname, forceswitch )
    if !self:CanEquipWeapon( weaponname ) and !forceswitch or self.l_NoWeaponSwitch then return end

    if !self:WeaponDataExists( weaponname ) then return end
    local weapondata = _LAMBDAPLAYERSWEAPONS[ weaponname ]

    if IsValid( self:GetSWEPWeaponEnt() ) then self:GetSWEPWeaponEnt():Remove() end

    local wepent = self.WeaponEnt
    local swep = weapons.Get( weaponname )
    if swep then

        local oldwepdata = _LAMBDAPLAYERSWEAPONS[ self.l_Weapon ]
        if oldwepdata and isfunction( oldwepdata.OnUnequip ) then oldwepdata.OnUnequip( self, wepent ) end

        self:SwitchWeaponSWEP( weaponname ) 
        return 
    end


    

    local oldwepdata = _LAMBDAPLAYERSWEAPONS[ self.l_Weapon ]
    if oldwepdata and isfunction( oldwepdata.OnUnequip ) then oldwepdata.OnUnequip( self, wepent ) end

    if weapondata.bonemerge then wepent:AddEffects( EF_BONEMERGE ) else wepent:RemoveEffects( EF_BONEMERGE ) end

    self.l_Weapon = weaponname
    self:SetNW2String( "lambda_spawnweapon", weaponname )
    self.l_WeaponPrettyName = weapondata.notagprettyname
    self.l_HasLethal = weapondata.islethal
    self.l_HasMelee = weapondata.ismelee 
    self.l_HoldType = weapondata.holdtype or "normal"
    self.l_CombatKeepDistance = weapondata.keepdistance
    self.l_CombatAttackRange = weapondata.attackrange
    self.l_OnDamagefunction = weapondata.OnDamage
    self.l_WeaponNoDraw = weapondata.nodraw or false
    self.l_WeaponSpeedMultiplier = weapondata.speedmultiplier or 1
    self.l_Clip = weapondata.clip or 0
    self.l_MaxClip = weapondata.clip or 0

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
    self:SetHasCustomDrawFunction( isfunction( weapondata.Draw ) )
    self:SetUsingSWEP( false )
    self:SetWeaponName( weaponname )
    self.WeaponEnt:SetNoDraw( weapondata.nodraw )
    self.WeaponEnt:DrawShadow( !weapondata.nodraw )

    self.WeaponEnt:SetLocalPos( weapondata.offpos or origin )
    self.WeaponEnt:SetLocalAngles( weapondata.offang or angle_zero )

    wepent:SetModel( weapondata.model )
    
    
    self.l_WeaponThinkFunction = weapondata.OnThink
    if isfunction( weapondata.OnEquip ) then weapondata.OnEquip( self, wepent ) end

end



function ENT:SwitchWeaponSWEP( classname )

    self:ClientSideNoDraw( self.WeaponEnt, true )
    self.WeaponEnt:SetNoDraw( true )
    self.WeaponEnt:DrawShadow( false )

    local ap = self:LookupAttachment( "anim_attachment_RH" )
    local attachpoint = self:GetAttachmentPoint( "hand" )

    local wep = ents.Create( classname )
    wep:SetPos( attachpoint.Pos )
    wep:SetAngles( attachpoint.Ang )
    wep:SetParent( self, ap )
    wep.IsLambdaWeapon = true
    wep:SetOwner( self )
    wep:SetMoveType( MOVETYPE_NONE )
    wep:Spawn()
    
    --wep:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )

    self:SetSWEPWeaponEnt( wep )
    self:SetUsingSWEP( true )
    self:SetHasCustomDrawFunction( false )
    self:SetWeaponName( wep:GetClass() )
    self.l_Weapon = wep:GetClass()
    self:SetNW2String( "lambda_spawnweapon", self.l_SpawnWeapon )
    self.l_HoldType = wep:GetHoldType()
    self.l_Clip = wep:Clip1()
    self.l_MaxClip = wep:GetMaxClip1()
    self.l_OnDamagefunction = nil
    self.l_WeaponPrettyName = wep:GetPrintName()
    self.l_WeaponNoDraw = false
    self:RemoveEffects( EF_BONEMERGE )

    -- Run the Equip function
    if wep.Equip then
        wep:Equip( self )
    end

    if wep.Deploy then
        wep:Deploy()
    end

    if LambdaSupportedSweps[ classname ] then LambdaSupportedSweps[ classname ][ 1 ]( self, wep ) end

end

local string_Explode = string.Explode
local string_find = string.find
local function TranslateRandomization( string )
    local hasstar = string_find( string, "*" )

    if hasstar then
        local exp = string_Explode( "*", string )
        local firsthalf = exp[ 1 ]
        local num = exp[ 2 ]
        local secondhalf = exp[ 3 ]
        return firsthalf .. random( num ) .. secondhalf
    else
        return string
    end
end

local bullettbl = {}


-- I like this way more than before 
local function DefaultRangedWeaponFire( self, wepent, target, weapondata, disabletbl )
    if self.l_Clip <= 0 then self:ReloadWeapon() return end
    disabletbl = disabletbl or {}
    if !disabletbl.cooldown then self.l_WeaponUseCooldown = CurTime() + weapondata.rateoffire end
    
    if !disabletbl.sound then wepent:EmitSound( TranslateRandomization( weapondata.attacksnd ), 70, 100, 1, CHAN_WEAPON ) end
    
    if !disabletbl.muzzleflash then self:HandleMuzzleFlash( weapondata.muzzleflash, weapondata.muzzleoffpos, weapondata.muzzleoffang ) end
    if !disabletbl.shell then self:HandleShellEject( weapondata.shelleject, weapondata.shelloffpos, weapondata.shelloffang ) end

    if !disabletbl.anim then
        self:RemoveGesture( weapondata.attackanim )
        self:AddGesture( weapondata.attackanim )
    end

    
    if !disabletbl.damage then
        bullettbl.Attacker = self
        bullettbl.Damage = weapondata.damage
        bullettbl.Force = weapondata.damage
        bullettbl.HullSize = 5
        bullettbl.Num = weapondata.bulletcount or 1
        bullettbl.TracerName = weapondata.tracername or "Tracer"
        bullettbl.Dir = ( target:WorldSpaceCenter() - wepent:GetPos() ):GetNormalized()
        bullettbl.Src = wepent:GetPos()
        bullettbl.Spread = Vector( weapondata.spread, weapondata.spread, 0 )
        bullettbl.IgnoreEntity = self
    end
    
    if !disabletbl.clipdrain then self.l_Clip = self.l_Clip - 1 end

    if !disabletbl.damage then wepent:FireBullets( bullettbl ) end
    
end

local function DefaultMeleeWeaponUse( self, wepent, target, weapondata, disabletbl )
    disabletbl = disabletbl or {}
    if !disabletbl.cooldown then self.l_WeaponUseCooldown = CurTime() + weapondata.rateoffire end
    
    if !disabletbl.sound then wepent:EmitSound( TranslateRandomization( weapondata.attacksnd ), 70, 100, 1, CHAN_WEAPON ) end
    
    if !disabletbl.anim then
        self:RemoveGesture( weapondata.attackanim )
        self:AddGesture( weapondata.attackanim )
    end

    if !disabletbl.damage then
        local dmg = DamageInfo() 
        dmg:SetDamage( weapondata.damage )
        dmg:SetAttacker( self )
        dmg:SetInflictor( wepent )
        dmg:SetDamageType( DMG_CLUB )
        dmg:SetDamageForce( ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * weapondata.damage )

        target:TakeDamageInfo( dmg )
    end


    if !disabletbl.sound then target:EmitSound( TranslateRandomization( weapondata.hitsnd ), 70 ) end
    

end




function ENT:UseWeapon( target )
    if !self:GetUsingSWEP() then

        if self:GetIsReloading() then return end
        if CurTime() < self.l_WeaponUseCooldown then return end
        local weapondata = _LAMBDAPLAYERSWEAPONS[ self.l_Weapon ]


        local ismelee = weapondata.ismelee or false
        local wepent = self:GetWeaponENT()
        local callback = weapondata.callback
        local result
        
        if callback then result = callback( self, wepent, target ) end
        
        if result != true then
            local defaultfunc = ismelee and DefaultMeleeWeaponUse or DefaultRangedWeaponFire
            defaultfunc( self, wepent, target, weapondata, result )
        end

    else
        local swep = self:GetSWEPWeaponEnt()
        if CurTime() < swep:GetNextPrimaryFire() then return end
        if swep:Clip1() <= 0 then self:ReloadSWEP() return end

        if random( 1, 30 ) == 1 and isfunction( swep.SecondaryAttack ) and swep:Clip2() > 0 then
            swep:SecondaryAttack()
            return
        end
        
        self.l_WeaponUseCooldown = swep:GetNextPrimaryFire()
        swep:PrimaryAttack()
        --LambdaSupportedSweps[ self:GetWeaponName() ][ 2 ]( self, swep )
    end
end

-- Reloads our SWEP 
function ENT:ReloadSWEP()
    local swep = self:GetSWEPWeaponEnt()

    if self:GetIsReloading() or swep:Clip1() == swep:GetMaxClip1() or self.l_HasMelee then return end
    local anim = _LAMBDAPLAYERSHoldTypeAnimations[ swep:GetHoldType() ].reload

    self:SetIsReloading( true )

    if anim then
        self:AddGesture( anim )
    end

    self:NamedTimer( "Reload", self.l_swepreloadtime, 1, function()
        if !self:GetIsReloading() or !IsValid( swep ) then return end

        swep:SetClip1( swep:GetMaxClip1() )
        swep:SetClip2( swep:GetMaxClip2() )

        self:SetIsReloading( false )
    end )

end

function ENT:ReloadWeapon()
    if self:GetUsingSWEP() then self:ReloadSWEP() return end -- Detour to SWEP function
    if self.l_HasMelee or self.l_Clip == self.l_MaxClip or self:GetIsReloading() then return end
    local weapondata = _LAMBDAPLAYERSWEAPONS[ self.l_Weapon ]

    self:SetIsReloading( true )

    local wep = self:GetWeaponENT()
    local time = weapondata.reloadtime or 1
    local anim = weapondata.reloadanim
    local animspeed = weapondata.reloadanimspeed or 1
    local snds = weapondata.reloadsounds

    if snds and #snds > 0 then
        for k, tbl in ipairs( snds ) do
            self:SimpleTimer( tbl[ 1 ], function()
                wep:EmitSound( tbl[ 2 ], 65, 100, 1, CHAN_WEAPON )
            end )
        end
    end

    if anim then
        local id = self:AddGesture( anim )
        self:SetLayerPlaybackRate( id, animspeed )
    end

    local onReloadFunc = weapondata.OnReload
    if isfunction( onReloadFunc ) then onReloadFunc( self, wep ) end

    self:NamedTimer( "Reload", time, 1, function()
        if !self:GetIsReloading() then return end
        self.l_Clip = self.l_MaxClip

        self:SetIsReloading( false )
    end )

end


-- 1 = Regular
-- 5 = Combine
-- 7 Regular but bigger
function ENT:HandleMuzzleFlash( type, offpos, offang )
    if !type then return end

    local wepent = self:GetWeaponENT()
    local attach = wepent:GetAttachment( 1 )
    if !attach and offpos and offang then attach = { Pos = offpos, Ang = offang } elseif !attach and ( !offpos or !offang ) then return end
    if !IsValid( wepent ) then return end
    local effect = EffectData()
    effect:SetOrigin( attach.Pos )
    effect:SetStart( attach.Pos )
    effect:SetAngles( attach.Ang )
    effect:SetFlags( type )
    effect:SetEntity( wepent )
    Effect( "MuzzleFlash", effect, true )
end

function ENT:HandleShellEject( name, offpos, offang )
    if !name then return end

    local wepent = self:GetWeaponENT()
    if !IsValid( wepent ) then return end
    offpos = offpos or Vector()
    offang = offang or Angle()

    local effect = EffectData()
    effect:SetOrigin( wepent:WorldSpaceCenter() + offpos )
    effect:SetAngles( wepent:GetAngles() + Angle( 0, 90, 0 ) + offang )
    effect:SetEntity( wepent )
    Effect( name, effect, true )
end

-- If the Lambda's weapon data has nodraw enabled
function ENT:IsWeaponMarkedNodraw()
    return self.l_WeaponNoDraw
end

-- If we can equip the specified weapon name
function ENT:CanEquipWeapon( weaponname )
    return weaponname != self.l_Weapon and ( IsSWEP( weaponname ) and isplayerfaked:GetBool() or !IsSWEP( weaponname ) ) and ( _LAMBDAWEAPONALLOWCONVARS[ weaponname ] and _LAMBDAWEAPONALLOWCONVARS[ weaponname ]:GetBool() )
end

function ENT:SwitchToRandomWeapon()
    for k, v in RandomPairs( _LAMBDAPLAYERSWEAPONS ) do
        if self:CanEquipWeapon( k ) and k != self.l_Weapon and !hook.Run( "LambdaCanSwitchWeapon", self, k, v ) then
            self:SwitchWeapon( k )
            return
        end
    end
    self:SwitchWeapon( "none", true )
end

function ENT:SwitchToLethalWeapon()
    for k, v in RandomPairs( _LAMBDAPLAYERSWEAPONS ) do
        if v.islethal and self:CanEquipWeapon( k ) and k != self.l_Weapon and !hook.Run( "LambdaCanSwitchWeapon", self, k, v ) then
            self:SwitchWeapon( k )
            return
        end
    end
    self:SwitchWeapon( self.l_Weapon )
end