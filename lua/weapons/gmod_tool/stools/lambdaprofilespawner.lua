AddCSLuaFile()

if ( CLIENT ) then
    TOOL.Information = { { name = "left" } }

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
local pairs = pairs
local spawnAng = Angle( 0, 0, 0 )

function TOOL:LeftClick( tr )
    local profileTbl = LambdaPersonalProfiles
    if !profileTbl or isempty( profileTbl ) then return false end

    if ( SERVER ) then
        local owner = self:GetOwner()
        local profilename = self:GetClientInfo( "profilename" )
        local profileinfo = profileTbl[ profilename ]

        if profileinfo then
            local lambda = ents.Create( "npc_lambdaplayer" )
            lambda:SetPos( tr.HitPos )
            lambda:SetCreator( owner )
            lambda.l_NoRandomModel = true

            spawnAng.y = owner:EyeAngles().y
            lambda:SetAngles( spawnAng )
            lambda:Spawn()

            lambda:SetRespawn( self:GetClientNumber( "respawn", 0 ) == 1 )
            lambda:ApplyLambdaInfo( profileinfo )
            lambda:SimpleTimer( 0, function() LambdaRunHook( "LambdaOnProfileApplied", lambda, profileinfo ) end, true )
        else
            LambdaPlayers_ChatAdd( owner, profilename .. "'s profile data does not exist on the Server"  )
            return false
        end
    end
   
    return true
end

function TOOL.BuildCPanel( pnl )
    pnl:Help( "NOTE: Profiles listed here are only found and loaded on your PC! This means some profiles will not work if the Server doesn't have it" )

    pnl:CheckBox( "Respawn", "lambdaprofilespawner_respawn" )
    pnl:ControlHelp( "If the Lambda spawned should be able to respawn" )

    local box = pnl:ComboBox( "Profile Name", "lambdaprofilespawner_profilename" )

    local profileTbl = LambdaPersonalProfiles
    if profileTbl then for name, _ in pairs( profileTbl ) do box:AddChoice( name, name ) end end

    pnl:ControlHelp( "The Profile to spawn with Left Click" )

    local update = vgui.Create( "DButton", pnl )
    update:SetText( "Update Profile List" )
    pnl:AddItem( update )

    function update:DoClick()
        box:Clear()
        if profileTbl then for name, _ in pairs( profileTbl ) do box:AddChoice( name, name ) end end
    end
end