local string = string
local table = table
local math = math
local hook_Add = hook.Add
local hook_Remove = hook.Remove
local RandomPairs = RandomPairs
local LambdaIsValid = LambdaIsValid
local print = print
local ipairs = ipairs
local pairs = pairs
local CurTime = CurTime
local RealTime = RealTime
local IsValid = IsValid
local file_Find = file.Find
local abs = math.abs
local max = math.max
local Clamp = math.Clamp
local FindInSphere = ents.FindInSphere
local file_Find = file.Find
local table_Empty = table.Empty
local table_IsEmpty = table.IsEmpty
local table_RemoveByValue = table.RemoveByValue
local table_Copy = table.Copy
local table_Add = table.Add
local ents_GetAll = ents.GetAll
local VectorRand = VectorRand
local SortTable = table.sort
local timer_simple = timer.Simple
local timer_create = timer.Create
local timer_Remove = timer.Remove
local table_Merge = table.Merge
local coroutine = coroutine
local Trace = util.TraceLine
local TraceHull = util.TraceHull
local EndsWith = string.EndsWith
local tobool = tobool
local isstring = isstring
local string_sub = string.sub
local next = next
local floor = math.floor
local table_concat = table.concat
local string_Explode = string.Explode
local string_match = string.match
local table_insert = table.insert
local StartsWith = string.StartsWith
local isfunction = isfunction
local isentity = isentity
local tostring = tostring
local visibilitytrace = {}
local tracetable = {}
local jumpTr = {}
local GetLambdaPlayers = GetLambdaPlayers
local color_white = color_white
local ents_Create = ents and ents.Create or nil
local red = Color( 255, 0, 0 )
local GetConVar = GetConVar
local aidisable = GetConVar( "ai_disabled" )
local debugcvar = GetConVar( "lambdaplayers_debug" )
local chatAllowed = GetConVar( "lambdaplayers_text_enabled" )
local chatlimit = GetConVar( "lambdaplayers_text_chatlimit" )
local collisionPly = GetConVar( "lambdaplayers_lambda_noplycollisions" )
local rasp = GetConVar( "lambdaplayers_lambda_respawnatplayerspawns" )
local serversidecleanup = GetConVar( "lambdaplayers_lambda_serversideremovecorpseonrespawn" )
local serversidecleanupeffect = GetConVar( "lambdaplayers_lambda_serversideragdollcleanupeffect" )
local usemarkovgenerator = GetConVar( "lambdaplayers_text_markovgenerate" )
local allowlinks = GetConVar( "lambdaplayers_text_allowimglinks" )
local player_GetAll = player.GetAll
local vpFallback = GetConVar( "lambdaplayers_voice_voiceprofilefallback" )
local isnumber = isnumber
local ismatrix = ismatrix
local IsValidModel = util.IsValidModel
local IsNavmeshLoaded = ( SERVER and navmesh.IsLoaded )
local obeynav = GetConVar( "lambdaplayers_lambda_obeynavmeshattributes" )
local spawnBehavior = GetConVar( "lambdaplayers_combat_spawnbehavior" )
local spawnBehavInitSpawn = GetConVar( "lambdaplayers_combat_spawnbehavior_initialspawnonly" )
local spawnBehavUseRange = GetConVar( "lambdaplayers_combat_spawnbehavior_usedistance" )
local ignoreFriendNPCs = GetConVar( "lambdaplayers_combat_ignorefriendlynpcs" )
local slightDelay = GetConVar( "lambdaplayers_voice_slightdelay" )
local allowShots = GetConVar( "lambdaplayers_viewshots_enabled" )
local changePlyMdlChance = GetConVar( "lambdaplayers_lambda_switchplymdlondeath" )
local allowaddonmodels = GetConVar( "lambdaplayers_lambda_allowrandomaddonsmodels" )
local onlyaddonmodels = GetConVar( "lambdaplayers_lambda_onlyaddonmodels" )
local rndBodyGroups = GetConVar( "lambdaplayers_lambda_allowrandomskinsandbodygroups" )
local allowMdlBgSets = GetConVar( "lambdaplayers_lambda_enablemdlbodygroupsets" )

---- Anything Shared can go here ----

-- Function for debugging prints
function ENT:DebugPrint( ... )
    if !debugcvar:GetBool() then return end
    print( self:GetLambdaName() .. " EntIndex = ( " .. self:EntIndex() .. " )" .. ": ", ... )
end

-- Creates a hook that will remove itself if it runs while the Lambda is invalid or if the provided function returns false
-- preserve makes the hook not remove itself when the Entity is considered "dead" by self:GetIsDead(). Mainly used by Respawning
-- cooldown arg is meant to be used with Tick and Think hooks
function ENT:Hook( hookname, uniquename, func, preserve, cooldown )
    cooldown = ( cooldown or 0 )
    local curTime = ( CurTime() + cooldown )
    local hookIdent = "lambdaplayershook" .. self:EntIndex() .. "_" .. uniquename

    self:DebugPrint( "Created a hook: " .. hookname .. " | " .. uniquename )
    self.l_Hooks[ hookname ] = ( self.l_Hooks[ hookname ] or {} )
    self.l_Hooks[ hookname ][ uniquename ] = { hookIdent, preserve }

    hook_Add( hookname, hookIdent, function( ... )
        if CurTime() < curTime then return end
        if !IsValid( self ) then hook_Remove( hookname, hookIdent ) return end
        if !preserve and self:GetIsDead() then self:RemoveHook( hookname, uniquename ) return end

        local result = func( ... )
        if result == "end" then self:RemoveHook( hookname, uniquename ) return end

        curTime = ( CurTime() + cooldown )
        return result
    end )
end

-- Returns if the hook exists
function ENT:HookExists( hookname, uniquename )
    local hooks = self.l_Hooks
    return ( hooks[ hookname ] != nil and hooks[ hookname ][ uniquename ] != nil )
end

-- Removes a hook created by the function above
function ENT:RemoveHook( hookname, uniquename )
    local hooks = self.l_Hooks
    if hooks[ hookname ] == nil then return end

    local hookTbl = hooks[ hookname ][ uniquename ]
    if hookTbl == nil then return end

    self:DebugPrint( "Removed a hook: " .. hookname .. " | " .. uniquename )
    hooks[ hookname ][ uniquename ] = nil
    hook_Remove( hookname, hookTbl[ 1 ] )
end

-- Creates a coroutine thread
function ENT:Thread( func, name, preserve )
    local thread = coroutine.create( func )
    self:DebugPrint( "Created a Thread | " .. name  )

    self:Hook( "Tick", "CoroutineThread_" .. name, function()
        if coroutine.status( thread ) != "dead" then
            local ok, msg = coroutine.resume( thread )
            if !ok then ErrorNoHaltWithStack( self, " ", msg ) end
        else
            self:RemoveHook( "Tick", "CoroutineThread_" .. name )
        end
    end, preserve, 0 )
end

-- Kills the specified thread, making it stop running
function ENT:KillThread( name )
    self:RemoveHook( "Tick", "CoroutineThread_" .. name )
end

-- Creates a simple timer that won't run if we are invalid or dead. ignoredead var will run the timer even if self:GetIsDead() is true
function ENT:SimpleTimer( delay, func, ignoredead )
    local id = tostring( func ) .. LambdaRNG( 100000 )
    local lastDeathT = self.l_LastDeathTime
    self.l_SimpleTimers[ id ] = !ignoredead
    timer_simple( delay, function()
        if !IsValid( self ) or !ignoredead and ( lastDeathT != self.l_LastDeathTime or !self.l_SimpleTimers[ id ] or !self:Alive() ) then return end
        func( self )
        self.l_SimpleTimers[ id ] = nil
    end )
end

-- Same as ENT:SimpleTimer(), but also checks if our weapon is valid and is the same one we created this timer with
function ENT:SimpleWeaponTimer( delay, func, ignoredead, ignorewepname )
    local lastSwitchT = self.l_LastWeaponSwitchTime
    self:SimpleTimer( delay, function()
        if !IsValid( self:GetWeaponENT() ) or !ignorewepname and lastSwitchT != self.l_LastWeaponSwitchTime then return end
        func( self )
    end, ignoredead )
end

-- Prevents every simple timer that does not have ignoredead from running
function ENT:TerminateNonIgnoredDeadTimers()
    table_Empty( self.l_SimpleTimers )
end

-- Creates a named timer that can be stopped. ignoredead var will run the time even if we are dead
-- Return true in the function to remove the timer
function ENT:NamedTimer( name, delay, repeattimes, func, ignoredead )
    local id = self:EntIndex()
    local intname = "lambdaplayers_" .. name .. id
    self:DebugPrint( "Created a Timer: " .. name )

    timer_create( intname, delay, repeattimes, function()
        if !IsValid( self ) or !ignoredead and !self:Alive() then return end
        local result = func( self )
        if result == true then timer_Remove( intname ); self:DebugPrint( "Removed a Timer: " .. name ) end
    end )

    table_insert( self.l_Timers, intname )
end

-- Same as ENT:NamedTimer(), but also checks if our weapon is valid and is the same one we created this timer with
function ENT:NamedWeaponTimer( name, delay, repeattimes, func, ignoredead, ignorewepname )
    local lastSwitchT = self.l_LastWeaponSwitchTime
    self:NamedTimer( name, delay, repeattimes, function()
        if !IsValid( self:GetWeaponENT() ) then return true end 
        if !ignorewepname and lastSwitchT != self.l_LastWeaponSwitchTime then return end
        return func( self )
    end, ignoredead )
end

-- Removes the named timer
function ENT:RemoveNamedTimer( name )
    local id = self:EntIndex()
    local intname = "lambdaplayers_" .. name .. id
    for k, v in ipairs( self.l_Timers ) do
        if v == intname then
            self:DebugPrint( "Removed a Timer: " .. name )
            timer_Remove( intname )
            break
        end
    end
end

-- Removes all timers
function ENT:RemoveTimers()
    for k, v in ipairs( self.l_Timers ) do
        timer_Remove( v )
    end
end

-- Find in sphere function with a filter
function ENT:FindInSphere( pos, radius, filter )
    pos = pos or self:GetPos()
    local enttbl = {}

    for k, v in ipairs( FindInSphere( pos, radius ) ) do
        if IsValid( v ) and v != self and ( filter == nil or filter( v ) ) then
            enttbl[ #enttbl + 1 ] = v
        end
    end

    return enttbl
end

-- Returns the closest entity to us
function ENT:GetClosestEntity( pos, radius, filter )
    pos = pos or self:GetPos()
    local closestent
    local dist
    local find = self:FindInSphere( pos, radius, filter )

    for k, v in ipairs( find ) do
        if !closestent then closestent = v dist = pos:DistToSqr( v:GetPos() ) continue end
        local newdist = pos:DistToSqr( v:GetPos() )
        if newdist < dist then
            closestent = v
            dist = newdist
        end
    end

    return closestent
end

-- Returns the position and angle of a specified bone
function ENT:GetBoneTransformation( bone, target )
    target = ( target or self )

    local pos, ang = target:GetBonePosition( bone )
    if !pos or pos:IsZero() or pos == target:GetPos() then
        local matrix = target:GetBoneMatrix( bone )
        if matrix and ismatrix( matrix ) then
            pos = matrix:GetTranslation()
            ang = matrix:GetAngles()
        end
    end

    return { Pos = pos, Ang = ang, Bone = bone }
end

-- Returns a table that contains a position and angle with the specified type. hand or eyes
local eyeOffAng = Angle( 20, 0, 0 )
function ENT:GetAttachmentPoint( pointType, target )
    target = ( target or self )
    local attachData = { Pos = target:WorldSpaceCenter(), Ang = target:GetForward():Angle(), Index = 0 }

    if pointType == "hand" then
        local lookup = target:LookupAttachment( "anim_attachment_RH" )
        local handAttach = target:GetAttachment( lookup )

        if !handAttach then
            local bone = target:LookupBone( "ValveBiped.Bip01_R_Hand" )
            if isnumber( bone ) then attachData = target:GetBoneTransformation( bone ) end
        else
            attachData = handAttach
            attachData.Index = lookup
        end
    elseif pointType == "eyes" then
        local lookup = target:LookupAttachment( "eyes" )
        local eyeAttach = target:GetAttachment( lookup )

        if !eyeAttach then
            attachData.Pos = ( attachData.Pos + vector_up * 30 )
            attachData.Ang = ( attachData.Ang + eyeOffAng )
        else
            attachData = eyeAttach
            attachData.Index = lookup
        end
    end

    return attachData
end
--

-- Returns a normal direction to the pos or entity
function ENT:GetNormalTo( pos )
    pos = ( isentity( pos ) and pos:GetPos() or pos )
    return ( pos - self:WorldSpaceCenter() ):GetNormalized()
end

-- AI/Nextbot creators can assign .LambdaPlayerSTALP = true to their entities if they want the Lambda Players to treat them like players
-- When the function is underused: >:(
function ENT:ShouldTreatAsLPlayer( ent )
    if ent.LambdaPlayerSTALP then return true end
    if ent.IsLambdaPlayer then return true end
    if ent:IsPlayer() then return true end
    if ent:IsNPC() or ent:IsNextBot() then return false end
end

-- Turns the Lambda Player into a table of its personal data
-- See function ENT:ApplyLambdaInfo() to use this data with
-- This function is shared so that means the client can get a Lambda Player's info and save it for themselves
function ENT:ExportLambdaInfo()
    local info = {
        name = self:GetLambdaName(),
        model = self:GetModel(),
        profilepicture = self:GetProfilePicture(),
        health = self:GetNWMaxHealth(),

        crouchspeed = self:GetCrouchSpeed(),
        slowwalkspeed = self:GetSlowWalkSpeed(),
        walkspeed = self:GetWalkSpeed(),
        runspeed = self:GetRunSpeed(),

        mdlSkin = self:GetSkin(),
        bodygroups = self:GetBodyGroupData(),

        plycolor = self:GetPlyColor(),
        physcolor = self:GetPhysColor(),

        voicepitch = self:GetVoicePitch(),
        voice = self:GetVoiceChance(),
        text = self:GetTextChance(),
        voiceprofile = self:GetNW2String( "lambda_vp", self.l_VoiceProfile ),
        textprofile = self:GetNW2String( "lambda_tp", self.l_TextProfile ),
        averageping = self:GetAvgPing(),

        -- Non personal data --
        respawn = self:GetRespawn(),
        spawnwep = self:GetNW2String( "lambda_spawnweapon", self.l_SpawnWeapon ),
        frags = self:GetFrags(),
        deaths = self:GetDeaths(),

        externalvars = table_Copy( self.l_ExternalVars ),

--[[         -- NW Vars --
        nwvars = self:GetNWVarTable(),
        nw2vars = self:GetNW2VarTable(), ]]
    }

    info.personality = {}
    for k, v in ipairs( self.l_Personality ) do
        info.personality[ v[ 1 ] ] = self:GetNW2Int( "lambda_chance_" .. v[ 1 ], 0 )
    end

    return info
end

-- Performs a Trace from ourselves or the overridestart to the postion
function ENT:Trace( pos, overridestart, ignoreEnt )
    tracetable.start = overridestart or self:WorldSpaceCenter()
    tracetable.endpos = ( isentity( pos ) and IsValid( pos ) and pos:GetPos() or pos )
    tracetable.filter = ( ignoreEnt and { self, ignoreEnt } or self )
    return Trace( tracetable )
end

-- Returns if we can see the ent in question.
-- Simple trace
function ENT:CanSee( ent )
    if !IsValid( ent ) then return false end

    visibilitytrace.start = self:GetAttachmentPoint( "eyes" ).Pos
    visibilitytrace.endpos = ent:WorldSpaceCenter()
    visibilitytrace.filter = self

    local result = Trace( visibilitytrace )
    if LambdaRunHook( "LambdaOnCanSeeEntity", self, ent, result ) == true then return false end

    local hitEnt = result.Entity
    if IsValid( hitEnt ) and hitEnt:IsVehicle() and !ent:IsVehicle() then
        hitEnt = hitEnt:GetDriver()
    end
    return ( hitEnt == ent or result.Fraction == 1.0 )
end

-- Returns the color that should be used in displays such as Name Display, Text Chat, ect
-- If on Server, returns the color the ply is using for the Display Color
local useplycolorasdisplay = GetConVar( "lambdaplayers_useplayermodelcolorasdisplaycolor" )
function ENT:GetDisplayColor( ply )
    if CLIENT then
        local overridecolor = LambdaRunHook( "LambdaGetDisplayColor", self, LocalPlayer() )
        return overridecolor != nil and overridecolor or useplycolorasdisplay:GetBool() and self:GetPlyColor():ToColor() or _LambdaDisplayColor
    elseif SERVER then
        local useplycolorasdisplay = tobool( ply:GetInfoNum( "lambdaplayers_useplayermodelcolorasdisplaycolor", 0 ) )
        local overridecolor = LambdaRunHook( "LambdaGetDisplayColor", self, ply )
        return overridecolor != nil and overridecolor or useplycolorasdisplay and self:GetPlyColor():ToColor() or Color( ply:GetInfoNum( "lambdaplayers_displaycolor_r", 255 ), ply:GetInfoNum( "lambdaplayers_displaycolor_g", 136 ), ply:GetInfoNum( "lambdaplayers_displaycolor_b", 0 ) )
    end
end

-- Obviously returns the current state
-- If the 'checkState' argument is set, returns if current state is the set one instead
function ENT:GetState( checkState )
    local curState = self:GetNW2String( "lambda_state", "Idle" )
    if checkState then return ( checkState == curState ) end
    return curState
end

-- Returns the last state we were in
function ENT:GetLastState()
    return self:GetNW2String( "lambda_laststate", "Idle" )
end

-- If we currently are fighting
function ENT:InCombat()
    return ( self:GetState() == "Combat" and LambdaIsValid( self:GetEnemy() ) )
end

-- If we are panicking
function ENT:IsPanicking()
    return ( self:GetState() == "Retreat" )
end

-- Returns if we are currently speaking
function ENT:IsSpeaking( voicetype )
    return ( ( !voicetype or self:GetLastSpokenVoiceType() == voicetype ) and RealTime() < self:GetLastSpeakingTime() )
end

if SERVER then

    local GetAllNavAreas = navmesh.GetAllNavAreas
    local ignoreplayer = GetConVar( "ai_ignoreplayers" )
    local realisticfalldamage = GetConVar( "lambdaplayers_lambda_realisticfalldamage" )

    -- Applies info data from :ExportLambdaInfo() to the Lambda Player
    function ENT:ApplyLambdaInfo( info )
        self:SimpleTimer( 0, function()

            self:DebugPrint( "had Lambda Info applied to them" )

            self:SetLambdaName( info.name or self:GetLambdaName() )
            self:SetProfilePicture( info.profilepicture or self:GetProfilePicture() )
            self:SetMaxHealth( info.health or self:GetMaxHealth() )
            self:SetHealth( info.health or self:GetMaxHealth() )
            self:SetNWMaxHealth( info.health or self:GetMaxHealth() )
            self:SetArmor( info.armor or self:GetArmor() )

            self:SetCrouchSpeed( info.crouchspeed or self:GetCrouchSpeed() )
            self:SetSlowWalkSpeed( info.slowwalkspeed or self:GetSlowWalkSpeed() )
            self:SetWalkSpeed( info.walkspeed or self:GetWalkSpeed() )
            self:SetRunSpeed( info.runspeed or self:GetRunSpeed() )

            local model = ( info.model or self:GetModel() )
            if !IsValidModel( model ) then model = "models/player/kleiner.mdl" end
            self:SetPlayerModel( model, true )
            self:SetSkin( info.mdlSkin or 0 )

            local bodygroups = info.bodygroups
            if bodygroups and !table_IsEmpty( bodygroups ) then
                for index, submdl in pairs( bodygroups ) do
                    self:SetBodygroup( index, submdl )
                end
            end

            self:SetPlyColor( info.plycolor or self:GetPlyColor() )
            self:SetPhysColor( info.physcolor or self:GetPhysColor() )
            self.WeaponEnt:SetNW2Vector( "lambda_weaponcolor", ( info.physcolor or self:GetPhysColor() ) )

            if info.personality then
                self:BuildPersonalityTable( info.personality )
            end

            self:SetVoiceChance( info.voice or self:GetVoiceChance() )
            self:SetTextChance( info.text or self:GetTextChance() )
            SortTable( self.l_Personality, function( a, b ) return a[ 2 ] > b[ 2 ] end )

            self:SetAvgPing( info.averageping or info.pingrange or self:GetAvgPing() )
            self:SetVoicePitch( info.voicepitch or self:GetVoicePitch() )
            self.l_VoiceProfile = info.voiceprofile or self.l_VoiceProfile
            self:SetNW2String( "lambda_vp", self.l_VoiceProfile )

            self.l_TextProfile = info.textprofile or self.l_TextProfile
            self:SetNW2String( "lambda_tp", self.l_TextProfile )
            -- Non Personal Data --
            self:SetRespawn( info.respawn or self:GetRespawn() )
            self:SwitchToSpawnWeapon()
            self:SetNW2String( "lambda_spawnweapon", self.l_SpawnWeapon )

            self.l_FavoriteWeapon = ( info.favwep or self.l_FavoriteWeapon )
            self.l_WeaponRestrictions = ( info.weaponrestrictions or self.l_WeaponRestrictions )

            self:SetFrags( info.frags or self:GetFrags() )
            self:SetDeaths( info.deaths or self:GetDeaths() )

            if info.externalvars then
                for k, v in pairs( info.externalvars ) do
                    self.l_ExternalVars[ k ] = v
                    self[ k ] = v
                end
            end

            self:SetCollisionBounds( Vector( -10, -10, 0 ), Vector( 10, 10, 72 ) )
            self:PhysicsInitShadow()


--[[             -- NW Vars --
            local nw = info.nwvars
            local nw2 = info.nw2vars
            if istable( nw ) then
                for k, v in pairs( nw ) do
                    self:SetNWVar( k, v )
                end
            end
            if istable( nw2 ) then
                for k, vartable in pairs( nw2 ) do
                    self:SetNW2Var( k, vartable.value )
                end
            end ]]

        end, true )
    end

    -- Set a value that will be exported with :ExportLambdaInfo()
    function ENT:SetExternalVar( key, val )
        self.l_ExternalVars[ key ] = val
        self[ key ] = val
    end

    -- Gets a value set by :SetExternalVar( key, val )
    function ENT:GetExternalVar( key )
        return self.l_ExternalVars[ key ]
    end

    -- Returns the position we are going to
    function ENT:GetDestination()
        local pos = self.l_movepos
        return ( ( isentity( pos ) and IsValid( pos ) ) and pos:GetPos() or pos )
    end

    -- Returns if the given entity is a player, NPC, or a Nextbot
    function ENT:IsValidTarget( ent )
        return ( ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() )
    end

    -- If the we can target the ent
    function ENT:CanTarget( ent )
        if ent == self then return false end

        if ent.IsLambdaPlayer then
            if !ent:Alive() then return false end
            if ent:IsFlagSet( FL_NOTARGET ) then return false end
        elseif ent:IsPlayer() then
            if !ent:Alive() then return false end
            if ent:IsFlagSet( FL_NOTARGET ) then return false end
            if ent:GetInfoNum( "lambdaplayers_combat_allowtargetyou", 0 ) == 0 then return false end
            if ignoreplayer:GetBool() then return false end
        elseif ent:IsNPC() or ent:IsNextBot() then
            if ent.IsLambdaAntlion and ( self:GetWeaponName() == "hl2_bugbait" or ent:GetOwner() == self ) then return false end
            if ent.IsDrGNextbot and ent:IsDown() then return false end
            if ent:IsFlagSet( FL_NOTARGET ) then return false end
            if ent:GetInternalVariable( "m_lifeState" ) != 0 then return false end
            if ignoreFriendNPCs:GetBool() and self:Relations( ent ) == D_LI then return false end

            local class = ent:GetClass()
            if class == "rd_target" then return false end
            if string_match( class, "bullseye" ) then return false end
        else
            return false
        end

        if LambdaRunHook( "LambdaCanTarget", self, ent ) == true then return false end
        return true
    end

    -- Attacks the specified entity
    function ENT:AttackTarget( ent, forceAttack )
        if !LambdaIsValid( ent ) then return end

        local overrideTarget = LambdaRunHook( "LambdaOnAttackTarget", self, ent )
        if overrideTarget == true then return end

        if IsValid( overrideTarget ) then ent = overrideTarget end
        self:SetEnemy( ent )
        if !forceAttack and self:IsPanicking() and CurTime() < self.l_retreatendtime then return end

        if LambdaRNG( 100 ) <= self:GetVoiceChance() and !self:GetIsTyping() and !self:IsSpeaking() then self:PlaySoundFile( "taunt" ) end
        self:SetState( "Combat" )
        self:CancelMovement()
        self.l_combatendtime = ( CurTime() + LambdaRNG( 180, 300 ) )
    end

    -- Retreats from entity target
    -- If the target is not specified, then Lambda will stop retreating only when time runs out
    function ENT:RetreatFrom( target, timeout, speakLine )
        local alreadyPanic = self:IsPanicking()
        if !alreadyPanic then
            self:CancelMovement()
            self:SetState( "Retreat" )

            if ( speakLine == nil or speakLine == true ) and self:GetVoiceChance() > 0 then
                self:PlaySoundFile( "panic" )
            end
        end

        local retreatTime = ( CurTime() + ( timeout or LambdaRNG( 10, 20 ) ) )
        if retreatTime > self.l_retreatendtime then self.l_retreatendtime = retreatTime end

        local ene = self:GetEnemy()
        if !alreadyPanic or LambdaIsValid( ene ) then self:SetEnemy( target ) end
    end

    -- PlaySequenceAndWait but without t-posing
    function ENT:PlayGestureAndWait( id, speed )

        local hookId, hookSpeed = LambdaRunHook( "LambdaOnPlayGestureAndWait", self, id, speed )
        if hookId == true then
            return
        else
            id = ( hookId or id )
            speed = ( hookSpeed or speed )
        end

        local isSeq = isstring( id )
        if isSeq then id = self:LookupSequence( id ) end

        local layer = ( isSeq and self:AddGestureSequence( id ) or self:AddGesture( id ) )
        if !self:IsValidLayer( layer ) then return end

        self.l_UpdateAnimations = false
        self.l_CurrentPlayedGesture = id
        self:SetNW2Int( "lambda_curanimgesture", id )

        local len = self:GetLayerDuration( layer )
        speed = speed or 1

        self:SetPlaybackRate( speed )

        -- wait for it to finish
        local endTime = ( CurTime() + ( len / speed ) )
        while ( CurTime() < endTime and !self:GetIsDead() and self:IsValidLayer( layer ) ) do
            coroutine.yield()
        end

        if self:IsValidLayer( layer ) then
            self:SetLayerCycle( layer, 1 )
        end
        if !isSeq then
            self:RemoveGesture( id )
        end

        self.l_UpdateAnimations = true
        self:SetNW2Int( "lambda_curanimgesture", -1 )

    end

    -- Updates our networked health
    -- We use both NW2 and NW because in multiplayer NW2 sometimes fails so we use NW as a backup
    function ENT:UpdateHealthDisplay( overrideHP )
        overrideHP = overrideHP or self:Health()
        self:SetNW2Float( "lambda_health", overrideHP )
        self:SetNWFloat( "lambda_health", overrideHP )
    end

    -- Gets a name that is currently not being used.
    -- If all names are being used, a random name will be picked anyways even if it is used
    function ENT:GetOpenName()
        local nametablecopy = table_Copy( LambdaPlayerNames )

        for k, v in ipairs( GetLambdaPlayers() ) do
            if v == self then continue end
            table_RemoveByValue( nametablecopy, v:GetLambdaName() )
        end
        local name = nametablecopy[ LambdaRNG( #nametablecopy ) ]
        if !name then name = LambdaPlayerNames[ LambdaRNG( #LambdaPlayerNames ) ] end
        return name
    end

    -- If the provided name is being used or not
    function ENT:IsNameOpen( name )
        for k, v in ipairs( GetLambdaPlayers() ) do
            if v != self and v:GetLambdaName() == name then return false end
        end
        return true
    end

    -- Checks if our name has a profile. If so, apply the profile info
    function ENT:ProfileCheck()
        local info = LambdaPersonalProfiles and LambdaPersonalProfiles[ self:GetLambdaName() ] or nil
        if !info then return end

        self:ApplyLambdaInfo( info )
        self.l_usingaprofile = true
        self:SimpleTimer( 0, function() LambdaRunHook( "LambdaOnProfileApplied", self, info ) end, true )
    end

    -- Makes the Lambda face the position or a entity if provided
    -- if poseonly is true, then the Lambda will not change its angles and will only change it's pose params
    function ENT:LookTo( pos, time, poseonly, priority )
        if priority and self.l_FacePriority and priority < self.l_FacePriority then return end
        self.Face = pos
        self.l_PoseOnly = poseonly or false
        self.l_Faceend = time and CurTime() + time or nil
        self.l_FacePriority = ( priority or nil )
    end

    -- Returns if the provided state exists
    function ENT:StateExists( state )
        return isfunction( self[ state ] )
    end

    -- Return the state that our behavior coroutine is currenly running
    function ENT:GetBehaviorState()
        return self.l_BehaviorState
    end

    -- Sets our state
    -- The 'arg' is an optional variable that can be used by a state
    function ENT:SetState( state, arg )
        state = ( state or "Idle" )
        local curState = self:GetState()
        if state == curState then return end
        if LambdaRunHook( "LambdaOnChangeState", self, curState, state, arg ) == true then return end

        local behavState = self:GetBehaviorState()
        if behavState != state then self:SetNW2String( "lambda_laststate", behavState ) end

        self:SetNW2String( "lambda_state", state )
        self.l_statearg = arg
        self:DebugPrint( "Changed state from " .. curState .. " to " .. state )
    end

    -- Returns if our ai is disabled
    function ENT:IsDisabled()
        return self:GetIsTyping() or self.l_isfrozen or aidisable:GetBool()
    end
    -- If we have a lethal weapon
    function ENT:HasLethalWeapon()
        return self.l_HasLethal or false
    end

    -- Returns if we are in noclip
    function ENT:IsInNoClip()
        return self:GetNoClip()
    end

    -- Enter or exit Noclip. Calls a hook to be able to block the event
    function ENT:NoClipState( bool )
        local result = LambdaRunHook( "LambdaOnNoclip", self, bool )
        if !result then self:SetNoClip( bool ) end
    end

    -- Returns whether the given position or entity is at a given range
    function ENT:IsInRange( target, range )
        return ( ( !isentity( target ) or IsValid( target ) ) and self:GetRangeSquaredTo( target ) <= ( range * range ) )
    end

    -- Prevents the Lambda Player from switching weapons when this is true
    function ENT:PreventWeaponSwitch( bool )
        self.l_NoWeaponSwitch = bool
    end

    -- Returns the current weapon's pretty name
    function ENT:GetPrettyWeaponName()
        return self:GetNW2String( "lambda_weaponprettyname", "UNAVAILABLE" )
    end

    function ENT:SetPlayerModel( mdl, noBodygroups )
        local forceMdl = LambdaRunHook( "LambdaOnSetPlayerModel", self, mdl )
        if forceMdl != nil then
            if forceMdl == true then return end
            mdl = forceMdl
        end

        if !mdl then
            local mdlTbl = _LAMBDAPLAYERS_DefaultPlayermodels
            if allowaddonmodels:GetBool() then
                mdlTbl = ( onlyaddonmodels:GetBool() and _LAMBDAPLAYERS_AddonPlayermodels or _LAMBDAPLAYERS_AllPlayermodels )
                if #mdlTbl == 0 then mdlTbl = _LAMBDAPLAYERS_DefaultPlayermodels end
            end
            mdl = mdlTbl[ LambdaRNG( #mdlTbl ) ]
        elseif istable( mdl ) then
            mdl = mdl[ LambdaRNG( #mdl ) ]
        end
        self:SetModel( mdl )

        if !noBodygroups and rndBodyGroups:GetBool() then
            local mdlSets = LambdaPlayermodelBodySkinSets[ mdl ]
            if mdlSets and #mdlSets != 0 and allowMdlBgSets:GetBool() then
                local rndSet = mdlSets[ LambdaRNG( #mdlSets ) ]

                local skin = ( rndSet.skin or 0 )
                self:SetSkin( skin != -1 and skin or LambdaRNG( 0, self:SkinCount() - 1 ) )

                local groups = rndSet.bodygroups
                for _, v in ipairs( self:GetBodyGroups() ) do
                    local index = v.id
                    local group = groups[ index ]

                    if !group then continue end
                    self:SetBodygroup( index, ( group != -1 and group or LambdaRNG( 0, #v.submodels ) ) )
                end
            else
                for _, v in ipairs( self:GetBodyGroups() ) do
                    local subMdls = #v.submodels
                    if subMdls == 0 then continue end
                    self:SetBodygroup( v.id, LambdaRNG( 0, subMdls ) )
                end

                local skinCount = self:SkinCount()
                if skinCount > 0 then self:SetSkin( LambdaRNG( 0, skinCount - 1 ) ) end
            end
        end

        if StartsWith( self:GetProfilePicture(), "spawnicons/" ) then
            self:SetProfilePicture( "spawnicons/".. string_sub( mdl, 1, #mdl - 4 ).. ".png" )
        end

        self:SimpleTimer( 0.1, function()
            local hasAnim = ( self:LookupSequence( "taunt_zombie" ) > 0 )
            local uniqueAnim = self.l_HasStandartAnim
            self.l_ChangedModelAnims = ( !uniqueAnim and hasAnim or !hasAnim and uniqueAnim )

            if self.l_HasExtendedAnims != nil then
                self.l_HasExtendedAnims = ( self:SelectWeightedSequence( ACT_GESTURE_BARNACLE_STRANGLE ) > 0 )
            end
            if self.l_AnimatedSprint != nil then
                self.l_AnimatedSprint = ( self:LookupSequence( "wos_mma_sprint_all" ) > 0 )
            end
            if self.l_HardLandingRolls then
                self.l_HardLandingRolls.HasAnims = ( self:LookupSequence( "wos_mma_roll" ) > 0 )
            end
        end )
    end

    -- Respawns the Lambda only if they have self:SetRespawn( true ) otherwise they are removed from run time
    function ENT:LambdaRespawn()
        self:DebugPrint( "Respawned" )
        self:SetSolidMask( MASK_SOLID_BRUSHONLY ) -- This should maybe help with the issue where the nextbot can't set pos because it's in something

        local spawnPos, spawnAng = self.l_SpawnPos, self.l_SpawnAngles
        if rasp:GetBool() then
            LambdaSpawnPoints = ( LambdaSpawnPoints or LambdaGetPossibleSpawns() )
            if LambdaSpawnPoints and #LambdaSpawnPoints > 0 then
                local rndPoint = LambdaSpawnPoints[ LambdaRNG( #LambdaSpawnPoints ) ]
                if IsValid( rndPoint ) then
                    spawnPos = rndPoint:GetPos()
                    spawnAng = rndPoint:GetAngles()
                end
            end
        end
        self:SetPos( spawnPos )
        self:SetSolidMask( MASK_PLAYERSOLID )

        self:SetAngles( spawnAng )
        self.loco:SetVelocity( vector_origin )
        self:SetCollisionGroup( !collisionPly:GetBool() and COLLISION_GROUP_PLAYER or COLLISION_GROUP_PASSABLE_DOOR )

        local phys = self:GetPhysicsObject()
        if IsValid( phys ) then phys:EnableCollisions( true ) end

        if !self.l_usingaprofile then
            local rndSwitchMdl = changePlyMdlChance:GetInt()
            if rndSwitchMdl > 0 and LambdaRNG( 100 ) <= rndSwitchMdl then
                self:SetPlayerModel()
            end
        end

        self:ClientSideNoDraw( self, false )
        self:SetNoDraw( false )
        self:DrawShadow( true )

        local wepent = self.WeaponEnt
        local isMarked = self:IsWeaponMarkedNodraw()
        self:ClientSideNoDraw( wepent, isMarked )
        wepent:SetNoDraw( isMarked )
        wepent:DrawShadow( !isMarked )

        self:SetIsDead( false )
        self:SetHealth( self:GetMaxHealth() )
        self:SetArmor( self.l_SpawnArmor )
        self:SetState()
        self:SetCrouch( false )
        self:SetEnemy( NULL )
        self:SetIsReloading( false )
        self:SetNoTarget( false )

        self:PreventDefaultComs( false )
        self:PreventWeaponSwitch( false )
        self.l_IsUsingTool = false

        self.l_ladderarea = nil
        self.l_UpdateAnimations = true
        self.l_Clip = self.l_MaxClip

        self:SimpleTimer( 0.1, function()
            self:AddFlags( FL_CLIENT )
            self:SwitchToSpawnWeapon()
        end )
        self:UpdateHealthDisplay()

        net.Start( "lambdaplayers_updatecsstatus" )
            net.WriteEntity( self )
            net.WriteBool( false )
            net.WriteInt( self:GetFrags(), 11 )
            net.WriteInt( self:GetDeaths(), 11 )
            net.WriteVector( self:GetPos() )
        net.Broadcast()

        if serversidecleanup:GetBool() then
            local ragdoll = self.ragdoll
            local dropEnt = self.weapondrop
            if IsValid( dropEnt ) and dropEnt:GetOwner() != self then dropEnt = nil end

            self.ragdoll = nil
            self.weapondrop = nil

            local disintegrate = serversidecleanupeffect:GetBool()
            if disintegrate then
                net.Start( "lambdaplayers_disintegrationeffect" )
                    net.WriteEntity( ragdoll )
                net.Broadcast()

                net.Start( "lambdaplayers_disintegrationeffect" )
                    net.WriteEntity( dropEnt )
                net.Broadcast()
            end

            self:SimpleTimer( ( disintegrate and 5 or 0 ), function()
                if IsValid( ragdoll ) then ragdoll:Remove() end
                if IsValid( dropEnt ) then dropEnt:Remove() end
            end, true )
        end

        if !spawnBehavInitSpawn:GetBool() then
            self:ApplyCombatSpawnBehavior()
        end

        LambdaRunHook( "LambdaOnRespawn", self )
    end

    -- Delete ourself and spawn a recreation of ourself.
    -- If ignoreprehook is true, the LambdaPreRecreated hook won't run meaning addons won't be able to stop this
    function ENT:Recreate( ignoreprehook, inPlace )
        local shouldblock = LambdaRunHook( "LambdaPreRecreated", self )
        self:SimpleTimer( 0.1, function() self:Remove() end, true )
        if !ignoreprehook and shouldblock == true then return end

        local pos, ang = self.l_SpawnPos, self.l_SpawnAngles
        if inPlace then
            tracetable.start = self:GetPos()
            tracetable.endpos = tracetable.start
            tracetable.filter = self
            tracetable.mins, tracetable.maxs = self:GetCollisionBounds()

            pos = TraceHull( tracetable ).HitPos
            ang = self:GetAngles()
        end

        local exportinfo = self:ExportLambdaInfo()
        local newlambda = ents_Create( "npc_lambdaplayer" )
        newlambda:SetPos( pos )
        newlambda:SetAngles( ang )

        local creator = self:GetCreator()
        newlambda:SetCreator( creator )

        newlambda.l_NoRandomModel = true
        newlambda:Spawn()
        newlambda:ApplyLambdaInfo( exportinfo )
        newlambda.l_SpawnPos = self.l_SpawnPos
        newlambda.l_SpawnAngles = self.l_SpawnAngles

        if inPlace then
            newlambda:SetHealth( self:Health() )
            newlambda:SetArmor( self:Armor() )
            newlambda:SetState( self:GetState() )
            newlambda:SetEnemy( self:GetEnemy() )
            newlambda.l_statearg = self.l_statearg

            local curWep = self:GetWeaponName()
            newlambda:SimpleTimer( 0.1, function() newlambda:SwitchWeapon( curWep ) end )
        end

        self.l_recreatedlambda = newlambda
        table_Merge( newlambda.l_SpawnedEntities, self.l_SpawnedEntities )

        if IsValid( creator ) then
            local undoName = "Lambda Player ( " .. self:GetLambdaName() .. " )"
            undo.Create( undoName )
                undo.SetPlayer( creator )
                undo.AddEntity( newlambda )
                undo.SetCustomUndoText( "Undone " .. undoName )
            undo.Finish( undoName )
        end

        self:SimpleTimer( 0, function() LambdaRunHook( "LambdaPostRecreated", newlambda ) end, true )
    end

    -- Returns a sequential table full of nav areas near the position
    function ENT:GetNavAreas( pos, dist )
        local neartbl = {}
        pos = ( pos or self:GetPos() )
        dist = ( dist or 1500 )

        for _, area in ipairs( GetAllNavAreas() ) do
            if !area:IsValid() or area:GetSizeX() < 75 or area:GetSizeY() < 75 then continue end
            local areaPos = area:GetCenter()
            if areaPos:IsUnderwater() or dist != true and areaPos:DistToSqr( pos ) > ( dist * dist ) then continue end
            neartbl[ #neartbl + 1 ] = area
        end

        return neartbl
    end

    -- Returns a random position near the position
    function ENT:GetRandomPosition( pos, dist, filter )
        pos = ( pos or self:GetPos() )
        dist = ( dist or 1500 )

        -- If the navmesh is loaded then find a nav area to go to
        if IsNavmeshLoaded() then
            for _, area in RandomPairs( self:GetNavAreas( pos, dist ) ) do
                local rndPoint = self:GetNavAreaRandomPoint( area )
                if filter and filter( pos, area, rndPoint ) == true then continue end
                if !self:IsAreaTraversable( area ) then continue end
                return rndPoint
            end
        end

        -- If not, try to go to a entirely random spot
        if !isnumber( dist ) then dist = 1500 end
        return ( pos + VectorRand( -dist, dist ) )
    end

    -- Gets a entirely random sound from the source engine sound folder
    function ENT:GetRandomSound()
        local dir = "sound/"

        for i = 1, 10 do
            local files, directories = file_Find( dir .. "*", "GAME", "nameasc" )

            if #files > 0 and ( i != 10 and LambdaRNG( 2 ) ==  1 ) then
                local selectedfile = files[ LambdaRNG( #files ) ]
                if selectedfile and EndsWith( selectedfile, ".mp3" ) or selectedfile and EndsWith( selectedfile, ".wav" ) then return string.Replace( dir .. selectedfile, "sound/", "" ) end
            else
                local rnd = directories[ LambdaRNG( #directories ) ]
                if rnd then
                    dir = dir .. rnd .. "/"
                end
            end
            table_Empty( files ) table_Empty( directories )
        end

        return ""
    end

    -- Retrieves a voice line from our Voice Profile or the Voicelines table
    function ENT:GetVoiceLine( voicetype )
        if self.l_VoiceProfile and LambdaVoiceProfiles[ self.l_VoiceProfile ] then
            local vptable = LambdaVoiceProfiles[ self.l_VoiceProfile ][ voicetype ]
            if vptable and #vptable > 0 then
                return vptable[ LambdaRNG( #vptable ) ]
            elseif !vpFallback:GetBool() then
                return false
            end
        end

        local voiceDir = GetConVar( "lambdaplayers_voice_" .. voicetype .. "dir" )
        if voiceDir and voiceDir:GetString() == "randomengine" then return self:GetRandomSound() end

        local tbl = LambdaVoiceLinesTable[ voicetype ]
        return ( tbl and tbl[ LambdaRNG( #tbl ) ] )
    end

    -- Disables or re-enables Lambda's ability to use voice chat/type in chat.
    -- Useful for modules that need lambdas to not speak passively.
    function ENT:PreventDefaultComs( bool )
        self.l_preventdefaultspeak = bool
    end

    -- Restarts the Lambda's AI thread. Useful for forcing state changes
    function ENT:ResetAI()
        self.BehaveThread = coroutine.create( function() self:RunBehaviour() end )
        self:SetNW2Int( "lambda_curanimgesture", -1 )
    end


    -- Combines a table of strings into one string
--[[     local function CombineStringTable( tbl )
        local strin = ""

         for k, v in ipairs( tbl ) do
             strin = strin .. " " .. v
         end

         return strin
     end

     -- Prototype created in StarFall
     -- Mixes sentences together for a wacky result
     local function sentencemixing( text, feed )

         local mod = ""

         local feedstring = CombineStringTable( feed )
         local textsplit = string_Explode( " ", text )
         local validwords = {}
         local smallwords = {}

         for k, word in ipairs( string_Explode( " ", feedstring ) ) do
             if #word > 3 then validwords[ #validwords + 1 ] = word end
         end

         for k, word in ipairs( string_Explode( " ", feedstring ) ) do
             if #word < 3 then smallwords[ #smallwords + 1 ] = word end
         end

         for k, word in ipairs( textsplit ) do
             local preword = word

             if #preword > 3 and LambdaRNG( 2 ) == 1 then
                 preword = validwords[ LambdaRNG( #validwords ) ]
             elseif #preword < 3 and LambdaRNG( 6 ) == 1 then
                 preword = smallwords[ LambdaRNG( #smallwords ) ]
             end

             mod = mod .. " " .. preword
         end

         return mod
     end ]]

    -- Textline Stuff
    local standartLines = {}
    local textLinks = {}
    local markovLookFwd = 5

    -- Markov Chain Generator --
    -- Source code from https://github.com/hay/markov
    -- I simply got it converted from PHP to GLua
    local function generate_markov_table( text )
        local charactertable = {}
        for i = 1, #text do
            local char = string_sub( text, i, ( i + markovLookFwd - 1 ) )
            if !charactertable[ char ] then charactertable[ char ] = {} end
        end

        for i = 1, #text - markovLookFwd do
            local char_index = string_sub( text, i, ( i + markovLookFwd - 1 ) )
            local char_count = string_sub( text, ( i + markovLookFwd ), ( i + markovLookFwd * 2 - 1 ) )
            local char_total = charactertable[ char_index ][ char_count ]
            charactertable[ char_index ][ char_count ] = ( ( char_total or 0 ) + 1 )
        end

        return charactertable
    end

    local function return_weighted_char( array )
        if !next( array ) then return false end

        local items, total = {}, 0
        for item, weight in pairs( array ) do
            items[ #items + 1 ] = item
            total = total + weight
        end

        local rand = LambdaRNG( total )
        for _, item in ipairs( items ) do
            local weight = array[ item ]
            if rand <= weight then return item end
            rand = ( rand - weight )
        end
    end

    local function generate_markov_text( length, markov_table )
        local char = next( markov_table )
        local o = char

        for i = 1, floor( length / markovLookFwd ) do
            local newchar = return_weighted_char( markov_table[ char ] )
            if newchar then
                char = newchar
                o = ( o .. newchar )
            else
                char = next( markov_table )
            end
        end

        return o
    end

    local function GetRandomMarkovLine( lambda, tbl )
        local validLines = {}

        local feedLines = {}
        for index, line in ipairs( tbl ) do
            if !standartLines[ line ] then
                local cond, modLine = LambdaConditionalKeyWordCheck( lambda, line )
                if !cond then continue end

                local keyLine = LambdaKeyWordModify( lambda, modLine )
                local incomplete = false
                for keyWord, _ in pairs( LambdaValidTextChatKeyWords ) do
                    if !string_match( keyLine, keyWord ) then continue end
                    incomplete = true
                    break
                end
                if incomplete then continue end

                -- Cache the lines that don't contain any keywords to avoid unnecesary resources at checking for them
                if line == modLine and line == keyLine then
                    standartLines[ line ] = true
                end

                line = keyLine
            end

            if textLinks[ line ] or ( string_match( line, "(https?://%S+)" ) != nil and LambdaRNG( 3 ) == 1 ) then
                validLines[ #validLines + 1 ] = line
                textLinks[ line ] = true
            else
                feedLines[ #feedLines + 1 ] = line
            end
        end

        if #feedLines != 0 then
            local markovtable = generate_markov_table( table_concat( feedLines, "\n" ) )
            local generated = generate_markov_text( 2000, markovtable )
            validLines = table_Add( validLines, string_Explode( "\n", generated ) )
        elseif #validLines == 0 then
            return tbl[ LambdaRNG( #tbl ) ]
        end

        return validLines[ LambdaRNG( #validLines ) ]
    end

    -- Literally the same thing as :GetVoiceLine() but for Text Lines
    function ENT:GetTextLine( texttype )
        local textLine, preModText = ""
        local tbl = LambdaTextTable[ texttype ]

        local textPfl = self.l_TextProfile
        if textPfl and LambdaTextProfiles[ textPfl ] then
            local texttable = LambdaTextProfiles[ textPfl ][ texttype ]
            if texttable and #texttable > 0 then tbl = texttable end
        end

        if tbl then
            if !allowlinks:GetBool() then
                local copyTbl = {}
                for index, line in ipairs( tbl ) do
                    if textLinks[ line ] or string_match( line, "(https?://%S+)" ) then
                        textLinks[ line ] = true
                        continue
                    end
                    copyTbl[ #copyTbl + 1 ] = line
                end
                tbl = copyTbl
            end
            preModText = textLine

            local markovLine = ( usemarkovgenerator:GetBool() and GetRandomMarkovLine( self, tbl ) )
            if markovLine then
                textLine = markovLine
            else
                for _, textline in RandomPairs( tbl ) do
                    local condition, modifiedline = LambdaConditionalKeyWordCheck( self, textline )
                    if !condition then continue end

                    textLine = LambdaKeyWordModify( self, modifiedline )
                    break
                end
            end

            textLine = ( LambdaRunHook( "LambdaOnStartTyping", self, textLine, texttype ) or textLine )
        end

        return textLine, preModText
    end

    -- Makes the Lambda say the specified file
    function ENT:PlaySoundFile( filepath, delay )
        if !filepath then return end

        local voiceType = filepath
        local isVoiceType = self:GetVoiceLine( filepath )
        if isVoiceType then
            if isVoiceType == false then return end
            self.l_lastspokenvoicetype = filepath
            filepath = isVoiceType
        end

        if !isnumber( delay ) then
            delay = ( ( delay == nil and slightDelay:GetBool() ) and LambdaRNG( 0.1, 0.75, true ) or 0 )
        end

        if LambdaRunHook( "LambdaOnPlaySound", self, filepath, voiceType ) == true then return end
        self:SetLastSpeakingTime( RealTime() + 4 )

        net.Start( "lambdaplayers_playsoundfile" )
            net.WriteEntity( self )
            net.WriteBool( self:Alive() )
            net.WriteString( filepath )
            net.WriteUInt( self:GetCreationID(), 32 )
            net.WriteVector( self:GetPos() )
            net.WriteFloat( delay )
        net.Broadcast()
    end

    local maxSafeFallSpeed = math.sqrt( 2 * 600 * 20 * 12 )
    local fatalFallSpeed = math.sqrt( 2 * 600 * 60 * 12 )
    function ENT:GetFallDamage( speed, realDmg )
        realDmg = ( realDmg == nil and realisticfalldamage:GetBool() or realDmg )
        speed = ( speed or self.l_FallVelocity )
        if !realDmg and speed > maxSafeFallSpeed then return 10 end

        local damageForFall = ( 100 / ( fatalFallSpeed - maxSafeFallSpeed ) )
        return max( ( speed - maxSafeFallSpeed ) * damageForFall, 0 )
    end

    function ENT:GetFallDamageFromHeight( height, realDmg )
        realDmg = ( realDmg == nil and realisticfalldamage:GetBool() )
        local gravityMult = ( 600 / self.loco:GetGravity() )

        local maxSafeFallHeight = ( 240 * gravityMult )
        if !realDmg and height > maxSafeFallHeight then return 10 end

        local fatalFallHeight = ( 720 * gravityMult )
        local damageForFall = ( 100 / ( fatalFallHeight - maxSafeFallHeight ) )
        return max( ( height - maxSafeFallHeight ) * damageForFall, 0 )
    end

    -- Stops the current voiceline we're speaking
    function ENT:StopCurrentVoiceLine()
        if !self:IsSpeaking() then return end
        self:SetLastSpeakingTime( 0 )

        net.Start( "lambdaplayers_stopcurrentsound" )
            net.WriteEntity( self )
        net.Broadcast()
    end

    -- Returns the last voicetype we have spoken a voiceline with
    function ENT:GetLastSpokenVoiceType()
        return self.l_lastspokenvoicetype
    end

    -- Returns if we are currently climbing a ladder
    function ENT:IsUsingLadder()
        return IsValid( self.l_ladderarea )
    end


    -- Makes the Lambda say the provided text
    -- if instant is true, the Lambda will say the text instantly.
    -- teamOnly is just so this function is compatible with addons basically
    -- recipients is optional
    function ENT:Say( text, teamOnly, recipients )
        local replacement = LambdaRunHook( "LambdaPlayerSay", self, text, ( teamOnly or false ) )
        if isstring( replacement ) then text = replacement end
        if text == "" then return end

        local condition, modifiedline = LambdaConditionalKeyWordCheck( self, text )
        if !condition then return end
        text = modifiedline

        -- This has changed so we can properly send each player a text chat message with their own custom display colors
        if !recipients then
            for _, ply in ipairs( player_GetAll() ) do
                LambdaPlayers_ChatAdd( ply, ( self:GetIsDead() and red or color_white ), ( self:GetIsDead() and "*DEAD* " or ""), self:GetDisplayColor( ply ), self:GetLambdaName(), color_white, ": " .. text )
            end
        elseif IsValid( recipients ) and recipients:IsPlayer() then
            LambdaPlayers_ChatAdd( recipients, ( self:GetIsDead() and red or color_white ), ( self:GetIsDead() and "*DEAD* " or ""), self:GetDisplayColor( recipients ), self:GetLambdaName(), color_white, ": " .. text )
        else
            for _, ply in ipairs( recipients:GetPlayers() ) do
                LambdaPlayers_ChatAdd( ply, ( self:GetIsDead() and red or color_white ), ( self:GetIsDead() and "*DEAD* " or ""), self:GetDisplayColor( ply ), self:GetLambdaName(), color_white, ": " .. text )
            end
        end

    end

    -- "Manually" type out a message and send it to text chat when we are finished
    function ENT:TypeMessage( text, sendCur )
        if text == "" then return end

        if sendCur != false and self:GetIsTyping() then
            self:Say( self.l_typedtext )
        end
        self:SetIsTyping( true )
        self:StopCurrentVoiceLine()

        self.l_starttypestate = self:GetState()
        self.l_typedtext = ""
        self.l_nexttext = 0
        self.l_queuedtext = text
        self:OnBeginTyping( text )
    end

    -- Returns if we can type a message
    function ENT:CanType()
        if !chatAllowed:GetBool() then return false end

        local chatMax = chatlimit:GetInt()
        if chatMax <= 0 then return true end

        local count = 0
        for _, v in ipairs( GetLambdaPlayers() ) do
            if !v:GetIsTyping() then continue end
            count = ( count + 1 )
            if count >= chatMax then return false end
        end

        return true
    end

    -- Makes the entity no longer draw on the client if bool is set to true.
    -- Making a entity nodraw server side seemed to have issues in multiplayer.
    -- As of 11/2/2022, it seems we need the server nodraw, client nodraw, and usage of Draw functions to make the Lambda Players to not draw. Kinda cringe but alright
    function ENT:ClientSideNoDraw( ent, bool )
        net.Start( "lambdaplayers_setnodraw" )
            net.WriteEntity( ent )
            net.WriteBool( bool or false )
        net.Broadcast()
    end

    -- Gets our relationship with entity
    function ENT:Relations( ent )
        if ent.IsVJBaseSNPC then
            if ent.PlayerFriendly then return D_LI end
            for _, v in ipairs( ent.VJ_NPC_Class ) do if v == "CLASS_PLAYER_ALLY" then return D_LI end end
            if ent.Behavior == VJ_BEHAVIOR_AGGRESSIVE then return D_HT end
        elseif ent.IsDrGNextbot then
            return ent:GetPlayersRelationship()
        end

        return ( _LAMBDAPLAYERSEntityRelations[ ent:GetClass() ] or D_NU )
    end

    -- Handles the NPC relationship with entity
    function ENT:HandleNPCRelations( ent )
        self:DebugPrint( "handling relationship with ", ent )

        local addRelationFunc = ent.AddEntityRelationship
        if !addRelationFunc then return end

        local relations, priority = self:Relations( ent )
        addRelationFunc( ent, self, relations, ( priority or 1 ) )

        if relations == D_HT and ent.IsVJBaseSNPC then
            self:SimpleTimer( 0.1, function()
                if !IsValid( ent ) or !ent.VJ_AddCertainEntityAsEnemy or !ent.CurrentPossibleEnemies then return end
                ent.VJ_AddCertainEntityAsEnemy[ #ent.VJ_AddCertainEntityAsEnemy + 1 ] = self
                ent.CurrentPossibleEnemies[ #ent.CurrentPossibleEnemies + 1 ] = self
            end, true )
        end
    end

    -- Calls ENT:HandleAllValidNPCRelations for all NPCs and Nextbots
    function ENT:HandleAllValidNPCRelations()
        for _, v in ipairs( ents_GetAll() ) do
            if !IsValid( v ) or v.IsLambdaPlayer or !v:IsNPC() and !v:IsNextBot() then continue end
            self:HandleNPCRelations( v )
        end
    end

    -- Returns if the specified NPC is currently angry at us
    function ENT:ShouldAttackNPC( ent )
        if !self:CanTarget( ent ) then return false end
        local getfunc = ent.GetEnemy
        if !getfunc then getfunc = ent.GetTarget end
        return ( !getfunc and true or ( getfunc( ent ) == self ) )
    end

    -- The ENT:WaterLevel() function seems to be inaccurate when done on Lambda Players, so we'll do this instead
    function ENT:GetWaterLevel()
        return ( self:GetAttachmentPoint( "eyes" ).Pos:IsUnderwater() and 3 or self:WorldSpaceCenter():IsUnderwater() and 2 or self:GetPos():IsUnderwater() and 1 or 0 )
    end

    -- Returns the time we will play our next footsteps ound
    function ENT:GetStepSoundTime()
        local stepTime = 0.35

        if self:GetWaterLevel() != 2 then
            local maxSpeed = self.loco:GetVelocity():Length2D()
            stepTime = Clamp( stepTime * ( 200 / maxSpeed ), 0.25, 0.45 )
        else
            stepTime = 0.6
        end
        if self:GetCrouch() then
            stepTime = stepTime + 0.05
        end

        return stepTime
    end

    -- Makes us jump
    function ENT:LambdaJump( forceJump )
        if !forceJump then
            if !self:IsOnGround() then return end
            local curNav = self.l_currentnavarea
            if obeynav:GetBool() and IsValid( curNav ) and ( curNav:HasAttributes( NAV_MESH_NO_JUMP ) or curNav:HasAttributes( NAV_MESH_STAIRS ) ) then return end
            if LambdaRunHook( "LambdaOnJump", self, curNav ) == true then return end
        end

        jumpTr.start = self:GetPos()
        jumpTr.endpos = jumpTr.start + ( self.loco:GetVelocity() * FrameTime() )
        jumpTr.filter = self
        jumpTr.mins, jumpTr.maxs = self:GetCollisionBounds()

        local jumpTrace = TraceHull( jumpTr )
        if jumpTrace.Hit then self:SetPos( jumpTrace.HitPos ) end

        self.loco:Jump()
        self:PlayStepSound( 1.0 )
        return true
    end

    local panicAnimations = GetConVar( "lambdaplayers_lambda_panicanimations" )

    -- Gets out weapon's holdtype we'll use for animations
    function ENT:GetWeaponHoldType()
        if !self.Face and self:IsPanicking() and !self:GetIsReloading() and CurTime() < self.l_retreatendtime and panicAnimations:GetBool() then
            local panicTbl = _LAMBDAPLAYERSHoldTypeAnimations[ "panic" ]
            if self:SelectWeightedSequence( panicTbl.run ) > 0 then return panicTbl, true end
        end

        local hType = self.l_HoldType
        return ( istable( hType ) and hType or _LAMBDAPLAYERSHoldTypeAnimations[ hType ] )
    end

    -- Applies the combat behavior on our initial spawn or respawn
    function ENT:ApplyCombatSpawnBehavior()
        local spawnBehav = spawnBehavior:GetInt()
        if spawnBehav == 0 then return end

        local findClosest = spawnBehavUseRange:GetBool()
        local closeTarget
        local searchDist = math.huge
        local selfZ = self:GetPos().z

        local pairGen = ( findClosest and ipairs or RandomPairs )
        for _, ent in pairGen( ents_GetAll() ) do
            if ent == self or !IsValid( ent ) or !self:CanTarget( ent ) then continue end
            if spawnBehav == 1 and !ent:IsPlayer() or spawnBehav == 2 and ( ent.IsLambdaPlayer or !ent:IsNPC() and !ent:IsNextBot() ) then continue end

            if !findClosest then
                closeTarget = ent
                break
            end

            local entDist = self:GetRangeSquaredTo( ent )
            local heightDiff = abs( selfZ - ent:GetPos().z )
            if ( entDist + ( heightDiff * heightDiff ) ) > searchDist then continue end

            closeTarget = ent
            searchDist = entDist
        end

        if !closeTarget then return end
        self:SetState( "CombatSpawnBehavior", closeTarget )
        self:CancelMovement()
    end

    -- Takes a view screenshot from Lambda's point of view
    function ENT:TakeViewShot( pos, ang )
        if !allowShots:GetBool() then return end

        local pvsEnd = ( CurTime() + 0.1 )
        self:Hook( "SetupPlayerVisibility", "ViewShotPVS", function()
            AddOriginToPVS( self:GetPos() )
            if CurTime() >= pvsEnd then return "end" end
        end, true )

        net.Start( "lambdaplayers_takeviewshot" )
            net.WriteEntity( self )
            net.WriteVector( pos or vector_origin )
            net.WriteAngle( ang or angle_zero )
        net.Broadcast()
    end

    -- Returns a random position point of a nav area
    -- Difference from the CNavArea:GetRandomPoint is this one limits the boundaries
    function ENT:GetNavAreaRandomPoint( area )
        local sizeX = ( area:GetSizeX() / 2 )
        if sizeX > 32 then sizeX = ( sizeX - 32 ) end

        local sizeY = ( area:GetSizeY() / 2 )
        if sizeY > 32 then sizeY = ( sizeY - 32 ) end

        local vecOff = Vector( LambdaRNG( -sizeX, sizeX ), LambdaRNG( -sizeY, sizeY ) )
        return ( area:GetCenter() + vecOff )
    end
end

if ( CLIENT ) then

    -- This is to keep all VTF pfps unique.
    local framerateconvar = GetConVar( "lambdaplayers_animatedpfpsprayframerate" )
    _LambdaPfpIndex = _LambdaPfpIndex or 0

    -- Returns our profile picture as a Material object.
    -- Very expensive to run. Try to cache the result so this can only be ran once
    function ENT:GetPFPMat()
        local pfp = self:GetProfilePicture()

        local isVTF = string.EndsWith( pfp, ".vtf" )
        local profilepicturematerial

        -- VTF ( Valve Texture Format ) support. This allows animated Profile Pictures
        if isVTF then
            _LambdaPfpIndex = _LambdaPfpIndex + 1
            profilepicturematerial = CreateMaterial( "lambdaprofilepicVTFmaterial" .. _LambdaPfpIndex, "UnlitGeneric", {
                [ "$basetexture" ] = pfp,
                [ "$translucent" ] = 1,
                [ "Proxies" ] = {
                    [ "AnimatedTexture" ] = {
                        [ "animatedTextureVar" ] = "$basetexture",
                        [ "animatedTextureFrameNumVar" ] = "$frame",
                        [ "animatedTextureFrameRate" ] = framerateconvar:GetInt()
                    }
                }
            })
        else
            profilepicturematerial = Material( pfp )
        end

        if profilepicturematerial:IsError() then
            local model = self:GetModel()
            profilepicturematerial = Material( "spawnicons/" .. string.sub( model, 1, #model - 4 ) .. ".png" )
        end
        return profilepicturematerial
    end

    -- If we are currently drawn and exist in clientside realm
    -- Deprecated(?) because of existance of ENT:IsDormant()
    function ENT:IsBeingDrawn()
        return ( RealTime() < self.l_lastdraw )
    end

end