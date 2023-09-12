
local canoverride = GetConVar( "lambdaplayers_lambda_overridegamemodehooks" )
local overridekillfeed = GetConVar( "lambdaplayers_lambda_overridedeathnoticehook" )
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
                self.Avatar = vgui.Create( "DImage", self )
                self.Avatar:SetMaterial( ply:GetPFPMat() )
            else
                self.Avatar = vgui.Create( "AvatarImage", self )
                self.Avatar:SetPlayer( ply )
            end

            self.Avatar:SetSize( 32, 32 )
            self.Avatar:Dock( LEFT )

            self.Color = team.GetColor( ply:IsPlayer() and ply:Team() or 0 )
            self:InvalidateLayout()
        end
        
        function PANEL:Paint( w, h )
            local ply = self.ply
            if !IsValid( ply ) then return end
            draw.RoundedBox( 4, 0, 0, w, h, Color( 0, ply:VoiceVolume() * 255, 0, 240 ) )
        end

        function PANEL:Think()
            if self.fadeAnim then self.fadeAnim:Run() end
            local ply = self.ply
            if IsValid( ply ) then self.LabelName:SetText( ply:Nick() ) end
        end
        
        function PANEL:FadeOut( anim, delta, data )
            if anim.Finished then
                local ply = self.ply
                local vcPanel = PlayerVoicePanels[ ply ]
                if IsValid( vcPanel ) then
                    vcPanel:Remove()
                    PlayerVoicePanels[ ply ] = nil
                end
                
                return 
            end
            
            self:SetAlpha( 255 - ( 255 * delta ) )
        end
        
        derma.DefineControl( "VoiceNotify", "", PANEL, "DPanel" )        
        
        function GAMEMODE:PlayerStartVoice( ply )
            if !IsValid( g_VoicePanelList ) or !IsValid( ply ) then return end
            
            -- There'd be an exta one if voice_loopback is on, so remove it.
            GAMEMODE:PlayerEndVoice( ply )

            local vcPanel = PlayerVoicePanels[ ply ]
            if IsValid( vcPanel ) then
                if vcPanel.fadeAnim then
                    vcPanel.fadeAnim:Stop()
                    vcPanel.fadeAnim = nil
                end
        
                vcPanel:SetAlpha( 255 )
                return
            end
                
            local pnl = g_VoicePanelList:Add( "VoiceNotify" )
            pnl:Setup( ply )
            PlayerVoicePanels[ ply ] = pnl
        end
        
        local function VoiceClean()
            for ply, _ in pairs( PlayerVoicePanels ) do
                if IsValid( ply ) then continue end
                GAMEMODE:PlayerEndVoice( ply )
            end
        end
        timer.Create( "VoiceClean", 10, 0, VoiceClean )

        function GAMEMODE:PlayerEndVoice( ply )
            local vcPanel = PlayerVoicePanels[ ply ]
            if !IsValid( vcPanel ) or vcPanel.fadeAnim then return end        
            vcPanel.fadeAnim = Derma_Anim( "FadeOut", vcPanel, vcPanel.FadeOut )
            vcPanel.fadeAnim:Start( 2 )
        end
        
        local function CreateVoiceVGUI()
            g_VoicePanelList = vgui.Create( "DPanel" )
            g_VoicePanelList:ParentToHUD()
            g_VoicePanelList:SetPos( ScrW() - 300, 100 )
            g_VoicePanelList:SetSize( 250, ScrH() - 200 )
            g_VoicePanelList:SetPaintBackground( false )
        end
        hook.Add( "InitPostEntity", "CreateVoiceVGUI", CreateVoiceVGUI )
        
        if overridekillfeed:GetBool() then
            local olddeathnoticehookfunc = GAMEMODE.AddDeathNotice

            function GAMEMODE:AddDeathNotice( attacker, attackerTeam, inflictor, victim, victimTeam, flags )
                if attacker == "#npc_lambdaplayer" then return end
                olddeathnoticehookfunc( self, attacker, attackerTeam, inflictor, victim, victimTeam, flags )
            end
        end
    end )
end

if ( CLIENT ) then return end

hook.Add( "Initialize", "lambdaplayers_overridegamemodehooks", function() 
    -- This fixes the issues of Lambda's health reaching below 0 and actually dying in internally
    local olddamagehookfunc = GAMEMODE.EntityTakeDamage
    function GAMEMODE:EntityTakeDamage( targ, dmg )
        local result = hook.Run( "LambdaTakeDamage", targ, dmg )
        if result == true then return true end
        olddamagehookfunc( self, targ, dmg )
    end

    if canoverride:GetBool() then
        function GAMEMODE:CreateEntityRagdoll( entity, ragdoll )
            if entity.IsLambdaPlayer then return end

            -- Replace the entity with the ragdoll in cleanups etc
            undo.ReplaceEntity( entity, ragdoll )
            cleanup.ReplaceEntity( entity, ragdoll )
        end

        _LambdaGamemodeHooksOverriden = true
    end
end )