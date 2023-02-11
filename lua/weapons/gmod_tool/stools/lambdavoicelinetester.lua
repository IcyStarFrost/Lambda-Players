
AddCSLuaFile()

if CLIENT then

TOOL.Information = {
    { name = "left" },
    { name = "right" },
}

    
language.Add("tool.lambdavoicelinetester", "Voice Line Tester")

language.Add("tool.lambdavoicelinetester.name", "Voice Line Tester")
language.Add("tool.lambdavoicelinetester.desc", "Forces Lambda Players to say certain voice lines" )
language.Add("tool.lambdavoicelinetester.left", "Fire onto a Lambda Player to force them to speak a voice type. See the tool's settings" )
language.Add("tool.lambdavoicelinetester.right", "Fire onto a Lambda Player to force them to say a specific sound file. See the tool's settings" )

end

TOOL.Tab = "Lambda Player"
TOOL.Category = "Tools"
TOOL.Name = "#tool.lambdavoicelinetester"
TOOL.ClientConVar = {
    [ "voicetype" ] = "idle",
    [ "voicelinepath" ] = ""
}


function TOOL:LeftClick( tr )
    local ent = tr.Entity
    local owner = self:GetOwner()
    if !IsValid( ent ) or !ent.IsLambdaPlayer then return end

    if SERVER then
        ent:PlaySoundFile( ent:GetVoiceLine( self:GetClientInfo( "voicetype" ) ) )
    end

    return true
end


function TOOL:RightClick( tr )
    local ent = tr.Entity
    local owner = self:GetOwner()
    if !IsValid( ent ) or !ent.IsLambdaPlayer then return end

    if SERVER then
        ent:PlaySoundFile( self:GetClientInfo( "voicelinepath" ) )
    end

    return true
end

function TOOL.BuildCPanel( pnl )

    local box = pnl:ComboBox( "Voice Type", "lambdavoicelinetester_voicetype" )

    for k, v in pairs( LambdaVoiceLinesTable ) do
        box:AddChoice( k, k )
    end

    pnl:ControlHelp( "The Voice Type to test with Left Click" )

    pnl:TextEntry( "Sound Path", "lambdavoicelinetester_voicelinepath" )
    pnl:ControlHelp( "The Sound File to test with Right Click" )

end