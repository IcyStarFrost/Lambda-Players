AddCSLuaFile()

if CLIENT then

TOOL.Information = {
    { name = "left" },
    { name = "right" },
}

    
language.Add("tool.lambdatexttester", "Text Line Tester")

language.Add("tool.lambdatexttester.name", "Text Line Tester")
language.Add("tool.lambdatexttester.desc", "Forces Lambda Players to type out/say a certain text chat message" )
language.Add("tool.lambdatexttester.left", "Fire onto a Lambda Player to force them to type a text type. See the tool's settings" )
language.Add("tool.lambdatexttester.right", "Fire onto a Lambda Player to force them to say a specific line. See the tool's settings" )

end

TOOL.Tab = "Lambda Player"
TOOL.Category = "Tools"
TOOL.Name = "#tool.lambdatexttester"
TOOL.ClientConVar = {
    [ "texttype" ] = "idle",
    [ "textline" ] = ""
}

local random = math.random

function TOOL:LeftClick( tr )
    local ent = tr.Entity
    local owner = self:GetOwner()
    if !IsValid( ent ) or !ent.IsLambdaPlayer then return end

    if SERVER then
        ent:TypeMessage( ent:GetTextLine( self:GetClientInfo( "texttype" ) ) )
    end

    return true
end


function TOOL:RightClick( tr )
    local ent = tr.Entity
    local owner = self:GetOwner()
    if !IsValid( ent ) or !ent.IsLambdaPlayer then return end

    if SERVER then
        ent:TypeMessage( self:GetClientInfo( "textline" ) )
    end

    return true
end

function TOOL.BuildCPanel( pnl )

    local box = pnl:ComboBox( "Text Type", "lambdatexttester_texttype" )

    for k, v in pairs( LambdaTextTable ) do
        box:AddChoice( k, k )
    end

    pnl:ControlHelp( "The Text Type to test with Left Click" )

    pnl:TextEntry( "Text Line", "lambdatexttester_textline" )
    pnl:ControlHelp( "The text to make a Lambda Player say with Right Click" )

end