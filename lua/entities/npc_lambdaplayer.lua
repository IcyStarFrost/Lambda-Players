AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.PrintName = "Lambda Player"
ENT.Author = "StarFrost"
ENT.IsLambdaPlayer = true

local include = include
local print = print
local AddCSLuaFile = AddCSLuaFile
local ipairs = ipairs

--- Include files based on sv_ sh_ or cl_
local ENTFiles = file.Find( "lambdaplayers/lambda/*", "LUA", "nameasc" )

for k, luafile in ipairs( ENTFiles ) do

    if string.StartWith( luafile, "sv_" ) then -- Server Side Files
        include( "lambdaplayers/lambda/" .. luafile )
        print( "Lambda Players ENT TABLE: Included Server Side ENT Lua File [" .. luafile .. "]" )
    elseif string.StartWith( luafile, "sh_" ) then -- Shared Files
        if SERVER then
            AddCSLuaFile( "lambdaplayers/lambda/" .. luafile )
        end
        include( "lambdaplayers/lambda/" .. luafile )
        print( "Lambda Players ENT TABLE: Included Shared ENT Lua File [" .. luafile .. "]" )
    elseif string.StartWith( luafile, "cl_" ) then -- Client Side Files
        if SERVER then
            AddCSLuaFile( "lambdaplayers/lambda/" .. luafile )
        else
            include( "lambdaplayers/lambda/" .. luafile )
            print( "Lambda Players ENT TABLE: Included Client Side ENT Lua File [" .. luafile .. "]" )
        end
    end
end
---

-- Localization

    local random = math.random
    local rand = math.Rand
    local SortTable = table.sort
    local eyetracing = GetConVar( "lambdaplayers_debug_eyetracing" )
    local isfunction = isfunction
    local isnumber = isnumber
    local Lerp = Lerp
    local LerpVector = LerpVector
    local isentity = isentity
    local VectorRand = VectorRand
    local Vector = Vector
    local IsValid = IsValid
    local coroutine_status = coroutine.status
    local coroutine_wait = coroutine.wait
    local undo = undo
    local debugoverlay = debugoverlay
    local GetTraceback = debug.traceback
    local table_GetKeys = table.GetKeys
    local voicepitchmin = GetConVar( "lambdaplayers_voice_voicepitchmin" )
    local voicepitchmax = GetConVar( "lambdaplayers_voice_voicepitchmax" )
    local drawflashlight = GetConVar( "lambdaplayers_drawflashlights" )
    local profilechance = GetConVar( "lambdaplayers_lambda_profileusechance" )
    local allowaddonmodels = GetConVar( "lambdaplayers_lambda_allowrandomaddonsmodels" ) 
    local onlyaddonmodels = GetConVar( "lambdaplayers_lambda_onlyaddonmodels" ) 
    local ents_Create = ents and ents.Create or nil
    local navmesh_GetNavArea = navmesh and navmesh.GetNavArea or nil
    local navmesh_Find = navmesh and navmesh.Find or nil 
    local voiceprofilechance = GetConVar( "lambdaplayers_lambda_voiceprofileusechance" )
    local textprofilechance = GetConVar( "lambdaplayers_lambda_textprofileusechance" )
    local thinkrate = GetConVar( "lambdaplayers_lambda_singleplayerthinkdelay" )
    local CurTime = CurTime
    local SysTime = SysTime
    local InSinglePlayer = game.SinglePlayer
    local Clamp = math.Clamp
    local isvector = isvector
    local color_white = color_white
    local RandomPairs = RandomPairs
    local TraceHull = util.TraceHull
    local FrameTime = FrameTime
    local unstucktable = {}
    local swimtable = { collisiongroup = COLLISION_GROUP_PLAYER }
    local sub = string.sub
    local lower = string.lower
    local RealTime = RealTime
    local rndBodyGroups = GetConVar( "lambdaplayers_lambda_allowrandomskinsandbodygroups" )
    local collisionmins = Vector( -16, -16, 0 )
    local standingcollisionmaxs = Vector( 16, 16, 72 )
    local crouchingcollisionmaxs = Vector( 16, 16, 36 )
    local maxHealth = GetConVar( "lambdaplayers_lambda_maxhealth" )
    local debugmode = GetConVar( "lambdaplayers_debug" )
    local spawnHealth = GetConVar( "lambdaplayers_lambda_spawnhealth" )
    local maxArmor = GetConVar( "lambdaplayers_lambda_maxarmor" )
    local spawnArmor = GetConVar( "lambdaplayers_lambda_spawnarmor" )
    local collisionPly = GetConVar( "lambdaplayers_lambda_noplycollisions" )
    local walkingSpeed = GetConVar( "lambdaplayers_lambda_walkspeed" )
    local runningSpeed = GetConVar( "lambdaplayers_lambda_runspeed" )
    local LambdaSpawnBehavior = GetConVar( "lambdaplayers_combat_spawnbehavior" )
    local ignorePlys = GetConVar( "ai_ignoreplayers" )
    local sv_gravity = GetConVar( "sv_gravity" )
    local physUpdateTime = GetConVar( "lambdaplayers_lambda_physupdatetime" )
--

if CLIENT then

    language.Add( "npc_lambdaplayer", "Lambda Player" )

end

function ENT:Initialize()

    self.l_SpawnPos = self:GetPos() -- Used for Respawning
    self.l_SpawnAngles = self:GetAngles()
    self.l_Hooks = {} -- The table holding all our created hooks
    self.l_Timers = {} -- The table holding all named timers
    self.l_SimpleTimers = {} -- The table holding all simple timers
    self.debuginitstart = SysTime() -- Debug time from initialize to ENT:RunBehaviour()
    
    -- Has to be here so the client can run this too. Originally was under Personal Stats
    self:BuildPersonalityTable() -- Builds all personality chances from autorun_includes/shared/lambda_personalityfuncs.lua for use in chance testing and creates Get/Set functions for each one

    if SERVER then
        
        local mdlTbl = _LAMBDAPLAYERS_DefaultPlayermodels
        if allowaddonmodels:GetBool() then
            mdlTbl = ( onlyaddonmodels:GetBool() and _LAMBDAPLAYERS_AddonPlayermodels or _LAMBDAPLAYERS_AllPlayermodels )
            if #mdlTbl == 0 then mdlTbl = _LAMBDAPLAYERS_DefaultPlayermodels end
        end    
        self:SetModel( mdlTbl[ random( #mdlTbl ) ] )

        self.l_SpawnedEntities = {} -- The table holding every entity we have spawned
        self.l_ExternalVars = {} -- The table holding any custom variables external addons want saved onto the Lambda so it can exported along with other Lambda Info

        -- Tables of certain types of entities. Used to limit certain entities
        for k, name in ipairs( LambdaEntityLimits ) do
            self[ "l_Spawned" .. name ] = {}
        end

        self.l_State = "Idle" -- The current state we are in
        self.l_LastState = "Idle" -- The last state we were in
        self.l_Weapon = "" -- The weapon we currently have
        self.l_queuedtext = nil -- The text that we want to send in chat
        self.l_typedtext = nil -- The current text we have typed out so far
        self.l_nexttext = 0 -- The next time we can type the next character
        self.l_starttypestate = "" -- The state we started typing in

        self.l_issmoving = false -- If we are moving
        self.l_isfrozen = false -- If set true, stop moving as if ai_disable is on
        self.l_unstuck = false -- If true, runs our unstuck process
        self.l_recomputepath = nil -- If set to true, recompute the current path. After that this will reset to nil
        self.l_UpdateAnimations = true -- If we can update our animations. Used for the purpose of playing sequences
        self.VJ_AddEntityToSNPCAttackList = true -- Makes creature-based VJ SNPCs able to damages us with melee and leap attacks
        self.l_isswimming = false -- If we are currenly swimming (only used to recompute paths when exitting swimming)
        self.l_AvoidCheck_NextToDoor = false -- If we are currenly near a door and shouldn't use obstacle avoidance

        self.l_UnstuckBounds = 50 -- The distance the unstuck process will use to check. This value increments during the process and set back to 50 when done
        self.l_nextspeedupdate = 0 -- The next time we update our speed
        self.l_NexthealthUpdate = 0 -- The next time we update our networked health
        self.l_stucktimes = 0 -- How many times did we get stuck in the past 10 seconds
        self.l_stucktimereset = 0 -- The time until l_stucktimes gets reset to 0
        self.l_nextfootsteptime = 0 -- The next time we play a footstep sound
        self.l_nextobstaclecheck = 0 -- The next time we will check for obstacles on our path
        self.l_nextphysicsupdate = 0 -- The next time we will update our Physics Shadow
        self.l_WeaponUseCooldown = 0 -- The time before we can use our weapon again
        self.l_noclipheight = 0 -- The height we will float off the ground from
        self.l_FallVelocity = 0 -- How fast we are falling
        self.l_debugupdate = 0 -- The next time the networked debug vars will be updated
        self.l_nextidlesound = CurTime() + 5 -- The next time we will play a idle sound
        self.l_outboundsreset = CurTime() + 5 -- The time until we get teleported back to spawn because we are out of bounds
        self.l_nextnpccheck = CurTime() + 1 -- The next time we will check for surrounding NPCs
        self.l_nextnoclipheightchange = 0 -- The next time we will change our height while in noclip
        self.l_nextUA = CurTime() + rand( 1, 15 ) -- The next time we will run a UAction. See lambda/sv_x_universalactions.lua
        self.l_NextPickupCheck = 0 -- The next time we will check for nearby items to pickup
        self.l_moveWaitTime = 0 -- The time we will wait until continuing moving through our path
        self.l_nextswimposupdate = 0 -- the next time we will update our swimming position
        self.l_ladderfailtimer = CurTime() + 15 -- The time until we are removed and recreated due to Gmod issues with nextbots and ladders. Thanks Facepunch
        self.l_NextWeaponThink = 0 -- The next time we will run the currenly held weapon's think callback
        self.l_CurrentPlayedGesture = -1 -- Gesture ID that is assigned when the ENT:PlayGestureAndWait( id ) function is ran
        self.l_retreatendtime = 0 -- The time until we stop retreating
        self.l_AvoidCheck_NextDoorCheck = 0 -- The next time we will check if we are next to a door while using obstacle avoidance

        self.l_ladderarea = NULL -- The ladder nav area we are currenly using to climb
        self.l_CurrentPath = nil -- The current path (PathFollower) we are on. If off navmesh, this will hold a Vector
        self.l_movepos = nil -- The position or entity we are going to
        self.l_moveoptions = nil -- The move position's options, such as updating, goal tolerance, etc.
        self.l_noclippos = self:GetPos() -- The position we want to noclip to
        self.l_swimpos = self:GetPos() -- The position we are currently swimming to
        
        local nearArea = navmesh_GetNavArea( self:WorldSpaceCenter(), 400 ) -- The current nav area we are in
        if IsValid( nearArea ) then self.l_currentnavarea = nearArea; self:OnNavAreaChanged( nearArea, nearArea ) end

        -- Personal Stats --
        self:SetLambdaName( self:GetOpenName() )
        self:SetProfilePicture( #Lambdaprofilepictures > 0 and Lambdaprofilepictures[ random( #Lambdaprofilepictures ) ] or "spawnicons/".. sub( self:GetModel(), 1, #self:GetModel() - 4 ).. ".png" )

        self:SetMaxHealth( maxHealth:GetInt() )
        self:SetNWMaxHealth( maxHealth:GetInt() )
        self:SetHealth( spawnHealth:GetInt() )
        self:UpdateHealthDisplay()

        self:SetArmor( spawnArmor:GetInt() ) -- Our current armor
        self:SetMaxArmor( maxArmor:GetInt() ) -- Our maximum armor

        self:SetPlyColor( Vector( random( 255 ) / 225, random( 255 ) / 255, random( 255 ) / 255 ) )
        self:SetPhysColor( Vector( random( 255 ) / 225, random( 255 ) / 255, random( 255 ) / 255 ) )
        self.l_PlyRealColor = self:GetPlyColor():ToColor()
        self.l_PhysRealColor = self:GetPhysColor():ToColor()

        local rndpingrange = random( 1, 120 )
        self:SetAbsPing( rndpingrange )  -- The lowest point our fake ping can get
        self:SetPing( rndpingrange ) -- Our actual fake ping
        self:SetSteamID64( 90071996842377216 + random( 1, 10000000 ) )
        self:SetTextPerMinute( 400 ) -- The amount of characters we can type within a minute
        self:SetNW2String( "lambda_steamid", "STEAM_0:0:" .. random( 1, 200000000 ) )
        self:SetNW2String( "lambda_ip", "192." .. random( 10, 200 ) .. "." .. random( 10 ).. "." .. random( 10, 200 ) .. ":27005" )
        self:SetNW2String( "lambda_state", "Idle" )
        self:SetNW2String( "lambda_laststate", "Idle" )
        
        self.l_BodyGroupData = {}
        if rndBodyGroups:GetBool() then
            -- Randomize my model's bodygroups
            for _, v in ipairs( self:GetBodyGroups() ) do
                local subMdls = #v.submodels
                if subMdls == 0 then continue end 
                    
                local rndID = random( 0, subMdls )
                self:SetBodygroup( v.id, rndID )
                self.l_BodyGroupData[ v.id ] = rndID
            end

            -- Randomize my model's skingroup
            local skinCount = self:SkinCount()
            if skinCount > 0 then self:SetSkin( random( 0, skinCount - 1 ) ) end
        end

        -- Personality function was relocated to the start of the code since it needs to be shared so clients can have Get functions
        
        self:SetVoiceChance( random( 1, 100 ) )
        self:SetTextChance( random( 1, 100 ))
        self:SetVoicePitch( random( voicepitchmin:GetInt(), voicepitchmax:GetInt() ) )

        local modelVP = LambdaModelVoiceProfiles[ lower( self:GetModel() ) ]
        if modelVP then 
            self.l_VoiceProfile = modelVP
        else
            local vpchance = voiceprofilechance:GetInt()
            if vpchance > 0 and random( 1, 100 ) <= vpchance then 
                local vps = table_GetKeys( LambdaVoiceProfiles ) 
                self.l_VoiceProfile = vps[ random( #vps ) ] 
            end
        end
        self:SetNW2String( "lambda_vp", self.l_VoiceProfile )

        local tpchance = textprofilechance:GetInt()
        if tpchance > 0 and random( 1, 100 ) < tpchance then local tps = table_GetKeys( LambdaTextProfiles ) self.l_TextProfile = tps[ random( #tps ) ] end
        self:SetNW2String( "lambda_tp", self.l_TextProfile )

        ----

        SortTable( self.l_Personality, function( a, b ) return a[ 2 ] > b[ 2 ] end )

        self.loco:SetJumpHeight( 50 )
        self.loco:SetAcceleration( 2000 )
        self.loco:SetDeceleration( 1000000 )
        self.loco:SetStepHeight( 30 )
        self.l_LookAheadDistance = 0
        self.loco:SetGravity( sv_gravity:GetFloat() ) -- Makes us fall at the same speed as the real players do

        self:SetRunSpeed( runningSpeed:GetInt() )
        self:SetCrouchSpeed( 60 )
        self:SetWalkSpeed( walkingSpeed:GetInt() )
        self:SetSlowWalkSpeed( 100 )

        self:SetCollisionBounds( collisionmins, standingcollisionmaxs )
        self:PhysicsInitShadow()

        if !collisionPly:GetBool() then
            self:SetCollisionGroup( COLLISION_GROUP_PLAYER )
        else
            self:SetCollisionGroup( COLLISION_GROUP_PASSABLE_DOOR )
        end

        self:SetSolidMask( MASK_PLAYERSOLID )
        self:AddCallback( "PhysicsCollide", function( self, data )
            self:HandleCollision( data )
        end)

        if LambdaSpawnBehavior:GetInt() == 1 then
            local plys = self:FindInSphere( nil, 25000, function( ent ) return ( ent:IsPlayer()) end )
            self:AttackTarget( plys[ random( #plys ) ] )
        elseif LambdaSpawnBehavior:GetInt() == 2 then
            local randomtarg = self:FindInSphere( nil, 25000, function( ent ) return ( ent:IsNPC() or ent:IsNextBot() or ent:IsPlayer() and !ignorePlys:GetBool() and ent:GetInfoNum( "lambdaplayers_combat_allowtargetyou", 0 ) == 1 and ent:Alive() ) end )
            self:AttackTarget( randomtarg[ random( #randomtarg ) ] )
        end

        self:SetLagCompensated( true )
        self:AddFlags( FL_OBJECT + FL_NPC )

        local ap = self:LookupAttachment( "anim_attachment_RH" )
        local attachpoint = self:GetAttachmentPoint( "hand" )

        self.WeaponEnt = ents_Create( "base_anim" )
        self.WeaponEnt:SetPos( attachpoint.Pos )
        self.WeaponEnt:SetAngles( attachpoint.Ang )
        self.WeaponEnt:SetParent( self, ap )
        self.WeaponEnt:Spawn()
        self.WeaponEnt.IsLambdaWeapon = true
        self.WeaponEnt:SetNW2Vector( "lambda_weaponcolor", self:GetPhysColor() )
        self.WeaponEnt:SetNoDraw( true )
        self:SetWeaponENT( self.WeaponEnt )
        self.l_SpawnWeapon = "physgun" -- The weapon we spawned with
        self:SetNW2String( "lambda_spawnweapon", self.l_SpawnWeapon )

        self:InitializeMiniHooks()
        self:SwitchWeapon( "physgun", true )
        
        self:HandleAllValidNPCRelations()


        if LambdaPersonalProfiles and random( 0, 100 ) < profilechance:GetInt() then
            for k, v in RandomPairs( LambdaPersonalProfiles ) do
                if self:IsNameOpen( k ) then
                    self:SetLambdaName( k )
                end
            end
        end

        self:ProfileCheck()

    elseif CLIENT then

        self.l_lastdraw = 0 -- The time since we were "last" drawn. Used with ENT:IsBeingDrawn() to test if we are in a client's PVS
        self.l_lightupdate = 0 -- The next time to check if we need to turn on our flashlight or off
        self.l_ismuted = false -- If we are muted by the Local Player

        self:InitializeMiniHooks()

        -- For some reason having this properly makes the weapon go invisible when the Lambda dies in multiplayer
        timer.Simple( 0, function()
            if !IsValid( self ) then return end

            local wep = self:GetWeaponENT()
            if !IsValid( wep ) then return end

            wep.Draw = function( entity )
                if self:GetIsDead() then return end
                entity:DrawModel()
            end
        end )

        self.GetPlayerColor = function() return self:GetPlyColor() end

    end


    -- For some reason for the voice chat flexes we have to do this in order to get it to work
    local sidewayFlex = self:GetFlexIDByName( "mouth_sideways" )
    if sidewayFlex and self:GetFlexBounds( sidewayFlex ) == -1 and self:GetFlexWeight( sidewayFlex ) == 0.0 then
        self:SetFlexWeight(sidewayFlex, 0.5)
    end
    sidewayFlex = self:GetFlexIDByName( "jaw_sideways" )
    if sidewayFlex and self:GetFlexBounds( sidewayFlex ) == -1 and self:GetFlexWeight( sidewayFlex ) == 0.0 then
        self:SetFlexWeight( sidewayFlex, 0.5 )
    end

    self:LambdaMoveMouth( 0 )

    LambdaRunHook( "LambdaOnInitialize", self, self:GetWeaponENT() )
end


-- This will be the new way of having networked variables
function ENT:SetupDataTables()

    self:NetworkVar( "String", 0, "LambdaName" ) -- Player name
    self:NetworkVar( "String", 1, "WeaponName" )
    self:NetworkVar( "String", 2, "ProfilePicture" )
 
    self:NetworkVar( "Bool", 0, "Crouch" )
    self:NetworkVar( "Bool", 1, "IsDead" )
    self:NetworkVar( "Bool", 2, "Respawn" )
    self:NetworkVar( "Bool", 3, "HasCustomDrawFunction" )
    self:NetworkVar( "Bool", 4, "IsReloading" )
    self:NetworkVar( "Bool", 5, "Run" )
    self:NetworkVar( "Bool", 6, "NoClip" )
    self:NetworkVar( "Bool", 7, "FlashlightOn" )
    self:NetworkVar( "Bool", 8, "IsFiring" )
    self:NetworkVar( "Bool", 9, "IsTyping" )
    self:NetworkVar( "Bool", 10, "SlowWalk" )

    self:NetworkVar( "Entity", 0, "WeaponENT" )
    self:NetworkVar( "Entity", 1, "Enemy" )

    self:NetworkVar( "Vector", 0, "PlyColor" )
    self:NetworkVar( "Vector", 1, "PhysColor" )

    self:NetworkVar( "Int", 0, "VoicePitch" )
    self:NetworkVar( "Int", 1, "NWMaxHealth" )
    self:NetworkVar( "Int", 2, "VoiceChance" )
    self:NetworkVar( "Int", 3, "Frags" )
    self:NetworkVar( "Int", 4, "Deaths" )
    self:NetworkVar( "Int", 5, "Ping" )
    self:NetworkVar( "Int", 6, "AbsPing" )
    self:NetworkVar( "Int", 7, "Armor" )
    self:NetworkVar( "Int", 8, "MaxArmor" )
    self:NetworkVar( "Int", 9, "SteamID64" )
    self:NetworkVar( "Int", 10, "WalkSpeed" )
    self:NetworkVar( "Int", 11, "RunSpeed" )
    self:NetworkVar( "Int", 12, "CrouchSpeed" )
    self:NetworkVar( "Int", 13, "Team" )
    self:NetworkVar( "Int", 14, "TextPerMinute" )
    self:NetworkVar( "Int", 15, "TextChance" )
    self:NetworkVar( "Int", 16, "SlowWalkSpeed" )

    self:NetworkVar( "Float", 0, "LastSpeakingTime" )
    self:NetworkVar( "Float", 1, "VoiceLevel" )

end

function ENT:Draw()
    if self:GetIsDead() then return end
    self.l_lastdraw = RealTime() + 0.1
    self:DrawModel()
end


function ENT:Think()

    local curTime = CurTime()

    -- Text Chat --
    -- Pretty simple stuff actually
    local queuedText = self.l_queuedtext
    self:SetIsTyping( queuedText != nil )
    
    if queuedText and curTime > self.l_nexttext then
        local typedText = self.l_typedtext
        local typedLen = #typedText

        if typedLen == #queuedText or self:GetState() != self.l_starttypestate then 
            self.l_queuedtext = nil
            self:Say( typedText )
            self:OnEndMessage( typedText )
        else
            self.l_typedtext = typedText .. sub( queuedText, typedLen + 1, typedLen + 1 )
            self.l_nexttext = ( curTime + 1 / ( self:GetTextPerMinute() / 60 ) )
        end
    end
    -- -- -- -- --

    local isDead = self:GetIsDead()
    local wepent = self:GetWeaponENT()

    -- Run our weapon's think callback if possible
    if SERVER and curTime > self.l_NextWeaponThink then
        local wepThinkFunc = self.l_WeaponThinkFunction
        if wepThinkFunc then
            local thinkTime = wepThinkFunc( self, wepent, isDead )
            if isnumber( thinkTime ) and thinkTime > 0 then self.l_NextWeaponThink = curTime + thinkTime end 
        end
    end

    -- Allow addons to add stuff to Lambda's Think
    LambdaRunHook( "LambdaOnThink", self, wepent, isDead )

    if isDead then return end
    
    if ( SERVER ) then

        local loco = self.loco
        local selfPos = self:GetPos()
        local selfAngles = self:GetAngles()
        local locoVel = loco:GetVelocity()
        local onGround = self:IsOnGround()
        local waterLvl = self:GetWaterLevel()
        local frameTime = FrameTime()
        local isDisabled = self:IsDisabled()
        local isCrouched = self:GetCrouch()

        if curTime > self.l_debugupdate then 
            local thread = self.BehaveThread
            if thread and debugmode:GetBool() then 
                self:SetNW2String( "lambda_threadstatus", coroutine_status( thread ) )
                self:SetNW2String( "lambda_threadtrace", GetTraceback( thread ) )
                self:SetNW2Bool( "lambda_isdisabled", isDisabled )
            end
            
            self.l_debugupdate = curTime + 0.1
        end

        if self.l_ispickedupbyphysgun then 
            locoVel = vector_origin
            loco:SetVelocity( locoVel ) 
        end

        -- Footstep sounds
        if curTime > self.l_nextfootsteptime and onGround and !locoVel:IsZero() then
            self:PlayStepSound()
            self.l_nextfootsteptime = curTime + self:GetStepSoundTime()
        end

        -- Play random Idle lines depending on current state
        if curTime > self.l_nextidlesound then
            if !isDisabled and !self:GetIsTyping() and !self:IsSpeaking() and !self.l_preventdefaultspeak then
                if random( 1, 100 ) <= self:GetVoiceChance() then
                    local idleLine = ( self:IsPanicking() and "panic" or ( self:InCombat() and "taunt" or "idle" ) )
                    self:PlaySoundFile( self:GetVoiceLine( idleLine ) )
                elseif random( 1, 100 ) <= self:GetTextChance() and self:CanType() and !self:InCombat() and !self:IsPanicking() then
                    local line = self:GetTextLine( "idle" )
                    line = LambdaRunHook( "LambdaOnStartTyping", self, line, "idle" ) or line
                    self:TypeMessage( line )
                end
            end

            self.l_nextidlesound = curTime + 5
        end

        -- Update our speed after some time
        if curTime > self.l_nextspeedupdate then
            loco:SetDesiredSpeed( ( isCrouched and self:GetCrouchSpeed() or ( self:GetSlowWalk() and self:GetSlowWalkSpeed() or ( self:GetRun() and self:GetRunSpeed() or self:GetWalkSpeed() ) ) ) * self.l_WeaponSpeedMultiplier )
            self.l_nextspeedupdate = curTime + 0.5
        end

        -- Attack nearby NPCs
        if curTime > self.l_nextnpccheck then 
            if !self:InCombat() then
                local npcs = self:FindInSphere( nil, 2000, function( ent ) return LambdaIsValid( ent ) and ( ent:IsNPC() or ent:IsNextBot() and !self:ShouldTreatAsLPlayer( ent ) ) and ent:Health() > 0 and self:ShouldAttackNPC( ent ) and self:CanSee( ent ) end )
                if #npcs > 0 then self:AttackTarget( npcs[ random( #npcs ) ] ) end
            end
            
            self.l_nextnpccheck = curTime + 1
        end

        -- Ladder Physics Failure (LPF to sound cool) fallback
        if !loco:IsUsingLadder() then
            self.l_ladderfailtimer = curTime + 15
        elseif curTime > self.l_ladderfailtimer then
            self:Recreate( true, selfPos, selfAngles )
            self.l_ladderfailtimer = curTime + 1
        end
        --

        -- Update our physics object
        if curTime > self.l_nextphysicsupdate then
            local phys = self:GetPhysicsObject()
            if waterLvl == 0 then
                phys:SetPos( selfPos )
                phys:SetAngles( selfAngles )
            else
                phys:UpdateShadow( selfPos, selfAngles, 0 )
            end

            -- Change collision bounds based on if we are crouching or not.
            self:SetCollisionBounds( collisionmins, ( isCrouched and crouchingcollisionmaxs or standingcollisionmaxs ) )

            self.l_nextphysicsupdate = ( curTime + physUpdateTime:GetFloat() )
        end

        -- Handle picking up entities
        if curTime > self.l_NextPickupCheck then
            for _, v in ipairs( self:FindInSphere( selfPos, 58 ) ) do
                local pickFunc = _LAMBDAPLAYERSItemPickupFunctions[ v:GetClass() ]
                if isfunction( pickFunc ) and v:Visible( self ) then 
                    LambdaRunHook( "LambdaOnPickupEnt", self, v ) 
                    pickFunc( self, v ) 
                end
            end

            self.l_NextPickupCheck = curTime + 0.1
        end

        -- Handle our ping rising or dropping
        if random( 125 ) == 1 then
            local ping, absPing = self:GetPing(), self:GetAbsPing()
            self:SetPing( Clamp( ping + random( -20, ( 24 - ( ping / absPing ) ) ), absPing, 999 ) )
        end

        -- Reload randomly when we aren't shooting
        if self.l_Clip < self.l_MaxClip and random( 100 ) == 1 and curTime > self.l_WeaponUseCooldown + 1 then
            self:ReloadWeapon()
        end

        -- Out of Bounds Fail Safe --
        if self:IsInWorld() then
            self.l_outboundsreset = curTime + 5
        elseif curTime > self.l_outboundsreset then
            self:Kill()
        end

        -- UA, Universal Actions
        -- See sv_x_universalactions.lua
        if curTime > self.l_nextUA and !isDisabled then
            local UAfunc = LambdaUniversalActions[ random( #LambdaUniversalActions ) ]
            UAfunc( self )
            self.l_nextUA = curTime + rand( 1, 15 )
        end

        local eyeAttach = self:GetAttachmentPoint( "eyes" )

        -- Eye tracing
        if eyetracing:GetBool() then
            debugoverlay.Line( eyeAttach.Pos, self:GetEyeTrace().HitPos, 0.1, color_white, false )
        end

        -- How fast we are falling
        if !onGround then
            local fallSpeed = -locoVel.z
            if ( fallSpeed - self.l_FallVelocity ) <= 1000 then
                self.l_FallVelocity = fallSpeed
            end
        end

        -- Handle noclip
        if self:IsInNoClip() then
            if !self.l_ispickedupbyphysgun then
                self:SetCrouch( false )
                
                locoVel = vector_origin
                loco:SetVelocity( locoVel )

                -- Play the "floating" gesture
                if !self:IsPlayingGesture( ACT_GMOD_NOCLIP_LAYER ) then
                    self:AddGesture( ACT_GMOD_NOCLIP_LAYER, false )
                end

                -- Randomly change height
                if curTime > self.l_nextnoclipheightchange then
                    self.l_noclipheight = random( 0, 500 )
                    self.l_nextnoclipheightchange = curTime + random( 1, 20 )
                end

                local pathPos = ( isvector( self.l_CurrentPath ) and self.l_CurrentPath or ( IsValid( self.l_CurrentPath ) and self.l_CurrentPath:GetEnd() or nil ) )
                if pathPos then
                    local trace = self:Trace( pathPos + Vector( 0, 0, self.l_noclipheight ), pathPos + Vector( 0, 0, 3 ) ) -- Trace the height
                    local endPos = ( trace.HitPos + trace.HitNormal * 70 ) -- Subtract the normal so we are hovering below a ceiling by 70 Source Units
                    local copy = Vector( endPos[ 1 ], endPos[ 2 ], selfPos[ 3 ] ) -- Vector used if we are close to our goal

                    local ene = self:GetEnemy()
                    if self:GetState() == "Combat" and LambdaIsValid( ene ) then endPos[ 3 ] = ( ene:GetPos()[ 3 ] + ( self.l_HasMelee and 0 or 50 ) ) end

                    if self:IsInRange( copy, 20 ) then 
                        self:CancelMovement() 
                    else 
                        loco:FaceTowards( endPos )
                        local noclipSpeed = ( ( self:GetRun() and 1500 or 500 ) * frameTime )
                        self.l_noclippos = ( self.l_noclippos + ( endPos - self.l_noclippos ):GetNormalized() * noclipSpeed ) 
                    end
                end

                selfPos = self.l_noclippos
                self:SetPos( selfPos )
            else -- If we are in noclip but are being physgunned then do this
                self.l_noclipheight = 0
                self.l_noclippos = selfPos
            end
        else -- If we aren't in no clip then do this stuff
            self.l_noclipheight = 0
            self:RemoveGesture( ACT_GMOD_NOCLIP_LAYER )
            self.l_noclippos = selfPos
        end

        -- Handle swimming
        if waterLvl >= 2 and !self:IsInNoClip() then -- Don't swim if we are noclipping
            if curTime > self.l_nextswimposupdate then -- Update our swimming position over time
                self.l_nextswimposupdate = curTime + 0.1

                local ene = self:GetEnemy()
                local movePos = self.l_movepos
                local newSwimPos = self.l_CurrentPath
                if movePos and self:GetState() == "Combat" and LambdaIsValid( ene ) and ene:WaterLevel() != 0 and self:CanSee( ene ) then -- Move to enemy's position if valid
                    newSwimPos = ( !isvector( movePos ) and movePos:GetPos() or movePos )
                    if self.l_HasMelee then newSwimPos = newSwimPos + VectorRand( -50, 50 ) end -- Prevents not moving when enclose with enemy
                    self.l_nextswimposupdate = self.l_nextswimposupdate + rand( 0.1, 0.2 ) -- Give me more time to update my swim position
                elseif newSwimPos and !isvector( newSwimPos ) then 
                    if IsValid( newSwimPos ) and newSwimPos:IsValid() then -- Use PathFollower if valid
                        local curGoal = newSwimPos:GetCurrentGoal()
                        if curGoal and istable( curGoal ) and curGoal.pos then 
                            newSwimPos = curGoal.pos 
                        else
                            newSwimPos = newSwimPos:GetEnd()
                        end
                    else
                        newSwimPos = nil
                    end
                end
                
                self.l_swimpos = newSwimPos
            end

            local swimPos = self.l_swimpos
            if !onGround then
                self.l_isswimming = true

                local swimVel = vector_origin
                if swimPos and self.l_issmoving then
                    local swimSpeed = ( ( ( self:GetRun() and !isCrouched ) and 320 or 160 ) * self.l_WeaponSpeedMultiplier )
                    
                    local path = self.l_CurrentPath
                    if !isvector( path ) and IsValid( path ) and path:GetCurrentGoal().type == 1 then
                        swimVel = ( vector_up * -swimSpeed )
                    else
                        local swimTrace = self:Trace( swimPos + vector_up * loco:GetJumpHeight(), swimPos ).HitPos
                        if swimPos.z > selfPos.z - 32 and swimTrace:IsUnderwater() then swimPos = swimTrace end -- Try swimming a little higher if possible
                        local swimDir = ( swimPos - selfPos ):GetNormalized()
                        swimVel = ( swimDir * swimSpeed )

                        if swimPos.z > selfPos.z then
                            swimtable.start = selfPos
                            swimtable.endpos = ( selfPos + swimDir * ( swimSpeed * FrameTime() * 10 ) )
                            swimtable.filter = self
                            
                            local mins, maxs = self:GetCollisionBounds()
                            swimtable.mins = mins
                            swimtable.maxs = maxs

                            if TraceHull( swimtable ).HitWorld then
                                if !swimTrace:IsUnderwater() then
                                    swimSpeed = swimSpeed + ( loco:GetJumpHeight() + loco:GetStepHeight() )
                                end
                                swimVel = ( vector_up * swimSpeed )
                            end
                        end
                    end

                    loco:FaceTowards( swimPos )
                end

                locoVel = LerpVector( 20 * frameTime, locoVel, swimVel )
                loco:SetVelocity( locoVel )
            elseif LambdaIsValid( self:GetEnemy() ) or swimPos and ( swimPos.z - selfPos.z ) > loco:GetJumpHeight() then
                loco:Jump() -- Jump and start swimming if there's a enemy or our move position height is higher than our jump height
            end
        elseif self.l_isswimming then -- If just exited the swimming state
            self:RecomputePath() -- Recompute our current path after exitting water if possible
            self.l_isswimming = false
        end

        -- Animations --
        if self.l_UpdateAnimations then
            local anims = self:GetWeaponHoldType()

            if anims then
                local anim = anims.idle
                
                if !self:IsInNoClip() then
                    if onGround then
                        local locoVel = locoVel
                        if !locoVel:IsZero() then
                            anim = ( isCrouched and anims.crouchWalk or ( ( !self:GetSlowWalk() and locoVel:LengthSqr() > ( 150 ^ 2 ) ) and anims.run or anims.walk ) )
                        elseif isCrouched then
                            anim = anims.crouchIdle
                        end
                    elseif self.l_isswimming then
                        local moveVel = locoVel; moveVel.z = 0
                        anim = ( !moveVel:IsZero() and anims.swimMove or anims.swimIdle )
                    else
                        anim = anims.jump
                    end
                end

                if self:GetActivity() != anim then
                    self:StartActivity( anim )
                end
            end
        end
        --

        -- Handles facing positions or entities --
        local lookAng = Angle( 0, 0, 0 )
        local faceTarg = self.Face

        if faceTarg then
            if self.l_Faceend and curTime > self.l_Faceend or isentity( faceTarg ) and !IsValid( faceTarg ) then 
                self.Face = nil 
                self.l_Faceend = nil 
                self.l_PoseOnly = nil 
            else
                local pos = ( isentity( faceTarg ) and ( isfunction( faceTarg.EyePos ) and faceTarg:EyePos() or faceTarg:WorldSpaceCenter() ) or faceTarg )
                if !self.l_PoseOnly then loco:FaceTowards( pos ); loco:FaceTowards( pos ) end
                lookAng = self:WorldToLocalAngles( ( pos - eyeAttach.Pos ):Angle() )
            end
        end

        local poseP = ( ( self:GetPoseParameter( "head_pitch" ) + self:GetPoseParameter( "aim_pitch" ) ) / 2 )
        local poseY = ( ( self:GetPoseParameter( "head_yaw" ) + self:GetPoseParameter( "aim_yaw" ) ) / 2 )

        local approachP = Lerp( 4 * frameTime, poseP, lookAng.p )
        local approachY = Lerp( 4 * frameTime, poseY, lookAng.y )

        self:SetPoseParameter( "head_pitch", approachP )
        self:SetPoseParameter( "aim_pitch", approachP )
        self:SetPoseParameter( "head_yaw", approachY )
        self:SetPoseParameter( "aim_yaw", approachY )
        --

        -- UNSTUCK --
        if self.l_stucktimes > 0 and curTime > self.l_stucktimereset then
            self.l_stucktimes = 0
        end

        if self.l_unstuck then
            local unstuckbounds = self.l_UnstuckBounds
            local testpoint = selfPos + VectorRand( -unstuckbounds, unstuckbounds )
            local navareas = navmesh_Find( selfPos, unstuckbounds, loco:GetDeathDropHeight(), loco:GetJumpHeight() )

            local randompoint
            for _, v in RandomPairs( navareas ) do 
                if IsValid( v ) then 
                    randompoint = v:GetClosestPointOnArea( testpoint ) 
                    break 
                end 
            end

            if randompoint then
                local mins, maxs = self:GetCollisionBounds()
                unstucktable.start = randompoint
                unstucktable.endpos = randompoint
                unstucktable.mins = mins
                unstucktable.maxs = maxs

                if TraceHull( unstucktable ).Hit then
                    self.l_UnstuckBounds = unstuckbounds + 5
                else
                    self.l_unstuck = false
                    self.l_UnstuckBounds = 50
                    self:SetPos( randompoint )
                    loco:ClearStuck()
                end
            else
                self.l_UnstuckBounds = unstuckbounds + 5
            end
        end
        -- -- -- -- --

    end
    
    if ( CLIENT ) then
        
        local selfCenter = self:WorldSpaceCenter()
        local selfAngles = self:GetAngles()

        -- Update our flashlight
        if curTime > self.l_lightupdate then
            local lightvec = render.GetLightColor( selfCenter )

            if lightvec:LengthSqr() < ( 0.02 ^ 2 ) and !self:GetIsDead() and drawflashlight:GetBool() and self:IsBeingDrawn() then
                if !IsValid( self.l_flashlight ) then
                    self:SetFlashlightOn( true )
                    self.l_flashlighton = true
                    self.l_flashlight = ProjectedTexture() 
                    self.l_flashlight:SetTexture( "effects/flashlight001" ) 
                    self.l_flashlight:SetFarZ( 600 ) 
                    self.l_flashlight:SetEnableShadows( false )
                    self.l_flashlight:SetPos( selfCenter )
                    self.l_flashlight:SetAngles( selfAngles )
                    self.l_flashlight:Update()
    
                    self:EmitSound( "items/flashlight1.wav", 60 )
                end
            elseif IsValid( self.l_flashlight ) then
                self:SetFlashlightOn( false )
                self.l_flashlighton = false
                self.l_flashlight:Remove()
                self:EmitSound( "items/flashlight1.wav", 60 )
            end

            self.l_lightupdate = curTime + 1
        end

        if IsValid( self.l_flashlight ) then
            self.l_flashlight:SetPos( selfCenter )
            self.l_flashlight:SetAngles( selfAngles )
            self.l_flashlight:Update()
        end

    end

    -- Think Delay
    if InSinglePlayer() then
        self:NextThink( curTime + thinkrate:GetFloat() )
        return true
    end
end

function ENT:BodyUpdate()
    local velocity = self.loco:GetVelocity()
    if !velocity:IsZero() then
        -- Apparently NEXTBOT:BodyMoveXY() really don't likes swimming animations and sets their playback rate to crazy values, causing the game to crash
        -- So instead I tried to recreate what that function does, but with clamped set playback rate
        if self:GetWaterLevel() >= 2 then
            local selfPos = self:GetPos()

            -- Setup pose parameters (model's legs movement)
            local moveDir = ( ( selfPos + velocity ) - selfPos ); moveDir.z = 0
            local moveXY = ( self:GetAngles() - moveDir:Angle() ):Forward()

            local frameTime = FrameTime()
            self:SetPoseParameter( "move_x", Lerp( 15 * frameTime, self:GetPoseParameter( "move_x" ), moveXY.x ) )
            self:SetPoseParameter( "move_y", Lerp( 15 * frameTime, self:GetPoseParameter( "move_y" ), moveXY.y ) )

            -- Setup swimming animation's clamped playback rate
            local length = velocity:Length()
            local groundSpeed = self:GetSequenceGroundSpeed( self:GetSequence() )
            self:SetPlaybackRate( Clamp( ( length > 0.2 and ( length / groundSpeed ) or 1 ), 0.5, 2 ) )
        else
            self:BodyMoveXY()
            return
        end
    end
    
    self:FrameAdvance()
end

function ENT:RunBehaviour()
    if !self.l_initialized then 
        if IsValid( self:GetCreator() ) then
            local undoName = "Lambda Player ( " .. self:GetLambdaName() .. " )"
            undo.Create( undoName )
                undo.SetPlayer( self:GetCreator() )
                undo.SetCustomUndoText( "Undone " .. undoName )
                undo.AddEntity( self )
            undo.Finish( undoName )
        end
            
        self:DebugPrint( "Initialized their AI in ", SysTime() - self.debuginitstart, " seconds" )
        self.l_initialized = true 
        LambdaRunHook( "LambdaAIInitialize", self ) 
    end

    while true do
        if !self:GetIsDead() and !self:IsDisabled() then
            local statefunc = self[ self:GetState() ] -- I forgot this was possible. See sv_states.lua
            if statefunc then statefunc( self ) end
        end

        local time = ( InSinglePlayer() and thinkrate:GetFloat() or 0.2 )
        coroutine_wait( time )
    end
end

list.Set( "NPC", "npc_lambdaplayer", {
	Name = "Lambda Player",
	Class = "npc_lambdaplayer",
	Category = "Lambda Players"
} )