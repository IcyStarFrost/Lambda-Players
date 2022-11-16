local ipairs = ipairs
local table_insert = table.insert
local random = math.random

-- Sets up the Personality chances and creates Get/Set functions. overridetable arg is mainly used by the Export/apply lambda info functions
function ENT:BuildPersonalityTable( overridetable )
    self.l_Personality = {}

    for k, v in ipairs( LambdaPersonalities ) do
        self[ "Chance_" .. v[ 1 ] ] = v[ 2 ] -- Set the functions
        self[ "Get" .. v[ 1 ] .. "Chance" ] = function( self ) return self:GetNW2Int( "lambda_chance_" .. v[ 1 ], 0 ) end -- Create Get Function
        self[ "Set" .. v[ 1 ] .. "Chance" ] = function( self, int ) self:SetNW2Int( "lambda_chance_" .. v[ 1 ], int ) end -- Create Set Function

        self:SetNW2Int( "lambda_chance_" .. v[ 1 ], overridetable and overridetable[ v[ 1 ] ] or random( 1, 100 ) ) 

        table_insert( self.l_Personality, { v[ 1 ], self:GetNW2Int( "lambda_chance_" .. v[ 1 ], 0 ) } )
    end

end