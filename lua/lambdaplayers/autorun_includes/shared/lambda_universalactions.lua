local CurTime = CurTime

-- Adds a function to Lambda's Universal Actions

-- Universal actions are functions that are randomly called during run time.
-- This means Lambda players could randomly change weapons or randomly look at something and ect

LambdaUniversalActions = LambdaUniversalActions or {}

-- The first arg in the functions is the Lambda Player who called the function
function AddUActionToLambdaUA( func, name )
    LambdaUniversalActions[ name or tostring( func ) ] = func
end

-- Random weapon switching
AddUActionToLambdaUA( function( self )
    if LambdaRNG( 2 ) != 1 then return end
    if self:InCombat() or self:IsPanicking() then
        self:SwitchToLethalWeapon()
    else
        self:SwitchToRandomWeapon()
    end
end, "SwitchToRandomWeapon" )

-- Use a random act
AddUActionToLambdaUA( function( self )
    if !self:GetState( "Idle" ) or LambdaRNG( 2 ) != 1 then return end
    self:CancelMovement()
    self:SetState( "UsingAct" )
end, "Do 'act *'" )

-- Undo entities
AddUActionToLambdaUA( function( self )
    if !self:GetState( "Idle" ) then return end
    self:NamedTimer( "UndoEntities", LambdaRNG( 0.3, 0.6, true ), LambdaRNG( 6 ), function() self:UndoLastSpawnedEnt() end )
end, "UndoEntities" )

local isbutton = {
    [ "func_button" ] = true,
    [ "gmod_button" ] = true,
    [ "gmod_wire_button" ] = true
}
-- Look for and press a button
AddUActionToLambdaUA( function( self )
    if !self:GetState( "Idle" ) then return end

    local find = self:FindInSphere( nil, 2000, function( ent ) 
        return ( isbutton[ ent:GetClass() ] and self:CanSee( ent ) )
    end )
    if #find == 0 then return end

    self:CancelMovement()
    self:SetState( "PushButton", find[ LambdaRNG( #find ) ] )
end, "FindButton" )

-- Crouch
AddUActionToLambdaUA( function( self )
    if LambdaRNG( 2 ) != 1 or self:IsPanicking() then return end
    self:SetCrouch( true )

    local lastState = self:GetState()
    local crouchTime = ( CurTime() + LambdaRNG( 15 ) )
    self:NamedTimer( "UnCrouch", 1, 0, function() 
        if self:GetState() == lastState and CurTime() < crouchTime then return end
        self:SetCrouch( false )
        return true
    end )
end, "Crouch" )

local allowNoclip = GetConVar( "lambdaplayers_lambda_allownoclip" )
local unreachOnly = GetConVar( "lambdaplayers_lambda_onlynoclipifcantreach" )
-- NoClip
AddUActionToLambdaUA( function( self )
    if unreachOnly:GetBool() then return end
    if LambdaRNG( 3 ) != 1 or !allowNoclip:GetBool() then return end
    
    self:NoClipState( true )
    local noclipTime = ( CurTime() + LambdaRNG( 10, 120 ) )

    self:NamedTimer( "UnNoclip", 1, 0, function() 
        if !self:IsInNoClip() then return true end
        if CurTime() < noclipTime and allowNoclip:GetBool() then return end
        
        self:NoClipState( false )
        return true
    end )
end, "Noclip" )

-- Jump around ( Disabled due to causes of many 'stuck in wall or ceiling' situations )
-- AddUActionToLambdaUA( function( self )
--     if LambdaRNG( 2 ) != 1 or self:GetState() != "Idle" then return end
--     self:LambdaJump()

--     if self.l_issmoving then
--         self:NamedTimer( "JumpMoving", 1, LambdaRNG( 3, 15 ), function() 
--             if !self.l_issmoving or self:GetState() != "Idle" then return true end
--             self:LambdaJump() 
--         end )
--     end
-- end )

local killbind = GetConVar( "lambdaplayers_lambda_allowkillbind" )
-- Use Killbind
AddUActionToLambdaUA( function( self )
    if !killbind:GetBool() or LambdaRNG( self:IsPlayingTaunt() and 40 or 150 ) != 1 then return end
    self.l_killbinded = true
    self:Kill()
    self.l_killbinded = false
end, "Killbind" )

-- Equip and use medkit on myself if it's allowed, we are hurt and not in combat
AddUActionToLambdaUA( function( self )
    if self:Health() >= self:GetMaxHealth() or self:InCombat() or !self:CanEquipWeapon( "gmod_medkit" ) then return end
    self:SwitchWeapon( "gmod_medkit" )
end, "HealWithMedkit" )

local shotChance = GetConVar( "lambdaplayers_viewshots_chance" )
-- Request a view shot
AddUActionToLambdaUA( function( self )
    if LambdaRNG( 100 ) <= shotChance:GetInt() then self:TakeViewShot() end
end, "RequestViewShot" )