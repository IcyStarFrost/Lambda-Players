local ipairs = ipairs

-- Toolgun tools are made in autorun_includes/shared/lambda_toolguntools.lua
-- It has to be this way because the spawnmenu is made before entities

-- Makes us use a specified toolname.
-- Must be used in the coroutine thread
function ENT:UseTool( toolname, ent, checkallowed )
    if !self:CanEquipWeapon( "toolgun" ) then return end
    if self:GetWeaponName() != "toolgun" then self:SwitchWeapon( "toolgun" ) end
    
    -- Get the tool convar and function
    local tbl 
    for k, v in ipairs( LambdaToolGunTools ) do
        if v[ 1 ] == toolname then tbl = v break end
    end

    -- Use the tool if allowed
    if tbl and ( checkallowed and tbl[ 2 ]:GetBool() or !checkallowed ) then
        tbl[ 3 ]( self, ent )
    end
end

-- Uses a random tool on the target.
function ENT:UseRandomToolOn( target )
    self:SwitchWeapon( "toolgun" )
    if self.l_Weapon != "toolgun" then return end

    self.l_IsUsingTool = true
    self:PreventWeaponSwitch( true )

    -- Loops through random tools and only stops if a tool tells us it actually got used by returning true
    for index, tooltable in RandomPairs( LambdaToolGunTools ) do
        if !tooltable[ 2 ]:GetBool() then continue end -- If the tool is allowed

        local name = tooltable[ 1 ]
        if LambdaRunHook( "LambdaOnToolUse", self, name ) == true then break end

        local result
        local ok, msg = pcall( function() result = tooltable[ 3 ]( self, target ) end )

        if !ok then ErrorNoHaltWithStack( name .. " Tool had a error! If this is from a addon, report it to the author!", msg ) end
        if result then self:DebugPrint( "Used " .. name .. " Tool" ) break end
    end

    self.l_IsUsingTool = false
    self:PreventWeaponSwitch( false )
end