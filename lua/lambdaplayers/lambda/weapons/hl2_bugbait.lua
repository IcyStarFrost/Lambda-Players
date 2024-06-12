
local CurTime = CurTime

local ents_Create = ents.Create
local Angle = Angle
local IsValid = IsValid
local VectorRand = VectorRand

local antLimit = GetConVar( "lambdaplayers_weapons_bugbait_antlionlimit" )

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    bugbait = {
        model = "models/weapons/w_bugbait.mdl",
        origin = "Half-Life 2",
        prettyname = "Bug Bait",
        holdtype = "grenade",
        bonemerge = true,
        dropentity = "weapon_bugbait",
        
        islethal = true,
        keepdistance = 600,
        attackrange = 1500,

        OnDeploy = function( self, wepent )
            self.l_AntlionCount = 0
            
            wepent.NextSqueezeTime = ( CurTime() + LambdaRNG( 20 ) )
            wepent.NextThrowTime = ( CurTime() + LambdaRNG( 10 ) )
        end,

        OnHolster = function( self, wepent )
            wepent.NextSqueezeTime = nil
            wepent.NextThrowTime = nil
        end,

        OnAttack = function( self, wepent, target )
            if !self.l_AntlionCount then
                self.l_AntlionCount = 0
                return true
            end
            if self.l_AntlionCount >= antLimit:GetInt() then return true end

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
            self.l_WeaponUseCooldown = ( CurTime() + 2 )

            local bait = ents_Create( "npc_grenade_bugbait" )
            bait:SetPos( wepent:GetPos() )
            bait:SetSaveValue( "m_hThrower", self )
            bait:SetOwner( self )
            bait:Spawn()
            bait:SetCollisionGroup( COLLISION_GROUP_WEAPON )

            bait:SetVelocity( ( ( ( isvector( target ) and target or target:GetPos() ) + VectorRand( -60, 60 ) ) - wepent:GetPos() ):GetNormalized() * 1000 )
            bait:SetLocalAngularVelocity( Angle( 600, LambdaRNG( -1200, 1200 ), 0 ) )

            bait:CallOnRemove( "LambdaPlayers_BugbaitSpawnAntlion" .. bait:GetCreationID(), function()
                if !IsValid( self ) then return end

                local ant = ents_Create( "npc_lambdaantlion" )
                ant:SetPos( bait:GetPos() )
                ant:SetAngles( Angle( 0, bait:GetAngles().y, 0 ) )
                ant:SetOwner( self )
                ant:Spawn()
            end )

            return true
        end,

        OnThink = function( self, wepent, isDead )
            if isDead then return end

            if CurTime() >= wepent.NextSqueezeTime then
                wepent.NextSqueezeTime = ( CurTime() + LambdaRNG( 20 ) )
                wepent:EmitSound( "weapons/bugbait/bugbait_squeeze" .. LambdaRNG( 3 ) .. ".wav", 65, 100, 10, CHAN_WEAPON )
            end

            if CurTime() >= wepent.NextThrowTime then 
                wepent.NextThrowTime = ( CurTime() + LambdaRNG( 10 ) )

                if self.l_AntlionCount < antLimit:GetInt() then
                    local rndPos = self:GetRandomPosition( nil, 750 )
                    self:LookTo( rndPos, 3 )
                    self:SimpleWeaponTimer( LambdaRNG( 1, 2, true ), function() self:UseWeapon( rndPos ) end )
                end
            end

            return 1.0
        end
    }
} )