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