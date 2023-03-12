
local canoverride = GetConVar( "lambdaplayers_lambda_overridegamemodehooks" )
_LambdaGamemodeHooksOverriden = _LambdaGamemodeHooksOverriden or false

if CLIENT then
    if !canoverride:GetBool() then return end
    local table_Add = table.Add
    local draw = draw
    local CurTime = CurTime
    local math = math
    local sub = string.sub
    local Material = Material

    hook.Add( "Initialize", "lambdaplayers_overridegamemodehooks", function() 

        local PLAYER_LINE = {
            Init = function( self )
        
                self.AvatarButton = self:Add( "DButton" )
                self.AvatarButton:Dock( LEFT )
                self.AvatarButton:SetSize( 32, 32 )
                self.AvatarButton.DoClick = function() if self.Player.IsLambdaPlayer then return end self.Player:ShowProfile() end
        
                self.Avatar = vgui.Create( "AvatarImage", self.AvatarButton )
                self.Avatar:SetSize( 32, 32 )
                self.Avatar:SetMouseInputEnabled( false )

                self.LambdaAvatar = vgui.Create( "DImage", self.AvatarButton )
                self.LambdaAvatar:SetSize( 32, 32 )
                self.LambdaAvatar:SetMouseInputEnabled( false )
                self.LambdaAvatar:Hide()
        
                self.Name = self:Add( "DLabel" )
                self.Name:Dock( FILL )
                self.Name:SetFont( "ScoreboardDefault" )
                self.Name:SetTextColor( Color( 93, 93, 93 ) )
                self.Name:DockMargin( 8, 0, 0, 0 )
        
                self.Mute = self:Add( "DImageButton" )
                self.Mute:SetSize( 32, 32 )
                self.Mute:Dock( RIGHT )
        
                self.Ping = self:Add( "DLabel" )
                self.Ping:Dock( RIGHT )
                self.Ping:SetWidth( 50 )
                self.Ping:SetFont( "ScoreboardDefault" )
                self.Ping:SetTextColor( Color( 93, 93, 93 ) )
                self.Ping:SetContentAlignment( 5 )
        
                self.Deaths = self:Add( "DLabel" )
                self.Deaths:Dock( RIGHT )
                self.Deaths:SetWidth( 50 )
                self.Deaths:SetFont( "ScoreboardDefault" )
                self.Deaths:SetTextColor( Color( 93, 93, 93 ) )
                self.Deaths:SetContentAlignment( 5 )
        
                self.Kills = self:Add( "DLabel" )
                self.Kills:Dock( RIGHT )
                self.Kills:SetWidth( 50 )
                self.Kills:SetFont( "ScoreboardDefault" )
                self.Kills:SetTextColor( Color( 93, 93, 93 ) )
                self.Kills:SetContentAlignment( 5 )
        
                self:Dock( TOP )
                self:DockPadding( 3, 3, 3, 3 )
                self:SetHeight( 32 + 3 * 2 )
                self:DockMargin( 2, 0, 2, 2 )
        
            end,
        
            Setup = function( self, pl )
        
                self.Player = pl
        
                if !pl.IsLambdaPlayer then
                    self.Avatar:SetPlayer( pl )
                else
                    self.LambdaAvatar:SetMaterial( pl:GetPFPMat() )
                    self.LambdaAvatar:Show()
                end
                
                self:Think( self )
        
                --local friend = self.Player:GetFriendStatus()
                --MsgN( pl, " Friend: ", friend )
        
            end,
        
            Think = function( self )
        
                if ( !IsValid( self.Player ) ) then
                    self:SetZPos( 9999 ) -- Causes a rebuild
                    self:Remove()
                    return
                end
        
                if ( self.PName == nil or self.PName != self.Player:Nick() ) then
                    self.PName = self.Player:Nick()
                    self.Name:SetText( self.PName )
                end
        
                if ( self.NumKills == nil or self.NumKills != self.Player:Frags() ) then
                    self.NumKills = self.Player:Frags()
                    self.Kills:SetText( self.NumKills )
                end
        
                if ( self.NumDeaths == nil or self.NumDeaths != self.Player:Deaths() ) then
                    self.NumDeaths = self.Player:Deaths()
                    self.Deaths:SetText( self.NumDeaths )
                end
        
                if ( self.NumPing == nil or self.NumPing != self.Player:Ping() ) then
                    self.NumPing = self.Player:Ping()
                    self.Ping:SetText( self.NumPing )
                end
        
                --
                -- Change the icon of the mute button based on state
                --
                if ( self.Muted == nil or self.Muted != self.Player:IsMuted() ) then
        
                    self.Muted = self.Player:IsMuted()
                    if ( self.Muted ) then
                        self.Mute:SetImage( "icon32/muted.png" )
                    else
                        self.Mute:SetImage( "icon32/unmuted.png" )
                    end
        
                    self.Mute.DoClick = function( s ) self.Player:SetMuted( !self.Muted ) end
                    self.Mute.OnMouseWheeled = function( s, delta )
                        self.Player:SetVoiceVolumeScale( self.Player:GetVoiceVolumeScale() + ( delta / 100 * 5 ) )
                        s.LastTick = CurTime()
                    end
        
                    self.Mute.PaintOver = function( s, w, h )
                        if ( !IsValid( self.Player ) ) then return end
                    
                        local a = 255 - math.Clamp( CurTime() - ( s.LastTick or 0 ), 0, 3 ) * 255
                        if ( a <= 0 ) then return end
                        
                        draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, a * 0.75 ) )
                        draw.SimpleText( math.ceil( self.Player:GetVoiceVolumeScale() * 100 ) .. "%", "DermaDefaultBold", w / 2, h / 2, Color( 255, 255, 255, a ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
                    end
        
                end
        
                --
                -- Connecting players go at the very bottom
                --
                if ( self.Player:IsPlayer() and self.Player:Team() == TEAM_CONNECTING ) then
                    self:SetZPos( 2000 + self.Player:EntIndex() )
                    return
                end
        
                --
                -- This is what sorts the list. The panels are docked in the z order,
                -- so if we set the z order according to kills they'll be ordered that way!
                -- Careful though, it's a signed short internally, so needs to range between -32,768k and +32,767
                --
                self:SetZPos( ( self.NumKills * -50 ) + self.NumDeaths + self.Player:EntIndex() )
        
            end,
        
            Paint = function( self, w, h )
        
                if ( !IsValid( self.Player ) ) then
                    return
                end
        
                --
                -- We draw our background a different colour based on the status of the player
                --
        
                if ( self.Player:IsPlayer() and self.Player:Team() == TEAM_CONNECTING ) then
                    draw.RoundedBox( 4, 0, 0, w, h, Color( 200, 200, 200, 200 ) )
                    return
                end
        
                if ( !self.Player:Alive() ) then
                    draw.RoundedBox( 4, 0, 0, w, h, Color( 230, 200, 200, 255 ) )
                    return
                end
        
                if ( self.Player:IsPlayer() and self.Player:IsAdmin() ) then
                    draw.RoundedBox( 4, 0, 0, w, h, Color( 230, 255, 230, 255 ) )
                    return
                end
        
                draw.RoundedBox( 4, 0, 0, w, h, Color( 230, 230, 230, 255 ) )
        
            end
        }
        
        --
        -- Convert it from a normal table into a Panel Table based on DPanel
        --
        PLAYER_LINE = vgui.RegisterTable( PLAYER_LINE, "DPanel" )



        local SCORE_BOARD = {
            Init = function( self )

                self.Header = self:Add( "Panel" )
                self.Header:Dock( TOP )
                self.Header:SetHeight( 100 )
        
                self.Name = self.Header:Add( "DLabel" )
                self.Name:SetFont( "ScoreboardDefaultTitle" )
                self.Name:SetTextColor( color_white )
                self.Name:Dock( TOP )
                self.Name:SetHeight( 40 )
                self.Name:SetContentAlignment( 5 )
                self.Name:SetExpensiveShadow( 2, Color( 0, 0, 0, 200 ) )
        
                --self.NumPlayers = self.Header:Add( "DLabel" )
                --self.NumPlayers:SetFont( "ScoreboardDefault" )
                --self.NumPlayers:SetTextColor( color_white )
                --self.NumPlayers:SetPos( 0, 100 - 30 )
                --self.NumPlayers:SetSize( 300, 30 )
                --self.NumPlayers:SetContentAlignment( 4 )
        
                self.Scores = self:Add( "DScrollPanel" )
                self.Scores:Dock( FILL )
        
            end,
        
            PerformLayout = function( self )
        
                self:SetSize( 700, ScrH() - 200 )
                self:SetPos( ScrW() / 2 - 350, 100 )
        
            end,
        
            Paint = function( self, w, h )
        
                --draw.RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, 200 ) )
        
            end,
        
            Think = function( self, w, h )
        
                self.Name:SetText( GetHostName() )
        
                --
                -- Loop through each player, and if one doesn't have a score entry - create it.
                --
                local plyrs = player.GetAll()
                local lambda = GetLambdaPlayers()
                table_Add( plyrs, lambda )

                for id, pl in pairs( plyrs ) do
                    if ( IsValid( pl.ScoreEntry ) ) then continue end
        
                    pl.ScoreEntry = vgui.CreateFromTable( PLAYER_LINE, pl.ScoreEntry )
                    pl.ScoreEntry:Setup( pl )
        
                    self.Scores:AddItem( pl.ScoreEntry )
        
                end
        
            end
        }

        SCORE_BOARD = vgui.RegisterTable( SCORE_BOARD, "EditablePanel" )

        function GAMEMODE:ScoreboardShow()

            if ( !IsValid( g_Scoreboard ) ) then
                g_Scoreboard = vgui.CreateFromTable( SCORE_BOARD )
            end
        
            if ( IsValid( g_Scoreboard ) ) then
                g_Scoreboard:Show()
                g_Scoreboard:MakePopup()
                g_Scoreboard:SetKeyboardInputEnabled( false )
            end
        
        end
        function GAMEMODE:ScoreboardHide()
        
            if ( IsValid( g_Scoreboard ) ) then
                g_Scoreboard:Hide()
            end
        
        end








        local PANEL = {}
        local PlayerVoicePanels = {}
        
        function PANEL:Init()
        
            self.LabelName = vgui.Create( "DLabel", self )
            self.LabelName:SetFont( "GModNotify" )
            self.LabelName:Dock( FILL )
            self.LabelName:DockMargin( 8, 0, 0, 0 )
            self.LabelName:SetTextColor( color_white )
        
            self.Avatar = vgui.Create( "AvatarImage", self )
            self.Avatar:Dock( LEFT )
            self.Avatar:SetSize( 32, 32 )
        
            self.Color = color_transparent
        
            self:SetSize( 250, 32 + 8 )
            self:DockPadding( 4, 4, 4, 4 )
            self:DockMargin( 2, 2, 2, 2 )
            self:Dock( BOTTOM )
        
        end
        
        function PANEL:Setup( ply )
        
            self.ply = ply
            self.LabelName:SetText( ply:Nick() )
    
            if ply.IsLambdaPlayer then
                self.Avatar:Remove()
                self.LambdaAvatar = vgui.Create( "DImage", self )
                self.LambdaAvatar:SetSize( 32, 32 )
                self.LambdaAvatar:Dock( LEFT )
                self.LambdaAvatar:SetMaterial( ply:GetPFPMat() )
            else
                self.Avatar:SetPlayer( ply )
            end
    
            self.Color = team.GetColor( ply:IsPlayer() and ply:Team() or 0 )
            
            self:InvalidateLayout()
        
        end
        
        function PANEL:Paint( w, h )
        
            if ( !IsValid( self.ply ) ) then return end
            draw.RoundedBox( 4, 0, 0, w, h, Color( 0, self.ply:VoiceVolume() * 255, 0, 240 ) )
        
        end
        
        function PANEL:Think()
            
            if ( IsValid( self.ply ) ) then
                self.LabelName:SetText( self.ply:Nick() )
            end
        
            if ( self.fadeAnim ) then
                self.fadeAnim:Run()
            end
        
        end
        
        function PANEL:FadeOut( anim, delta, data )
            
            if ( anim.Finished ) then
            
                if ( IsValid( PlayerVoicePanels[ self.ply ] ) ) then
                    PlayerVoicePanels[ self.ply ]:Remove()
                    PlayerVoicePanels[ self.ply ] = nil
                    return
                end
                
            return end
            
            self:SetAlpha( 255 - ( 255 * delta ) )
        
        end
        
        derma.DefineControl( "VoiceNotify", "", PANEL, "DPanel" )
        
        
        
        function GAMEMODE:PlayerStartVoice( ply )
        
            if ( !IsValid( g_VoicePanelList ) ) then return end
            
            -- There'd be an exta one if voice_loopback is on, so remove it.
            GAMEMODE:PlayerEndVoice( ply )
        
        
            if ( IsValid( PlayerVoicePanels[ ply ] ) ) then
        
                if ( PlayerVoicePanels[ ply ].fadeAnim ) then
                    PlayerVoicePanels[ ply ].fadeAnim:Stop()
                    PlayerVoicePanels[ ply ].fadeAnim = nil
                end
        
                PlayerVoicePanels[ ply ]:SetAlpha( 255 )
        
                return
        
            end
        
            if ( !IsValid( ply ) ) then return end
        
            local pnl = g_VoicePanelList:Add( "VoiceNotify" )
            pnl:Setup( ply )
            
            PlayerVoicePanels[ ply ] = pnl
        
        end
        
        local function VoiceClean()
        
            for k, v in pairs( PlayerVoicePanels ) do
            
                if ( !IsValid( k ) ) then
                    GAMEMODE:PlayerEndVoice( k )
                end
            
            end
        
        end
        timer.Create( "VoiceClean", 10, 0, VoiceClean )
        
        function GAMEMODE:PlayerEndVoice( ply )
        
            if ( IsValid( PlayerVoicePanels[ ply ] ) ) then
        
                if ( PlayerVoicePanels[ ply ].fadeAnim ) then return end
        
                PlayerVoicePanels[ ply ].fadeAnim = Derma_Anim( "FadeOut", PlayerVoicePanels[ ply ], PlayerVoicePanels[ ply ].FadeOut )
                PlayerVoicePanels[ ply ].fadeAnim:Start( 2 )
        
            end
        
        end
        
        local function CreateVoiceVGUI()
        
            g_VoicePanelList = vgui.Create( "DPanel" )
        
            g_VoicePanelList:ParentToHUD()
            g_VoicePanelList:SetPos( ScrW() - 300, 100 )
            g_VoicePanelList:SetSize( 250, ScrH() - 200 )
            g_VoicePanelList:SetPaintBackground( false )
        
        end
        
        hook.Add( "InitPostEntity", "CreateVoiceVGUI", CreateVoiceVGUI )


    end )




end





if CLIENT then return end



hook.Add( "Initialize", "lambdaplayers_overridegamemodehooks", function() 

    -- This fixes the issues of Lambda's health reaching below 0 and actually dying in internally
    local olddamagehookfunc = GAMEMODE.EntityTakeDamage
    function GAMEMODE:EntityTakeDamage( targ, dmg )
        local result = hook.Run( "LambdaTakeDamage", targ, dmg )
        if result == true then return true end
        olddamagehookfunc( self, targ, dmg )
    end

    if canoverride:GetBool() then

        function GAMEMODE:PlayerDeath( ply, inflictor, attacker )

            -- Don't spawn for at least 2 seconds
            ply.NextSpawnTime = CurTime() + 2
            ply.DeathTime = CurTime()

            if ( IsValid( attacker ) and attacker:GetClass() == "trigger_hurt" ) then attacker = ply end

            if ( IsValid( attacker ) and attacker:IsVehicle() and IsValid( attacker:GetDriver() ) ) then
                attacker = attacker:GetDriver()
            end

            if ( !IsValid( inflictor ) and IsValid( attacker ) ) then
                inflictor = attacker
            end

            -- Convert the inflictor to the weapon that they're holding if we can.
            -- This can be right or wrong with NPCs since combine can be holding a
            -- pistol but kill you by hitting you with their arm.
            if ( IsValid( inflictor ) and inflictor == attacker and ( inflictor:IsPlayer() or inflictor:IsNPC() ) ) then

                inflictor = inflictor:GetActiveWeapon()
                if ( !IsValid( inflictor ) ) then inflictor = attacker end

            end

            player_manager.RunClass( ply, "Death", inflictor, attacker )

            if ( attacker == ply ) then

                net.Start( "PlayerKilledSelf" )
                    net.WriteEntity( ply )
                net.Broadcast()

                MsgAll( attacker:Nick() .. " suicided!\n" )

            return end

            if ( attacker:IsPlayer() ) then

                net.Start( "PlayerKilledByPlayer" )

                    net.WriteEntity( ply )
                    net.WriteString( inflictor:GetClass() )
                    net.WriteEntity( attacker )

                net.Broadcast()

                MsgAll( attacker:Nick() .. " killed " .. ply:Nick() .. " using " .. inflictor:GetClass() .. "\n" )

            return end

            if !attacker.IsLambdaPlayer then
                net.Start( "PlayerKilled" )

                    net.WriteEntity( ply )
                    net.WriteString( inflictor:GetClass() )
                    net.WriteString( attacker:GetClass() )

                net.Broadcast()
            end

            MsgAll( ply:Nick() .. " was killed by " .. attacker:GetClass() .. "\n" )

        end

        function GAMEMODE:OnNPCKilled( ent, attacker, inflictor )

            -- Don't spam the killfeed with scripted stuff
            if ( ent:GetClass() == "npc_bullseye" or ent:GetClass() == "npc_launcher" ) then return end
        
            if ( IsValid( attacker ) and attacker:GetClass() == "trigger_hurt" ) then attacker = ent end
            
            if ( IsValid( attacker ) and attacker:IsVehicle() and IsValid( attacker:GetDriver() ) ) then
                attacker = attacker:GetDriver()
            end
        
            if ( !IsValid( inflictor ) and IsValid( attacker ) ) then
                inflictor = attacker
            end
            
            -- Convert the inflictor to the weapon that they're holding if we can.
            if ( IsValid( inflictor ) and attacker == inflictor and ( inflictor:IsPlayer() or inflictor:IsNPC() ) ) then
            
                inflictor = inflictor:GetActiveWeapon()
                if ( !IsValid( attacker ) ) then inflictor = attacker end
            
            end
            
            local InflictorClass = "worldspawn"
            local AttackerClass = "worldspawn"
            
            if ( IsValid( inflictor ) ) then InflictorClass = inflictor:GetClass() end
            if ( IsValid( attacker ) and !ent.IsLambdaPlayer and !attacker.IsLambdaPlayer ) then
        
                AttackerClass = attacker:GetClass()
            
                if ( attacker:IsPlayer() ) then
        
                    net.Start( "PlayerKilledNPC" )
                
                        net.WriteString( ent:GetClass() )
                        net.WriteString( InflictorClass )
                        net.WriteEntity( attacker )
                
                    net.Broadcast()
        
                    return
                end
        
            end
        
            if ( ent:GetClass() == "npc_turret_floor" ) then AttackerClass = ent:GetClass() end

            if ent.IsLambdaPlayer or attacker.IsLambdaPlayer then return end
        
            net.Start( "NPCKilledNPC" )
            
                net.WriteString( ent:GetClass() )
                net.WriteString( InflictorClass )
                net.WriteString( AttackerClass )
            
            net.Broadcast()
        
        end

        function GAMEMODE:CreateEntityRagdoll( entity, ragdoll )
        
            if entity.IsLambdaPlayer then return end

            -- Replace the entity with the ragdoll in cleanups etc
            undo.ReplaceEntity( entity, ragdoll )
            cleanup.ReplaceEntity( entity, ragdoll )
        
        end

        _LambdaGamemodeHooksOverriden = true

    end
end )