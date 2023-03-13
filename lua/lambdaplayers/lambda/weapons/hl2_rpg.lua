local IsValid = IsValid
local CurTime = CurTime
local ents_Create = ents.Create
local Rand = math.Rand

table.Merge( _LAMBDAPLAYERSWEAPONS, {
--Missing guided rockets

    rpg = {
        model = "models/weapons/w_rocket_launcher.mdl",
        origin = "Half-Life 2",
        prettyname = "RPG",
        holdtype = "rpg",
        killicon = "rpg_missile",
        bonemerge = true,
        keepdistance = 800,
        attackrange = 5000,

        OnAttack = function( self, wepent, target )            
            local rocket = ents_Create( "rpg_missile" )
            if !IsValid( rocket ) then return end

            self.l_WeaponUseCooldown = CurTime() + Rand( 2.0, 3.0 )

            wepent:EmitSound( "Weapon_RPG.Single" )

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG )

            local spawnAttach = wepent:GetAttachment(2)
            local targetAng = ( target:WorldSpaceCenter() - wepent:GetPos() ):Angle()
            rocket:SetPos( spawnAttach.Pos + targetAng:Forward() * 40 + targetAng:Up() * 15 )
            rocket:SetAngles( ( target:WorldSpaceCenter() - rocket:GetPos() ):Angle() )
            rocket:SetOwner( self )
            rocket:SetMoveType( MOVETYPE_FLYGRAVITY )
            rocket:SetAbsVelocity( self:GetForward() * 300 + Vector( 0, 0, 128 ) )
            rocket:SetCollisionGroup( COLLISION_GROUP_DEBRIS ) -- SetOwner should prevent collision but it doesn't
            rocket:SetSaveValue( "m_flDamage", 150 ) -- Gmod RPG only does 150 damage
            rocket:Spawn()

            self:SimpleTimer( 0.4, function() -- Grace period to avoid collision with the shooter
                if !IsValid( rocket ) then return end
                rocket:SetCollisionGroup( COLLISION_GROUP_PROJECTILE )
            end)

            rocket:CallOnRemove( "LambdaPlayer_RPGRocket_" .. rocket:EntIndex(), function()
                rocket:StopSound( "weapons/rpg/rocket1.wav" ) -- Trying to prevent source being dumb
            end)

            return true
        end,

        islethal = true,
    }

})