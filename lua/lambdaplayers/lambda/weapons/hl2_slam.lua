local CurTime = CurTime
local ipairs = ipairs
local isentity = isentity
local IsValid = IsValid
local FindInSphere = ents.FindInSphere
local random = math.random
local Rand = math.Rand
local EffectData = EffectData
local ents_Create = ents.Create
local util_Effect = util.Effect
local BlastDamage = util.BlastDamage
local angVel = Angle( 0, 400, 0 )

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    slam = {
        model = "models/weapons/w_slam.mdl",
        origin = "Half-Life 2",
        prettyname = "S.L.A.M",
        holdtype = "slam",
        killicon = "npc_satchel",
        bonemerge = true,
        keepdistance = 400,
        attackrange = 500,

        OnDeploy = function( self, wepent )
            wepent.DroppedSlams = ( wepent.DroppedSlams or {} )
        end,

        OnThink = function( self, wepent, dead )
            if !dead and CurTime() > self.l_WeaponUseCooldown and random( 1, 80 ) == 1 and !self:InCombat() then
                local randPos = self:GetRandomPosition( nil, 400 )
                self:LookTo( randPos, 1.5 )
                self:SimpleWeaponTimer( 1, function() self:UseWeapon( randPos ) end )
            end

            for _, slam in ipairs( wepent.DroppedSlams ) do
                if !IsValid( slam ) or slam.l_BeingDetonated then continue end

                local shouldExplode = dead
                if !shouldExplode then
                    for _, ent in ipairs( FindInSphere( slam:GetPos() - ( slam:GetVelocity() * 0.25 ), random( 125, 175 ) ) ) do
                        shouldExplode = ( ent != self and ent != slam and IsValid( ent ) and self:CanTarget( ent ) and slam:Visible( ent ) )
                        if shouldExplode then break end
                    end
                end

                if shouldExplode then
                    if !dead then wepent:EmitSound( "Weapon_SLAM.SatchelDetonate" ) end
                    slam:EmitSound( "Weapon_SLAM.TripMineMode" )
                    slam.l_BeingDetonated = true

                    self:SimpleTimer( Rand( 0.25, 0.5 ), function() 
                        if !IsValid( slam ) then return end

                        local effData = EffectData()
                        effData:SetOrigin( slam:GetPos() )
                        util_Effect( "Explosion", effData, true, true )

                        slam:Remove()
                        BlastDamage( slam, self, slam:WorldSpaceCenter(), 200, 150 )
                    end, true ) 
                end
            end

            return 0.1
        end,

        OnAttack = function( self, wepent, target )
            local slam = ents_Create( "npc_satchel" )
            if !IsValid( slam ) then return end

            local throwPos = ( ( isentity( target ) and IsValid( target ) ) and target:GetPos() or target )
            local faceDir = ( !throwPos and self:GetForward() or ( throwPos - ( self:WorldSpaceCenter() + vector_up * 24 ) ):GetNormalized() )

            slam:SetPos( self:WorldSpaceCenter() + faceDir * 18 + self:GetUp() * 24 )
            slam:SetSaveValue( "m_hThrower", self )
            slam:SetSaveValue( "m_bIsLive", true )
            slam:Spawn()
            slam:SetOwner( self )
            slam:SetLocalAngularVelocity( angVel )

            local phys = slam:GetPhysicsObject()
            if IsValid( phys ) then phys:ApplyForceCenter( self.loco:GetVelocity() + faceDir * 500 ) end

            slam.l_BeingDetonated = false
            slam:SetColor( self:GetPlyColor():ToColor() )

            wepent:EmitSound( "Weapon_SLAM.SatchelThrow" )
            wepent.DroppedSlams[ #wepent.DroppedSlams + 1 ] = slam

            self:DeleteOnRemove( slam )
            self.l_WeaponUseCooldown = ( CurTime() + 2.5 )
            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM )

            return true
        end,

        islethal = true
    }
})