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
    local aidisable = GetConVar( "ai_disabled" )
    local developer = GetConVar( "developer" )
    local isfunction = isfunction
    local Lerp = Lerp
    local isentity = isentity
    local VectorRand = VectorRand
    local Vector = Vector
    local IsValid = IsValid
    local coroutine = coroutine
    local debugoverlay = debugoverlay
    local table_Random = table.Random
    local table_GetKeys = table.GetKeys
    local voicepitchmin = GetConVar( "lambdaplayers_voice_voicepitchmin" )
    local voicepitchmax = GetConVar( "lambdaplayers_voice_voicepitchmax" )
    local idledir = GetConVar( "lambdaplayers_voice_idledir" )
    local drawflashlight = GetConVar( "lambdaplayers_drawflashlights" )
    local profilechance = GetConVar( "lambdaplayers_lambda_profileusechance" )
    local allowaddonmodels = GetConVar( "lambdaplayers_lambda_allowrandomaddonsmodels" ) 
    local ents_Create = ents and ents.Create or nil
    local navmesh_GetNavArea = navmesh and navmesh.GetNavArea or nil
    local navmesh_Find = navmesh and navmesh.Find or nil 
    local voiceprofilechance = GetConVar( "lambdaplayers_lambda_voiceprofileusechance" )
    local textprofilechance = GetConVar( "lambdaplayers_lambda_textprofileusechance" )
    local thinkrate = GetConVar( "lambdaplayers_lambda_singleplayerthinkdelay" )
    local _LAMBDAPLAYERSFootstepMaterials = _LAMBDAPLAYERSFootstepMaterials
    local CurTime = CurTime
    local SysTime = SysTime
    local InSinglePlayer = game.SinglePlayer
    local Clamp = math.Clamp
    local min = math.min
    local LerpVector = LerpVector
    local IsInWorld = util.IsInWorld
    local isvector = isvector
    local color_white = color_white
    local RandomPairs = RandomPairs
    local TraceHull = util.TraceHull
    local QuickTrace = util.QuickTrace
    local FrameTime = FrameTime
    local unstucktable = {}
    local sub = string.sub
    local zerovector = Vector()
    local RealTime = RealTime
    local rndBodyGroups = GetConVar( "lambdaplayers_lambda_allowrandomskinsandbodygroups" )
    local tracetable = {}
    
--

if CLIENT then

    language.Add( "npc_lambdaplayer", "Lambda Player" )

end

function ENT:Initialize()

    self.l_SpawnPos = self:GetPos() -- Used for Respawning
    self.l_SpawnAngles = self:GetAngles()

    -- Has to be here so the client can run this too. Originally was under Personal Stats
    self:BuildPersonalityTable() -- Builds all personality chances from autorun_includes/shared/lambda_personalityfuncs.lua for use in chance testing and creates Get/Set functions for each one

    if SERVER then
    

        self:SetModel( allowaddonmodels:GetBool() and _LAMBDAPLAYERS_Allplayermodels[ random( #_LAMBDAPLAYERS_Allplayermodels ) ] or _LAMBDAPLAYERSDEFAULTMDLS[ random( #_LAMBDAPLAYERSDEFAULTMDLS ) ] )


        self.l_SpawnedEntities = {} -- The table holding every entity we have spawned
        self.l_ExternalVars = {} -- The table holding any custom variables external addons want saved onto the Lambda so it can exported along with other Lambda Info
        self.l_Timers = {} -- The table holding all named timers
        self.l_SimpleTimers = {} -- The table holding all simple timers

        self.l_State = "Idle" -- The state we are in. See sv_states.lua
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
        self.l_ClimbingLadder = false -- If we are currenly climbing a ladder
        self.VJ_AddEntityToSNPCAttackList = true -- Makes creature-based VJ SNPCs able to damages us with melee and leap attacks

        self.l_UnstuckBounds = 50 -- The distance the unstuck process will use to check. This value increments during the process and set back to 50 when done
        self.l_nextspeedupdate = 0 -- The next time we update our speed
        self.l_NexthealthUpdate = 0 -- The next time we update our networked health
        self.l_stucktimes = 0 -- How many times did we get stuck in the past 10 seconds
        self.l_stucktimereset = 0 -- The time until l_stucktimes gets reset to 0
        self.NextFootstepTime = 0 -- The next time we play a footstep sound
        self.l_nextdoorcheck = 0 -- The next time we will check for doors to open
        self.l_nextphysicsupdate = 0 -- The next time we will update our Physics Shadow
        self.l_WeaponUseCooldown = 0 -- The time before we can use our weapon again
        self.l_noclipheight = 0 -- The height we will float off the ground from
        self.l_FallVelocity = 0 -- How fast we are falling
        self.debuginitstart = SysTime() -- Debug time from initialize to ENT:RunBehaviour()
        self.l_nextidlesound = CurTime() + 5 -- The next time we will play a idle sound
        self.l_nextnpccheck = CurTime() + 1 -- The next time we will check for surrounding NPCs
        self.l_nextnoclipheightchange = 0 -- The next time we will change our height while in noclip
        self.l_nextUA = CurTime() + rand( 1, 15 ) -- The next time we will run a UAction. See lambda/sv_x_universalactions.lua
        self.l_NextPickupCheck = 0 -- The next time we will check for nearby items to pickup
        self.l_moveWaitTime = 0 -- The time we will wait until continuing moving through our path


        self.l_CurrentPath = nil -- The current path (PathFollower) we are on. If off navmesh, this will hold a Vector
        self.l_movepos = nil -- The position or entity we are going to
        self.l_noclippos = self:GetPos() -- The position we want to noclip to
        self.l_currentnavarea = navmesh_GetNavArea( self:WorldSpaceCenter(), 400 ) -- The current nav area we are in


        -- Personal Stats --
        self:SetLambdaName( self:GetOpenName() )
        self:SetProfilePicture( #Lambdaprofilepictures > 0 and Lambdaprofilepictures[ random( #Lambdaprofilepictures ) ] or "spawnicons/".. sub( self:GetModel(), 1, #self:GetModel() - 4 ).. ".png" )

        self:SetMaxHealth( 100 )
        self:SetNWMaxHealth( 100 )
        self:SetHealth( 100 )

        self:SetArmor( 0 ) -- Our current armor
        self:SetMaxArmor( 100 ) -- Our maximum armor

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
        self:SetVoicePitch( random( voicepitchmin:GetInt(), voicepitchmax:GetInt() ) )

        local vpchance = voiceprofilechance:GetInt()
        if vpchance > 0 and random( 1, 100 ) < vpchance then local vps = table_GetKeys( LambdaVoiceProfiles ) self.l_VoiceProfile = vps[ random( #vps ) ] end
        self:SetNW2String( "lambda_vp", self.l_VoiceProfile )

        local tpchance = textprofilechance:GetInt()
        if tpchance > 0 and random( 1, 100 ) < tpchance then local tps = table_GetKeys( LambdaTextProfiles ) self.l_TextProfile = tps[ random( #tps ) ] end
        self:SetNW2String( "lambda_tp", self.l_TextProfile )

        ----

        SortTable( self.l_Personality, function( a, b ) return a[ 2 ] > b[ 2 ] end )

        self.loco:SetJumpHeight( 50 )
        self.loco:SetAcceleration( 1000 )
        self.loco:SetDeceleration( 1000 )
        self.loco:SetStepHeight( 30 )
        self.loco:SetGravity( -physenv.GetGravity().z ) -- Makes us fall at the same speed as the real players do

        self:SetRunSpeed( 400 )
        self:SetCrouchSpeed( 60 )
        self:SetWalkSpeed( 200 )

        self:SetCollisionBounds( Vector( -10, -10, 0 ), Vector( 10, 10, 72 ) )
        self:PhysicsInitShadow()
        self:SetCollisionGroup( COLLISION_GROUP_NPC )
        self:AddCallback( "PhysicsCollide", function( self, data )
            self:HandleCollision( data )
        end)

        

        self:SetLagCompensated( true )
        self:AddFlags( FL_OBJECT + FL_NPC + FL_CLIENT )

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
            local wep = self:GetWeaponENT()
            wep.Draw = function( entity )
                if self:GetIsDead() then return end
                entity:DrawModel()
            end
        end )

        self.GetPlayerColor = function() return self:GetPlyColor() end

    end


    -- For some reason for the voice chat flexes we have to do this in order to get it to work
    local sidewayFlex = self:GetFlexIDByName("mouth_sideways")
    if sidewayFlex and self:GetFlexBounds(sidewayFlex) == -1 and self:GetFlexWeight(sidewayFlex) == 0.0 then
        self:SetFlexWeight(sidewayFlex, 0.5)
    end
    sidewayFlex = self:GetFlexIDByName("jaw_sideways")
    if sidewayFlex and self:GetFlexBounds(sidewayFlex) == -1 and self:GetFlexWeight(sidewayFlex) == 0.0 then
        self:SetFlexWeight(sidewayFlex, 0.5)
    end

    self:LambdaMoveMouth( 0 )

    hook.Run( "LambdaOnInitialize", self, self:GetWeaponENT() )
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
    self:NetworkVar( "Bool", 8, "UsingSWEP" )
    self:NetworkVar( "Bool", 9, "IsFiring" )
    self:NetworkVar( "Bool", 10, "IsTyping" )

    self:NetworkVar( "Entity", 0, "WeaponENT" )
    self:NetworkVar( "Entity", 1, "Enemy" )
    self:NetworkVar( "Entity", 2, "SWEPWeaponEnt" )

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

    self:NetworkVar( "Float", 0, "LastSpeakingTime" )
    self:NetworkVar( "Float", 1, "VoiceLevel" )
end

function ENT:Draw()
    if self:GetIsDead() then return end
    self.l_lastdraw = RealTime() + 0.1
    self:DrawModel()
end


function ENT:Think()
    if self:GetIsDead() then return end

    -- Allow addons to add stuff to Lambda's Think
    hook.Run( "LambdaOnThink", self, self:GetWeaponENT() )
    
    if SERVER then
        if self.l_ispickedupbyphysgun then self.loco:SetVelocity( Vector() ) end

        -- Footstep sounds
        if CurTime() > self.NextFootstepTime and self:IsOnGround() and !self.loco:GetVelocity():IsZero() then
            local desSpeed = self.loco:GetDesiredSpeed()
            local result = QuickTrace( self:WorldSpaceCenter(), self:GetUp() * -32600, self )
            local stepsounds = _LAMBDAPLAYERSFootstepMaterials[ result.MatType ] or _LAMBDAPLAYERSFootstepMaterials[ MAT_DEFAULT ]
            local snd = stepsounds[ random( #stepsounds ) ]
            --hook.Run( "PlayerFootstep", self, self:GetPos(), random( 0, 1 ), snd, 0.5, RecipientFilter() )
            self:EmitSound( snd, 75, 100, 0.5 )
            self.NextFootstepTime = CurTime() + min(0.25 * (self:GetRunSpeed() / desSpeed), 0.35)
        end
        
        -- Play random Idle Voice lines
        if !self:GetIsTyping() and CurTime() > self.l_nextidlesound and !self:IsSpeaking() and random( 1, 100 ) <= self:GetVoiceChance() then
            
            self:PlaySoundFile( idledir:GetString() == "randomengine" and self:GetRandomSound() or self:GetVoiceLine( "idle" ), true )
            self.l_nextidlesound = CurTime() + 5
        end

        -- Update our speed after some time
        if CurTime() > self.l_nextspeedupdate then
            local speed = ( self:GetCrouch() and self:GetCrouchSpeed() or self:GetRun() and self:GetRunSpeed() or self:GetWalkSpeed() ) +  self.l_CombatSpeedAdd
            self.loco:SetDesiredSpeed( speed )
            self.l_nextspeedupdate = CurTime() + 0.5
        end
        
        -- Update our networked health
        if CurTime() > self.l_NexthealthUpdate then
            self:UpdateHealthDisplay()
            self.l_NexthealthUpdate = CurTime() + 0.1
        end

        if CurTime() > self.l_nextnpccheck and self:GetState() != "Combat" then
            local npcs = self:FindInSphere( nil, 2000, function( ent ) return ( ent:IsNPC() or ent:IsNextBot() and !self:ShouldTreatAsLPlayer( ent ) ) and self:ShouldAttackNPC( ent ) and self:CanSee( ent ) end )
            self:AttackTarget( npcs[ random( #npcs ) ] )
            self.l_nextnpccheck = CurTime() + 1
        end

        -- Update our physics object
        if CurTime() > self.l_nextphysicsupdate then
            local phys = self:GetPhysicsObject()
            if self:WaterLevel() == 0 then
                phys:SetPos( self:GetPos() )
                phys:SetAngles( self:GetAngles() )
            else
                phys:UpdateShadow( self:GetPos(), self:GetAngles(), 0 )
            end
            self.l_nextphysicsupdate = CurTime() + 0.5
        end

        -- Handle picking up entities
        if CurTime() > self.l_NextPickupCheck then
            for _, v in ipairs( self:FindInSphere( self:WorldSpaceCenter(), 48 ) ) do
                local pickFunc = _LAMBDAPLAYERSItemPickupFunctions[ v:GetClass() ]
                if isfunction( pickFunc ) and self:Visible( v ) then pickFunc( self, v ) end
            end
            self.l_NextPickupCheck = CurTime() + 0.1
        end

        -- Handle our ping rising or dropping
        if random( 125 ) == 1 then
            self:SetPing( Clamp( self:GetPing() + random( -20, ( 24 - ( self:GetPing() / self:GetAbsPing() ) ) ), self:GetAbsPing(), 999 ) )
        end

        -- Reload randomly when we aren't shooting
        if !self:GetUsingSWEP() then
            if self.l_Clip < self.l_MaxClip and random( 100 ) == 1 and CurTime() > self.l_WeaponUseCooldown + 1 then
                self:ReloadWeapon()
            end
        else
            local swep = self:GetSWEPWeaponEnt()
            if swep:Clip1() < swep:GetMaxClip1() and random( 100 ) == 1 and CurTime() > swep:GetNextPrimaryFire() + 1 then
                self:ReloadWeapon()
            end
        end
        

        -- UA, Universal Actions
        -- See sv_x_universalactions.lua
        if CurTime() > self.l_nextUA and !self:IsDisabled() then
            local UAfunc = self.l_UniversalActions[ random( #self.l_UniversalActions ) ]
            UAfunc( self )
            self.l_nextUA = CurTime() + rand( 1, 15 )
        end

        -- Eye tracing
        if developer:GetBool() then
            local attach = self:GetAttachmentPoint( "eyes" )
            debugoverlay.Line( attach.Pos, self:GetEyeTrace().HitPos, 0.1, color_white, true  )
        end

        -- How fast we are falling
        if !self:IsOnGround() then
            self.l_FallVelocity = -self.loco:GetVelocity().z
        end

        -- Handle noclip
        if self:IsInNoClip() then
            if !self.l_ispickedupbyphysgun then
                self:SetCrouch( false )
                self.loco:SetVelocity( zerovector )

                -- Play the "floating" gesture
                if !self:IsPlayingGesture( ACT_GMOD_NOCLIP_LAYER ) then
                    self:AddGesture( ACT_GMOD_NOCLIP_LAYER, false )
                end

                -- Randomly change height
                if CurTime() > self.l_nextnoclipheightchange then
                    self.l_noclipheight = random( 0, 500 )
                    self.l_nextnoclipheightchange = CurTime() + random( 1, 20 )
                end

                local pathPos = ( isvector( self.l_CurrentPath ) and self.l_CurrentPath or ( IsValid( self.l_CurrentPath ) and self.l_CurrentPath:GetEnd() or nil ) )
                if pathPos then

                    local trace = self:Trace( pathPos + Vector( 0, 0, self.l_noclipheight ), pathPos + Vector( 0, 0, 3 ) ) -- Trace the height
                    local endPos = ( trace.HitPos + trace.HitNormal * 70 ) -- Subtract the normal so we are hovering below a ceiling by 70 Source Units
                    local copy = Vector( endPos[ 1 ], endPos[ 2 ], self:GetPos()[ 3 ] ) -- Vector used if we are close to our goal

                    local ene = self:GetEnemy()
                    if self:GetState() == "Combat" and LambdaIsValid( ene ) then endPos[ 3 ] = ( ene:GetPos()[ 3 ] + ( self.l_HasMelee and 0 or 50 ) ) end

                    if self:IsInRange( copy, 20 ) then 
                        self:CancelMovement() 
                    else 
                        self.loco:FaceTowards( endPos )

                        local noclipSpeed = ( ( self:GetRun() and 1500 or 500 ) * FrameTime() )
                        self.l_noclippos = ( self.l_noclippos + ( endPos - self.l_noclippos ):GetNormalized() * noclipSpeed ) 
                    end

                end

                self:SetPos( self.l_noclippos )
            else -- If we are in noclip but are being physgunned then do this
                self.l_noclipheight = 0
                self.l_noclippos = self:GetPos()
            end
        else -- If we aren't in no clip then do this stuff
            self.l_noclipheight = 0
            self:RemoveGesture( ACT_GMOD_NOCLIP_LAYER )
            self.l_noclippos = self:GetPos()
        end

        -- Animations --
        if self.l_UpdateAnimations then
            local anims = _LAMBDAPLAYERSHoldTypeAnimations[ self.l_HoldType ]

            if self:IsOnGround() then
                if self.loco:GetVelocity():IsZero() then
                    self:StartActivity( self:GetCrouch() and anims.crouchIdle or anims.idle )
                else
                    local moveAnim = ( self:GetCrouch() and anims.crouchWalk or anims.run )
                    if self:GetActivity() != moveAnim then self:StartActivity( moveAnim ) end
                end
            elseif self:IsInNoClip() then
                self:StartActivity( anims.idle )
            elseif self:GetActivity() != anims.jump then
                self:StartActivity( anims.jump )
            end
        end
        --


        -- Handles facing positions or entities
        if self.Face then
            if self.l_Faceend and CurTime() > self.l_Faceend then self.l_Faceend = nil self.Face = nil return end
            if isentity( self.Face ) and !IsValid( self.Face ) then self.Face = nil return end
            local pos = ( isentity( self.Face ) and ( isfunction( self.Face.EyePos ) and self.Face:EyePos() or self.Face:WorldSpaceCenter() ) or self.Face )
            self.loco:FaceTowards( pos )
            self.loco:FaceTowards( pos )


            local aimangle = ( pos - self:GetAttachmentPoint( "eyes" ).Pos ):Angle()

            local loca = self:WorldToLocalAngles( aimangle )
            local approachy = Lerp( 5 * FrameTime(), self:GetPoseParameter('head_yaw'), loca[2] )
            local approachp = Lerp( 5 * FrameTime(), self:GetPoseParameter('head_pitch'), loca[1] )
            local approachaimy = Lerp( 5 * FrameTime(), self:GetPoseParameter('aim_yaw'), loca[2] )
            local approachaimp = Lerp( 5 * FrameTime(), self:GetPoseParameter('aim_pitch'), loca[1] )

            self:SetPoseParameter( 'head_yaw', approachy )
            self:SetPoseParameter( 'head_pitch', approachp )
            self:SetPoseParameter( 'aim_yaw', approachaimy )
            self:SetPoseParameter( 'aim_pitch', approachaimp )
        else
            local approachy = Lerp( 4 * FrameTime(), self:GetPoseParameter('head_yaw'), 0 )
            local approachp = Lerp( 4 * FrameTime(), self:GetPoseParameter('head_pitch'), 0 )
            local approachaimy = Lerp( 4 * FrameTime(), self:GetPoseParameter('aim_yaw'), 0 )
            local approachaimp = Lerp( 4 * FrameTime(), self:GetPoseParameter('aim_pitch'), 0 )

            self:SetPoseParameter( 'head_yaw', approachy )
            self:SetPoseParameter( 'head_pitch', approachp )
            self:SetPoseParameter( 'aim_yaw', approachaimy )
            self:SetPoseParameter( 'aim_pitch', approachaimp )
        end


        -- Text Chat --
        -- Pretty simple stuff actually

        self:SetIsTyping( self.l_queuedtext != nil )
        if self.l_queuedtext and CurTime() > self.l_nexttext then

            if #self.l_typedtext == #self.l_queuedtext or self:GetState() != self.l_starttypestate then 
                self.l_queuedtext = nil
                self:Say( self.l_typedtext )
                self:OnEndMessage( self.l_typedtext )
            else
                self.l_typedtext = self.l_typedtext .. sub( self.l_queuedtext, #self.l_typedtext + 1, #self.l_typedtext + 1 )
                self.l_nexttext = CurTime() + 1 / ( self:GetTextPerMinute() / 60 )
            end

        end


        -- -- -- -- --


        -- UNSTUCK --

        if self.l_stucktimes > 0 and CurTime() > self.l_stucktimereset then
            self.l_stucktimes = 0
        end


        if self.l_unstuck then
            local mins, maxs = self:GetCollisionBounds()
            local testpoint = self:GetPos() + VectorRand( -self.l_UnstuckBounds, self.l_UnstuckBounds )
            local navareas = navmesh_Find( self:GetPos(), self.l_UnstuckBounds, self.loco:GetDeathDropHeight(), self.loco:GetJumpHeight() )
            local randompoint

            for k, v in RandomPairs( navareas ) do if IsValid( v ) then randompoint = v:GetClosestPointOnArea( testpoint ) break end end

            if randompoint then

                unstucktable.start = randompoint
                unstucktable.endpos = randompoint
                unstucktable.mins = mins
                unstucktable.maxs = maxs
                local result = TraceHull( unstucktable )
                
                if result.Hit then
                    self.l_UnstuckBounds = self.l_UnstuckBounds + 5
                else
                    self:SetPos( randompoint )
                    self.loco:ClearStuck()
                    self.l_unstuck = false
                    self.l_UnstuckBounds = 50
                end

            else
                self.l_UnstuckBounds = self.l_UnstuckBounds + 5
            end


        end
        -- -- -- -- --


    elseif CLIENT then
        
        -- Update our flashlight
        if CurTime() > self.l_lightupdate then
            local lightvec = render.GetLightColor( self:WorldSpaceCenter() )

            if lightvec:Length() < 0.02 and !self:GetIsDead() and drawflashlight:GetBool() and self:IsBeingDrawn() then
                if !IsValid( self.l_flashlight ) then
                    self:SetFlashlightOn( true )
                    self.l_flashlight = ProjectedTexture() 
                    self.l_flashlight:SetTexture( "effects/flashlight001" ) 
                    self.l_flashlight:SetFarZ( 600 ) 
                    self.l_flashlight:SetEnableShadows( false )
                    self.l_flashlight:SetPos( self:WorldSpaceCenter() )
                    self.l_flashlight:SetAngles( self:GetAngles() )
                    self.l_flashlight:Update()

                    self:EmitSound( "items/flashlight1.wav", 60 )
                end
            elseif IsValid( self.l_flashlight ) then
                self:SetFlashlightOn( false )
                self.l_flashlight:Remove()
                self:EmitSound( "items/flashlight1.wav", 60 )
            end

            self.l_lightupdate = CurTime() + 1
        end

        if IsValid( self.l_flashlight ) then
            self.l_flashlight:SetPos( self:WorldSpaceCenter() )
            self.l_flashlight:SetAngles( self:GetAngles() )
            self.l_flashlight:Update()
        end

    end

    -- Think Delay
    if InSinglePlayer() then
        self:NextThink( CurTime() + thinkrate:GetFloat() )
        return true
    end
end

function ENT:BodyUpdate()
    if !self.loco:GetVelocity():IsZero() then
        self:BodyMoveXY()
        return
    end
    
    self:FrameAdvance()
end




function ENT:RunBehaviour()
    self:DebugPrint( "Initialized their AI in ", SysTime() - self.debuginitstart, " seconds" )
    if IsValid( self:GetCreator() ) then
        undo.Create( "Lambda Player ( " .. self:GetLambdaName() .. " )" )
            undo.SetPlayer( self:GetCreator() )
            undo.SetCustomUndoText( "Undone " .. "Lambda Player ( " .. self:GetLambdaName() .. " )" )
            undo.AddEntity( self )
        undo.Finish( "Lambda Player ( " .. self:GetLambdaName() .. " )" )
    end

    while true do

        if !self:GetIsDead() and !self:IsDisabled() then

            local statefunc = self[ self:GetState() ] -- I forgot this was possible. See sv_states.lua

            if statefunc then statefunc( self ) end

        end

        local time = InSinglePlayer() and thinkrate:GetFloat() or 0.2
        coroutine.wait( time )
    end

end




list.Set( "NPC", "npc_lambdaplayer", {
	Name = "Lambda Player",
	Class = "npc_lambdaplayer",
	Category = "Lambda Players"
})