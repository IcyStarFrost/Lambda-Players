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
    self.Face = self:GetPos() + VectorRand( -100, 100 )
    coroutine.wait( rand( 0.2, 1 ) )
    self:SpawnProp()
    coroutine.wait( rand( 0.2, 1 ) )
    self.Face = nil
end


local tools = {
    ENT.UseColorTool,
}

function ENT:Chance_Tool()
    self:SwitchWeapon( "toolgun" )
    if self.l_Weapon != "toolgun" or !self:CanEquipWeapon( "toolgun" ) then return end
    local find = self:FindInSphere( nil, 400, function( ent ) if !ent:IsNPC() and !ent:IsPlayer() and !ent:IsNextBot() and IsValid( ent:GetPhysicsObject() ) then return true end end )
    local func = tools[ random( #tools ) ]

    func( self, find[ random( #find ) ] )
end


function ENT:Chance_Combat() 

end