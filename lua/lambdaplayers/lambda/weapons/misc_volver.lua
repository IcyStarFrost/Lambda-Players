local random = math.random
local CurTime = CurTime
local IsValid = IsValid
local util_Effect = util.Effect
local bullettbl = {}

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    volver = {
        model = "models/lambdaplayers/volver/w_volver.mdl",
        origin = "Misc",
        prettyname = "Volver",
        holdtype = "crossbow",
        bonemerge = false,
        keepdistance = 600,
        attackrange = 4000,

        callback = function( self, wepent, target )
            self.l_WeaponUseCooldown = CurTime() + 5

            wepent:EmitSound( "weapons/pistol/pistol_empty.wav", 70, 100, 1, CHAN_WEAPON )

            self:SimpleTimer( 1, function()
                if !IsValid( self ) or !IsValid( target ) or !IsValid( wepent ) then return end
                wepent:EmitSound( "weapons/357/357_fire2.wav", 70, random( 70, 75 ), 1, CHAN_WEAPON )
                self:EmitSound( "ambient/explosions/explode_4.wav", 70, 100, 1, CHAN_WEAPON )
                self:EmitSound( "physics/body/body_medium_break"..math.random( 2, 4 )..".wav", 90)

                local attach = wepent:GetAttachment( 1 )

                self:HandleMuzzleFlash( 7 )

                util.ScreenShake( self:GetPos(), 10, 170, 3, 1500 )

                local effect = EffectData()
                    effect:SetOrigin( attach.Pos )
                    effect:SetStart( attach.Pos )
                    effect:SetAngles( attach.Ang )
                    effect:SetMagnitude( 5 )
                    effect:SetScale( 10 )
                    effect:SetRadius( 10 )
                util_Effect( "cball_bounce", effect, true, true )

                bullettbl.Attacker = self
                bullettbl.Damage = 1000
                bullettbl.Force = 1000
                bullettbl.HullSize = 5
                bullettbl.Num = 1
                bullettbl.TracerName = "GunshipTracer"
                bullettbl.Dir = ( target:WorldSpaceCenter() - wepent:GetPos() ):GetNormalized()
                bullettbl.Src = wepent:GetPos()
                bullettbl.Spread = Vector( 0.05, 0.05, 0 )
                bullettbl.IgnoreEntity = self
                
                wepent:FireBullets( bullettbl )

                local dmg = DamageInfo()
                dmg:SetDamage( self:Health() * 100000 )
                dmg:SetDamageType( DMG_BLAST ) 
                dmg:SetAttacker( self )
                dmg:SetInflictor( self )
                dmg:SetDamageForce( self:GetForward() * -80000000 )
                self:TakeDamageInfo( dmg )
            end)
            
            return true
        end,

        islethal = true,
    }

})