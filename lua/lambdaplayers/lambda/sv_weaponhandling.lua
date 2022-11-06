
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


-- Will need a rewrite
function ENT:UseWeapon( target )
    if self:GetIsReloading() then return end
    local weapondata = _LAMBDAPLAYERSWEAPONS[ self.l_Weapon ]
    if !weapondata or CurTime() < self.l_WeaponUseCooldown then return end
    local wepent = self.WeaponEnt

    local ismelee = weapondata.ismelee or false
    
    
    local callback = weapondata.callback
    local gesture = weapondata.attackanim
    local snd = weapondata.attacksnd
    local damage = weapondata.damage
    local rateoffire = weapondata.rateoffire or 0
    local num = weapondata.bulletcount or 1
    local tracer = weapondata.tracername or "Tracer"
    local spread = weapondata.spread
    local muzzleflash = weapondata.muzzleflash or 1
    local shelleject = weapondata.shelleject or "ShellEject"

        

    if callback == nil or isfunction( callback ) and !callback( self, wepent, target) then

        if ismelee then

            local hitsnd = weapondata.hitsnd

            self.l_WeaponUseCooldown = CurTime() + rateoffire

            wepent:EmitSound( TranslateRandomization( snd ), 70, 100, 1, CHAN_WEAPON )
            
            self:RemoveGesture( gesture )
            self:AddGesture( gesture )

            local dmg = DamageInfo() 
            dmg:SetDamage( damage )
            dmg:SetAttacker( self )
            dmg:SetInflictor( wepent )
            dmg:SetDamageType( DMG_CLUB )
            dmg:SetDamageForce( ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * damage )

            target:EmitSound( TranslateRandomization( hitsnd ), 70 )

            target:TakeDamageInfo( dmg )

        else
            if self.l_Clip <= 0 then self:ReloadWeapon() return end

            self.l_WeaponUseCooldown = CurTime() + rateoffire

            wepent:EmitSound( TranslateRandomization( snd ), 70, 100, 1, CHAN_WEAPON )

            self:RemoveGesture( gesture )
            self:AddGesture( gesture )
            
            self:HandleMuzzleFlash( muzzleflash )
            self:HandleShellEject( shelleject )

            bullettbl.Attacker = self
            bullettbl.Damage = damage
            bullettbl.Force = damage
            bullettbl.HullSize = 5
            bullettbl.Num = num or 1
            bullettbl.TracerName = tracer or "Tracer"
            bullettbl.Dir = ( target:WorldSpaceCenter() - wepent:GetPos() ):GetNormalized()
            bullettbl.Src = wepent:GetPos()
            bullettbl.Spread = Vector( spread, spread, 0 )
            bullettbl.IgnoreEntity = self

            self.l_Clip = self.l_Clip - 1

            wepent:FireBullets( bullettbl )
        end


    end




end


-- Will need a rewrite
function ENT:ReloadWeapon()
    if self.l_HasMelee or self.l_Clip == self.l_MaxClip or self:GetIsReloading() then return end
    local weapondata = _LAMBDAPLAYERSWEAPONS[ self.l_Weapon ]

    self:SetIsReloading( true )

    local wep = self:GetWeaponENT()
    local time = weapondata.reloadtime
    local anim = weapondata.reloadanim
    local animspeed = weapondata.reloadanimationspeed
    local snds = weapondata.reloadsounds

    if snds and #snds > 0 then
        for k, tbl in ipairs( snds ) do
            self:SimpleTimer( tbl[ 1 ], function()
                wep:EmitSound( tbl[ 2 ], 65, 100, 1, CHAN_WEAPON )
            end )
        end
    end

    local id = self:AddGesture( anim )
    self:SetLayerPlaybackRate( id, animspeed )

    self:NamedTimer( "Reload", time, 1, function()
        if !self:GetIsReloading() then return end
        self.l_Clip = self.l_MaxClip

        self:SetIsReloading( false )
    end )

end



-- Will need a rewrite

-- 1 = Regular
-- 5 = Combine
-- 7 Regular but bigger
function ENT:HandleMuzzleFlash( type )
    local wepent = self:GetWeaponENT()
    local attach = wepent:GetAttachment( 1 )
    if !attach or !IsValid( wepent ) then return end
    local effect = EffectData()
    effect:SetOrigin( attach.Pos )
    effect:SetStart( attach.Pos )
    effect:SetAngles( attach.Ang )
    effect:SetFlags( type )
    effect:SetEntity( wepent )
    Effect( "MuzzleFlash", effect, true )
end

-- Will need a rewrite
function ENT:HandleShellEject( name )
    local wepent = self:GetWeaponENT()
    if !IsValid( wepent ) then return end
    local effect = EffectData()
    effect:SetOrigin( wepent:WorldSpaceCenter() )
    effect:SetStart( wepent:WorldSpaceCenter() )
    effect:SetAngles( wepent:GetAngles() + Angle( 0, 90, 0 ) )
    effect:SetEntity( wepent )
    Effect( name, effect, true )
end

-- If the lambda's weapon data has nodraw enabled
function ENT:IsWeaponMarkedNodraw()
    local weapondata = _LAMBDAPLAYERSWEAPONS[ self.l_Weapon ]
    return weapondata.nodraw
end

function ENT:SwitchToRandomWeapon()
    for k, v in RandomPairs( _LAMBDAPLAYERSWEAPONS ) do
        if _LAMBDAWEAPONALLOWCONVARS[ k ]:GetBool() and k != self.l_Weapon then
            self:SwitchWeapon( k )
            return
        end
    end
    self:SwitchWeapon( "NONE" )
end

function ENT:SwitchToLethalWeapon()
    if self.l_HasLethal then return end
    for k, v in RandomPairs( _LAMBDAPLAYERSWEAPONS ) do
        if v.islethal and _LAMBDAWEAPONALLOWCONVARS[ k ]:GetBool() and k != self.l_Weapon then
            self:SwitchWeapon( k )
            return
        end
    end
    self:SwitchWeapon( "NONE" )
end