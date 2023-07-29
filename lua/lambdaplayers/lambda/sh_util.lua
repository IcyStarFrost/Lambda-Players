local string = string
local table = table
local math = math
local RandomPairs = RandomPairs
local LambdaIsValid = LambdaIsValid
local ipairs = ipairs
local pairs = pairs
local CurTime = CurTime
local RealTime = RealTime
local IsValid = IsValid
local file_Find = file.Find
local random = math.random
local abs = math.abs
local FindInSphere = ents.FindInSphere
local file_Find = file.Find
local table_Empty = table.Empty
local table_IsEmpty = table.IsEmpty
local table_remove = table.remove
local table_RemoveByValue = table.RemoveByValue
local table_Copy = table.Copy
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
local string_Replace = string.Replace
local string_Explode = string.Explode
local table_insert = table.insert
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
local unlimiteddistance = GetConVar( "lambdaplayers_lambda_infwanderdistance" )
local rasp = GetConVar( "lambdaplayers_lambda_respawnatplayerspawns" )
local serversidecleanup = GetConVar( "lambdaplayers_lambda_serversideremovecorpseonrespawn" )
local serversidecleanupeffect = GetConVar( "lambdaplayers_lambda_serversideragdollcleanupeffect" )
local usemarkovgenerator = GetConVar( "lambdaplayers_text_markovgenerate" )
local player_GetAll = player.GetAll
local Rand = math.Rand
local isnumber = isnumber
local ismatrix = ismatrix
local IsValidModel = util.IsValidModel
local IsNavmeshLoaded = ( SERVER and navmesh.IsLoaded )
local spawnArmor = GetConVar( "lambdaplayers_lambda_spawnarmor" )
local walkingSpeed = GetConVar( "lambdaplayers_lambda_walkspeed" )
local runningSpeed = GetConVar( "lambdaplayers_lambda_runspeed" )
local obeynav = GetConVar( "lambdaplayers_lambda_obeynavmeshattributes" )
local spawnBehavior = GetConVar( "lambdaplayers_combat_spawnbehavior" )
local spawnBehavInitSpawn = GetConVar( "lambdaplayers_combat_spawnbehavior_initialspawnonly" )
local spawnBehavUseRange = GetConVar( "lambdaplayers_combat_spawnbehavior_usedistance" )
local ignoreFriendNPCs = GetConVar( "lambdaplayers_combat_ignorefriendlynpcs" )
local slightDelay = GetConVar( "lambdaplayers_voice_slightdelay" )

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
    local id = self:EntIndex()
    local curtime = CurTime() + ( cooldown or 0 )

    self:DebugPrint( "Created a hook: " .. hookname .. " | " .. uniquename )
    table_insert( self.l_Hooks, { hookname, "lambdaplayershook" .. id .. "_" .. uniquename, preserve } )
    hook.Add( hookname, "lambdaplayershook" .. id .. "_" .. uniquename, function( ... )
        if CurTime() < curtime then return end
        if preserve and !IsValid( self ) or !preserve and !LambdaIsValid( self ) then hook.Remove( hookname, "lambdaplayershook" .. id .. "_" .. uniquename ) return end 
        local result = func( ... )
        if result == "end" then self:DebugPrint( "Removed a hook: " .. hookname .. " | " .. uniquename ) hook.Remove( hookname, "lambdaplayershook" .. id .. "_" .. uniquename) return end
        curtime = CurTime() + ( cooldown or 0 )
        return result 
    end )
end

-- Returns if the hook exists
function ENT:HookExists( hookname, uniquename )
    local hooks = hook.GetTable()
    return hooks[ hookname ] != nil and hooks[ hookname ][ uniquename ] != nil
end

-- Removes a hook created by the function above
function ENT:RemoveHook( hookname, uniquename )
    self:DebugPrint( "Removed a hook: " .. hookname .. " | " .. uniquename )
    for k, v in ipairs( self.l_Hooks ) do if v[ 1 ] == hookname and v[ 2 ] == "lambdaplayershook" .. self:EntIndex() .. "_" .. uniquename then table_remove( self.l_Hooks, k ) end end 
    hook.Remove( hookname, "lambdaplayershook" .. self:EntIndex() .. "_" .. uniquename )
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
    local id = tostring( func ) .. random( 100000 )
    self.l_SimpleTimers[ id ] = !ignoredead
    timer_simple( delay, function()
        if ignoredead and !IsValid( self ) or !ignoredead and !LambdaIsValid( self ) or !ignoredead and !self.l_SimpleTimers[ id ] then return end
        func()
        self.l_SimpleTimers[ id ] = nil
    end )
end

-- Same as ENT:SimpleTimer(), but also checks if our weapon is valid and weapon name is the same one we created this timer with
function ENT:SimpleWeaponTimer( delay, func, ignoredead, ignorewepname )
    local id = tostring( func ) .. random( 100000 )
    self.l_SimpleTimers[ id ] = !ignoredead
    
    local wepent = self:GetWeaponENT()
    local curWep = self:GetWeaponName()
    
    timer_simple( delay, function()
        if ignoredead and !IsValid( self ) or !ignoredead and !LambdaIsValid( self ) or !ignoredead and !self.l_SimpleTimers[ id ] then return end
        if !IsValid( wepent ) or !ignorewepname and self:GetWeaponName() != curWep then return end
        func()
        self.l_SimpleTimers[ id ] = nil
    end )
end

-- Prevents every simple timer that does not have ignoredead from running
function ENT:TerminateNonIgnoredDeadTimers()
    table_Empty( self.l_SimpleTimers )
end

-- Creates a named timer that can be stopped. ignore dead var will run the time even if we die
-- Return true in the function to remove the timer
function ENT:NamedTimer( name, delay, repeattimes, func, ignoredead )
    local id = self:EntIndex()
    local intname = "lambdaplayers_" .. name .. id
    self:DebugPrint( "Created a Timer: " .. name )
    timer_create( intname, delay, repeattimes, function() 
        if ignoredead and !IsValid( self ) or !ignoredead and !LambdaIsValid( self ) then return end
        local result = func()
        if result == true then timer_Remove( intname ) self:DebugPrint( "Removed a Timer: " .. name ) end
    end )

    table_insert( self.l_Timers, intname )
end

-- Same as ENT:NamedTimer(), but also checks if our weapon is valid and weapon name is the same one we created this timer with
function ENT:NamedWeaponTimer( name, delay, repeattimes, func, ignoredead, ignorewepname )
    local id = self:EntIndex()
    local intname = "lambdaplayers_" .. name .. id
    self:DebugPrint( "Created a Weapon Timer: " .. name )
    
    local wepent = self:GetWeaponENT()
    local curWep = self:GetWeaponName()
    
    timer_create( intname, delay, repeattimes, function() 
        if ignoredead and !IsValid( self ) or !ignoredead and !LambdaIsValid( self ) then return end
        if !IsValid( wepent ) or !ignorewepname and self:GetWeaponName() != curWep then return end
        local result = func()
        if result == true then timer_Remove( intname ) self:DebugPrint( "Removed a Timer: " .. name ) end
    end )

    table_insert( self.l_Timers, intname )
end

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

-- Returns bone position and angles
function ENT:GetBoneTransformation( bone )
    local pos, ang = self:GetBonePosition( bone )
    if !pos or pos:IsZero() or pos == self:GetPos() then
        local matrix = self:GetBoneMatrix( bone )
        if matrix and ismatrix( matrix ) then
            pos = matrix:GetTranslation()
            ang = matrix:GetAngles()
        end
    end
    return { Pos = pos, Ang = ang, Bone = bone }
end

-- Returns a table that contains a position and angle with the specified type. hand or eyes
local eyeOffAng = Angle( 20, 0, 0 )
function ENT:GetAttachmentPoint( pointtype )
    local attachData = { Pos = self:WorldSpaceCenter(), Ang = self:GetForward():Angle(), Index = 0 }

    if pointtype == "hand" then
        local lookup = self:LookupAttachment( "anim_attachment_RH" )
        local handAttach = self:GetAttachment( lookup )

        if !handAttach then
            local bone = self:LookupBone( "ValveBiped.Bip01_R_Hand" )
            if isnumber( bone ) then attachData = self:GetBoneTransformation( bone ) end
        else
            attachData = handAttach
            attachData.Index = lookup
        end
    elseif pointtype == "eyes" then
        local lookup = self:LookupAttachment( "eyes" )
        local eyeAttach = self:GetAttachment( lookup )

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

    return ( result.Fraction == 1.0 or result.Entity == ent )
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
    if checkState then return ( checkState == self:GetNW2String( "lambda_state", "Idle" ) ) end
    return self:GetNW2String( "lambda_state", "Idle" )
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

    local sqrt = math.sqrt
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

            local model = ( info.model or self:GetModel() )
            if !IsValidModel( model ) then model = "models/player/kleiner.mdl" end
            self:SetModel( model )
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

            local spawnwep = self:WeaponDataExists( info.spawnwep ) and info.spawnwep or self.l_SpawnWeapon
            self:SwitchToSpawnWeapon()
            self:SetNW2String( "lambda_spawnweapon", self.l_SpawnWeapon )
            
            self.l_FavoriteWeapon = ( info.favwep or self.l_FavoriteWeapon )

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
        return ( isentity( self.l_movepos ) and self.l_movepos:GetPos() or self.l_movepos )
    end

    -- If the we can target the ent
    function ENT:CanTarget( ent )
        if ent.IsLambdaPlayer then 
            if !ent:Alive() then return false end
        elseif ent:IsPlayer() then
            if !ent:Alive() then return false end 
            if ignoreplayer:GetBool() then return false end 
            if ent:GetInfoNum( "lambdaplayers_combat_allowtargetyou", 0 ) == 0 then return false end
        elseif ent:IsNPC() or ent:IsNextBot() then
            if ent.IsLambdaAntlion and ( self:GetWeaponName() == "hl2_bugbait" or ent:GetOwner() == self ) then return false end
            if ent:GetInternalVariable( "m_lifeState" ) != 0 then return false end
            if ignoreFriendNPCs:GetBool() and self:Relations( ent ) == D_LI then return false end
            if ent.IsDrGNextbot and ent:IsDown() then return false end
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
        if !forceAttack and self:IsPanicking() then return end

        if random( 100 ) <= self:GetVoiceChance() and !self:IsSpeaking( "taunt" ) then self:PlaySoundFile( "taunt" ) end
        self:SetState( "Combat" )
        self:CancelMovement()
    end

    -- Retreats from entity target
    -- If the target is not specified, then Lambda will stop retreating only when time runs out
    function ENT:RetreatFrom( target, timeout )
        local alreadyPanic = self:IsPanicking()
        if !alreadyPanic then 
            self:CancelMovement()
            self:SetState( "Retreat" )
            if self:GetVoiceChance() > 0 then self:PlaySoundFile( "panic" ) end
        end

        local retreatTime = ( CurTime() + ( timeout or random( 8, 20 ) ) )
        if retreatTime > self.l_retreatendtime then self.l_retreatendtime = retreatTime end

        local target = self:GetEnemy()
        if !alreadyPanic or LambdaIsValid( target ) then self:SetEnemy( target ) end
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
        self.l_CurrentPlayedGesture = -1
    
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
        local name = nametablecopy[ random( #nametablecopy ) ]
        if !name then name = LambdaPlayerNames[ random( #LambdaPlayerNames ) ] end
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
    function ENT:LookTo( pos, time, poseonly )
        self.Face = pos
        self.l_PoseOnly = poseonly or false
        self.l_Faceend = time and CurTime() + time or nil
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

    -- Respawns the Lambda only if they have self:SetRespawn( true ) otherwise they are removed from run time
    function ENT:LambdaRespawn()
        self:DebugPrint( "Respawned" )

        self:SetSolidMask( MASK_SOLID_BRUSHONLY ) -- This should maybe help with the issue where the nextbot can't set pos because it's in something
        local spawnPos, spawnAng = self.l_SpawnPos, self.l_SpawnAngles
        if rasp:GetBool() then
            LambdaSpawnPoints = ( LambdaSpawnPoints or LambdaGetPossibleSpawns() )
            if LambdaSpawnPoints and #LambdaSpawnPoints > 0 then 
                local rndPoint = LambdaSpawnPoints[ random( #LambdaSpawnPoints ) ]
                spawnPos = rndPoint:GetPos()
                spawnAng = rndPoint:GetAngles()
            end
        end
        self:SetPos( spawnPos )
        self:SetSolidMask( MASK_PLAYERSOLID )

        self:SetAngles( spawnAng )
        self.loco:SetVelocity( vector_origin )
        self:SetCollisionGroup( !collisionPly:GetBool() and COLLISION_GROUP_PLAYER or COLLISION_GROUP_PASSABLE_DOOR )

        local phys = self:GetPhysicsObject()
        if IsValid( phys ) then phys:EnableCollisions( true ) end

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
        self:SetRunSpeed( runningSpeed:GetInt() )
        self:SetWalkSpeed( walkingSpeed:GetInt() )
        self:SetIsReloading( false )

        self:PreventDefaultComs( false )
        self:PreventWeaponSwitch( false )

        self.l_ladderarea = NULL
        self.l_UpdateAnimations = true
        self.l_Clip = self.l_MaxClip

        self:SwitchToSpawnWeapon()
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
    function ENT:Recreate( ignoreprehook, spawnPos, spawnAng )
        local shouldblock = LambdaRunHook( "LambdaPreRecreated", self )

        self:SimpleTimer( 0.1, function() self:Remove() end, true )
        if !ignoreprehook and shouldblock == true then return end

        local pos, ang = self.l_SpawnPos, self.l_SpawnAngles
        if self:Alive() then
            if spawnPos then
                tracetable.start = spawnPos
                tracetable.endpos = spawnPos
                tracetable.filter = self

                local mins, maxs = self:GetCollisionBounds()
                tracetable.mins = mins
                tracetable.maxs = maxs

                pos = TraceHull( tracetable ).HitPos 
            end
            if spawnAng then ang = spawnAng end
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
        pos = ( pos or self:GetPos() )
        dist = ( ( dist or 1500 ) ^ 2 )

        local neartbl = {}
        local limitDist = !unlimiteddistance:GetBool()
        for _, area in ipairs( GetAllNavAreas() ) do
            if !IsValid( area ) or area:GetSizeX() < 75 or area:GetSizeY() < 75 or area:GetCenter():IsUnderwater() or limitDist and pos:DistToSqr( area:GetClosestPointOnArea( pos ) ) > dist then continue end
            neartbl[ #neartbl + 1 ] = area
        end

        return neartbl
    end
    
    -- Returns a random position near the position 
    function ENT:GetRandomPosition( pos, dist, filter )
        pos = ( pos or self:GetPos() )

        -- If the navmesh is loaded then find a nav area to go to
        if IsNavmeshLoaded() then
            for _, area in RandomPairs( self:GetNavAreas( pos, dist ) ) do
                if !IsValid( area ) or !self:IsAreaTraversable( area ) then continue end
                local rndPoint = area:GetRandomPoint()
                if filter and filter( pos, area, rndPoint ) == true then continue end
                return rndPoint
            end
        end

        -- If not, try to go to a entirely random spot
        dist = ( dist or 1500 )
        return ( pos + VectorRand( -dist, dist ) )
    end

    -- Gets a entirely random sound from the source engine sound folder
    function ENT:GetRandomSound()
        local dir = "sound/"
        
        for i = 1, 10 do
            local files, directories = file_Find( dir .. "*", "GAME", "nameasc" )

            if #files > 0 and ( i != 10 and random( 2 ) ==  1 ) then
                local selectedfile = files[ random( #files ) ]
                if selectedfile and EndsWith( selectedfile, ".mp3" ) or selectedfile and EndsWith( selectedfile, ".wav" ) then return string.Replace( dir .. selectedfile, "sound/", "" ) end
            else
                local rnd = directories[ random( #directories ) ]
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
                return vptable[ random( #vptable ) ]
            end
        end

        local voiceDir = GetConVar( "lambdaplayers_voice_" .. voicetype .. "dir" )
        if voiceDir and voiceDir:GetString() == "randomengine" then return self:GetRandomSound() end

        local tbl = LambdaVoiceLinesTable[ voicetype ]
        return ( tbl and tbl[ random( #tbl ) ] )
    end

    -- Disables or re-enables Lambda's ability to use voice chat/type in chat.
    -- Useful for modules that need lambdas to not speak passively.
    function ENT:PreventDefaultComs( bool )
        self.l_preventdefaultspeak = bool
    end

    -- Restarts the Lambda's AI thread. Useful for forcing state changes
    function ENT:ResetAI()
        self.BehaveThread = coroutine.create( function() self:RunBehaviour() end )
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
             
             if #preword > 3 and random( 2 ) == 1 then
                 preword = validwords[ random( #validwords ) ]
             elseif #preword < 3 and random( 6 ) == 1 then
                 preword = smallwords[ random( #smallwords ) ]
             end    
             
             mod = mod .. " " .. preword
         end
    
         return mod
     end ]]

    -- Markov Chain Generator --
    -- Source code from https://github.com/hay/markov
    -- I simply got it converted from PHP to GLua
    local function generate_markov_table( text, look_forward )
        look_forward = ( look_forward or 4 )

        local charactertable = {}
        for i = 1, #text do
            local char = string_sub( text, i, ( i + look_forward - 1 ) )
            if !charactertable[ char ] then charactertable[ char ] = {} end
        end
    
        for i = 1, #text - look_forward do
            local char_index = string_sub( text, i, ( i + look_forward - 1 ) )
            local char_count = string_sub( text, ( i + look_forward ), ( i + look_forward * 2 - 1 ) )
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

        local rand = random( total )
        for _, item in ipairs( items ) do
            local weight = array[ item ]
            if rand <= weight then return item end
            rand = ( rand - weight )
        end
    end

    local function generate_markov_text( length, markov_table, look_forward )
        look_forward = ( look_forward or 4 )
        
        local char = next( markov_table )
        local o = char
    
        for i = 1, floor( length / look_forward ) do
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

    local function GetRandomMarkovLine( tbl )
        local copy = table_Copy( tbl )
        for keyword, _ in pairs( LambdaConditionalKeyWords ) do  
            for i = 1, #copy do 
                copy[ i ] = string_Replace( copy[ i ], keyword, "" ) 
            end
        end

        local markovtable = generate_markov_table( table_concat( copy, "\n" ), 4 )
        local generated = generate_markov_text( 1000, markovtable, 4 )
        local lines = string_Explode( "\n", generated )
        return lines[ random( #lines ) ]
    end

    -- Literally the same thing as :GetVoiceLine() but for Text Lines
    function ENT:GetTextLine( texttype )
        local tbl = LambdaTextTable[ texttype ]

        local textPfl = self.l_TextProfile
        if textPfl and LambdaTextProfiles[ textPfl ] then
            local texttable = LambdaTextProfiles[ textPfl ][ texttype ]
            if texttable and #texttable > 0 then tbl = texttable end
        end

        if tbl then
            local useMarkov = usemarkovgenerator:GetBool()
            
            for _, textline in RandomPairs( tbl ) do
                local line = ( useMarkov and GetRandomMarkovLine( tbl ) or textline )
                local condition, modifiedline = LambdaConditionalKeyWordCheck( self, line )
                if condition then return modifiedline end
            end
        end

        return ""
    end

    -- Makes the Lambda say the specified file
    function ENT:PlaySoundFile( filepath, delay )
        if !filepath then return end
        
        if !isnumber( delay ) then
            delay = ( ( delay == nil and slightDelay:GetBool() ) and Rand( 0.1, 0.75 ) or 0 ) 
        end

        local isVoiceType = self:GetVoiceLine( filepath )
        if isVoiceType then 
            self.l_lastspokenvoicetype = filepath 
            filepath = isVoiceType
        end

        self:SetLastSpeakingTime( RealTime() + 4 )

        net.Start( "lambdaplayers_playsoundfile" )
            net.WriteEntity( self )
            net.WriteString( filepath )
            net.WriteUInt( self:GetCreationID(), 32 )
            net.WriteVector( self:GetPos() )
            net.WriteFloat( delay )
        net.Broadcast()
    end

    function ENT:GetFallDamage( speed, realDmg )
        local gravity = self.loco:GetGravity()
        local maxSafeFallSpeed = sqrt( 2 * gravity * 20 * 12 )

        speed = ( speed or self.l_FallVelocity )
        if !realDmg and speed > maxSafeFallSpeed and !realisticfalldamage:GetBool() then
            return 10
        end

        local fatalFallSpeed = sqrt( 2 * gravity * 60 * 12 )
        local damageForFall = ( 100 / ( fatalFallSpeed - maxSafeFallSpeed ) )
        return ( ( speed - maxSafeFallSpeed ) * damageForFall )
    end

    function ENT:StopCurrentVoiceLine()
        if !self:IsSpeaking() then return end

        net.Start( "lambdaplayers_stopcurrentsound" )
            net.WriteEntity( self )
        net.Broadcast()
    end

    function ENT:GetLastSpokenVoiceType()
        return self.l_lastspokenvoicetype
    end

    function ENT:IsUsingLadder()
        return IsValid( self.l_ladderarea )
    end


    -- Makes the Lambda say the provided text
    -- if instant is true, the Lambda will say the text instantly.
    -- teamOnly is just so this function is compatible with addons basically
    -- recipients is optional 
    function ENT:Say( text, teamOnly, recipients )
        local replacement = LambdaRunHook( "LambdaPlayerSay", self, text, ( teamOnly or false ) )
        text = isstring( replacement ) and replacement or text
        if text == "" then return end
        text = LambdaKeyWordModify( self, text )
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
    function ENT:TypeMessage( text )
        if text == "" then return end
        if self:GetIsTyping() then self:Say( self.l_typedtext ) end
        self:SetIsTyping( true )
        text = LambdaKeyWordModify( self, text )

        self.l_starttypestate = self:GetState()
        self.l_typedtext = ""
        self.l_nexttext = 0
        self.l_queuedtext = text
        self:OnBeginTyping( text )
    end

    -- Returns if we can type a message
    function ENT:CanType()
        if !chatAllowed:GetBool() then return false end
        if chatlimit:GetInt() == 0 then return true end
        local count = 0
        for k, v in ipairs( GetLambdaPlayers() ) do
            if IsValid( v ) and v:GetIsTyping() then count = count + 1 end 
        end
        return count < chatlimit:GetInt() 
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

    function ENT:HandleAllValidNPCRelations()
        for _, v in ipairs( ents_GetAll() ) do 
            if !IsValid( v ) or v.IsLambdaPlayer or !v:IsNPC() and !v:IsNextBot() then continue end 
            self:HandleNPCRelations( v ) 
        end
    end

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
            local maxSpeed = self.loco:GetDesiredSpeed()
            stepTime = ( maxSpeed <= 100 and 0.4 or maxSpeed <= 300 and 0.35 or 0.25 )
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
        if self:IsPanicking() and !self:GetIsFiring() and !self:GetIsReloading() and panicAnimations:GetBool() then
            return _LAMBDAPLAYERSHoldTypeAnimations[ "panic" ]
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
                self:AttackTarget( ent )
                return
            end

            local entDist = self:GetRangeSquaredTo( ent )
            local heightDiff = abs( selfZ - ent:GetPos().z )
            if ( entDist + ( heightDiff * heightDiff ) ) > searchDist then continue end

            closeTarget = ent
            searchDist = entDist
        end

        if closeTarget then
            self:AttackTarget( closeTarget ) 
        end
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

    function ENT:IsBeingDrawn()
        return ( RealTime() < self.l_lastdraw )
    end

end