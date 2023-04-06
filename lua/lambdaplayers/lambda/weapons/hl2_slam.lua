local IsValid = IsValid
local CurTime = CurTime
local VectorRand = VectorRand
local EmitEffect = util.Effect
local EmitExplosion = util.BlastDamage
local SimpleTimer = timer.Simple
local RandomInt = math.random
local RandomFloat = math.Rand
local EntityCreate = ents.Create
local hook_Add = hook.Add
local hook_Remove = hook.Remove
local FindInSphere = ents.FindInSphere
local ipairs = ipairs
local EffectData = EffectData

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    slam = {
        model = "models/weapons/w_slam.mdl",
        origin = "Half-Life 2",
        prettyname = "S.L.A.M",
        holdtype = "slam",
        killicon = "npc_satchel",
        bonemerge = true,
        keepdistance = 300,
        attackrange = 400,

        OnThink = function( self, wepent, dead )
            if !dead and CurTime() > self.l_WeaponUseCooldown and self:GetState() != "Combat" and RandomInt( 1, 6 ) == 1 then
                local randPos = self:GetRandomPosition( nil, 400 )
                self:LookTo( randPos, 1.5 )
                self:SimpleWeaponTimer( 1, function() self:UseWeapon( randPos ) end )
            end

            return 1.0
        end,

        OnAttack = function( self, wepent, target )
            local satchel = EntityCreate( "npc_satchel" )
            if !IsValid( satchel ) then return end

            local throwPos = ( ( IsEntity( target ) and IsValid( target ) ) and target:GetPos() or target )
            local faceDir = ( !throwPos and self:GetForward() or ( throwPos - ( self:WorldSpaceCenter() + self:GetUp() * 24 ) ):GetNormalized() )

            satchel:SetPos( self:WorldSpaceCenter() + faceDir * 18 + self:GetUp() * 24 )
            satchel:SetSaveValue( "m_hThrower", self )
            satchel:SetSaveValue( "m_bIsLive", true )
            satchel:Spawn()
            satchel:SetOwner( self )
            satchel:SetLocalAngularVelocity( Angle( 0, 400, 0 ) )

            local phys = satchel:GetPhysicsObject()
            if IsValid( phys ) then phys:ApplyForceCenter( self.loco:GetVelocity() + faceDir * 500 ) end

            local hookID = "LambdaSLAM_SearchForTargets_" .. satchel:EntIndex()
            local thinkTime = CurTime() + 0.1
            hook_Add( "Think", hookID, function()
                if CurTime() < thinkTime then return end
                if !IsValid( satchel ) then hook_Remove( "Think", hookID ) return end
                
                if !LambdaIsValid( self ) then 
                    satchel:EmitSound( "Weapon_SLAM.TripMineMode" )
                    SimpleTimer( RandomFloat( 0.25, 0.5 ), function() 
                        if !IsValid( satchel ) then return end

                        local effData = EffectData()
                        effData:SetOrigin( satchel:GetPos() )
                        EmitEffect( "Explosion", effData, true, true )

                        satchel:Remove()
                        EmitExplosion( satchel, ( IsValid( self ) and self or satchel ), satchel:WorldSpaceCenter(), 200, 150 )
                    end )

                    hook_Remove( "Think", hookID ) 
                    return 
                end

                for _, v in ipairs( FindInSphere( satchel:GetPos() - ( satchel:GetVelocity() * 0.25 ), RandomInt( 125, 175 ) ) ) do
                    if v == self or v == satchel or !LambdaIsValid( v ) or !self:CanTarget( v ) or !satchel:Visible( v ) then continue end

                    wepent:EmitSound( "Weapon_SLAM.SatchelDetonate" )
                    satchel:EmitSound( "Weapon_SLAM.TripMineMode" )
                    SimpleTimer( RandomFloat( 0.25, 0.5 ), function() 
                        if !IsValid( satchel ) then return end

                        local effData = EffectData()
                        effData:SetOrigin( satchel:GetPos() )
                        EmitEffect( "Explosion", effData, true, true )

                        satchel:Remove()
                        EmitExplosion( satchel, ( IsValid( self ) and self or satchel ), satchel:WorldSpaceCenter(), 200, 150 )
                    end )

                    hook_Remove( "Think", hookID ) 
                    return
                end

                thinkTime = CurTime() + 0.1
            end )

            self.l_WeaponUseCooldown = CurTime() + 2.5

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM )

            wepent:EmitSound( "Weapon_SLAM.SatchelThrow" )

            return true
        end,

        islethal = true
    }
})