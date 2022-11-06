local IsValid = IsValid
local ipairs = ipairs

-- We need to know the creators of whatever entities so we can test if we have permission to edit their props or not.

hook.Add( "PlayerSpawnedProp", "lambdaplayers_setCreator", function( ply, mdl, prop )
    timer.Simple( 0, function()
        if IsValid( prop ) then
            prop:SetCreator( ply )
        end
    end)
end)

hook.Add( "PlayerSpawnedVehicle", "lambdaplayers_setCreator", function( ply, vehicle )
    timer.Simple( 0, function()
        if IsValid( vehicle ) then
            vehicle:SetCreator( ply )
        end
    end)
end)

hook.Add( "PlayerSpawnedRagdoll", "lambdaplayers_setCreator", function( ply, mdl, ragdoll )
    timer.Simple( 0, function()
        if IsValid( ragdoll ) then
            ragdoll:SetCreator( ply )
        end
    end)
end)

hook.Add( "PlayerSpawnedEffect", "lambdaplayers_setCreator", function( ply, mdl, effect )
    timer.Simple( 0, function()
        if IsValid( effect ) then
            effect:SetCreator( ply )
        end
    end)
end)

hook.Add( "PlayerSpawnedSWEP", "lambdaplayers_setCreator", function( ply, swep )
    timer.Simple( 0, function()
        if IsValid( swep ) then
            swep:SetCreator( ply )
        end
    end)
end)

hook.Add( "PlayerSpawnedNPC", "lambdaplayers_setCreator", function( ply, ent )
    timer.Simple( 0, function()
        if IsValid( ent ) then
            ent:SetCreator( ply )
            if ent.IsLambdaPlayer then
                ent:OnSpawnedByPlayer( ply )
            end
        end
    end) 
end)

hook.Add( "PostEntityPaste", "lambdaplayers_setCreator", function( ply, ent, tbl )
    for k, v in ipairs( tbl ) do
        v:SetCreator( ply )
    end
end)

hook.Add( "PlayerSpawnedSENT", "lambdaplayers_setCreator", function( ply, ent )
    timer.Simple( 0, function()
        if IsValid( ent ) then
            ent:SetCreator( ply )
        end
    end)
end)