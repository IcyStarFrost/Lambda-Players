
local PANEL = {}

AccessorFunc( PANEL, "m_strModel", "Model" )
AccessorFunc( PANEL, "m_pOrigin", "Origin" )
AccessorFunc( PANEL, "m_bCustomIcon", "CustomIcon" )

function PANEL:Init()

	self:SetSize( ScrW(), ScrH() )
	self:SetTitle( "#smwidget.icon_editor" )

	local left = self:Add( "Panel" )
	left:Dock( LEFT )
	left:SetWide( ScrW() / 1.2 )
	self.LeftPanel = left

		local bg = left:Add( "DPanel" )
		bg:Dock( FILL )
		bg:DockMargin( 0, 0, 0, 4 )
		bg.Paint = function( self, w, h ) draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 128 ) ) end


        self.imagepnl = bg:Add( "DImage" )
        self.imagepnl:SetSize( 80, 80 )
        self.imagepnl:SetMaterial( "f" )

		self.ModelPanel = bg:Add( "DAdjustableModelPanel" )
		self.ModelPanel:Dock( FILL )
		self.ModelPanel.FarZ = 32768


        function self.ModelPanel.PreDrawModel( mdlpnl, ent )
            ent:SetMaterial( "models/debug/debugwhite" )
            render.SuppressEngineLighting( true )
        end

		function self.ModelPanel.PostDrawModel( mdlpnl, ent )
            render.SuppressEngineLighting( false )
		end

	local controls = left:Add( "Panel" )
	controls:SetTall( 64 )
	controls:Dock( BOTTOM )

		local controls_anim = controls:Add( "Panel" )
		controls_anim:SetTall( 20 )
		controls_anim:Dock( TOP )
		controls_anim:DockMargin( 0, 0, 0, 4 )
		controls_anim:MoveToBack()

			self.AnimTrack = controls_anim:Add( "DSlider" )
			self.AnimTrack:Dock( FILL )
			self.AnimTrack:SetNotches( 100 )
			self.AnimTrack:SetTrapInside( true )
			self.AnimTrack:SetLockY( 0.5 )

			self.AnimPause = controls_anim:Add( "DImageButton" )
			self.AnimPause:SetImage( "icon16/control_pause_blue.png" )
			self.AnimPause:SetStretchToFit( false )
			self.AnimPause:SetPaintBackground( true )
			self.AnimPause:SetIsToggle( true )
			self.AnimPause:SetToggle( false )
			self.AnimPause:Dock( LEFT )
			self.AnimPause:SetWide( 32 )

		local BestGuess = controls:Add( "DImageButton" )
		BestGuess:SetImage( "icon32/wand.png" )
		BestGuess:SetStretchToFit( false )
		BestGuess:SetPaintBackground( true )
		BestGuess.DoClick = function() self:BestGuessLayout() end
		BestGuess:Dock( LEFT )
		BestGuess:DockMargin( 0, 0, 0, 0 )
		BestGuess:SetWide( 50 )
		BestGuess:SetTooltip( "Best Guess" )

		local FullFrontal = controls:Add( "DImageButton" )
		FullFrontal:SetImage( "icon32/hand_point_090.png" )
		FullFrontal:SetStretchToFit( false )
		FullFrontal:SetPaintBackground( true )
		FullFrontal.DoClick = function() self:FullFrontalLayout() end
		FullFrontal:Dock( LEFT )
		FullFrontal:DockMargin( 2, 0, 0, 0 )
		FullFrontal:SetWide( 50 )
		FullFrontal:SetTooltip( "Front" )

		local Above = controls:Add( "DImageButton" )
		Above:SetImage( "icon32/hand_property.png" )
		Above:SetStretchToFit( false )
		Above:SetPaintBackground( true )
		Above.DoClick = function() self:AboveLayout() end
		Above:Dock( LEFT )
		Above:DockMargin( 2, 0, 0, 0 )
		Above:SetWide( 50 )
		Above:SetTooltip( "Above" )

		local Right = controls:Add( "DImageButton" )
		Right:SetImage( "icon32/hand_point_180.png" )
		Right:SetStretchToFit( false )
		Right:SetPaintBackground( true )
		Right.DoClick = function() self:RightLayout() end
		Right:Dock( LEFT )
		Right:DockMargin( 2, 0, 0, 0 )
		Right:SetWide( 50 )
		Right:SetTooltip( "Right" )

		local Origin = controls:Add( "DImageButton" )
		Origin:SetImage( "icon32/hand_point_090.png" )
		Origin:SetStretchToFit( false )
		Origin:SetPaintBackground( true )
		Origin.DoClick = function() self:OriginLayout() end
		Origin:Dock( LEFT )
		Origin:DockMargin( 2, 0, 0, 0 )
		Origin:SetWide( 50 )
		Origin:SetTooltip( "Center" )

		local Render = controls:Add( "DButton" )
		Render:SetText( "RENDER" )
		Render.DoClick = function() self:RenderIcon() end
		Render:Dock( RIGHT )
		Render:DockMargin( 2, 0, 0, 0 )
		Render:SetWide( 50 )
		Render:SetTooltip( "Render Icon" )


		local Rotate = controls:Add( "DImageButton" )
		Rotate:SetImage( "icon16/arrow_rotate_clockwise.png" )
		Rotate:SetStretchToFit( false )
		Rotate:SetPaintBackground( true )
		Rotate:Dock( RIGHT )
        Rotate:SetTooltip( "Rotate" )
		Rotate:DockMargin( 2, 0, 0, 0 )
		Rotate:SetWide( 50 )

		Rotate.DoClick = function()
            if IsValid( self.AnglePanel ) then return end
            local ent = self.ModelPanel:GetEntity()
            self.AnglePanel = LAMBDAPANELS:CreateFrame( "Angle Panel", 300, 150 )
            
            local pitch = LAMBDAPANELS:CreateNumSlider( self.AnglePanel, TOP, 0, "Pitch", -360, 360, 2 )
            local yaw = LAMBDAPANELS:CreateNumSlider( self.AnglePanel, TOP, 0, "Yaw", -360, 360, 2 )
            local roll = LAMBDAPANELS:CreateNumSlider( self.AnglePanel, TOP, 0, "Roll", -360, 360, 2 )

            function pitch:OnValueChanged( val )
                local oldang = ent:GetAngles()
                ent:SetAngles( Angle( val, oldang[ 2 ], oldang[ 3 ] ) )
            end

            function yaw:OnValueChanged( val )
                local oldang = ent:GetAngles()
                ent:SetAngles( Angle( oldang[ 1 ], val, oldang[ 3 ] ) )
            end

            function roll:OnValueChanged( val )
                local oldang = ent:GetAngles()
                ent:SetAngles( Angle( oldang[ 1 ], oldang[ 2 ], val ) )
            end
		end

	local right = self:Add( "DPropertySheet" )
	right:Dock( FILL )
	right:SetPadding( 0 )
	right:DockMargin( 4, 0, 0, 0 )
	self.PropertySheet = right

	-- Animations

	local anims = right:Add( "Panel" )
	anims:Dock( FILL )
	anims:DockPadding( 2, 0, 2, 2 )
	right:AddSheet( "#smwidget.animations", anims, "icon16/monkey.png" )

		self.AnimList = anims:Add( "DListView" )
		self.AnimList:AddColumn( "name" )
		self.AnimList:Dock( FILL )
		self.AnimList:SetMultiSelect( false )
		self.AnimList:SetHideHeaders( true )

	-- Bodygroups

	local pnl = right:Add( "Panel" )
	pnl:Dock( FILL )
	pnl:DockPadding( 7, 0, 7, 7 )

	self.BodygroupTab = right:AddSheet( "#smwidget.bodygroups", pnl, "icon16/brick.png" )

		self.BodyList = pnl:Add( "DScrollPanel" )
		self.BodyList:Dock( FILL )

			--This kind of works but they don't move their stupid mouths. So fuck off.
			--[[
			self.Scenes = pnl:Add( "DTree" )
			self.Scenes:Dock( BOTTOM )
			self.Scenes:SetSize( 200, 200 )
			self.Scenes.DoClick = function( _, node )

				if ( !node.FileName ) then return end
				local ext = string.GetExtensionFromFilename( node.FileName )
				if( ext != "vcd" ) then return end

				self.ModelPanel:StartScene( node.FileName )
				MsgN( node.FileName )

			end

			local materials = self.Scenes.RootNode:AddFolder( "Scenes", "scenes/", true )
			materials:SetIcon( "icon16/photos.png" )--]]

	-- Settings

	local settings = right:Add( "Panel" )
	settings:Dock( FILL )
	settings:DockPadding( 7, 0, 7, 7 )
	right:AddSheet( "#smwidget.settings", settings, "icon16/cog.png" )

		local angle = settings:Add( "DTextEntry" )
		angle:SetTooltip( "Entity Angles" )
		angle:Dock( TOP )
		angle:DockMargin( 0, 0, 0, 3 )
		angle:SetZPos( 100 )
		angle.OnChange = function( p, b )
			self.ModelPanel:GetEntity():SetAngles( Angle( angle:GetText() ) )
		end
		self.TargetAnglePanel = angle

		local cam_angle = settings:Add( "DTextEntry" )
		cam_angle:SetTooltip( "Camera Angles" )
		cam_angle:Dock( TOP )
		cam_angle:DockMargin( 0, 0, 0, 3 )
		cam_angle:SetZPos( 101 )
		cam_angle.OnChange = function( p, b )
			self.ModelPanel:SetLookAng( Angle( cam_angle:GetText() ) )
		end
		self.TargetCamAnglePanel = cam_angle

		local cam_pos = settings:Add( "DTextEntry" )
		cam_pos:SetTooltip( "Camera Position" )
		cam_pos:Dock( TOP )
		cam_pos:DockMargin( 0, 0, 0, 3 )
		cam_pos:SetZPos( 102 )
		cam_pos.OnChange = function( p, b )
			self.ModelPanel:SetCamPos( Vector( cam_pos:GetText() ) )
		end
		self.TargetCamPosPanel = cam_pos

		local playSpeed = settings:Add( "DNumSlider" )
		playSpeed:SetText( "Playback Speed" )
		playSpeed:Dock( TOP )
		playSpeed:DockMargin( 0, 0, 0, 3 )
		playSpeed:SetMin( -1 )
		playSpeed:SetDark( true )
		playSpeed:SetMax( 2 )
		playSpeed.OnValueChanged = function( s, value )
			self.ModelPanel:GetEntity():SetPlaybackRate( value )
		end

end

function PANEL:OnRemove()
    if IsValid( self.AnglePanel ) then self.AnglePanel:Remove() end
end

function PANEL:SetDefaultLighting()

	self.ModelPanel:SetAmbientLight( Color( 255 * 0.3, 255 * 0.3, 255 * 0.3 ) )

	self.ModelPanel:SetDirectionalLight( BOX_FRONT, Color( 255 * 1.3, 255 * 1.3, 255 * 1.3 ) )
	self.ModelPanel:SetDirectionalLight( BOX_BACK, Color( 255 * 0.2, 255 * 0.2, 255 * 0.2 ) )
	self.ModelPanel:SetDirectionalLight( BOX_RIGHT, Color( 255 * 0.2, 255 * 0.2, 255 * 0.2 ) )
	self.ModelPanel:SetDirectionalLight( BOX_LEFT, Color( 255 * 0.2, 255 * 0.2, 255 * 0.2 ) )
	self.ModelPanel:SetDirectionalLight( BOX_TOP, Color( 255 * 2.3, 255 * 2.3, 255 * 2.3 ) )
	self.ModelPanel:SetDirectionalLight( BOX_BOTTOM, Color( 255 * 0.1, 255 * 0.1, 255 * 0.1 ) )

end

function PANEL:BestGuessLayout()

	local ent = self.ModelPanel:GetEntity()
	local pos = ent:GetPos()
	local ang = ent:GetAngles()

	local tab = PositionSpawnIcon( ent, pos, true )

	ent:SetAngles( ang )
	if ( tab ) then
		self.ModelPanel:SetCamPos( tab.origin )
		self.ModelPanel:SetFOV( tab.fov )
		self.ModelPanel:SetLookAng( tab.angles )
	end

end

function PANEL:FullFrontalLayout()

	local ent = self.ModelPanel:GetEntity()
	local pos = ent:GetPos()
	local campos = pos + Vector( -200, 0, 0 )

	self.ModelPanel:SetCamPos( campos )
	self.ModelPanel:SetFOV( 45 )
	self.ModelPanel:SetLookAng( ( campos * -1 ):Angle() )

end

function PANEL:AboveLayout()

	local ent = self.ModelPanel:GetEntity()
	local pos = ent:GetPos()
	local campos = pos + Vector( 0, 0, 200 )

	self.ModelPanel:SetCamPos( campos )
	self.ModelPanel:SetFOV( 45 )
	self.ModelPanel:SetLookAng( ( campos * -1 ):Angle() )

end

function PANEL:RightLayout()

	local ent = self.ModelPanel:GetEntity()
	local pos = ent:GetPos()
	local campos = pos + Vector( 0, 200, 0 )

	self.ModelPanel:SetCamPos( campos )
	self.ModelPanel:SetFOV( 45 )
	self.ModelPanel:SetLookAng( ( campos * -1 ):Angle() )

end

function PANEL:OriginLayout()

	local ent = self.ModelPanel:GetEntity()
	local pos = ent:GetPos()
	local campos = pos + vector_origin

	self.ModelPanel:SetCamPos( campos )
	self.ModelPanel:SetFOV( 45 )
	self.ModelPanel:SetLookAng( Angle( 0, -180, 0 ) )

end

function PANEL:UpdateEntity( ent )

	ent:SetEyeTarget( self.ModelPanel:GetCamPos() )

	if ( IsValid( self.TargetAnglePanel ) && !self.TargetAnglePanel:IsEditing() ) then
		self.TargetAnglePanel:SetText( tostring( ent:GetAngles() ) )
	end
	if ( IsValid( self.TargetCamAnglePanel ) && !self.TargetCamAnglePanel:IsEditing() ) then
		self.TargetCamAnglePanel:SetText( tostring( self.ModelPanel:GetLookAng() ) )
	end
	if ( IsValid( self.TargetCamPosPanel ) && !self.TargetCamPosPanel:IsEditing() ) then
		self.TargetCamPosPanel:SetText( tostring( self.ModelPanel:GetCamPos() ) )
	end

	if ( self.AnimTrack:GetDragging() ) then

		ent:SetCycle( self.AnimTrack:GetSlideX() )
		self.AnimPause:SetToggle( true )

	elseif ( ent:GetCycle() != self.AnimTrack:GetSlideX() ) then

		local cyc = ent:GetCycle()
		if ( cyc < 0 ) then cyc = cyc + 1 end
		self.AnimTrack:SetSlideX( cyc )

	end

	if ( !self.AnimPause:GetToggle() ) then
		ent:FrameAdvance( FrameTime() )
	end

end

local capturecam = GetRenderTarget( "lambda_iconcapture1", 512, 512 )

local numbers = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" }
local endings = { "a", "b", "c" }
local function PrettyName( mdlpath )
    local split = string.Explode( "/", mdlpath )
    local basename =string.StripExtension( split[ #split ] )
    basename = string.Replace( basename, "_", " " )
    for k, number in ipairs( numbers ) do basename = string.Replace( basename, number, "" ) end
    for k, ending in ipairs( endings ) do if string.EndsWith( basename, ending ) then basename = string.Left( basename, #basename - 1 ) break end end
    return basename
end

function PANEL:RenderIcon()

	local tab = {}
	tab.ent = self.ModelPanel:GetEntity()
	tab.cam_pos = self.ModelPanel:GetCamPos()
	tab.cam_ang = self.ModelPanel:GetLookAng()
	tab.cam_fov = self.ModelPanel:GetFOV()

    render.PushRenderTarget( capturecam )

    render.SetColorMaterial()
    render.DrawScreenQuad()
    render.Clear(0, 0, 0, 0, true, true)

    cam.Start3D( tab.cam_pos, tab.cam_ang, tab.cam_fov, 0, 0, ScrW(), ScrH(), 1, 1024)

    render.ClearDepth()
    render.SuppressEngineLighting( true )



    tab.ent:DrawModel()

    cam.End3D()

    local data = render.Capture( {
        format = "png",
        x = 0,
        y = 0,
        w = 512,
        h = 512
    } )


    render.PopRenderTarget()

    local name = PrettyName( self:GetModel() )

    file.CreateDir( "lambdaplayers_renderedkillicons" )
    file.Write( "lambdaplayers_renderedkillicons/" .. name .. ".png", data )

    local mat = Material( "../data/lambdaplayers_renderedkillicons/" .. name .. ".png" )

    self.imagepnl:SetMaterial( mat )

    render.SuppressEngineLighting( false )


    local vmt = [[
UnlitGeneric
{
    "$baseTexture" 		"PATHTOICON"
    "$vertexcolor" 		1
    "$vertexalpha" 		1
    "$nolod" 			1
    "$additive"			1 // hldm style!
}]]

    file.Write( "lambdaplayers_renderedkillicons/" .. name .. ".vmt", vmt )

    chat.AddText( "Rendered Icon to: garrysmod/data/lambdaplayers_renderedkillicons/" .. name .. ".png")
end

function PANEL:SetIcon( icon )

	if ( !IsValid( icon ) ) then return end

	local model = icon:GetModelName()
	self:SetOrigin( icon )


	local w, h = icon:GetSize()
	if ( w / h < 1 ) then
		self:SetSize( 700, 502 + 400 )
		self.LeftPanel:SetWide( 400 )
	elseif ( w / h > 1 ) then
		self:SetSize( 900, 502 - 100 )
		self.LeftPanel:SetWide( 600 )
	else
		self:SetSize( 700, 502 )
		self.LeftPanel:SetWide( 400 )
	end

	if ( !model or model == "" ) then

		self:SetModel( "error.mdl" )
		self:SetCustomIcon( true )

	else

		self:SetModel( model )
		self:SetCustomIcon( false )

	end

end

function PANEL:Refresh()

	if ( !self:GetModel() ) then return end

	self.ModelPanel:SetModel( self:GetModel() )
	self.ModelPanel.LayoutEntity = function() self:UpdateEntity( self.ModelPanel:GetEntity() )  end

	local ent = self.ModelPanel:GetEntity()


	self:BestGuessLayout()
	self:FillAnimations( ent )
	self:SetDefaultLighting()

end

function PANEL:FillAnimations( ent )

	self.AnimList:Clear()

	for k, v in SortedPairsByValue( ent:GetSequenceList() or {} ) do

		local line = self.AnimList:AddLine( string.lower( v ) )

		line.OnSelect = function()

			local speed = ent:GetPlaybackRate()
			ent:ResetSequence( v )
			ent:SetCycle( 0 )
			ent:SetPlaybackRate( speed )
			if ( speed < 0 ) then ent:SetCycle( 1 ) end

		end

	end

	self.BodyList:Clear()
	local newItems = 0

	if ( ent:SkinCount() > 1 ) then

		local skinSlider = self.BodyList:Add( "DNumSlider" )
		skinSlider:Dock( TOP )
		skinSlider:DockMargin( 0, 0, 0, 3 )
		skinSlider:SetText( "Skin" )
		skinSlider:SetDark( true )
		skinSlider:SetDecimals( 0 )
		skinSlider:SetMinMax( 0, ent:SkinCount() - 1 )
		skinSlider:SetValue( ent:GetSkin() )
		skinSlider.OnValueChanged = function( s, newVal )
			newVal = math.Round( newVal )

			ent:SetSkin( newVal )

			if ( IsValid( self:GetOrigin() ) ) then self:GetOrigin():SkinChanged( newVal ) end

		end
		newItems = newItems + 1

	end

	for k = 0, ent:GetNumBodyGroups() - 1 do

		if ( ent:GetBodygroupCount( k ) <= 1 ) then continue end

		local bgSlider = self.BodyList:Add( "DNumSlider" )
		bgSlider:Dock( TOP )
		bgSlider:DockMargin( 0, 0, 0, 3 )
		bgSlider:SetDark( true )
		bgSlider:SetDecimals( 0 )
		bgSlider:SetText( ent:GetBodygroupName( k ) )
		bgSlider:SetMinMax( 0, ent:GetBodygroupCount( k ) - 1 )
		bgSlider:SetValue( ent:GetBodygroup( k ) )
		bgSlider.BodyGroupID = k
		bgSlider.OnValueChanged = function( s, newVal )
			newVal = math.Round( newVal )

			ent:SetBodygroup( s.BodyGroupID, newVal )

			if ( IsValid( self:GetOrigin() ) ) then self:GetOrigin():BodyGroupChanged( s.BodyGroupID, newVal ) end

		end
		newItems = newItems + 1

	end

	if ( newItems > 0 ) then
		self.BodygroupTab.Tab:SetVisible( true )
	else
		self.BodygroupTab.Tab:SetVisible( false )
	end
	local propertySheet = self.PropertySheet
	propertySheet.tabScroller:InvalidateLayout()

end

function PANEL:SetFromEntity( ent )

	if ( !IsValid( ent ) ) then return end

	local bodyStr = ""
	for i = 0, 8 do
		bodyStr = bodyStr .. math.min( ent:GetBodygroup( i ) or 0, 9 )
	end

	self:SetModel( ent:GetModel() )
	self:Refresh()

end

vgui.Register( "LambdaKIMaker", PANEL, "DFrame" )




local function OpenPropPanel()
    local frame = LAMBDAPANELS:CreateFrame( "Prop Panel", 800, 500 )
    LAMBDAPANELS:CreateLabel( "Click on models from the browser to create a kill icon from it", frame, TOP )
    local filebrowser = vgui.Create( "DFileBrowser", frame )

    filebrowser:SetFileTypes( "*.mdl" )
    filebrowser:Dock( FILL )
    filebrowser:SetModels( true )
    filebrowser:SetBaseFolder( "models" )

    function filebrowser:OnSelect( path, pnl )
        local pnl = vgui.Create( "LambdaKIMaker" )
        pnl:SetModel( string.lower( path ) )
        pnl:MakePopup()
        pnl:Refresh()
        pnl:Center() 
        frame:Remove()
    end

    local tree = filebrowser.Tree

    LambdaCreateThread( function()
        coroutine.wait( 0 )
        local files = file.Find( "settings/spawnlist/*", "GAME", "nameasc" )

        for k, spawnlist in ipairs( files ) do 
            local tbl = util.KeyValuesToTable( LAMBDAFS:ReadFile( "settings/spawnlist/" .. spawnlist, nil, "GAME" ) )
            local contents = tbl.contents

            if !contents then continue end

            local nodec = tree:AddNode( tbl.name, tbl.icon)

            

            function nodec:DoClick()
                if IsValid( filebrowser.Files ) then filebrowser.Files:Remove() end

                filebrowser.Files = filebrowser.Divider:Add( "DIconBrowser" )
                filebrowser.Files:SetManual( true )
                filebrowser.Files:SetBackgroundColor( Color( 234, 234, 234 ) )

                filebrowser.Divider:SetRight( filebrowser.Files )

                filebrowser.Files:Clear()

                for _, contenttbl in ipairs( contents ) do
                    if contenttbl.type != "model" then continue end
                    local icon = filebrowser.Files:Add( "SpawnIcon" )
                    icon:SetModel( contenttbl.model )

                    function icon:DoClick() 
                        local pnl = vgui.Create( "LambdaKIMaker" )
                        pnl:SetModel( self:GetModelName() )
                        pnl:MakePopup()
                        pnl:Refresh()
                        pnl:Center() 
                        frame:Remove()
                    end
                end
            end
        end
    end )

end









RegisterLambdaPanel( "DEV Kill Icon Maker", "Opens a panel that allows you to easily create a killicon using a model. THIS IS MEANT FOR DEVELOPERS ONLY!", OpenPropPanel )
