local random = math.random
local CurTime = CurTime
local IsValid = IsValid
local util_Effect = util.Effect
local util_ScreenShake = util.ScreenShake
local bulletData = {
    Damage = 1000,
    Force = 1000,
    HullSize = 5,
    Num = 1,
    TracerName = "GunshipTracer",
    Spread = Vector( 0.05, 0.05, 0 )
}

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    volver = {
        model = "models/lambdaplayers/volver/w_volver.mdl",
        origin = "Misc",
        prettyname = "Volver",
        holdtype = "crossbow",
        killicon = "lambdaplayers/killicons/icon_volver",
        bonemerge = false,
        keepdistance = 600,
        attackrange = 4000,

        callback = function( self, wepent, target )
            self.l_WeaponUseCooldown = CurTime() + 5
            wepent:EmitSound( "weapons/pistol/pistol_empty.wav", 70, 100, 1, CHAN_WEAPON )

            self:SimpleTimer( 1, function()
                if self.l_Weapon != "volver" or !IsValid( wepent ) then return end

                wepent:EmitSound( "weapons/357/357_fire2.wav", 70, random( 70, 75 ), 1, CHAN_WEAPON )
                self:EmitSound( "ambient/explosions/explode_4.wav", 70, 100, 1, CHAN_WEAPON )
                self:EmitSound( "physics/body/body_medium_break" .. random( 2, 4 ) .. ".wav", 90 )

                self:HandleMuzzleFlash( 7 )

                local attach = wepent:GetAttachment( 1 )
                local effData = EffectData()
                    effData:SetOrigin( attach.Pos )
                    effData:SetStart( attach.Pos )
                    effData:SetAngles( attach.Ang )
                    effData:SetMagnitude( 5 )
                    effData:SetScale( 10 )
                    effData:SetRadius( 10 )
                util_Effect( "cball_bounce", effData, true, true )

                util_ScreenShake( self:GetPos(), 10, 170, 3, 1500 )

                local shootDir = ( ( IsValid( target ) and target:WorldSpaceCenter() or self:GetEyeTrace().HitPos ) - wepent:GetPos() ):GetNormalized()

                bulletData.Dir = shootDir
                bulletData.Attacker = self
                bulletData.IgnoreEntity = self
                bulletData.Src = wepent:GetPos()
                wepent:FireBullets( bulletData )

                local dmginfo = DamageInfo()
                dmginfo:SetDamage( self:Health() * 100000 )
                dmginfo:SetDamageType( DMG_BLAST ) 
                dmginfo:SetAttacker( self )
                dmginfo:SetInflictor( self )
                dmginfo:SetDamageForce( shootDir * -80000000 )
                self:TakeDamageInfo( dmginfo )
            end)

            return true
        end,

        islethal = true,
    }

})