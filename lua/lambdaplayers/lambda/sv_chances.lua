local ipairs = ipairs
local random = math.random

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

-- All personality functions have been moved to autorun_includes/shared/lambda_personalityfuncs.lua due to a rewrite in code to allow external addons to create custom personalities