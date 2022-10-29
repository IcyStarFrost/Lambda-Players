
local IsValid = IsValid
local placeholdercolor = Color( 255,136,0)

if SERVER then

    local hitScales = {
        [HITGROUP_HEAD]     = GetConVar("sk_player_head"),
        [HITGROUP_LEFTARM]  = GetConVar("sk_player_arm"),
        [HITGROUP_RIGHTARM] = GetConVar("sk_player_arm"),
        [HITGROUP_CHEST]    = GetConVar("sk_player_chest"),
        [HITGROUP_STOMACH]  = GetConVar("sk_player_stomach"),
        [HITGROUP_LEFTLEG]  = GetConVar("sk_player_leg"),
        [HITGROUP_RIGHTARM] = GetConVar("sk_player_leg")
    }
    hook.Add("ScalePlayerDamage", "LambdaPlayers_DmgScale", function( ply,hit,dmginfo )
        if !ply.IsLambdaPlayer or !dmginfo:IsBulletDamage() then return end
        if hit == HITGROUP_HEAD then
            dmginfo:ScaleDamage( 0.5 )
        elseif hit == HITGROUP_LEFTARM or hit == HITGROUP_RIGHTARM or hit == HITGROUP_LEFTLEG or hit == HITGROUP_RIGHTLEG then
            dmginfo:ScaleDamage( 4 )
        end
        dmginfo:ScaleDamage( ( hitScales[ hit ] and hitScales[ hit ]:GetFloat() or 1.0 ) )
    end)

elseif CLIENT then
    

    hook.Add( "HUDPaint", "LambdaPlayers_NameDisplay", function()
        local sw, sh = ScrW(), ScrH()
        local traceent = LocalPlayer():GetEyeTrace().Entity


        if IsValid( traceent ) and traceent.IsLambdaPlayer then
            local name = traceent:GetLambdaName()
            local colvec = traceent:GetPlyColor()

            draw.DrawText(name, "lambdaplayers_displayname", sw / 2, sh / 1.95, placeholdercolor, TEXT_ALIGN_CENTER)
        end
    
    end )


end