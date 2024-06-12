AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.PrintName = "Lambda Antlion"
ENT.Author = "YerSoMashy"
ENT.IsLambdaAntlion = true

if ( CLIENT ) then 
    language.Add( "npc_lambdaantlion", ENT.PrintName ) 
else
    local CreateSound = CreateSound
    local IsValid = IsValid
    local string_Explode = string.Explode
    local ipairs = ipairs
    local CurTime = CurTime
    local ents_GetAll = ents.GetAll
    local FindInCone = ents.FindInCone
    local FindInSphere = ents.FindInSphere
    local hook_Add = hook.Add
    local hook_Run = hook.Run
    local hook_Remove = hook.Remove
    local SimpleTimer = timer.Simple
    local istable = istable
    local isentity = isentity
    local isvector = isvector
    local Path = Path
    local GetNavArea = navmesh.GetNavArea
    local GetNavAreas = navmesh.Find
    local GetNearestNavArea = navmesh.GetNearestNavArea
    local wait = coroutine.wait
    local yield = coroutine.yield
    local max = math.max
    local Clamp = math.Clamp
    
    
    local DamageInfo = DamageInfo
    local Vector = Vector
    local TraceHull = util.TraceHull

    local plyClr = Color( 255, 255, 255, 255 )
    local collMins, collMaxs = Vector( -10, -10, 0 ), Vector( 10, 10, 55 )
    local spawnPosFix = {
        mins = collMins,
        maxs = collMaxs
    }

    local ignorePlys = GetConVar( "ai_ignoreplayers" )
    local spawnHP = GetConVar( "lambdaplayers_weapons_bugbait_antlionhealth" )
    local dealDmg = GetConVar( "lambdaplayers_weapons_bugbait_antliondamage" )

    function ENT:Initialize()
        self:SetModel( "models/antlion.mdl" )
        self:SetCollisionBounds( collMins, collMaxs )
        self:PhysicsInitShadow()

        local hp = spawnHP:GetInt()
        self:SetHealth( hp )
        self:SetMaxHealth( hp )

        self:SetSkin( LambdaRNG( 0, ( self:SkinCount() - 1 ) ) )
        self:AddFlags( FL_OBJECT )
        self:SetShouldServerRagdoll( true )

        self.loco:SetAcceleration( 800 )
        self.loco:SetDesiredSpeed( 500 )

        self.l_UseLambdaDmgModifier = true
        self.NextFootstepT = 0
        self.NextProcessT = 0
        self.Enemy = NULL
        self.FlySound = CreateSound( self, "NPC_Antlion.WingsOpen" )

        local owner = self:GetOwner()
        if IsValid( owner ) then
            if owner.IsLambdaPlayer then
                self:SetColor( owner:GetPlyColor():ToColor() )
                owner.l_AntlionCount = ( owner.l_AntlionCount + 1 )
                owner:DeleteOnRemove( self )
            elseif owner:IsPlayer() then
                local clrInfo = string_Explode( " ", owner:GetInfo( "cl_playercolor" ) )
                plyClr.r = ( 255 * clrInfo[ 1 ] )
                plyClr.g = ( 255 * clrInfo[ 2 ] )
                plyClr.b = ( 255 * clrInfo[ 3 ] )
                self:SetColor( plyClr )
            end
        else
            SimpleTimer( 0.1, function()
                local creator = self:GetCreator()
                if !IsValid( creator ) then return end

                self:SetOwner( creator )
                if creator.IsLambdaPlayer then
                    self:SetColor( creator:GetPlyColor():ToColor() )
                    creator.l_AntlionCount = ( creator.l_AntlionCount + 1 )
                    creator:DeleteOnRemove( self )
                elseif creator:IsPlayer() then
                    local clrInfo = string_Explode( " ", creator:GetInfo( "cl_playercolor" ) )
                    plyClr.r = ( 255 * clrInfo[ 1 ] )
                    plyClr.g = ( 255 * clrInfo[ 2 ] )
                    plyClr.b = ( 255 * clrInfo[ 3 ] )
                    self:SetColor( plyClr )
                end
            end )
        end

        for _, npc in ipairs( ents_GetAll() ) do 
            if npc == self or !IsValid( npc ) or npc.IsLambdaPlayer or npc.IsLambdaAntlion or !npc:IsNPC() and !npc:IsNextBot() then continue end 
            self:HandleNPCRelations( npc )
        end

        local relationHook = "LambdaAntlion_SetNPCRelationships" .. self:GetCreationID()
        hook_Add( "OnEntityCreated", relationHook, function( ent )
            if !IsValid( self ) then hook_Remove( "OnEntityCreated", relationHook ) return end
            if !IsValid( ent ) or ent.IsLambdaPlayer or ent.IsLambdaAntlion or !ent:IsNPC() and !ent:IsNextBot() then return end
            self:HandleNPCRelations( ent )
        end )

        spawnPosFix.start = self:GetPos()
        spawnPosFix.endpos = ( spawnPosFix.start - vector_up * 1 )
        spawnPosFix.filter = self
        local spawnHit = TraceHull( spawnPosFix )

        if spawnHit.Hit then
            self.IsBusyActioning = true
            self:StartActivity( self:GetSequenceActivity( self:LookupSequence( "digidle" ) ) )
        end
        self:SetPos( spawnHit.HitPos )
    end

    function ENT:HandleNPCRelations( npc )
        local addRelationFunc = npc.AddEntityRelationship
        if !addRelationFunc then return end

        local owner = self:GetOwner()
        local relation = D_HT
        if IsValid( owner ) then
            if owner.IsLambdaPlayer then
                relation = owner:Relations( npc )
            elseif npc.Disposition then
                relation = npc:Disposition( owner )
            end
        end
        addRelationFunc( npc, self, relation, 99 )

        if relation == D_HT and npc.IsVJBaseSNPC then
            SimpleTimer( 0.1, function() 
                if !IsValid( self ) or !IsValid( npc ) or !npc.VJ_AddCertainEntityAsEnemy or !npc.CurrentPossibleEnemies then return end
                npc.VJ_AddCertainEntityAsEnemy[ #npc.VJ_AddCertainEntityAsEnemy + 1 ] = self
                npc.CurrentPossibleEnemies[ #npc.CurrentPossibleEnemies + 1 ] = self
            end )
        end
    end

    function ENT:Think()
        if self.IsBusyActioning then return end

        if CurTime() >= self.NextProcessT then
            self.NextProcessT = ( CurTime() + 0.2 )

            local owner = self:GetOwner()
            if IsValid( owner ) then
                self.loco:SetDesiredSpeed( 500 )

                if owner.IsLambdaPlayer then
                    self.Enemy = ( ( owner:InCombat() or owner:IsPanicking() ) and owner:GetEnemy() )
                else
                    local bugbaitHint = sound.GetLoudestSoundHint( SOUND_BUGBAIT, self:GetPos() )
                    if bugbaitHint and bugbaitHint.owner == owner then
                        local lastDist
                        local origin = bugbaitHint.origin
                        for _, ent in ipairs( FindInSphere( bugbaitHint.origin, 150 ) ) do
                            if ent == self or ent == owner or !LambdaIsValid( ent ) or ent.IsLambdaAntlion and ent:GetOwner() == owner or ( !ent:IsNPC() and !ent:IsNextBot() or ent:GetInternalVariable( "m_lifeState" ) != 0 ) and ( !ent:IsPlayer() or !ent:Alive() or ignorePlys:GetBool() ) then continue end

                            local entDist = ent:GetPos():DistToSqr( origin )
                            if lastDist and entDist > lastDist then continue end

                            self.Enemy = ent
                            lastDist = entDist
                        end

                        if !IsValid( self.Enemy ) then self.Enemy = origin end
                    else
                        if isvector( self.Enemy ) then self.Enemy = NULL end

                        local lastDist
                        for _, ent in ipairs( FindInSphere( self:GetPos(), 1500 ) ) do
                            if ent == self or ent == owner or !LambdaIsValid( ent ) or ent.IsLambdaAntlion and ent:GetOwner() == owner or ( !ent:IsNPC() and !ent:IsNextBot() or ent:GetInternalVariable( "m_lifeState" ) != 0 ) or !self:Visible( ent ) then continue end

                            local entDist = self:GetRangeSquaredTo( ent )
                            if lastDist and entDist > lastDist then continue end

                            local eneDisp = ent.Disposition
                            if eneDisp then 
                                if eneDisp( ent, owner ) != D_HT then continue end
                            else
                                local eneFunc = ent.GetEnemy
                                if !eneFunc then eneFunc = ent.GetTarget end
                                if !eneFunc or eneFunc( ent ) != owner and eneFunc( ent ) != self then continue end
                            end

                            self.Enemy = ent
                            lastDist = entDist
                        end
                    end
                end
            else
                local lastDist
                for _, ent in ipairs( FindInSphere( self:GetPos(), 1500 ) ) do
                    if ent == self or !LambdaIsValid( ent ) or ent.IsLambdaAntlion and !IsValid( ent:GetOwner() ) or ( !ent:IsNPC() and !ent:IsNextBot() or ent:GetInternalVariable( "m_lifeState" ) != 0 ) and ( !ent:IsPlayer() or !ent:Alive() or ignorePlys:GetBool() ) or !self:Visible( ent ) then continue end

                    local entDist = self:GetRangeSquaredTo( ent )
                    if lastDist and entDist > lastDist then continue end

                    self.Enemy = ent
                    lastDist = entDist
                end

                self.loco:SetDesiredSpeed( IsValid( self.Enemy ) and 500 or 250 )
            end
        end

        local anim = self:GetActivity()
        if self.loco:IsOnGround() then 
            if !self.loco:GetVelocity():IsZero() then 
                if CurTime() >= self.NextFootstepT then
                    self:EmitSound( "NPC_Antlion.Footstep" )
                    self.NextFootstepT = ( CurTime() + Clamp( 0.175 * ( 500 / self.loco:GetVelocity():Length() ), 0.175, 0.35 ) )
                end

                anim = ACT_RUN
            else
                anim = ACT_IDLE                
            end
        end
        if self:GetActivity() != anim then self:StartActivity( anim ) end
    end
    
    local attackAnims = { "attack1", "attack2", "attack3", "attack4" }

    function ENT:RunBehaviour()
        self:EmitSound( "NPC_Antlion.BurrowOut" )
        self:PlaySequenceAndWait( "digout" )        
        self.IsBusyActioning = false

        while ( true ) do
            if isvector( self.Enemy ) then
                self:MoveToPosition( self.Enemy )
                wait( 1.0 )
            elseif IsValid( self.Enemy ) then
                local chasePath = self:MoveToPosition( self.Enemy )

                if IsValid( self.Enemy ) and chasePath == "ok" then
                    self:EmitSound( "NPC_Antlion.MeleeAttackSingle" )
                    self:FacePosition( self.Enemy:GetPos() )

                    SimpleTimer( 0.45, function()
                        if !IsValid( self ) then return end

                        local dmginfo = DamageInfo()
                        dmginfo:SetDamage( dealDmg:GetInt() )
                        dmginfo:SetDamageType( DMG_SLASH )
                        dmginfo:SetInflictor( self )

                        local owner = self:GetOwner()
                        dmginfo:SetAttacker( IsValid( owner ) and owner or self )

                        local hitOnce = false
                        for _, v in ipairs( FindInCone( self:WorldSpaceCenter(), self:GetForward(), 100, 0.4 ) ) do
                            if v == self or v == owner or !LambdaIsValid( v ) or !self:Visible( v ) then continue end
                            if v.IsLambdaAntlion and v:GetOwner() == owner then continue end

                            v:TakeDamageInfo( dmginfo )
                            hitOnce = true
                        end
                        if hitOnce then self:EmitSound( "NPC_Antlion.MeleeAttack" ) end
                    end )

                    self.IsBusyActioning = true

                    self:SetSequence( attackAnims[ LambdaRNG( #attackAnims ) ] )
                    self:ResetSequenceInfo()
                    self:SetCycle( 0 )
                    self:SetPlaybackRate( 1.5 )

                    wait( 0.9 )
                    self.IsBusyActioning = false
                end
            else
                local owner = self:GetOwner()
                if LambdaIsValid( owner ) then 
                    if self:GetRangeSquaredTo( owner ) > 30625 then
                        self:MoveToPosition( owner, 125, true )
                        wait( 0.1 )
                    else
                        wait( 0.5 )
                    end
                else
                    local rndPos = ( self:GetPos() + ( Vector( LambdaRNG( -1, 1, true ), LambdaRNG( -1, 1, true ), 0 ) * 750 ) )
                    local nearArea = GetNearestNavArea( rndPos )
                    if IsValid( nearArea ) then rndPos = nearArea:GetClosestPointOnArea( rndPos ) end
                    self:MoveToPosition( rndPos, nil, true, false )
                end
            end

            yield()
        end
    end

    function ENT:FacePosition( pos )
        local faceAng = ( pos - self:GetPos() ):Angle()
        faceAng.x = 0
        faceAng.z = 0
        self:SetAngles( faceAng )
    end

    function ENT:MoveToPosition( goal, tolerance, cancelOnEnemy, update )
        local isEnt = isentity( goal )
        local goalPos = ( ( isEnt and IsValid( goal ) ) and goal:GetPos() or goal )

        local path = Path( "Follow" )
        path:SetMinLookAheadDistance( 500 )
        path:SetGoalTolerance( tolerance or 32 )
        path:Compute( self, goalPos )
        if !IsValid( path ) then return "failed" end

        update = ( update == nil and true )

        while ( IsValid( path ) ) do
            if isEnt and !IsValid( goal ) or cancelOnEnemy and IsValid( self.Enemy ) then return "failed" end
            goalPos = ( ( isEnt and IsValid( goal ) ) and goal:GetPos() or goal )

            if isEnt then
                local distSqr = self:GetRangeSquaredTo( goalPos )
                if distSqr > 360000 and distSqr <= 2250000 and self.loco:IsOnGround() and self:VisibleVec( goal:WorldSpaceCenter() ) and LambdaRNG( 50 ) == 1 then
                    SimpleTimer( 0.5, function()
                        if !IsValid( self ) or !IsValid( goal ) then return end
                        self:SetBodygroup( 1, 1 )
                        self.FlySound:Play()
                        self.loco:JumpAcrossGap( goal:GetPos(), self:GetForward() )
                    end )

                    self.IsBusyActioning = true
                    self:FacePosition( goalPos )
                    self:PlaySequenceAndWait( "fly_in" )
                    if !IsValid( goal ) or cancelOnEnemy and IsValid( self.Enemy ) then return "failed" end
                end
            end

            if update then
                local updateTime = max( 0.1, 0.1 * ( path:GetLength() / 500 ) )
                if path:GetAge() >= updateTime then path:Compute( self, goalPos ) end
            end

            path:Update(self)

            if self.loco:IsStuck() then
                self:HandleStuck()
                return "stuck"
            end

            yield()
        end

        return "ok"
    end

    function ENT:HandleStuck()
        self.IsBusyActioning = true
        self:DrawShadow( false )
        self:EmitSound( "NPC_Antlion.BurrowIn" )
        self:PlaySequenceAndWait( "digin" )

        self:StartActivity( self:GetSequenceActivity( self:LookupSequence( "digidle" ) ) )

        local owner = self:GetOwner()
        local area = ( IsValid( owner ) and GetNavArea( owner:GetPos(), 120 ) or GetNavAreas( self:GetPos(), 750, 256, 256 ) )
        if IsValid( area ) then self:SetPos( istable( area ) and area[ LambdaRNG( #area ) ]:GetRandomPoint() or area:GetRandomPoint() ) end

        self:DrawShadow( true )
        self:EmitSound( "NPC_Antlion.BurrowOut" )
        self:PlaySequenceAndWait( "digout" )

        self.IsBusyActioning = false
        self.loco:ClearStuck()
    end

    function ENT:OnTakeDamage( dmginfo )
        local owner = self:GetOwner()
        if dmginfo:GetAttacker() == owner then return true end
        
        self:EmitSound( "NPC_Antlion.Pain" )
        if LambdaIsValid( owner ) and owner.IsLambdaPlayer then owner:OnInjured( dmginfo ) end
    end

    function ENT:OnKilled( dmginfo )
        self.FlySound:Stop()
        hook_Run( "OnNPCKilled", self, dmginfo:GetAttacker(), dmginfo:GetInflictor() )

        local ragdoll = self:BecomeRagdoll( dmginfo )
        ragdoll:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
        SimpleTimer( 15, function()
            if !IsValid( ragdoll ) then return end
            ragdoll:Remove()
        end )
    end

    function ENT:OnOtherKilled( victim, dmginfo )
        if victim == self.Enemy then self.Enemy = NULL end
    end

    function ENT:OnRemove()
        self.FlySound:Stop()

        local owner = self:GetOwner()
        if IsValid( owner ) and owner.l_AntlionCount then
            owner.l_AntlionCount = ( owner.l_AntlionCount - 1 )
        end
    end

    function ENT:OnLandOnGround()
        if self.FlySound:IsPlaying() then
            self.FlySound:Stop()
            self:SetBodygroup( 1, 0 )
            self:EmitSound( "NPC_Antlion.Land" )
            self.IsBusyActioning = false
        end
    end
end