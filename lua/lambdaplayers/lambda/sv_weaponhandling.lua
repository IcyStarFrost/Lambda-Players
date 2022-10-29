


-- Switch to a weapon with the provided name.
-- See the lambda/weapons folder for weapons. Check out the holster.lua file to see the current valid weapon settings
function ENT:SwitchWeapon( weaponname )
    local weapondata = _LAMBDAPLAYERSWEAPONS[ weaponname ]
    if !weapondata then return end
    local wepent = self.WeaponEnt

    if weapondata.bonemerge then wepent:AddEffects( EF_BONEMERGE ) else wepent:RemoveEffects( EF_BONEMERGE ) end

    self.l_HoldType = weapondata.holdtype
    
    wepent:SetNoDraw( weapondata.nodraw or false )
    wepent:DrawShadow( !weapondata.nodraw ) -- Prevent Shadows from rendering

    wepent:SetModel( weapondata.model )

end