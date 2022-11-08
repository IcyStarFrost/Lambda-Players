AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.PrintName = "Lambda Player"
ENT.Author = "StarFrost"
ENT.IsLambdaPlayer = true

--- Include files based on sv_ sh_ or cl_
local ENTFiles = file.Find( "lambdaplayers/lambda/*", "LUA", "nameasc" )

for k, luafile in ipairs( ENTFiles ) do

    if string.StartWith( luafile, "sv_" ) then -- Server Side Files
        include( "lambdaplayers/lambda/" .. luafile )
        print( "Lambda Players: Included Server Side ENT Lua File [" .. luafile .. "]" )
    elseif string.StartWith( luafile, "sh_" ) then -- Shared Files
        if SERVER then
            AddCSLuaFile( "lambdaplayers/lambda/" .. luafile )
        end
        include( "lambdaplayers/lambda/" .. luafile )
        print( "Lambda Players: Included Shared ENT Lua File [" .. luafile .. "]" )
    elseif string.StartWith( luafile, "cl_" ) then -- Client Side Files
        if SERVER then
            AddCSLuaFile( "lambdaplayers/lambda/" .. luafile )
        else
            include( "lambdaplayers/lambda/" .. luafile )
            print( "Lambda Players: Included Client Side ENT Lua File [" .. luafile .. "]" )
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
    local Vector = Vector
    local debugoverlay = debugoverlay
    local voicepitchmin = GetConVar( "lambdaplayers_voice_voicepitchmin" )
    local voicepitchmax = GetConVar( "lambdaplayers_voice_voicepitchmax" )
    local idledir = GetConVar( "lambdaplayers_voice_idledir" )
    local drawflashlight = GetConVar( "lambdaplayers_drawflashlights" )
    local allowaddonmodels = GetConVar( "lambdaplayers_lambda_allowrandomaddonsmodels" ) 
    local CurTime = CurTime
    local color_white = color_white
    local FrameTime = FrameTime
    local sub = string.sub
    local RealTime = RealTime
    
--

if CLIENT then

    language.Add( "npc_lambdaplayer", "Lambda Player" )

end


function ENT:Initialize()

    self.l_SpawnPos = self:GetPos() -- Used for Respawning
    self.l_SpawnAngles = self:GetAngles()

    if SERVER then

        LambdaPlayerNames = LambdaPlayerNames or LAMBDAFS:GetNameTable()
        LambdaPlayerProps = LambdaPlayerProps or LAMBDAFS:GetPropTable()
        Lambdaprofilepictures = Lambdaprofilepictures or LAMBDAFS:GetProfilePictures()

        self:SetSolid( SOLID_BBOX )
        self:SetCollisionBounds( Vector( -17, -17, 0 ), Vector( 17, 17, 72 ) )

        self:SetModel( allowaddonmodels:GetBool() and _LAMBDAPLAYERS_Allplayermodels[ random( #_LAMBDAPLAYERS_Allplayermodels ) ] or _LAMBDAPLAYERSDEFAULTMDLS[ random( #_LAMBDAPLAYERSDEFAULTMDLS ) ] )

        self.IsMoving = false
        self.l_State = "Idle" -- See sv_states.lua
        self.l_Weapon = ""
        self.debuginitstart = SysTime()
        self.l_nextidlesound = CurTime() + 5
        self.l_SpawnedEntities = {}
        self.l_Timers = {}
        self.l_SimpleTimers = {}
        self.l_NexthealthUpdate = 0
        self.l_movepos = nil
        self.l_nextdoorcheck = 0
        self.l_nextphysicsupdate = 0
        self.l_WeaponUseCooldown = 0
        self.l_currentnavarea = navmesh.GetNavArea( self:WorldSpaceCenter(), 400 )


        -- Personal Stats --
        
        self:SetLambdaName( LambdaPlayerNames[ random( #LambdaPlayerNames ) ] )
        self:SetProfilePicture( #Lambdaprofilepictures > 0 and Lambdaprofilepictures[ random( #Lambdaprofilepictures ) ] or "spawnicons/".. sub( self:GetModel(), 1, #self:GetModel() - 4 ).. ".png" )

        self:SetMaxHealth( 100 )
        self:SetNWMaxHealth( 100 )
        self:SetHealth( 100 )

        self:SetPlyColor( Vector( random( 255 ) / 225, random( 255 ) / 255, random( 255 ) / 255 ) )
        self:SetPhysColor( Vector( random( 255 ) / 225, random( 255 ) / 255, random( 255 ) / 255 ) )
        self.l_PlyRealColor = self:GetPlyColor():ToColor()
        self.l_PhysRealColor = self:GetPhysColor():ToColor()

        self:SetBuildChance( random( 1, 100 ) )
        self:SetCombatChance( random( 1, 100 ) )
        self:SetVoiceChance( random( 1, 100 ) )
        self.l_Personality = { -- See sv_chances.lua
            { "Build", self:GetBuildChance() },
            { "Combat", self:GetCombatChance() },
        }
        
        
        self:SetVoicePitch( random( voicepitchmin:GetInt(), voicepitchmax:GetInt() ) )

        ----

        SortTable( self.l_Personality, function( a, b ) return a[ 2 ] > b[ 2 ] end )

        self.loco:SetJumpHeight( 60 )
        self.loco:SetAcceleration( 1000 )
        self.loco:SetDeceleration( 1000 )
        self.loco:SetStepHeight( 30 )


        self:PhysicsInitShadow()
        self:SetCollisionGroup( COLLISION_GROUP_PLAYER )
        self:AddCallback( "PhysicsCollide", function( self, data )
            self:HandleCollision( data )
        end)

        self:SetLagCompensated( true )
        self:AddFlags( FL_OBJECT + FL_NPC + FL_CLIENT )

        local ap = self:LookupAttachment( "anim_attachment_RH" )
        local attachpoint = self:GetAttachmentPoint( "hand" )

        self.WeaponEnt = ents.Create( "base_anim" )
        self.WeaponEnt:SetPos( attachpoint.Pos )
        self.WeaponEnt:SetAngles( attachpoint.Ang )
        self.WeaponEnt:SetParent( self, ap )
        self.WeaponEnt:Spawn()
        self.WeaponEnt:SetNW2Vector( "lambda_weaponcolor", self:GetPhysColor() )
        self.WeaponEnt:SetNoDraw( true )

        self:InitializeMiniHooks()
        self:SwitchWeapon( "physgun" )
        self.l_SpawnWeapon = "physgun"
        
        self:SetWeaponENT( self.WeaponEnt )

        self:HandleAllValidNPCRelations()



    elseif CLIENT then

        self.l_lastdraw = 0
        self.l_lightupdate = 0

        self:InitializeMiniHooks()

        -- For some reason having this properly makes the weapon go invisible when the lambda dies in multiplayer
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

    self:NetworkVar( "Entity", 0, "WeaponENT" )
    self:NetworkVar( "Entity", 1, "Enemy" )

    self:NetworkVar( "Vector", 0, "PlyColor" )
    self:NetworkVar( "Vector", 1, "PhysColor" )

    self:NetworkVar( "Int", 0, "VoicePitch" )
    self:NetworkVar( "Int", 1, "NWMaxHealth" )
    self:NetworkVar( "Int", 2, "BuildChance" )
    self:NetworkVar( "Int", 3, "CombatChance" )
    self:NetworkVar( "Int", 4, "VoiceChance" )
    
    self:NetworkVar( "Float", 0, "LastSpeakingTime" )
end

function ENT:Draw()
    if self:GetIsDead() then return end
    self.l_lastdraw = RealTime() + 0.1
    self:DrawModel()
end


function ENT:Think()
    if self:GetIsDead() then return end

    
    if SERVER then
        if self.l_ispickedupbyphysgun then self.loco:SetVelocity( Vector() ) end

        if CurTime() > self.l_nextidlesound and !self:IsSpeaking() and random( 1, 100 ) <= self:GetVoiceChance() then
            self:PlaySoundFile( idledir:GetString() == "randomengine" and self:GetRandomSound() or idledir:GetString() .. "/*", true )
            self.l_nextidlesound = CurTime() + 5
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

        if developer:GetBool() then
            local attach = self:GetAttachmentPoint( "eyes" )
            debugoverlay.Line( attach.Pos, self:GetEyeTrace().HitPos, 0.1, color_white, true  )
        end

        -- Animations --
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


    elseif CLIENT then
        
        if CurTime() > self.l_lightupdate then
            local lightvec = render.GetLightColor( self:WorldSpaceCenter() )

            if lightvec:Length() < 0.02 and !self:GetIsDead() and drawflashlight:GetBool() then
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

        -- TODO: Fix weird performance drop when ai_disabled is enabled
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