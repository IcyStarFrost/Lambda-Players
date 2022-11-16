local IsValid = IsValid
local CurTime = CurTime
local util_BlastDamage = util.BlastDamage
local ents_Create = ents.Create

table.Merge( _LAMBDAPLAYERSWEAPONS, {
--Missing guided rockets

    rpg = {
        model = "models/weapons/w_rocket_launcher.mdl",
        origin = "Half Life: 2",
        prettyname = "RPG",
        holdtype = "rpg",
        killicon = "rpg_missile",
        bonemerge = true,
        keepdistance = 800,
        attackrange = 5000,

        OnEquip = function( lambda, wepent )
            wepent.CurrentRocket = NULL
            lambda:Hook( "Think", "LambdaPlayer_OnlyOneRPGRocket", function()
                if !IsValid( wepent.CurrentRocket ) then return end
                lambda.l_WeaponUseCooldown = CurTime() + 2.0
            end, false )
        end,

        OnUnequip = function( lambda, wepent )
            wepent.CurrentRocket = nil
            lambda:RemoveHook( "Think", "LambdaPlayer_OnlyOneRPGRocket" )
        end,

        callback = function( self, wepent, target )            
            local rocket = ents_Create( "rpg_missile" )
            if !IsValid( rocket ) then return end

            self.l_WeaponUseCooldown = CurTime() + 2.0

            wepent:EmitSound( "Weapon_RPG.Single" )

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG )

            local spawnAttach = wepent:GetAttachment(2)
            local targetAng = ( target:WorldSpaceCenter() - wepent:GetPos() ):Angle()
            rocket:SetPos( spawnAttach.Pos + targetAng:Forward() * 100 + targetAng:Up() * 15 )
            rocket:SetAngles( ( target:WorldSpaceCenter() - rocket:GetPos() ):Angle() )
            rocket:SetOwner( self )
            rocket:SetCollisionGroup( COLLISION_GROUP_DEBRIS ) -- SetOwner should prevent collision but it doesn't
            rocket:Spawn()

            self:SimpleTimer( 0.3, function() -- Grace period to avoid collision with the shooter
                if !IsValid( rocket ) then return end
                rocket:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )
            end)

            rocket:CallOnRemove( "LambdaPlayer_RPGRocket_" .. rocket:EntIndex(), function()
                rocket:StopSound( "weapons/rpg/rocket1.wav" ) -- Trying to prevent source being dumb
                util_BlastDamage( rocket, ( IsValid( self ) and self or rocket ), rocket:GetPos(), 260, 210)
            end)

            wepent.CurrentRocket = rocket

            return true
        end,

        islethal = true,
    }

})