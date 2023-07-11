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

        OnThink = function( self, wepent, dead )
            if !dead and CurTime() > self.l_WeaponUseCooldown and random( 80 ) == 1 and !self:InCombat() then
                local randPos = self:GetRandomPosition( nil, 400 )
                self:LookTo( randPos, 1.5 )
                self:SimpleWeaponTimer( 1, function() self:UseWeapon( randPos ) end )
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

            slam:SetColor( self:GetPlyColor():ToColor() )
            wepent:EmitSound( "Weapon_SLAM.SatchelThrow" )

            self:DeleteOnRemove( slam )
            self.l_WeaponUseCooldown = ( CurTime() + 2.5 )
            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM )

            local nextThink = 0
            slam:LambdaHookTick( "LambdaSLAM_OnThink", function()
                if CurTime() < nextThink then return end
                nextThink = ( CurTime() + 0.1 )

                local shouldExplode = !self:Alive()
                if !shouldExplode then
                    for _, ent in ipairs( FindInSphere( slam:GetPos() - ( slam:GetVelocity() * 0.25 ), random( 125, 175 ) ) ) do
                        shouldExplode = ( ent != self and ent != slam and IsValid( ent ) and self:CanTarget( ent ) and slam:Visible( ent ) )
                        if shouldExplode then break end
                    end
                end

                if shouldExplode then
                    if self:Alive() then wepent:EmitSound( "Weapon_SLAM.SatchelDetonate" ) end
                    slam:EmitSound( "Weapon_SLAM.TripMineMode" )

                    self:SimpleTimer( Rand( 0.25, 0.5 ), function() 
                        if !IsValid( slam ) then return end

                        local effData = EffectData()
                        effData:SetOrigin( slam:GetPos() )
                        util_Effect( "Explosion", effData )

                        BlastDamage( slam, self, slam:WorldSpaceCenter(), 200, 150 )
                        slam:Remove()
                    end, true )

                    return true
                end
            end )

            return true
        end,

        islethal = true
    }
})