local IsValid = IsValid

-- Due to how some sound files are not .wav, Garry's Mod's SoundDuration() function is completely useless.
-- So we ask for the help of the client to send us the duration of the sound a lambda player is playing-
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
    GetConVar( convar ):SetString( val )
end )