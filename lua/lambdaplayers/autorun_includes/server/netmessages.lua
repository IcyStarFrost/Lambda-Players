local IsValid = IsValid
local isfunction = isfunction
local GetConVar = GetConVar
local net = net
local print = print
local CurTime = CurTime
local concommand_Run = concommand.Run
local hook_Run = hook.Run

-- Due to how some sound files are not .wav, Garry's Mod's SoundDuration() function is completely useless.
-- So we ask for the help of the client to send us the duration of the sound a Lambda Player is playing-
-- so we can do our part and prevent sounds from being played while one is already playing
net.Receive( "lambdaplayers_server_sendsoundduration", function( len, ply )
    local ent = net.ReadEntity()
    if !IsValid( ent ) then return end
    ent:SetLastSpeakingTime( CurTime() + net.ReadFloat() )
end )

net.Receive( "lambdaplayers_updateconvar", function( len, ply )
    if !ply:IsSuperAdmin() then return end
    local cvar = GetConVar( net.ReadString() )
    if cvar and cvar:IsFlagSet( FCVAR_LUA_SERVER ) then cvar:SetString( net.ReadString() ) end
end )

net.Receive( "lambdaplayers_runconcommand", function( len, ply )
    if !ply:IsSuperAdmin() then return end
    concommand_Run( ply, net.ReadString() )
end )

net.Receive( "lambdaplayers_realplayerendvoice", function( len, ply )
    hook_Run( "LambdaOnRealPlayerEndVoice", ply )
end )

net.Receive( "lambdaplayers_onclosebirthdaypanel", function( len, ply )
    local month = net.ReadString()
    if month == "NIL" then return end

    print( "Lambda Players: " .. ply:Name() .. " changed their birthday setting")
    _LambdaPlayerBirthdays[ ply:SteamID() ] = { month = month, day = net.ReadUInt( 5 ) }
end )

net.Receive( "lambdaplayers_server_getpos", function( len, ply )
    local ent = net.ReadEntity()
    if !IsValid( ent ) or !isfunction( ent.GetPos ) then return end

    net.Start( "lambdaplayers_server_sendpos" )
        net.WriteVector( net.ReadBool() and ent:GetPos() or ent:WorldSpaceCenter() )
    net.Broadcast()
end )