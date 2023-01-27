local table_insert = table.insert
-- Universal actions are functions that are randomly called during run time.
-- This means Lambda players could randomly change weapons or randomly look at something and ect

ENT.l_UniversalActions = {}

-- Adds a function to the Universal Actions
function AddUActionToLambdaUA( func )
    table_insert( ENT.l_UniversalActions, func )
end

local curTime = CurTime
local random = math.random
local rand = math.Rand

-- Random weapon switching
AddUActionToLambdaUA( function( self )
    if random( 1, 3 ) != 1 then return end
    if self:GetState() == "Idle" then
        self:SwitchToRandomWeapon()
    elseif self:GetState() == "Combat" then
        self:SwitchToLethalWeapon()
    end
end )

-- Use a random act
AddUActionToLambdaUA( function( self )
    if self:GetState() != "Idle" or random( 1, 2 ) != 1 then return end
    self:CancelMovement()
    self:SetState( "UsingAct" )
end )

-- Undo entities
AddUActionToLambdaUA( function( self )
    if self:GetState() != "Idle" then return end
    self:NamedTimer( "Undoentities", rand( 0.3, 0.6 ), random( 1, 6 ), function() self:UndoLastSpawnedEnt() end )
end )

local isbutton = {
    [ "func_button" ] = true,
    [ "gmod_button" ] = true,
    [ "gmod_wire_button" ] = true
}
-- Look for and press a button
AddUActionToLambdaUA( function( self )
    if self:GetState() != "Idle" then return end
    
    local find = self:FindInSphere( self:GetPos(), 2000, function( ent ) 
        return ( isbutton[ ent:GetClass() ] and self:CanSee( ent ) )
    end )
    if #find == 0 then return end

    self.l_buttonentity = find[ random( #find ) ]
    self:CancelMovement()
    self:SetState( "PushButton" )
end )

-- Crouch
AddUActionToLambdaUA( function( self )
    if random( 1, 2 ) != 1 then return end
    self:SetCrouch( true )

    local lastState = self:GetState()
    local crouchTime = curTime() + rand( 1, 30 )
    self:NamedTimer( "UnCrouch", 1, 0, function() 
        if self:GetState() != lastState or curTime() >= crouchTime then
            self:SetCrouch( false )
            return true
        end
    end )
end )


local noclip = GetConVar( "lambdaplayers_lambda_allownoclip" )
-- NoClip
AddUActionToLambdaUA( function( self )
    if random( 1, 2 ) != 1 or !noclip:GetBool() then return end
    self:NoClipState( true )

    local Nocliptime = curTime() + rand( 1, 120 )
    self:NamedTimer( "UnNoclip", 1, 0, function() 
        if curTime() >= Nocliptime or !noclip:GetBool() then
            self:NoClipState( false )
            return true
        end
    end )
end )

-- Jump around
AddUActionToLambdaUA( function( self )
    if random( 1, 2 ) != 1 or self:GetState() != "Idle" then return end
    self.loco:Jump()

    if self.IsMoving then
        self:NamedTimer( "JumpMoving", 1, random( 3, 15 ), function() 
            if !self.IsMoving or self:GetState() != "Idle" then return true end
            if !self:IsOnGround() then return end
            self.loco:Jump() 
        end )
    end
end )


local killbind = GetConVar( "lambdaplayers_lambda_allowkillbind" )
-- Use Killbind
AddUActionToLambdaUA( function( self )
    if random( 100 ) != 1 or !killbind:GetBool() then return end

    local dmginfo = DamageInfo()
    dmginfo:SetDamage( 0 )
    dmginfo:SetAttacker( self )
    dmginfo:SetInflictor( self )
    self:LambdaOnKilled( dmginfo )
end )



-- Called when all default UA actions have been made
-- This hook can be used to add UActions with AddUActionToLambdaUA()
hook.Run( "LambdaOnUAloaded" )