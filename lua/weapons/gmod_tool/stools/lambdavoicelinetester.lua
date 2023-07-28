AddCSLuaFile()

if ( CLIENT ) then
    TOOL.Information = { { name = "left" }, { name = "right" } }
    
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

local pairs = pairs

function TOOL:LeftClick( tr )
    local ent = tr.Entity
    if !LambdaIsValid( ent ) or !ent.IsLambdaPlayer then return false end

    if ( SERVER ) then ent:PlaySoundFile( self:GetClientInfo( "voicetype" ) ) end
    return true
end

function TOOL:RightClick( tr )
    local ent = tr.Entity
    if !LambdaIsValid( ent ) or !ent.IsLambdaPlayer then return false end

    if ( SERVER ) then ent:PlaySoundFile( self:GetClientInfo( "voicelinepath" ) ) end
    return true
end

function TOOL.BuildCPanel( pnl )
    local box = pnl:ComboBox( "Voice Type", "lambdavoicelinetester_voicetype" )
    for vType, _ in pairs( LambdaVoiceLinesTable ) do box:AddChoice( vType, vType ) end
    pnl:ControlHelp( "The Voice Type to test with Left Click" )

    pnl:TextEntry( "Sound Path", "lambdavoicelinetester_voicelinepath" )
    pnl:ControlHelp( "The Sound File to test with Right Click" )
end