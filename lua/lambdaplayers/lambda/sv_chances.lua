local ipairs = ipairs
local random = math.random
local VectorRand = VectorRand
local rand = math.Rand

local function Get100Percents( tbl )
    local count = 0

    for k, v in ipairs( tbl ) do
        if v[ 2 ] == 100 then
            count = count + 1
        end
    end

    return count
end
-- Tests highest chances before low chances 
function ENT:ComputeChance()
   
    local hundreds = Get100Percents( self.l_Personality )
    for k, v in ipairs( self.l_Personality ) do
        if v[ 2 ] == 100 and hundreds > 1 and random( 1, 2 ) == 1 then hundreds = hundreds - 1 self:DebugPrint( v[ 1 ] .. " one of their hundred percent chances failed" ) continue end
        local rnd = random( 1, 100 )
        if rnd < v[ 2 ] then
            
            self:DebugPrint( v[ 1 ] .. " chance succeeded in its chance. ( " .. rnd .. " to " .. v[ 2 ] .. " )" )
            self[ "Chance_" .. v[ 1 ] ]( self )
            return
        end
        
    end
 
end

-- In the self.l_Personality table, The first args in the internal tables will correspond to these functions


function ENT:Chance_Build()
    self:PreventWeaponSwitch( true )

    for index, buildtable in RandomPairs( self.l_BuildingFunctions ) do
        if !buildtable[ 2 ]:GetBool() then continue end

        local result = buildtable[ 3 ]( self )

        if result then self:DebugPrint( "Used a building function: " .. buildtable[ 1 ] ) break end
    end

    self:PreventWeaponSwitch( false )
end



function ENT:Chance_Tool()
    self:SwitchWeapon( "toolgun" )
    if self.l_Weapon != "toolgun" then return end

    self:PreventWeaponSwitch( true )

    local find = self:FindInSphere( nil, 400, function( ent ) if !ent:IsNPC() and !ent:IsPlayer() and !ent:IsNextBot() and self:CanSee( ent ) and IsValid( ent:GetPhysicsObject() ) and self:HasPermissionToEdit( ent ) then return true end end )
    local target = find[ random( #find ) ]

    -- Loops through random tools and only stops if a tool tells us it actually got used by returning true 
    for index, tooltable in RandomPairs( self.l_ToolgunTools ) do
        if !tooltable[ 2 ]:GetBool() then continue end -- If the tool is allowed

        local result = tooltable[ 3 ]( self, target )

        if result then self:DebugPrint( "Used" .. tooltable[ 1 ] .. "Tool" ) break end
    end

    self:PreventWeaponSwitch( false )
end


function ENT:Chance_Combat() 
    self:SetState( "FindTarget" )
end