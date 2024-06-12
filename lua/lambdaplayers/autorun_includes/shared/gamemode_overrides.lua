local canoverride = GetConVar( "lambdaplayers_lambda_overridegamemodehooks" )
_LambdaGamemodeHooksOverriden = ( _LambdaGamemodeHooksOverriden or false )

local IsValid = IsValid

if ( CLIENT ) then
    if !canoverride:GetBool() then return end

    local table_Add = table.Add
    local ipairs = ipairs
    local CurTime = CurTime
    local Color = Color
    local Clamp = math.Clamp
    local ceil = math.ceil
    local RoundedBox = draw.RoundedBox
    local SimpleText = draw.SimpleText
    local player_GetAll = player.GetAll

    local overridekillfeed = GetConVar( "lambdaplayers_lambda_overridedeathnoticehook" )
    local voicepopupx = GetConVar( "lambdaplayers_voice_voicepopupoffset_x" )
    local voicepopupy = GetConVar( "lambdaplayers_voice_voicepopupoffset_y" )
    
    local scoreBoardClr1 = Color( 93, 93, 93 )
    local scoreBoardClr2 = Color( 0, 0, 0, 200 )
    local statusClr_Connecting = Color( 200, 200, 200, 200 )
    local statusClr_Dead = Color( 230, 200, 200, 255 )
    local statusClr_Admin = Color( 230, 255, 230, 255 )
    local statusClr_Default = Color( 230, 230, 230, 255 )

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
                self.Name:SetTextColor( scoreBoardClr1 )
                self.Name:DockMargin( 8, 0, 0, 0 )
        
                self.Mute = self:Add( "DImageButton" )
                self.Mute:SetSize( 32, 32 )
                self.Mute:Dock( RIGHT )
        
                self.Ping = self:Add( "DLabel" )
                self.Ping:Dock( RIGHT )
                self.Ping:SetWidth( 50 )
                self.Ping:SetFont( "ScoreboardDefault" )
                self.Ping:SetTextColor( scoreBoardClr1 )
                self.Ping:SetContentAlignment( 5 )
        
                self.Deaths = self:Add( "DLabel" )
                self.Deaths:Dock( RIGHT )
                self.Deaths:SetWidth( 50 )
                self.Deaths:SetFont( "ScoreboardDefault" )
                self.Deaths:SetTextColor( scoreBoardClr1 )
                self.Deaths:SetContentAlignment( 5 )
        
                self.Kills = self:Add( "DLabel" )
                self.Kills:Dock( RIGHT )
                self.Kills:SetWidth( 50 )
                self.Kills:SetFont( "ScoreboardDefault" )
                self.Kills:SetTextColor( scoreBoardClr1 )
                self.Kills:SetContentAlignment( 5 )
        
                self:Dock( TOP )
                self:DockPadding( 3, 3, 3, 3 )
                self:SetHeight( 32 + 3 * 2 )
                self:DockMargin( 2, 0, 2, 2 )
            end,
        
            Setup = function( self, ply )
                self.Player = ply

                if !ply.IsLambdaPlayer then
                    self.Avatar:SetPlayer( ply )
                else
                    ply.ScoreEntry = self
                    local pfpMat = ply:GetPFPMat()
                    self.LastLambdaPfp = pfpMat
                    self.LambdaAvatar:SetMaterial( pfpMat )
                    self.LambdaAvatar:Show()
                end
                
                self:Think( self )
            end,
        
            Think = function( self )
                local ply = self.Player
                if !IsValid( ply ) then
                    self:SetZPos( 9999 ) -- Causes a rebuild
                    self:Remove()
                    return
                end

                if self.PName == nil or self.PName != ply:Nick() then
                    self.PName = ply:Nick()
                    self.Name:SetText( self.PName )
                end
                if self.NumKills == nil or self.NumKills != ply:Frags() then
                    self.NumKills = ply:Frags()
                    self.Kills:SetText( self.NumKills )
                end
                if self.NumDeaths == nil or self.NumDeaths != ply:Deaths() then
                    self.NumDeaths = ply:Deaths()
                    self.Deaths:SetText( self.NumDeaths )
                end
                if self.NumPing == nil or self.NumPing != ply:Ping() then
                    self.NumPing = ply:Ping()
                    self.Ping:SetText( self.NumPing )
                end

                -- Change the icon of the mute button based on state
                local isMuted = ply:IsMuted()
                if self.Muted == nil or self.Muted != isMuted then
                    self.Muted = isMuted
                    self.Mute:SetImage( isMuted and "icon32/muted.png" or "icon32/unmuted.png" )

                    self.Mute.DoClick = function() 
                        ply:SetMuted( !self.Muted ) 
                    end

                    self.Mute.OnMouseWheeled = function( s, delta )
                        ply:SetVoiceVolumeScale( ply:GetVoiceVolumeScale() + ( delta / 100 * 5 ) )
                        s.LastTick = CurTime()
                    end

                    self.Mute.PaintOver = function( s, w, h )
                        if !IsValid( ply ) then return end

                        local a = ( 255 - Clamp( CurTime() - ( s.LastTick or 0 ), 0, 3 ) * 255 )
                        if a <= 0 then return end

                        RoundedBox( 4, 0, 0, w, h, Color( 0, 0, 0, a * 0.75 ) )
                        SimpleText( ceil( ply:GetVoiceVolumeScale() * 100 ) .. "%", "DermaDefaultBold", w / 2, h / 2, Color( 255, 255, 255, a ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
                    end
                end

                -- Connecting players go at the very bottom
                if ply:IsPlayer() and ply:Team() == TEAM_CONNECTING then
                    self:SetZPos( 2000 + ply:EntIndex() )
                    return
                end

                -- This is what sorts the list. The panels are docked in the z order,
                -- so if we set the z order according to kills they'll be ordered that way!
                -- Careful though, it's a signed short internally, so needs to range between -32,768k and +32,767
                self:SetZPos( ( self.NumKills * -50 ) + self.NumDeaths + ply:EntIndex() )
            end,
        
            Paint = function( self, w, h )
                local ply = self.Player
                if !IsValid( ply ) then return end
                
                -- We draw our background a different colour based on the status of the player
                local drawClr = statusClr_Default
                if ply:Team() == TEAM_CONNECTING then
                    drawClr = statusClr_Connecting
                elseif !ply:Alive() then
                    drawClr = statusClr_Dead
                elseif ply:IsPlayer() and ply:IsAdmin() then
                    drawClr = statusClr_Admin
                end

                RoundedBox( 4, 0, 0, w, h, drawClr )
            end
        }
        -- Convert it from a normal table into a Panel Table based on DPanel
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
                self.Name:SetExpensiveShadow( 2, scoreBoardClr2 )
        
                self.Scores = self:Add( "DScrollPanel" )
                self.Scores:Dock( FILL )
            end,
        
            PerformLayout = function( self )
                self:SetSize( 700, ScrH() - 200 )
                self:SetPos( ScrW() / 2 - 350, 100 )
            end,

            Paint = function( self, w, h )
            end,

            Think = function( self, w, h )
                self.Name:SetText( GetHostName() )

                -- Loop through each player, and if one doesn't have a score entry - create it.
                for _, ply in ipairs( table_Add( player_GetAll(), GetLambdaPlayers() ) ) do
                    if IsValid( ply.ScoreEntry ) then continue end
                    ply.ScoreEntry = vgui.CreateFromTable( PLAYER_LINE, ply.ScoreEntry )
                    ply.ScoreEntry:Setup( ply )
                    self.Scores:AddItem( ply.ScoreEntry )
                end
            end
        }
        SCORE_BOARD = vgui.RegisterTable( SCORE_BOARD, "EditablePanel" )

        function GAMEMODE:ScoreboardShow()
            if !IsValid( g_Scoreboard ) then
                g_Scoreboard = vgui.CreateFromTable( SCORE_BOARD )
                if !IsValid( g_Scoreboard ) then return end
            end

            g_Scoreboard:Show()
            g_Scoreboard:MakePopup()
            g_Scoreboard:SetKeyboardInputEnabled( false )        
        end

        function GAMEMODE:ScoreboardHide()
            if !IsValid( g_Scoreboard ) then return end
            g_Scoreboard:Hide()        
        end

        local PANEL = {}
        local PlayerVoicePanels = {}
        local BaseTeams = {
            [ TEAM_CONNECTING ] = true,
            [ TEAM_UNASSIGNED ] = true,
            [ TEAM_SPECTATOR ] = true
        }
        local PopupBoxColor = Color( 0, 255, 0, 240 )

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

            self.Team = ply:Team()
            self.Color = team.GetColor( self.Team )

            self:InvalidateLayout()
        end

        function PANEL:Paint( w, h )
            local ply = self.ply
            if !IsValid( ply ) then return end

            local plyVol = ply:VoiceVolume()
            if !BaseTeams[ self.Team ] then
                local teamClr = self.Color
                PopupBoxColor.r = ( teamClr.r * plyVol )
                PopupBoxColor.g = ( teamClr.g * plyVol )
                PopupBoxColor.b = ( teamClr.b * plyVol )
            else
                PopupBoxColor.r = 0
                PopupBoxColor.g = ( 255 * plyVol )
                PopupBoxColor.b = 0
            end

            RoundedBox( 4, 0, 0, w, h, PopupBoxColor )
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
            g_VoicePanelList:SetPos( ScrW() - 300 + voicepopupx:GetInt(), 100 + voicepopupy:GetInt() )
            g_VoicePanelList:SetSize( 250, ScrH() - 200 )
            g_VoicePanelList:SetPaintBackground( false )
        end
        
        hook.Add( "InitPostEntity", "CreateVoiceVGUI", CreateVoiceVGUI )
    end )

    hook.Add( "Initialize", "lambdaplayers_overridekillfeedhook", function()
        if !overridekillfeed:GetBool() then return end
        local olddeathnoticehookfunc = GAMEMODE.AddDeathNotice

        function GAMEMODE:AddDeathNotice( attacker, attackerTeam, inflictor, victim, victimTeam, flags )
            if attacker == "#npc_lambdaplayer" then return end
            olddeathnoticehookfunc( self, attacker, attackerTeam, inflictor, victim, victimTeam, flags )
        end
    end )
end


if ( SERVER ) then
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
end