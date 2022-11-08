
local RandomPairs = RandomPairs
local LambdaIsValid = LambdaIsValid
local ipairs = ipairs
local IsValid = IsValid
local file_Find = file.Find
local string_find = string.find
local random = math.random
local FindInSphere = ents.FindInSphere
local table_empty = table.Empty
local file_Find = file.Find
local table_Empty = table.Empty
local ents_GetAll = ents.GetAll
local VectorRand = VectorRand
local SortTable = table.sort
local timer_simple = timer.Simple
local timer_create = timer.Create
local timer_Remove = timer.Remove
local Trace = util.TraceLine
local table_add = table.Add
local EndsWith = string.EndsWith
local string_Replace = string.Replace
local table_insert = table.insert
local eyetracetable = {}
local GetLambdaPlayers = GetLambdaPlayers
local debugcvar = GetConVar( "lambdaplayers_debug" )

---- Anything Shared can go here ----

-- Function for debugging prints
function ENT:DebugPrint( ... )
    if !debugcvar:GetBool() then return end
    print( self:GetLambdaName() .. " EntIndex = ( " .. self:EntIndex() .. " )" .. ": ", ... )
end

-- Creates a hook that will remove itself if it runs while the lambda is invalid or if the provided function returns false
-- preserve makes the hook not remove itself when the Entity is considered "dead" by self:GetIsDead(). Mainly used by Respawning
-- cooldown arg is meant to be used with Tick and Think hooks
function ENT:Hook( hookname, uniquename, func, preserve, cooldown )
    local id = self:EntIndex()
    local curtime = CurTime() + ( cooldown or 0 )

    self:DebugPrint( "Created a hook: " .. hookname .. " | " .. uniquename )
    hook.Add( hookname, "lambdaplayershook" .. id .. "_" .. uniquename, function( ... )
        if CurTime() < curtime then return end
        if preserve and !IsValid( self ) or !preserve and !LambdaIsValid( self ) then hook.Remove( hookname, "lambdaplayershook" .. id .. "_" .. uniquename ) return end 
        local result = func( ... )
        if result == "end" then self:DebugPrint( "Removed a hook: " .. hookname .. " | " .. uniquename ) hook.Remove( hookname, "lambdaplayershook" .. id .. "_" .. uniquename) return end
        curtime = CurTime() + ( cooldown or 0 )
        return result 
    end )
end

-- Removes a hook created by the function above
function ENT:RemoveHook( hookname, uniquename )
    self:DebugPrint( "Removed a hook: " .. hookname .. " | " .. uniquename )
    hook.Remove( hookname, "lambdaplayershook" .. self:EntIndex() .. "_" .. uniquename )
end

-- Creates a simple timer that won't run if we are invalid or dead. ignoredead var will run the timer even if self:GetIsDead() is true
function ENT:SimpleTimer( delay, func, ignoredead )
    timer_simple( delay, function() 
        if ignoredead and !IsValid( self ) or !ignoredead and !LambdaIsValid( self ) then return end
        func()
    end )
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

-- Returns bone position and angles
function ENT:GetBoneTransformation( bone )
    local pos, ang = self:GetBonePosition( bone )

    if !pos or pos:IsZero() or pos == self:GetPos() then
        local matrix = self:GetBoneMatrix( bone )

        if matrix and ismatrix( matrix ) then

            return { Pos = matrix:GetTranslation(), Ang = matrix:GetAngles() }
        end

    end
    
    return { Pos = pos, Ang = ang }
end

-- Returns a table that contains a position and angle with the specified type. hand or eyes
function ENT:GetAttachmentPoint( pointtype )
    if pointtype == "hand" then
        local lookup = self:LookupAttachment( 'anim_attachment_RH' )
        if lookup == 0 then
            local bone = self:LookupBone( "ValveBiped.Bip01_R_Hand" )
            if !bone then
                return { Pos = self:WorldSpaceCenter(), Ang = self:GetForward():Angle() }
            else
                if isnumber( bone ) then
                    return self:GetBonePosAngs( bone )
                else
                    return { Pos = self:WorldSpaceCenter(), Ang = self:GetForward():Angle() }
                end
            end
        else
            return self:GetAttachment( lookup )
        end
    elseif pointtype == "eyes" then
        local lookup = self:LookupAttachment( 'eyes' )
        if lookup == 0 then
            return { Pos = self:WorldSpaceCenter() + Vector( 0, 0, 5 ), Ang = self:GetForward():Angle() + Angle( 20, 0, 0 ) }
        else
            return self:GetAttachment( lookup )
        end
    end
end
--

-- AI/Nextbot creators can assign .LambdaPlayerSTALP = true to their entities if they want the Lambda Players to treat them like players
function ENT:ShouldTreatAsLPlayer( ent )
    if ent.LambdaPlayerSTALP then return true end
    if ent.IsLambdaPlayer then return true end
    if ent:IsPlayer() then return true end
    if ent:IsNPC() or ent:IsNextBot() then return false end
end

-- Returns our eye position
function ENT:EyePos()
    return self:GetAttachmentPoint( "eyes" ).Pos
end

-- Returns our eye angles
function ENT:EyeAngles()
    return self:GetAttachmentPoint( "eyes" ).Ang
end

-- Returns the direction we are looking to
function ENT:GetAimVector()
    return self:GetAttachmentPoint( "eyes" ).Ang:Forward()
end

-- Similar to Real Player's :GetEyeTrace()
function ENT:GetEyeTrace()
    local attach = self:GetAttachmentPoint( "eyes" )
    eyetracetable.start = attach.Pos
    eyetracetable.endpos = attach.Ang:Forward() * 30000
    eyetracetable.filter = self
    local result = Trace( eyetracetable )
    return result
end


-- Turns the Lambda Player into a table of its personal data
-- See function ENT:ApplyLambdaInfo() to use this data with
-- This function is shared so that means the client can get a Lambda Player's info and save it for themselves
function ENT:ExportLambdaInfo()
    local info = {
        name = self:GetLambdaName(),
        model = self:GetModel(),
        health = self:GetNWMaxHealth(),

        plycolor = self:GetPlyColor(),
        physcolor = self:GetPhysColor(),

        -- Chances
        build = self:GetBuildChance(),
        combat = self:GetCombatChance(),
        voice = self:GetVoiceChance(),
        --

        voicepitch = self:GetVoicePitch()
    }

    return info
end


if SERVER then

    local GetAllNavAreas = navmesh.GetAllNavAreas
    local ignoreplayer = GetConVar( "ai_ignoreplayers" )


    -- Applies info data from :ExportLambdaInfo() to the Lambda Player
    function ENT:ApplyLambdaInfo( info )
        self:DebugPrint( "had Lambda Info applied to them" )

        self:SetLambdaName( info.name or self:GetLambdaName() )
        self:SetModel( info.model or self:GetModel() )
        self:SetMaxHealth( info.health or self:GetMaxHealth() )
        self:SetHealth( info.health or self:GetMaxHealth() )
        self:SetNWMaxHealth( info.health or self:GetMaxHealth() )

        self:SetPlyColor( info.plycolor or self:GetPlyColor() )
        self:SetPhysColor( info.physcolor or self:GetPhysColor() )
        self.WeaponEnt:SetNW2Vector( "lambda_weaponcolor", ( info.physcolor or self:GetPhysColor() ) )

        self:SetBuildChance( info.build or self:GetBuildChance() )
        self:SetCombatChance( info.combat or self:GetCombatChance() )
        self:SetVoiceChance( info.voice or self:GetVoiceChance() )
        self.l_Personality = {
            { "Build", info.build or self:GetBuildChance() },
            { "Combat", info.combat or self:GetCombatChance() },
        }
        SortTable( self.l_Personality, function( a, b ) return a[ 2 ] > b[ 2 ] end )

        self:SetVoicePitch( info.voicepitch or self:GetVoicePitch() )

    end
    
    -- If the we can target the ent
    function ENT:CanTarget( ent )
        return self:Visible( ent ) and ( ent:IsNPC() or ent:IsNextBot() or ent:IsPlayer() and !ignoreplayer:GetBool() )
    end

    -- Updates our networked health
    function ENT:UpdateHealthDisplay()
        self:SetNW2Float( "lambda_health", self:Health() )
    end

    -- Makes the lambda face the position or a entity if provided
    function ENT:LookTo( pos, time )
        self.Face = pos
        self.l_Faceend = time and CurTime() + time or nil
    end

    -- Sets our state
    function ENT:SetState( state )
        if state == self.l_State then return end
        self:DebugPrint( "Changed state from " .. self.l_State .. " to " .. state )
        self.l_LastState = self.l_State
        self.l_State = state
    end

    -- Obviously returns the current state
    function ENT:GetState()
        return self.l_State
    end

    -- Returns the last state we were in
    function ENT:GetLastState()
        return self.l_LastState
    end

    -- Returns if we are currently speaking
    function ENT:IsSpeaking() 
        return CurTime() < self:GetLastSpeakingTime()
    end

    -- Returns the walk speed
    function ENT:GetWalkSpeed()
        return 200
    end

    -- If we have a lethal weapon
    function ENT:HasLethalWeapon()
        return self.l_HasLethal or false
    end

    -- Returns the run speed
    function ENT:GetRunSpeed()
        return 400
    end

    -- Respawns the lambda only if they have self:SetRespawn( true ) otherwise they are removed from run time
    function ENT:LambdaRespawn()
        self:DebugPrint( "Respawned" )
        self:SetIsDead( false )
        self:SetIsReloading( false )
        self:SetPos( self.l_SpawnPos )
        self:SetCollisionGroup( COLLISION_GROUP_PLAYER )

        self:ClientSideNoDraw( self, false )
        self:SetNoDraw( false )
        self:DrawShadow( true )

        self:SetHealth( self:GetMaxHealth() )
        self:AddFlags( FL_OBJECT )
        self:SwitchWeapon( "none" )
        self:UpdateHealthDisplay()
        
        self:SetState( "Idle" )
        self:SetCrouch( false )
        self:SetEnemy( nil )

        net.Start( "lambdaplayers_invalidateragdoll" )
        net.WriteEntity( self )
        net.Broadcast()
    end

    -- Returns a sequential table full of nav areas new the position
    function ENT:GetNavAreas( pos, dist )
        pos = pos or self:GetPos()
        dist = dist or 1500

        local areas = GetAllNavAreas()
        local neartbl = {}

        local squared = dist * dist

        for k, v in ipairs( areas ) do
            if LambdaIsValid( v ) and v:GetSizeX() > 75 and v:GetSizeY() > 75 and !v:IsUnderwater() and v:GetClosestPointOnArea( pos ):DistToSqr( pos ) <= squared then
                neartbl[ #neartbl + 1 ] = v
            end
        end

        return neartbl
    end
    
    -- Returns a random position near the position 
    function ENT:GetRandomPosition( pos, dist )
        pos = pos or self:GetPos()
        dist = dist or 1500

        if navmesh.IsLoaded() then -- If the navmesh is loaded then find a nav area to go to

            local areas = self:GetNavAreas( pos, dist )

            for k, v in RandomPairs( areas ) do
                if IsValid( v ) then
                    return v:GetRandomPoint()
                end
            end

        else -- If not, try to go to a entirely random spot
            return self:GetPos() + VectorRand( -dist, dist )
        end
    end

    -- Gets a entirely random sound from the source engine sound folder
    function ENT:GetRandomSound()
        local dir = "sound/"
        
        for i = 1, 10 do
            local files, directories = file_Find( dir .. "*", "GAME", "nameasc" )

            if #files > 0 and ( i != 10 and random( 1, 2 ) ==  1 ) then
                local selectedfile = files[ random( #files ) ]
                if selectedfile and EndsWith( selectedfile, ".mp3" ) or selectedfile and EndsWith( selectedfile, ".wav" ) then return dir .. selectedfile end
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

    -- Makes the Lambda say the specified file or file path.
    -- Random sound files for example, something/idle/*
    function ENT:PlaySoundFile( filepath, stoponremove )
        local isdir = string_find( filepath, "/*" )

        self:SetLastSpeakingTime( CurTime() + 2 )

        if isdir then
            local soundfiles = file_Find( "sound/" .. filepath, "GAME", "nameasc" )
            if !soundfiles then return end

            filepath = string_Replace( filepath, "*", soundfiles[ random( #soundfiles ) ] )
            filepath = string_Replace( filepath, "sound/", "")

            table_Empty( soundfiles )
        end

        net.Start( "lambdaplayers_playsoundfile" )
            net.WriteEntity( self )
            net.WriteString( filepath )
            net.WriteBool( stoponremove )
            net.WriteUInt( self:GetCreationID(), 32 )
        net.Broadcast()
    end

    -- Makes the entity no longer draw on the client if bool is set to true.
    -- Making a entity nodraw server side seemed to have issues in multiplayer.

    -- As of 11/2/2022, it seems we need the server nodraw, client nodraw, and usage of Draw functions to make the lambda players to not draw. Kinda cringe but alright

    function ENT:ClientSideNoDraw( ent, bool )
        net.Start( "lambdaplayers_setnodraw" )
            net.WriteEntity( ent )
            net.WriteBool( bool or false )
        net.Broadcast()
    end

    function ENT:Relations( ent )
        if _LAMBDAPLAYERSEnemyRelations[ ent:GetClass() ] then return D_HT end
        return D_NU
    end

    function ENT:HandleNPCRelations( ent )
        self:DebugPrint( "handling relationship with ", ent )
        ent:AddEntityRelationship( self , self:Relations( ent ), 1 )
    end

    function ENT:HandleAllValidNPCRelations()
        for k, v in ipairs( ents_GetAll() ) do 
            if IsValid( v ) and v:IsNPC() then self:HandleNPCRelations( v ) end
        end
    end


elseif CLIENT then



end