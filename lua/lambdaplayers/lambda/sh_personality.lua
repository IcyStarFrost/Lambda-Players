local ipairs = ipairs
local table_insert = table.insert


-- Sets up the Personality chances and creates Get/Set functions. overridetable arg is mainly used by the Export/apply lambda info functions
function ENT:BuildPersonalityTable( overridetable )
    self.l_Personality = {}

    for k, v in ipairs( LambdaPersonalities ) do
        local name, func = v[ 1 ], v[ 2 ]

        -- Set the functions if any is set
        if func then self[ "Chance_" .. name ] = func end

        self[ "Get" .. name .. "Chance" ] = function( self ) return self:GetNW2Int( "lambda_chance_" .. name, 0 ) end -- Create Get Function
        self[ "Set" .. name .. "Chance" ] = function( self, int ) self:SetNW2Int( "lambda_chance_" .. name, int ) end -- Create Set Function

        local rndChan = ( overridetable and overridetable[ name ] or LambdaRNG( 0, 100 ) )
        self:SetNW2Int( "lambda_chance_" .. name, rndChan )
        table_insert( self.l_Personality, { name, rndChan, func } )
    end
end