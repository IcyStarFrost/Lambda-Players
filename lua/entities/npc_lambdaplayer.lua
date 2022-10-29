AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.Spawnable = true
ENT.PrintName = "Lambda Player"
ENT.Author = "StarFrost"

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

--

if CLIENT then

    language.Add( "npc_lambdaplayer", "Lambda Player" )

end


function ENT:Initialize()

    if SERVER then

        self.IsMoving = false
        self.l_State = "Idle" -- See sv_states.lua
        self.l_Weapon = "NONE"
        

        self:SetModel( _LAMBDAPLAYERSDEFAULTMDLS[ random( #_LAMBDAPLAYERSDEFAULTMDLS ) ] )

        self.loco:SetJumpHeight( 60 )
        self.loco:SetAcceleration( 1000 )
        self.loco:SetDeceleration( 1000 )
        self.loco:SetStepHeight( 30 )
        
        self:AddFlags( FL_OBJECT + FL_NPC + FL_CLIENT )

        local ap = self:LookupAttachment( "anim_attachment_RH" )
        local attachpoint = self:GetAttachmentPoint( "hand" )

        self.WeaponEnt = ents.Create( "base_anim" )
        self.WeaponEnt:SetPos( attachpoint.Pos )
        self.WeaponEnt:SetAngles( attachpoint.Ang )
        self.WeaponEnt:SetParent( self, ap )
        self.WeaponEnt:Spawn()
        self.WeaponEnt:SetNoDraw( true )

        self:SwitchWeapon( self.l_Weapon )
        
        self:SetWeaponENT( self.WeaponEnt )

    elseif CLIENT then



    end

end


-- This will be the new way of having networked variables
function ENT:SetupDataTables()

    self:NetworkVar( "String", 0, "LambdaName" ) -- Player name
 
    self:NetworkVar( "Bool", 0, "Crouch" )

    self:NetworkVar( "Entity", 0, "WeaponENT" )

end


function ENT:Think()

    -- Animations --
    if SERVER then

        local anims = _LAMBDAPLAYERSHoldTypeAnimations[ self.l_HoldType ]


        if self:IsOnGround() and self.IsMoving and !self:GetCrouch() and self:GetActivity() != anims.run then
            self:StartActivity( anims.run )
        elseif self:IsOnGround() and self.IsMoving and self:GetCrouch() and self:GetActivity() != anims.crouchWalk then
            self:StartActivity( anims.crouchWalk )
        elseif self:IsOnGround() and !self.IsMoving and self:GetCrouch() then
            self:StartActivity( anims.crouchIdle )
        elseif self:IsOnGround() and !self.IsMoving and !self:GetCrouch() then
            self:StartActivity( anims.idle )
        elseif !self:IsOnGround() and self:GetActivity() != anims.jump then
            self:StartActivity( anims.jump )
        end

    end
    --

end

function ENT:BodyUpdate()
    if self.IsMoving then
        self:BodyMoveXY()
        return
    end
    
    self:FrameAdvance()
end


function ENT:RunBehaviour()

    while true do

        local statefunc = self[ self.l_State ] -- I forgot this was possible. See sv_states.lua

        if statefunc then statefunc( self ) end

        coroutine.wait( 0.3 )
    end

end




list.Set( "NPC", "npc_lambdaplayer", {
	Name = "Lambda Player",
	Class = "npc_lambdaplayer",
	Category = "Lambda Players"
})