local table_insert = table.insert

-- The reason this lua file has a d_ in its filename is because of the order on how lua files are loaded.
-- If we didn't do this, we wouldn't have _LAMBDAConVarSettings 
-- are ya learnin son?
local ipairs = ipairs

-- settingstbl is just about the same as the convar's settingstbl
function CreateLambdaConsoleCommand( name, func, isclient, helptext, settingstbl )

    if isclient and SERVER then return end

    concommand.Add( name, func, nil, helptext )

    if CLIENT and settingstbl then
        settingstbl.concmd = name
        settingstbl.type = "Button"
        settingstbl.desc = ( isclient and "Client-Side | " or "Server-Side | " ) .. helptext
        table_insert( _LAMBDAConVarSettings, settingstbl )
    end

end


CreateLambdaConsoleCommand( "lambdaplayers_cmd_updatedata", function( ply ) 
    if IsValid( ply ) and !ply:IsSuperAdmin() then return end
    print( "Lambda Players: Updated data via console command" )

    LambdaPlayerNames = LAMBDAFS:GetNameTable()
    LambdaPlayerProps = LAMBDAFS:GetPropTable()

end, false, "Updates data such as names, props, ect. ", { name = "Update Lambda Data", category = "Utilities" } )

CreateLambdaConsoleCommand( "lambdaplayers_cmd_cleanupclientsideents", function( ply ) 

    for k, v in ipairs( _LAMBDAPLAYERS_ClientSideEnts ) do
        if IsValid( v ) then v:Remove() end
    end

end, true, "Removes lambda client side entities such as ragdolls and dropped weapons", { name = "Remove Lambda Client Side ents", category = "Utilities" } )
