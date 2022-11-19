AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.PrintName = "Lambda Player"
ENT.Author = "StarFrost"
ENT.IsLambdaPlayer = true

local include = include
local print = print
local AddCSLuaFile = AddCSLuaFile

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
    local voiceprofilechance = GetConVar( "lambdaplayers_lambda_voiceprofileusechance" )
    local thinkrate = GetConVar( "lambdaplayers_lambda_singleplayerthinkrate" )
    local _LAMBDAPLAYERSFootstepMaterials = _LAMBDAPLAYERSFootstepMaterials
    local CurTime = CurTime
    local Clamp = math.Clamp
    local min = math.min
    local color_white = color_white
    local RandomPairs = RandomPairs
    local TraceHull = util.TraceHull
    local QuickTrace = util.QuickTrace
    local FrameTime = FrameTime
    local unstucktable = {}
    local sub = string.sub
    local RealTime = RealTime
    
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

        self.IsMoving = false -- If we are moving
        self.l_unstuck = false -- If true, runs our unstuck process
        self.l_UpdateAnimations = true -- If we can update our animations. Used for the purpose of playing sequences

        self.l_deaths = 0 -- The amount of deaths we have had
        self.l_frags = 0 -- The amount of kills we have
        self.l_UnstuckBounds = 50 -- The distance the unstuck process will use to check. This value increments during the process and set back to 50 when done
        self.l_nextspeedupdate = 0 -- The next time we update our speed
        self.l_NexthealthUpdate = 0 -- The next time we update our networked health
        self.l_stucktimes = 0 -- How many times did we get stuck in the past 10 seconds
        self.l_stucktimereset = 0 -- The time until l_stucktimes gets reset to 0
        self.NextFootstepTime = 0 -- The next time we play a footstep sound
        self.l_nextdoorcheck = 0 -- The next time we will check for doors to open
        self.l_nextphysicsupdate = 0 -- The next time we will update our Physics Shadow
        self.l_WeaponUseCooldown = 0 -- The time before we can use our weapon again
        self.l_FallVelocity = 0 -- How fast we are falling
        self.debuginitstart = SysTime() -- Debug time from initialize to ENT:RunBehaviour()
        self.l_nextidlesound = CurTime() + 5 -- The next time we will play a idle sound
        self.l_nextUA = CurTime() + rand( 1, 15 ) -- The next time we will run a UAction. See lambda/sv_x_universalactions.lua


        self.l_CurrentPath = nil -- The current path (PathFollower) we are on. If off navmesh, this will hold a Vector
        self.l_movepos = nil -- The position or entity we are going to
        self.l_currentnavarea = navmesh_GetNavArea( self:WorldSpaceCenter(), 400 ) -- The current nav area we are in


        -- Personal Stats --
        self:SetLambdaName( self:GetOpenName() )
        self:SetProfilePicture( #Lambdaprofilepictures > 0 and Lambdaprofilepictures[ random( #Lambdaprofilepictures ) ] or "spawnicons/".. sub( self:GetModel(), 1, #self:GetModel() - 4 ).. ".png" )

        self:SetMaxHealth( 100 )
        self:SetNWMaxHealth( 100 )
        self:SetHealth( 100 )

        self:SetPlyColor( Vector( random( 255 ) / 225, random( 255 ) / 255, random( 255 ) / 255 ) )
        self:SetPhysColor( Vector( random( 255 ) / 225, random( 255 ) / 255, random( 255 ) / 255 ) )
        self.l_PlyRealColor = self:GetPlyColor():ToColor()
        self.l_PhysRealColor = self:GetPhysColor():ToColor()

        local rndpingrange = random( 1, 120 )
        self:SetAbsPing( rndpingrange )  -- The lowest point our fake ping can get
        self:SetPing( rndpingrange ) -- Our actual fake ping
        
        -- Personality function was relocated to the start of the code since it needs to be shared so clients can have Get functions
        
        self:SetVoiceChance( random( 1, 100 ) )
        self:SetVoicePitch( random( voicepitchmin:GetInt(), voicepitchmax:GetInt() ) )

        local vpchance = voiceprofilechance:GetInt()
        if vpchance > 0 and random( 1, 100 ) < vpchance then local vps = table_GetKeys( LambdaVoiceProfiles ) self.l_VoiceProfile = vps[ random( #vps ) ] end
        self:SetNW2String( "lambda_vp", self.l_VoiceProfile )
        ----

        SortTable( self.l_Personality, function( a, b ) return a[ 2 ] > b[ 2 ] end )

        self.loco:SetJumpHeight( 60 )
        self.loco:SetAcceleration( 1000 )
        self.loco:SetDeceleration( 1000 )
        self.loco:SetStepHeight( 30 )
        self.loco:SetGravity( -physenv.GetGravity().z ) -- Makes us fall at the same speed as the real players do

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
    
    self:NetworkVar( "Float", 0, "LastSpeakingTime" )
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

        if CurTime() > self.NextFootstepTime and self:IsOnGround() and !self.loco:GetVelocity():IsZero() then
            local desSpeed = self.loco:GetDesiredSpeed()
            local result = QuickTrace( self:WorldSpaceCenter(), self:GetUp() * -32600, self )
            local stepsounds = _LAMBDAPLAYERSFootstepMaterials[ result.MatType ] or _LAMBDAPLAYERSFootstepMaterials[ MAT_DEFAULT ]
            self:EmitSound( stepsounds[ random( #stepsounds ) ], 75, 100, 0.5 )
            self.NextFootstepTime = CurTime() + min(0.25 * (self:GetRunSpeed() / desSpeed), 0.35)
        end
        
        if CurTime() > self.l_nextidlesound and !self:IsSpeaking() and random( 1, 100 ) <= self:GetVoiceChance() then
            
            self:PlaySoundFile( idledir:GetString() == "randomengine" and self:GetRandomSound() or self:GetVoiceLine( "idle" ), true )
            self.l_nextidlesound = CurTime() + 5
        end

        if CurTime() > self.l_nextspeedupdate then
            local speed = ( self:GetCrouch() and self:GetCrouchSpeed() or self:GetRun() and self:GetRunSpeed() or self:GetWalkSpeed() ) +  self.l_CombatSpeedAdd
            self.loco:SetDesiredSpeed( speed )
            self.l_nextspeedupdate = CurTime() + 0.5
        end
        
        if CurTime() > self.l_NexthealthUpdate then
            self:UpdateHealthDisplay()
            self.l_NexthealthUpdate = CurTime() + 0.1
        end

        if CurTime() > self.l_nextphysicsupdate then
            local phys = self:GetPhysicsObject()
            phys:UpdateShadow( self:GetPos(), self:GetAngles(), 0 )
            self.l_nextphysicsupdate = CurTime() + 0.5
        end

        if random( 125 ) == 1 then
            self:SetPing( Clamp( self:GetPing() + random( -20, ( 24 - ( self:GetPing() / self:GetAbsPing() ) ) ), self:GetAbsPing(), 999 ) )
        end


        if self.l_Clip < self.l_MaxClip and random( 100 ) == 1 and CurTime() > self.l_WeaponUseCooldown + 1 then
            self:ReloadWeapon()
        end
        

        -- UA, Universal Actions
        -- See sv_x_universalactions.lua
        if CurTime() > self.l_nextUA then
            local UAfunc = self.l_UniversalActions[ random( #self.l_UniversalActions ) ]
            UAfunc( self )
            self.l_nextUA = CurTime() + rand( 1, 15 )
        end

        if developer:GetBool() then
            local attach = self:GetAttachmentPoint( "eyes" )
            debugoverlay.Line( attach.Pos, self:GetEyeTrace().HitPos, 0.1, color_white, true  )
        end

        if !self:IsOnGround() then
            self.l_FallVelocity = -self.loco:GetVelocity().z
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
            elseif self:GetActivity() != anims.jump then
                self:StartActivity( anims.jump )
            end
        end
        --



        if self.Face then
            if self.l_Faceend and CurTime() > self.l_Faceend then self.Face = nil return end
            if isentity( self.Face ) and !IsValid( self.Face ) then self.Face = nil return end
            local pos = ( isentity( self.Face ) and self.Face:WorldSpaceCenter() or self.Face )
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


        -- UNSTUCK --

        if self.l_stucktimes > 0 and CurTime() > self.l_stucktimereset then
            self.l_stucktimes = 0
        end


        if self.l_unstuck then
            local mins, maxs = self:GetModelBounds()
            local randompoint = self:GetPos() + VectorRand( -self.l_UnstuckBounds, self.l_UnstuckBounds )

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

        end
        -- -- -- -- --


    elseif CLIENT then
        
        if CurTime() > self.l_lightupdate then
            local lightvec = render.GetLightColor( self:WorldSpaceCenter() )

            if lightvec:Length() < 0.02 and !self:GetIsDead() and drawflashlight:GetBool() and self:IsBeingDrawn() then
                if !IsValid( self.l_flashlight ) then
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
    if game.SinglePlayer() then
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


        if !self:GetIsDead() and !aidisable:GetBool() then

            local statefunc = self[ self:GetState() ] -- I forgot this was possible. See sv_states.lua

            if statefunc then statefunc( self ) end

        end

        coroutine.wait( 0.3 )
    end

end




list.Set( "NPC", "npc_lambdaplayer", {
	Name = "Lambda Player",
	Class = "npc_lambdaplayer",
	Category = "Lambda Players"
})