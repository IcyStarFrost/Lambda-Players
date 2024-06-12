local ipairs = ipairs


-- Tests highest chances before low chances
function ENT:ComputeChance()
    local persTbl = self.l_Personality

    local hundreds = 0
    for _, v in ipairs( persTbl ) do
        if !v[ 3 ] or v[ 2 ] != 100 then continue end
        hundreds = ( hundreds + 1 )
    end

    for _, v in ipairs( persTbl ) do
        if !v[ 3 ] then continue end

        local chan = v[ 2 ]
        if chan == 100 and hundreds > 1 and LambdaRNG( 2 ) == 1 then
            hundreds = ( hundreds - 1 )
            self:DebugPrint( v[ 1 ] .. " one of their hundred percent chances failed" )
            continue
        end

        local rnd = LambdaRNG( 100 )
        if rnd < chan then
            self:DebugPrint( v[ 1 ] .. " chance succeeded in its chance. ( " .. rnd .. " to " .. chan .. " )" )
            self[ "Chance_" .. v[ 1 ] ]( self )
            return
        end
    end
end

-- All personality functions have been moved to autorun_includes/shared/lambda_personalityfuncs.lua due to a rewrite in code to allow external addons to create custom personalities