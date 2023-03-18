
AddCSLuaFile()

if CLIENT then

TOOL.Information = {
    { name = "left" },
}

    
language.Add("tool.lambdaprofilespawner", "Lambda Profile Spawner")

language.Add("tool.lambdaprofilespawner.name", "Lambda Profile Spawner")
language.Add("tool.lambdaprofilespawner.desc", "Spawns a Lambda Player of the specified Profile" )
language.Add("tool.lambdaprofilespawner.left", "Fire any where to spawn a Profile Lambda Player" )

end

TOOL.Tab = "Lambda Player"
TOOL.Category = "Tools"
TOOL.Name = "#tool.lambdaprofilespawner"
TOOL.ClientConVar = {
    [ "profilename" ] = "",
    [ "respawn" ] = "1"
}


local isempty = table.IsEmpty

function TOOL:LeftClick( tr )
    local owner = self:GetOwner()

    if SERVER and LambdaPersonalProfiles and !isempty( LambdaPersonalProfiles ) then
        local profileinfo = LambdaPersonalProfiles[ self:GetClientInfo( "profilename" ) ]

        if profileinfo then
            local lambda = ents.Create( "npc_lambdaplayer" )
            lambda:SetPos( tr.HitPos )
            lambda:SetAngles( Angle( 0, owner:EyeAngles().y, 0 ) )
            lambda:SetCreator( owner )
            lambda:Spawn()

            lambda:SetRespawn( self:GetClientNumber( "respawn", 0 ) == 1 )
        
            lambda:ApplyLambdaInfo( profileinfo )
            lambda:SimpleTimer( 0, function() LambdaRunHook( "LambdaOnProfileApplied", lambda, info ) end, true )
        else
            LambdaPlayers_ChatAdd( owner, self:GetClientInfo( "profilename" ) .. "'s profile data does not exist on the Server"  )
        end
    end

   
    return true
end

function TOOL.BuildCPanel( pnl )
    pnl:Help( "NOTE: Profiles listed here are only found and loaded on your PC! This means some profiles will not work if the Server doesn't have it")

    pnl:CheckBox( "Respawn", "lambdaprofilespawner_respawn" )
    pnl:ControlHelp( "If the Lambda spawned should be able to respawn" )

    local box = pnl:ComboBox( "Profile Name", "lambdaprofilespawner_profilename" )

    if LambdaPersonalProfiles and !isempty( LambdaPersonalProfiles ) then
        for name, info in pairs( LambdaPersonalProfiles ) do
            box:AddChoice( name, name )
        end
    end

    pnl:ControlHelp( "The Profile to spawn with Left Click" )

    local update = vgui.Create( "DButton", pnl )
    update:SetText( "Update Profile List" )
    pnl:AddItem( update )

    function update:DoClick()
        box:Clear()

        if LambdaPersonalProfiles and !isempty( LambdaPersonalProfiles ) then
            for name, info in pairs( LambdaPersonalProfiles ) do
                box:AddChoice( name, name )
            end
        end
    end


end