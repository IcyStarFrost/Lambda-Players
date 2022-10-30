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
        if v[ 2 ] == 100 and hundreds > 1 and random( 1, 2 ) == 1 then hundreds = hundreds - 1 continue end
        
        if random( 1, 100 ) < v[ 2 ] then
            
            self[ "Chance_" .. v[ 1 ] ]( self )
            return
        end
        
    end
 
end

-- In the self.l_Personality table, The first args in the internal tables will correspond to these functions

function ENT:Chance_Build()

end

function ENT:Chance_Combat() 

end