if ( CLIENT ) then
    local cssFontName = "lambdakillicons_CSS_WeaponKillIcons"
    surface.CreateFont( cssFontName, { font = "csd", size = ScreenScale( 30 ), weight = 500, antialias = true, additive = true } )
    killicon.AddFont( "lambdakillicons_css_knife", cssFontName, "j", Color( 255, 80, 0, 255 ) )
end


local DamageInfo = DamageInfo
local CurTime = CurTime
local backstabCvar = CreateLambdaConvar( "lambdaplayers_weapons_knifebackstab", 1, true, false, true, "If Lambda Players should be allowed to use the backstab feature of the Knife.", 0, 1, { type = "Bool", name = "Knife - Enable Backstab", category = "Weapon Utilities" } )

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    knife = {
        model = "models/weapons/w_knife_t.mdl",
        origin = "Counter-Strike: Source",
        prettyname = "Knife",
        holdtype = "knife",
        ismelee = true,
        bonemerge = true,
        keepdistance = 10,
        attackrange = 50,
        killicon = "lambdakillicons_css_knife",

        OnDeploy = function( lambda, wepent )
            wepent:EmitSound( "Weapon_Knife.Deploy" )
        end,

        OnAttack = function( self, wepent, target )
            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_KNIFE )

            local isBackstab = false
            if backstabCvar:GetBool() then
                local los = ( target:GetPos() - self:GetPos() )
                los.z = 0

                local targetFwd = target:GetForward()
                targetFwd.z = 0

                isBackstab = ( los:GetNormalized():Dot( targetFwd ) > 0.75 )
            end

            local slashSnd = "Weapon_Knife." .. ( isBackstab and "Stab" or "Hit" )
            local slashDmg = ( isBackstab and 195 or ( ( ( CurTime() - self.l_WeaponUseCooldown ) > 0.4 ) and 20 or 15 ) )

            local dmginfo = DamageInfo() 
            dmginfo:SetDamage( slashDmg )
            dmginfo:SetAttacker( self )
            dmginfo:SetInflictor( wepent )
            dmginfo:SetDamageType( DMG_SLASH )
            dmginfo:SetDamageForce( ( target:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * slashDmg )
            target:TakeDamageInfo( dmginfo )

            wepent:EmitSound( slashSnd )
            self.l_WeaponUseCooldown = ( CurTime() + ( isBackstab and 1.1 or 0.5 ) )

            return true
        end,

        islethal = true
    }
} )