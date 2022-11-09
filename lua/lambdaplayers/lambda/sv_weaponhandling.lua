
local isfunction = isfunction
local random = math.random
local RandomPairs = RandomPairs
local ipairs = ipairs
local Effect = util.Effect
local CurTime = CurTime

-- Switch to a weapon with the provided name.
-- See the lambda/weapons folder for weapons. Check out the holster.lua file to see the current valid weapon settings
function ENT:SwitchWeapon( weaponname )
    local weapondata = _LAMBDAPLAYERSWEAPONS[ weaponname ]
    if !weapondata or weaponname == self.l_Weapon then return end

    local wepent = self.WeaponEnt

    local oldwepdata = _LAMBDAPLAYERSWEAPONS[ self.l_Weapon ]
    if oldwepdata and isfunction( oldwepdata.OnUnequip ) then oldwepdata.OnUnequip( self, wepent ) end

    

    if weapondata.bonemerge then wepent:AddEffects( EF_BONEMERGE ) else wepent:RemoveEffects( EF_BONEMERGE ) end

    self.l_Weapon = weaponname
    self.l_HasLethal = weapondata.islethal
    self.l_HasMelee = weapondata.ismelee
    self.l_HoldType = weapondata.holdtype
    self.l_CombatKeepDistance = weapondata.keepdistance
    self.l_CombatAttackRange = weapondata.attackrange
    self.l_CombatSpeedAdd = weapondata.addspeed or 0
    self.l_Clip = weapondata.clip or 0
    self.l_MaxClip = weapondata.clip or 0
    
    self:ClientSideNoDraw( self.WeaponEnt, weapondata.nodraw )
    self:SetHasCustomDrawFunction( isfunction( weapondata.Draw ) )
    self:SetWeaponName( weaponname )
    self.WeaponEnt:SetNoDraw( weapondata.nodraw )
    self.WeaponEnt:DrawShadow( !weapondata.nodraw )

    wepent:SetModel( weapondata.model )

    if isfunction( weapondata.OnEquip ) then weapondata.OnEquip( self, wepent ) end

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
    
    if !disabletbl.muzzleflash then self:HandleMuzzleFlash( weapondata.muzzleflash ) end
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
end


function ENT:ReloadWeapon()
    if self.l_HasMelee or self.l_Clip == self.l_MaxClip or self:GetIsReloading() then return end
    local weapondata = _LAMBDAPLAYERSWEAPONS[ self.l_Weapon ]

    self:SetIsReloading( true )

    local wep = self:GetWeaponENT()
    local time = weapondata.reloadtime or 1
    local anim = weapondata.reloadanim
    local animspeed = weapondata.reloadanimationspeed or 1
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
    local wepent = self:GetWeaponENT()
    local attach = wepent:GetAttachment( 1 )
    if !attach and offpos and offang then attach = { Pos = offpos, Ang = offang } elseif !attach and ( offpos or offang ) then return end
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

-- If the lambda's weapon data has nodraw enabled
function ENT:IsWeaponMarkedNodraw()
    local weapondata = _LAMBDAPLAYERSWEAPONS[ self.l_Weapon ]
    return weapondata.nodraw
end

-- If we can equip the specified weapon name
function ENT:CanEquipWeapon( weaponname )
    return _LAMBDAWEAPONALLOWCONVARS[ weaponname ]:GetBool()
end

function ENT:SwitchToRandomWeapon()
    for k, v in RandomPairs( _LAMBDAPLAYERSWEAPONS ) do
        if self:CanEquipWeapon( k ) and k != self.l_Weapon then
            self:SwitchWeapon( k )
            return
        end
    end
    self:SwitchWeapon( "NONE" )
end

function ENT:SwitchToLethalWeapon()
    if self.l_HasLethal then return end
    for k, v in RandomPairs( _LAMBDAPLAYERSWEAPONS ) do
        if v.islethal and self:CanEquipWeapon( k ) and k != self.l_Weapon then
            self:SwitchWeapon( k )
            return
        end
    end
    self:SwitchWeapon( "NONE" )
end