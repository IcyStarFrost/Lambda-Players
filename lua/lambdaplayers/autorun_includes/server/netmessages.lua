local IsValid = IsValid
net.Receive( "lambdaplayers_server_sendsoundduration", function( len, ply )
    local ent = net.ReadEntity()
    local dur = net.ReadFloat()

    if !IsValid( ent ) then return end
    ent.l_lastspeakingtime = CurTime() + dur
end )