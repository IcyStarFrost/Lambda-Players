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

    local GetLightColor

    local random = math.random
    local rand = math.Rand
    local max = math.max
    local min = math.min
    local abs = math.abs
    local SortTable = table.sort
    local CopyTable = table.Copy
    local table_Random = table.Random
    local eyetracing = GetConVar( "lambdaplayers_debug_eyetracing" )
    local isfunction = isfunction
    local isnumber = isnumber
    local isstring = isstring
    local Lerp = Lerp
    local LerpVector = LerpVector
    local isentity = isentity
    local istable = istable
    local VectorRand = VectorRand
    local Vector = Vector
    local IsValid = IsValid
    local IsValidModel = util.IsValidModel
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
    local IsInWorld = util.IsInWorld
    local FrameTime = FrameTime
    local collisionmins = Vector( -16, -16, 0 )
    local standingcollisionmaxs = Vector( 16, 16, 72 )
    local crouchingcollisionmaxs = Vector( 16, 16, 36 )
    local unstucktable = {}
    local swimtable = { collisiongroup = COLLISION_GROUP_PLAYER }
    local combatjumptbl = {
        filter = NULL,
        collisiongroup = COLLISION_GROUP_PLAYER,
        mins = collisionmins,
        maxs = standingcollisionmaxs
    }
    local sub = string.sub
    local match = string.match
    local string_find = string.find
    local lower = string.lower
    local gmatch = string.gmatch
    local string_Replace = string.Replace
    local RealTime = RealTime
    local rndBodyGroups = GetConVar( "lambdaplayers_lambda_allowrandomskinsandbodygroups" )
    local maxHealth = GetConVar( "lambdaplayers_lambda_maxhealth" )
    local debugmode = GetConVar( "lambdaplayers_debug" )
    local spawnHealth = GetConVar( "lambdaplayers_lambda_spawnhealth" )
    local maxArmor = GetConVar( "lambdaplayers_lambda_maxarmor" )
    local spawnArmor = GetConVar( "lambdaplayers_lambda_spawnarmor" )
    local collisionPly = GetConVar( "lambdaplayers_lambda_noplycollisions" )
    local walkingSpeed = GetConVar( "lambdaplayers_lambda_walkspeed" )
    local runningSpeed = GetConVar( "lambdaplayers_lambda_runspeed" )
    local noclipSpeed = GetConVar( "lambdaplayers_lambda_noclipspeed" )
    local jumpHeight = GetConVar( "lambdaplayers_lambda_jumpheight" )
    local ignorePlys = GetConVar( "ai_ignoreplayers" )
    local sv_gravity = GetConVar( "sv_gravity" )
    local physUpdateTime = GetConVar( "lambdaplayers_lambda_physupdatetime" )
    local lethalWaters = GetConVar( "lambdaplayers_lambda_lethalwaters" )
    local useWeaponPanic = GetConVar( "lambdaplayers_combat_useweapononretreat" )
    local jumpInCombat = GetConVar( "lambdaplayers_combat_usejumpsincombat" )
    local forcePlyMdl = GetConVar( "lambdaplayers_lambda_forceplayermodel" )
    local drownTime = GetConVar( "lambdaplayers_lambda_drowntime" )
    local saveInterrupt = GetConVar( "lambdaplayers_text_saveoninterrupted" )
--

if CLIENT then

    GetLightColor = render.GetLightColor

    language.Add( "npc_lambdaplayer", "Lambda Player" )

end

function ENT:Initialize()
    self.l_Hooks = {} -- The table holding all our created hooks
    self.l_Timers = {} -- The table holding all named timers
    self.l_SimpleTimers = {} -- The table holding all simple timers
    self.debuginitstart = SysTime() -- Debug time from initialize to ENT:RunBehaviour()
    
    -- Has to be here so the client can run this too. Originally was under Personal Stats
    self:BuildPersonalityTable() -- Builds all personality chances from autorun_includes/shared/lambda_personalityfuncs.lua for use in chance testing and creates Get/Set functions for each one

    if SERVER then

        local spawnMdl = "models/player/kleiner.mdl"
        if !self.l_NoRandomModel then
            local forceMdl = forcePlyMdl:GetString()
            if forceMdl != "" and IsValidModel( forceMdl ) then
                spawnMdl = forceMdl
            else
                local mdlTbl = _LAMBDAPLAYERS_DefaultPlayermodels
                if allowaddonmodels:GetBool() then
                    mdlTbl = ( onlyaddonmodels:GetBool() and _LAMBDAPLAYERS_AddonPlayermodels or _LAMBDAPLAYERS_AllPlayermodels )
                    if #mdlTbl == 0 then mdlTbl = _LAMBDAPLAYERS_DefaultPlayermodels end
                end
                spawnMdl = mdlTbl[ random( #mdlTbl ) ]
            end    
        end
        self:SetModel( spawnMdl )

        self.l_SpawnedEntities = {} -- The table holding every entity we have spawned
        self.l_ExternalVars = {} -- The table holding any custom variables external addons want saved onto the Lambda so it can exported along with other Lambda Info

        -- Tables of certain types of entities. Used to limit certain entities
        for k, name in ipairs( LambdaEntityLimits ) do
            self[ "l_Spawned" .. name ] = {}
        end

        self.l_BehaviorState = "Idle" -- The state our behavior thread is currently running
        self.l_Weapon = "" -- The weapon we currently have
        self.l_queuedtext = nil -- The text that we want to send in chat
        self.l_typedtext = nil -- The current text we have typed out so far
        self.l_lasttypedchar = "" -- The last character we used when typing
        self.l_combolastchar = 0 -- How many times we used the same character when typing
        self.l_nexttext = 0 -- The next time we can type the next character
        self.l_starttypestate = "" -- The state we started typing in
        self.l_interruptedtext = nil -- The text that we wanted to send but were suddenly interrupted
        self.l_interruptchecktime = 0 -- The next time we'll check if have an interrupted message stored
        self.l_lastspokenvoicetype = "" -- The last type of voiceline we spoke with

        self.l_issmoving = false -- If we are moving
        self.l_isfrozen = false -- If set true, stop moving as if ai_disable is on
        self.l_unstuck = false -- If true, runs our unstuck process
        self.l_recomputepath = nil -- If set to true, recompute the current path. After that this will reset to nil
        self.l_UpdateAnimations = true -- If we can update our animations. Used for the purpose of playing sequences
        self.VJ_AddEntityToSNPCAttackList = true -- Makes creature-based VJ SNPCs able to damages us with melee and leap attacks
        self.l_isswimming = false -- If we are currenly swimming (only used to recompute paths when exitting swimming)

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
        self.l_ladderfailtimer = CurTime() + 5 -- The time until we are removed and recreated due to Gmod issues with nextbots and ladders. Thanks Facepunch
        self.l_NextWeaponThink = 0 -- The next time we will run the currenly held weapon's think callback
        self.l_CurrentPlayedGesture = -1 -- Gesture ID that is assigned when the ENT:PlayGestureAndWait( id ) function is ran
        self.l_retreatendtime = 0 -- The time until we stop retreating
        self.l_PreDeathDamage = 0 -- The damage we took before running our death function and setting it to zero
        self.l_NextSprayUseTime = 0 -- The next time we can use sprays to spray
        self.l_DStepsWhichFoot = 1 -- The foot that is used in DSteps for stepping. 0 for left, 1 for right
        self.l_DrownStartTime = false -- The time we will start drowning in water
        self.l_DrownLostHealth = 0 -- The amount of health we lost while drowning
        self.l_DrownActionTime = 0 -- The next time we start losing or recovering lost health when drowning
        self.l_CombatPosUpdateTime = 0 -- The next time we'll update the combat position

        self.l_ladderarea = NULL -- The ladder nav area we are currenly using to climb
        self.l_CurrentPath = nil -- The current path (PathFollower) we are on. If off navmesh, this will hold a Vector
        self.l_movepos = nil -- The position or entity we are going to
        self.l_moveoptions = nil -- The move position's options, such as updating, goal tolerance, etc.
        self.l_noclippos = self:GetPos() -- The position we want to noclip to
        self.l_swimpos = self:GetPos() -- The position we are currently swimming to
        self.l_combatpos = self:GetPos() -- The position we are moving to in combat
        self.l_statearg = nil -- Our state's optional arguments we set in
        self.l_precombatmovepos = nil

        self.l_AvoidCheck_IsStuck = false -- If we are currenly stuck due to obstacle avoidance and shouldn't use it
        self.l_AvoidCheck_LastPos = self:GetPos()
        self.l_AvoidCheck_NextStuckCheck = 0 -- The next time we will check if we are stuck in one place due to obstacle avoidance

        local nearArea = navmesh_GetNavArea( self:WorldSpaceCenter(), 400 ) -- The current nav area we are in
        if IsValid( nearArea ) then self.l_currentnavarea = nearArea; self:OnNavAreaChanged( nearArea, nearArea ) end

        -- Used for Respawning
        self.l_SpawnPos = self:GetPos()
        self.l_SpawnAngles = self:GetAngles()

        -- Personal Stats --
        self:SetLambdaName( self:GetOpenName() )
        self:SetProfilePicture( #Lambdaprofilepictures > 0 and Lambdaprofilepictures[ random( #Lambdaprofilepictures ) ] or "spawnicons/".. sub( self:GetModel(), 1, #self:GetModel() - 4 ).. ".png" )

        self:SetMaxHealth( maxHealth:GetInt() )
        self:SetNWMaxHealth( maxHealth:GetInt() )
        self:SetHealth( spawnHealth:GetInt() )
        self:UpdateHealthDisplay()

        self.l_SpawnArmor = spawnArmor:GetInt()
        self:SetArmor( self.l_SpawnArmor ) -- Our current armor
        self:SetMaxArmor( maxArmor:GetInt() ) -- Our maximum armor

        self:SetPlyColor( Vector( random( 255 ) / 225, random( 255 ) / 255, random( 255 ) / 255 ) )
        self:SetPhysColor( Vector( random( 255 ) / 225, random( 255 ) / 255, random( 255 ) / 255 ) )
        self.l_PlyRealColor = self:GetPlyColor():ToColor()
        self.l_PhysRealColor = self:GetPhysColor():ToColor()

        local rndpingrange = random( 150 )
        self:SetAvgPing( rndpingrange )  -- Our average ping we'll use for calculations
        self:SetPing( rndpingrange ) -- Our actual fake ping
        self:SetSteamID64( 90071996842377216 + random( 10000000 ) )
        self:SetTextPerMinute( random( 4, 8 ) * 100 ) -- The amount of characters we can type within a minute
        self:SetTeam( 1001 )
        self:SetNW2String( "lambda_steamid", "STEAM_0:0:" .. random( 200000000 ) )
        self:SetNW2String( "lambda_ip", "192." .. random( 10, 200 ) .. "." .. random( 10 ).. "." .. random( 10, 200 ) .. ":27005" )
        self:SetNW2String( "lambda_state", "Idle" )
        self:SetNW2String( "lambda_laststate", "Idle" )
        
        if rndBodyGroups:GetBool() then
            -- Randomize my model's bodygroups
            for _, v in ipairs( self:GetBodyGroups() ) do
                local subMdls = #v.submodels
                if subMdls == 0 then continue end 
                self:SetBodygroup( v.id, random( 0, subMdls ) )
            end

            -- Randomize my model's skingroup
            local skinCount = self:SkinCount()
            if skinCount > 0 then self:SetSkin( random( 0, skinCount - 1 ) ) end
        end

        -- Personality function was relocated to the start of the code since it needs to be shared so clients can have Get functions
        
        self:SetVoiceChance( random( 100 ) )
        self:SetTextChance( random( 100 ) )
        self:SetVoicePitch( random( voicepitchmin:GetInt(), voicepitchmax:GetInt() ) )

        local modelVP = LambdaModelVoiceProfiles[ lower( self:GetModel() ) ]
        if modelVP then 
            self.l_VoiceProfile = modelVP
        else
            local vpchance = voiceprofilechance:GetInt()
            if vpchance > 0 and random( 100 ) <= vpchance then 
                local vps = table_GetKeys( LambdaVoiceProfiles ) 
                self.l_VoiceProfile = vps[ random( #vps ) ] 
            end
        end
        self:SetNW2String( "lambda_vp", self.l_VoiceProfile )

        local tpchance = textprofilechance:GetInt()
        if tpchance > 0 and random( 100 ) < tpchance then local tps = table_GetKeys( LambdaTextProfiles ) self.l_TextProfile = tps[ random( #tps ) ] end
        self:SetNW2String( "lambda_tp", self.l_TextProfile )

        ----

        SortTable( self.l_Personality, function( a, b ) return a[ 2 ] > b[ 2 ] end )
        self.loco:SetJumpHeight( jumpHeight:GetInt() )
        self.loco:SetAcceleration( 2000 )
        self.loco:SetDeceleration( 1000000 )
        self.loco:SetStepHeight( 18 )
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

        self:SetLagCompensated( true )
        self:AddFlags( FL_OBJECT + FL_NPC + FL_CLIENT )
        self:SetSolidMask( MASK_PLAYERSOLID )
        self:AddCallback( "PhysicsCollide", function( self, data )
            self:HandleCollision( data )
        end )

        local wepent = ents_Create( "base_anim" )
        local attachPoint = self:GetAttachmentPoint( "hand" )
        wepent:SetPos( attachPoint.Pos )
        wepent:SetAngles( attachPoint.Ang )
        
        wepent:SetParent( self, attachPoint.Index )
        if attachPoint.Bone then wepent:FollowBone( self, attachPoint.Bone ) end

        wepent:Spawn()
        wepent:SetNW2Vector( "lambda_weaponcolor", self:GetPhysColor() )
        wepent:SetNoDraw( true )

        wepent.IsLambdaWeapon = true
        wepent.AutomaticFrameAdvance = true

        wepent.Think = function( entity )
            if !IsValid( self ) then return end
            local curTime = CurTime()

            -- Run our weapon's think callback if possible
            if curTime >= self.l_NextWeaponThink then
                local wepThinkFunc = self.l_WeaponThinkFunction
                if wepThinkFunc then
                    local thinkTime = wepThinkFunc( self, entity, self:GetIsDead() )
                    if isnumber( thinkTime ) and thinkTime > 0 then self.l_NextWeaponThink = curTime + thinkTime end 
                end
            end

            entity:NextThink( curTime )
            return true
        end

        self.l_SpawnWeapon = "physgun" -- The weapon we spawned with
        self:SetExternalVar( "l_FavoriteWeapon", false ) -- Our favorite weapon
        self:SetExternalVar( "l_WeaponRestrictions", false ) -- Our weapon restrictions

        self.WeaponEnt = wepent
        self:SetWeaponENT( wepent )
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

        self:SimpleTimer( 0.2, function()
            self:ApplyCombatSpawnBehavior()
        end )

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
                local deadFunc = self.GetIsDead
                if deadFunc and deadFunc( self ) then return end
                entity:DrawModel()
            end

            wep.Think = function( entity )
                entity:NextThink( CurTime() )
                return true
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
    self:NetworkVar( "Int", 6, "AvgPing" )
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
    self:NetworkVar( "Float", 2, "PingUpdateTime" )

end

function ENT:Draw()
    if self:GetIsDead() then return end
    self.l_lastdraw = RealTime() + 0.1
    self:DrawModel()
end


function ENT:Think()

    local curTime = CurTime()
    local isDead = self:GetIsDead()

    -- Text Chat --
    -- Pretty simple stuff actually

    local interruptedText = self.l_interruptedtext
    if interruptedText and curTime >= self.l_interruptchecktime then
        self.l_interruptchecktime = ( curTime + 0.5 )

        if !self:InCombat() and !self:IsPanicking() then
            if !queuedText then
                self:TypeMessage( interruptedText[ 1 ], false )
                self.l_typedtext = interruptedText[ 2 ]
            end

            self.l_interruptedtext = nil
        end
    end

    local queuedText = self.l_queuedtext
    if queuedText and curTime >= self.l_nexttext then
        local typedText = self.l_typedtext
        local typedLen = #typedText

        local doneTyping = ( typedLen >= #queuedText )
        if doneTyping or self:GetState() != self.l_starttypestate then 
            if !doneTyping and saveInterrupt:GetBool() then
                self.l_interruptedtext = {
                    queuedText,
                    typedText
                }
            else
                local sayMsg = ( match( queuedText, "(https?://%S+)" ) != nil and queuedText or typedText )
                self:Say( sayMsg )
            end

            self:OnEndMessage( typedText )
            queuedText = nil
            self.l_queuedtext = queuedText
        else
            local lastWord = ""
            for word in gmatch( typedText, "%S+" ) do 
                lastWord = word 
            end
            
            local nextChar = sub( queuedText, typedLen + 1, typedLen + 1 )
            if nextChar == self.l_lasttypedchar then
                self.l_combolastchar = ( self.l_combolastchar + 2 )
            else
                self.l_combolastchar = 0
            end

            local foundLink = match( lastWord, "(https?://%S+)" )
            local ctrlplused = false
            if foundLink != nil then 
                local linkStart, linkEnd = string_find( queuedText, lastWord .. "(%S+)" )
                if linkStart and linkEnd then
                    ctrlplused = true
                    self.l_typedtext = string_Replace( typedText, foundLink, sub( queuedText, linkStart, linkEnd ) )
                end
            end
            if !ctrlplused then
                self.l_typedtext = typedText .. nextChar
                self.l_lasttypedchar = nextChar
            end

            local typePerMinute = ( 60 - self.l_combolastchar )
            if isDead then
                typePerMinute = ( typePerMinute / 1.33 )
            end
            self.l_nexttext = ( curTime + 1 / ( self:GetTextPerMinute() / max( typePerMinute, 30 ) ) )
        end
    end

    self:SetIsTyping( queuedText != nil )
    -- -- -- -- --

    local wepent = self:GetWeaponENT()

    -- Handle our ping rising or dropping
    if curTime >= self:GetPingUpdateTime() then
        self:SetPingUpdateTime( curTime + 1 )

        if ( SERVER or self:IsDormant() ) and random( 3 ) == 1 then
            local curPing, avgPing = self:GetPing(), self:GetAvgPing()
            local newPing = Clamp( random( avgPing - ( avgPing / 2 ), avgPing + ( avgPing / ( random( 15, 20 ) * 0.1 ) ) ), 0, 999 )            
            self:SetPing( newPing )
        end
    end
    -- -- -- -- --

    -- Allow addons to add stuff to Lambda's Think
    LambdaRunHook( "LambdaOnThink", self, wepent, isDead )
    -- -- -- -- --

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

        if curTime >= self.l_debugupdate then 
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
        if curTime >= self.l_nextfootsteptime and onGround and !locoVel:IsZero() and !self:IsInNoClip() then
            self:PlayStepSound()
            self.l_nextfootsteptime = curTime + self:GetStepSoundTime()
        end

        -- Play random Idle lines depending on current state or speak in text chat
        if curTime >= self.l_nextidlesound then
            if !isDisabled and !self.l_preventdefaultspeak and !self:GetIsTyping() and !self:IsSpeaking() then
                if random( 100 ) <= self:GetVoiceChance() then
                    self:PlaySoundFile( self:IsPanicking() and "panic" or ( self:InCombat() and "taunt" or "idle" ) )
                elseif random( 100 ) <= self:GetTextChance() and self:CanType() and !self:InCombat() and !self:IsPanicking() then
                    self:TypeMessage( self:GetTextLine( "idle" ) )
                end
            end

            self.l_nextidlesound = ( curTime + 5 )
        end

        -- Update our speed after some time
        if curTime >= self.l_nextspeedupdate then
            loco:SetDesiredSpeed( ( isCrouched and self:GetCrouchSpeed() or ( self:GetSlowWalk() and self:GetSlowWalkSpeed() or ( self:GetRun() and self:GetRunSpeed() or self:GetWalkSpeed() ) ) ) * self.l_WeaponSpeedMultiplier )
            self.l_nextspeedupdate = curTime + 0.5
        end

        -- Attack nearby NPCs
        if curTime >= self.l_nextnpccheck then 
            if !self:InCombat() then
                local npcs = self:FindInSphere( nil, 2000, function( ent ) return LambdaIsValid( ent ) and ( ent:IsNPC() or ent:IsNextBot() and !self:ShouldTreatAsLPlayer( ent ) ) and ent:Health() > 0 and self:ShouldAttackNPC( ent ) and self:CanSee( ent ) end )
                if #npcs != 0 then self:AttackTarget( npcs[ random( #npcs ) ] ) end
            else
                local ene = self:GetEnemy()
                if ene.IsDrGNextbot and ene:IsDown() then
                    self:SetEnemy( NULL )
                    self:CancelMovement()
                end
            end

            self.l_nextnpccheck = ( curTime + 1 )
        end

        local isFiring = false
        if !isDisabled then 
            local target = self:GetEnemy()
            local behavState = self:GetBehaviorState()
            local isPanicking = ( behavState == "Retreat" )
            
            if LambdaIsValid( target ) and ( isPanicking or behavState == "Combat" ) then
                local canSee = self:CanSee( target )
                local attackRange = self.l_CombatAttackRange

                if attackRange and ( !isPanicking or useWeaponPanic:GetBool() ) then 
                    if isPanicking then attackRange = ( attackRange * 0.8 ) end

                    if canSee then 
                        if self:IsInRange( target, attackRange * ( self.l_HasMelee and 3 or 1 ) ) then
                            self.Face = target
                            self.l_Faceend = ( CurTime() + rand( 0.5, 2.0 ) )
                        end

                        if self:IsInRange( target, attackRange ) then
                            isFiring = true
                            self:UseWeapon( target )
                        end
                    end
                end

                if !isPanicking then
                    if curTime >= self.l_CombatPosUpdateTime then
                        self.l_CombatPosUpdateTime = ( curTime + 0.2 )
                        local keepDist, myOrigin = self.l_CombatKeepDistance, self:GetPos()
                        local posCopy = target:GetPos(); posCopy.z = myOrigin.z

                        if canSee and keepDist and self:IsInRange( posCopy, keepDist ) then
                            local moveAng = ( myOrigin - posCopy ):Angle()
                            local potentialPos = ( myOrigin + moveAng:Forward() * random( -self:GetRunSpeed(), keepDist ) + moveAng:Right() * random( -keepDist, keepDist ) )
                            self.l_combatpos = ( IsInWorld( potentialPos ) and potentialPos or self:Trace( potentialPos ).HitPos )
                        else
                            self.l_combatpos = target
                        end
                    end

                    local preCombatMovePos = self.l_precombatmovepos
                    if preCombatMovePos and self:GetIsReloading() then
                        self.l_movepos = preCombatMovePos
                    else
                        self.l_precombatmovepos = nil
                        self.l_movepos = self.l_combatpos
                    end
                end

                if jumpInCombat:GetBool() and ( isPanicking or canSee and attackRange and self:IsInRange( target, attackRange * ( self.l_HasMelee and 10 or 2 ) ) ) and onGround and locoVel:Length() >= ( self:GetRunSpeed() * 0.8 ) and random( isPanicking and 30 or 40 ) == 1 then
                    combatjumptbl.start = self:GetPos()
                    combatjumptbl.endpos = ( combatjumptbl.start + locoVel )
                    combatjumptbl.filter = self

                    local jumpTr = TraceHull( combatjumptbl )
                    local hitNorm = jumpTr.HitNormal
                    local invertVel = false
                    local canJump = ( hitNorm.x == 0 and hitNorm.y == 0 and hitNorm.z <= 0 )

                    if !canJump and !isPanicking then 
                        invertVel = Vector( -locoVel.x, -locoVel.y, locoVel.z )
                        combatjumptbl.endpos = ( combatjumptbl.start + invertVel )
                        jumpTr = TraceHull( combatjumptbl )
                        hitNorm = jumpTr.HitNormal

                        canJump = ( hitNorm.z < 0 and hitNorm.x == 0 and hitNorm.y == 0 )
                    end

                    if canJump and self:LambdaJump() and invertVel then
                        locoVel = invertVel
                        self.loco:SetVelocity( locoVel )
                    end
                end
            else
                self.l_precombatmovepos = self.l_movepos
            end
        end
        self:SetIsFiring( isFiring )

        -- Ladder Physics Failure (LPF to sound cool) fallback
        if !loco:IsUsingLadder() then
            self.l_ladderfailtimer = curTime + 5
        elseif curTime >= self.l_ladderfailtimer then
            self:Recreate( true, true )
            self.l_ladderfailtimer = curTime + 1
        end
        --

        -- Update our physics object
        if curTime >= self.l_nextphysicsupdate then
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

        -- Handle entities that are near our pickup range
        if curTime >= self.l_NextPickupCheck then
            for _, ent in ipairs( self:FindInSphere( selfPos, 58 ) ) do
                local pickFunc = _LAMBDAPLAYERSItemPickupFunctions[ ent:GetClass() ]
                if isfunction( pickFunc ) and ent:Visible( self ) then 
                    LambdaRunHook( "LambdaOnPickupEnt", self, ent ) 
                    pickFunc( self, ent )
                end
            end

            self.l_NextPickupCheck = curTime + 0.1
        end

        -- Reload randomly when we aren't shooting
        if !self:GetIsTyping() and self.l_Clip < self.l_MaxClip and random( 100 ) == 1 and curTime >= self.l_WeaponUseCooldown + 1 then
            self:ReloadWeapon()
        end

        -- Out of Bounds Fail Safe --
        if self:IsInWorld() and ( waterLvl == 0 or !lethalWaters:GetBool() ) then
            self.l_outboundsreset = curTime + 5
        elseif curTime >= self.l_outboundsreset then
            self:Kill()
            self.l_outboundsreset = curTime + 5
        end

        -- UA, Universal Actions
        -- See sv_x_universalactions.lua
        if !isDisabled and curTime >= self.l_nextUA then
            local UAfunc = table_Random( LambdaUniversalActions )
            UAfunc( self )
            self.l_nextUA = ( curTime + rand( 1, 15 ) )
        end

        local eyeAttach = self:GetAttachmentPoint( "eyes" )

        -- Eye tracing
        if eyetracing:GetBool() then
            debugoverlay.Line( eyeAttach.Pos, self:GetEyeTrace().HitPos, 0.1, color_white, false )
        end

        -- How fast we are falling
        if !onGround then
            if waterLvl == 3 or self:IsUsingLadder() then
                self.l_FallVelocity = 0
            else
                local fallSpeed = -locoVel.z
                if ( fallSpeed - self.l_FallVelocity ) <= 1000 then
                    self.l_FallVelocity = fallSpeed
                end

                if !self.l_preventdefaultspeak and !self:IsSpeaking( "fall" ) then
                    local fallDmg = self:GetFallDamage( fallSpeed, true )
                    if ( fallDmg > 30 or fallDmg >= self:Health() ) and !self:Trace( ( selfPos + locoVel ), selfPos ).HitPos:IsUnderwater() then
                        self:PlaySoundFile( "fall", false )
                    end
                end
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
                if !self:GetState( "Idle" ) and ( !self:InCombat() or self.l_HasMelee ) then
                    self.l_noclipheight = 0
                elseif curTime >= self.l_nextnoclipheightchange then
                    self.l_noclipheight = random( 0, 400 )
                    self.l_nextnoclipheightchange = curTime + random( 10 )
                end

                local movePos = self:GetDestination()
                local curPath = self.l_CurrentPath
                if !isvector( curPath ) and IsValid( curPath ) then
                    movePos = curPath:GetEnd()
                end
                if movePos then
                    local trace = self:Trace( movePos + vector_up * self.l_noclipheight, movePos + vector_up * 3 ) -- Trace the height
                    local endPos = ( trace.HitPos + trace.HitNormal * 70 ) -- Subtract the normal so we are hovering below a ceiling by 70 Source Units
                    local copy = Vector( endPos[ 1 ], endPos[ 2 ], selfPos[ 3 ] ) -- Vector used if we are close to our goal

                    if self.l_HasMelee then
                        local ene = self:GetEnemy()
                        local attackRange = self.l_CombatAttackRange
                        if attackRange and self:GetState( "Combat" ) and LambdaIsValid( ene ) then
                            endPos = ( endPos + VectorRand( -attackRange, attackRange ) )
                        end
                    end

                    if self:IsInRange( copy, 20 ) then 
                        self:CancelMovement() 
                    else 
                        loco:FaceTowards( endPos )
                        self.l_noclippos = ( self.l_noclippos + ( endPos - self.l_noclippos ):GetNormalized() * ( noclipSpeed:GetFloat() * frameTime ) ) 
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

        -- Drowning Mechanic
        if waterLvl == 3 then
            if !self.l_DrownStartTime then 
                local airTime = drownTime:GetFloat()
                if airTime > 0 then self.l_DrownStartTime = ( curTime + airTime ) end
            elseif curTime >= self.l_DrownStartTime and curTime >= self.l_DrownActionTime then
                local preDmgHp = self:Health()

                local drownDmg = DamageInfo()
                drownDmg:SetDamage( 10 )
                drownDmg:SetAttacker( Entity( 0 ) )
                drownDmg:SetDamageType( DMG_DROWN )
                self:TakeDamageInfo( drownDmg )

                local lostHp = ( preDmgHp - self:Health() )
                if lostHp > 0 then
                    if self:Health() > 0 then
                        self.l_DrownLostHealth = ( self.l_DrownLostHealth + lostHp )
                    end
                    
                    self:EmitSound( "Player.DrownContinue" )
                end
                self.l_DrownActionTime = ( curTime + 1 )
            end
        else
            self.l_DrownStartTime = false

            if self.l_DrownLostHealth > 0 and curTime >= self.l_DrownActionTime then
                local recoverHp = min( self.l_DrownLostHealth, 10 )
                self.l_DrownLostHealth = max( self.l_DrownLostHealth - recoverHp, 0 )
                self:SetHealth( self:Health() + recoverHp )
                self.l_DrownActionTime = ( curTime + 3 )
            end
        end

        -- Handle swimming
        if waterLvl == 3 and !self:IsInNoClip() then -- Don't swim if we are noclipping
            if curTime >= self.l_nextswimposupdate then -- Update our swimming position over time
                self.l_nextswimposupdate = curTime + 0.1

                local ene = self:GetEnemy()
                local movePos = self.l_movepos
                local newSwimPos = self.l_CurrentPath
                if movePos and self:GetState() == "Combat" and LambdaIsValid( ene ) and ene:WaterLevel() != 0 and self:CanSee( ene ) then -- Move to enemy's position if valid
                    newSwimPos = ( ( isentity( movePos ) and IsValid( movePos ) ) and movePos:GetPos() or movePos )
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
                            swimtable.endpos = ( selfPos + swimDir * ( swimSpeed * frameTime * 10 ) )
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
        local lookAng = angle_zero

        if !self:IsPlayingTaunt() then
            local faceTarg = self.Face
            if faceTarg then
                if self.l_Faceend and curTime >= self.l_Faceend or isentity( faceTarg ) and !IsValid( faceTarg ) then 
                    self.Face = nil 
                    self.l_Faceend = nil 
                    self.l_PoseOnly = nil 
                else
                    local pos = ( isentity( faceTarg ) and ( faceTarg.IsLambdaPlayer and faceTarg:EyePos2() or ( isfunction( faceTarg.EyePos ) and faceTarg:EyePos() or faceTarg:WorldSpaceCenter() ) ) or faceTarg )
                    if !self.l_PoseOnly then loco:FaceTowards( pos ); loco:FaceTowards( pos ) end
                    lookAng = self:WorldToLocalAngles( ( pos - eyeAttach.Pos ):Angle() )
                end
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
        if self.l_stucktimes > 0 and curTime >= self.l_stucktimereset then
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
        local flashlight = self.l_flashlight

        -- Update our flashlight
        if curTime >= self.l_lightupdate then
            self.l_lightupdate = ( curTime + 1 )
        
            local isAtLight = ( GetLightColor( selfCenter ):LengthSqr() > 0.0004 )
            local beingDrawn = !self:IsDormant()

            if isDead or !beingDrawn or isAtLight or !drawflashlight:GetBool() then
                self:SetFlashlightOn( false )
                self.l_flashlighton = false

                if IsValid( flashlight ) then
                    flashlight:Remove()
                    if !isDead and beingDrawn then self:EmitSound( "HL2Player.FlashLightOff" ) end
                end
            elseif !isAtLight then
                self:SetFlashlightOn( true )
                self.l_flashlighton = true

                if !IsValid( flashlight ) then
                    flashlight = ProjectedTexture() 
                    flashlight:SetTexture( "effects/flashlight001" ) 
                    flashlight:SetFarZ( 600 ) 
                    flashlight:SetEnableShadows( false )
                    flashlight:SetPos( selfCenter )
                    flashlight:SetAngles( selfAngles )
                    flashlight:Update()
                    
                    self.l_flashlight = flashlight
                    if beingDrawn then self:EmitSound( "HL2Player.FlashLightOn" ) end
                end
            end
        end
        if IsValid( flashlight ) then
            flashlight:SetPos( selfCenter )
            flashlight:SetAngles( selfAngles )
            flashlight:Update()
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
            local curState = self:GetState()
            local statefunc = self[ curState ] -- I forgot this was possible. See sv_states.lua
            if statefunc then
                self.l_BehaviorState = curState

                local stateArg = self.l_statearg
                local returnState = statefunc( self, ( istable( stateArg ) and CopyTable( stateArg ) or stateArg ) )

                if returnState and curState == self:GetState() then 
                    self:SetState( ( isstring( returnState ) and returnState ) ) 
                end
            end
        end

        local time = ( InSinglePlayer() and max( 0.1, thinkrate:GetFloat() ) or 0.2 )
        coroutine_wait( time )
    end
end

list.Set( "NPC", "npc_lambdaplayer", {
    Name = "Lambda Player",
    Class = "npc_lambdaplayer",
    Category = "Lambda Players"
} )