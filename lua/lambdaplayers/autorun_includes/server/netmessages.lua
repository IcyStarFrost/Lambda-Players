local IsValid = IsValid

-- Due to how some sound files are not .wav, Garry's Mod's SoundDuration() function is completely useless.
-- So we ask for the help of the client to send us the duration of the sound a Lambda Player is playing-
-- so we can do our part and prevent sounds from being played while one is already playing
net.Receive( "lambdaplayers_server_sendsoundduration", function( len, ply )
    local ent = net.ReadEntity()
    local dur = net.ReadFloat()

    if !IsValid( ent ) then return end
    ent:SetLastSpeakingTime( CurTime() + dur )
end )

net.Receive( "lambdaplayers_updateconvar", function( len, ply )
    if !ply:IsSuperAdmin() then return end
    local convar = net.ReadString()
    local val = net.ReadString()

    local cvar =  GetConVar( convar )

    if cvar and cvar:IsFlagSet( FCVAR_LUA_SERVER ) then cvar:SetString( val ) end
   
end )

net.Receive( "lambdaplayers_runconcommand", function( len, ply )
    if !ply:IsSuperAdmin() then return end
    local concmd = net.ReadString()

    concommand.Run( ply, concmd )
end )

net.Receive( "lambdaplayers_realplayerendvoice", function( len, ply )
    hook.Run( "LambdaOnRealPlayerEndVoice", ply )
end )

net.Receive( "lambdaplayers_onclosebirthdaypanel", function( len, ply )
    local month = net.ReadString()
    local day = net.ReadUInt( 5 )
    print( "Lambda Players: " .. ply:Name() .. " changed their birthday setting")
    if month == "NIL" then return end
    _LambdaPlayerBirthdays[ ply:SteamID() ] = { month = month, day = day }
end )