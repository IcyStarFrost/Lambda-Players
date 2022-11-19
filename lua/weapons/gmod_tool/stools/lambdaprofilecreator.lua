
AddCSLuaFile()

if CLIENT then

TOOL.Information = {
    { name = "left" },
}

    
language.Add("tool.lambdaprofilecreator", "Lambda Profile Creator")

language.Add("tool.lambdaprofilecreator.name", "Lambda Profile Creator")
language.Add("tool.lambdaprofilecreator.desc", "Creates a Profile to your Lambda Profiles" )
language.Add("tool.lambdaprofilecreator.left", "Fire onto a Lambda Player to create a Profile of them" )

end

TOOL.Tab = "Lambda Player"
TOOL.Category = "Tools"
TOOL.Name = "#tool.lambdaprofilecreator"


function TOOL:LeftClick( tr )
    local ent = tr.Entity
    local owner = self:GetOwner()
    if !IsValid( ent ) then return end
    if !ent.IsLambdaPlayer then return end
    
    if SERVER and owner:IsListenServerHost() then
        local info = ent:ExportLambdaInfo()
        LambdaPlayers_ChatAdd( owner, "Saved " .. info.name .. " to your profiles" )
        LAMBDAFS:UpdateKeyValueFile( "lambdaplayers/profiles.json", { [ info.name ] = info }, "json" ) 
    elseif CLIENT then
        local info = ent:ExportLambdaInfo()
        chat.AddText( "Saved " .. info.name .. " to your profiles" )
        LAMBDAFS:UpdateKeyValueFile( "lambdaplayers/profiles.json", { [ info.name ] = info }, "json" ) 
    end


   
    return true
end