local table_insert = table.insert
local random = math.random
local rand = math.Rand

-- Adds a function to Lambda's Universal Actions

-- Universal actions are functions that are randomly called during run time.
-- This means Lambda players could randomly change weapons or randomly look at something and ect

LambdaUniversalActions = {}

-- The first arg in the functions is the Lambda Player who called the function
function AddUActionToLambdaUA( func )
    table_insert( LambdaUniversalActions, func )
end

-- Random weapon switching
AddUActionToLambdaUA( function( self )
    if random( 1, 3 ) != 1 then return end
    if self:GetState() == "Idle" then
        self:SwitchToRandomWeapon()
    elseif self:InCombat() then
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
    local crouchTime = CurTime() + rand( 1, 30 )
    self:NamedTimer( "UnCrouch", 1, 0, function() 
        if self:GetState() != lastState or CurTime() >= crouchTime then
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

    local Nocliptime = CurTime() + rand( 1, 120 )
    self:NamedTimer( "UnNoclip", 1, 0, function() 
        if CurTime() >= Nocliptime or !noclip:GetBool() then
            self:NoClipState( false )
            return true
        end
    end )
end )

-- Jump around
AddUActionToLambdaUA( function( self )
    if random( 1, 2 ) != 1 or self:GetState() != "Idle" then return end
    self:LambdaJump()

    if self.l_issmoving then
        self:NamedTimer( "JumpMoving", 1, random( 3, 15 ), function() 
            if !self.l_issmoving or self:GetState() != "Idle" then return true end
            self:LambdaJump() 
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


-- Equip and use medkit on myself if it's allowed, we are hurt and not in combat
AddUActionToLambdaUA( function( self )
    if self:Health() >= self:GetMaxHealth() or self:InCombat() or !self:CanEquipWeapon( "gmod_medkit" ) then return end
    self:SwitchWeapon( "gmod_medkit" )
end )