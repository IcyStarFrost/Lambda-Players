-- Because hook.Run() doesn't pcall() for each hook function, every external addon down the line won't have their hooks run because some addon errored.
function LambdaRunHook( hookname, ... )
    local hooks = hook.GetTable()
    local hooktable = hooks[ hookname ]
    if !hooktable then return end

    local args = { ... }
    local a, b, c, d, e, f

    for uniquename, func in pairs( hooktable ) do
        
        local ok, msg = pcall( function() a, b, c, d, e, f = func( unpack( args ) ) end )
        if !ok then ErrorNoHaltWithStack( msg ) end
        
    end
    return a, b, c, d, e, f
end