local CreateVGUI = vgui.Create
local pairs = pairs
local SortedPairs = SortedPairs
local GetAllValidModel = player_manager.AllValidModels
local AddNotification = notification.AddLegacy
local RealTime = RealTime
local PlaySound = surface.PlaySound
local lower = string.lower
local Rand = math.Rand

local function OpenModelVoiceProfilePanel( ply )
    if !ply:IsSuperAdmin() then 
        AddNotification( "You must be a Super Admin in order to use this!", 1, 4 )
        PlaySound( "buttons/button10.wav" ) 
        return 
    end

    local frame = LAMBDAPANELS:CreateFrame( "Playermodel Voice Profile", 700, 500 )
    LAMBDAPANELS:CreateLabel( "Select a playermodel from the right panel and pick a voice profile from the list below it", frame, TOP )
    LAMBDAPANELS:CreateLabel( "Changes are applied by a button below the list", frame, TOP )

    function frame:OnClose()
        chat.AddText( "Remember to Update Lambda Data after any changes!" )
    end

    local mdlpanel = LAMBDAPANELS:CreateBasicPanel( frame, RIGHT )
    mdlpanel:SetSize( 312, 200 )

    local mdlpreview = CreateVGUI( "DModelPanel", frame )
    mdlpreview:SetSize( 375, 200 )
    mdlpreview:Dock( LEFT )
    mdlpreview:SetModel( "" )
    
    function mdlpreview:LayoutEntity( Entity )
        Entity:SetAngles( Angle( 0, RealTime() * 20 % 360, 0 ) )
    end

    local mdlcolor = Vector( Rand( 0.0, 1.0 ), Rand( 0.0, 1.0 ), Rand( 0.0, 1.0 ) )
    local function GetPlayerColor() return mdlcolor end

    local mdlvplist = {}
    LAMBDAPANELS:RequestDataFromServer( "lambdaplayers/modelvoiceprofiles.json", "json", function( data ) if data then mdlvplist = data end end )

    local mdlselected, vpselected

    LAMBDAPANELS:CreateButton( mdlpanel, BOTTOM, "Apply", function()
        if !mdlselected then
            AddNotification( "You haven't selected any playermodel from the list!", 1, 4 )
            PlaySound( "buttons/button10.wav" ) 
            return 
        end
        if mdlvplist[ mdlselected ] == vpselected then return end

        if vpselected == "/NIL" then 
            if !mdlvplist[ mdlselected ] then return end
            LAMBDAPANELS:RemoveVarFromKVFile( "lambdaplayers/modelvoiceprofiles.json", mdlselected, "json" ) 
        else
            LAMBDAPANELS:UpdateKeyValueFile( "lambdaplayers/modelvoiceprofiles.json", { [ lower( mdlselected ) ] = vpselected }, "json" )
        end
        AddNotification( "Successfully applied the change!", 0, 4 )
        PlaySound( "buttons/button15.wav" )

        mdlvplist[ mdlselected ] = vpselected
    end )
    
    local vptbl = { [ "No Voice Profile" ] = "/NIL" }
    for vp, _ in pairs( LambdaVoiceProfiles ) do vptbl[ vp ] = vp end
    local vplist = LAMBDAPANELS:CreateComboBox( mdlpanel, BOTTOM, vptbl )
    vplist:SelectOptionByKey( "/NIL" )
    function vplist:OnSelect( _, _, data ) vpselected = data end

    local mdlscroll = LAMBDAPANELS:CreateScrollPanel( mdlpanel, false, FILL )
    
    local pmlist = CreateVGUI( "DIconLayout", mdlscroll )
    pmlist:Dock( FILL )
    pmlist:SetSpaceY( 12 )
    pmlist:SetSpaceX( 12 )
    for _, mdl in SortedPairs( GetAllValidModel() ) do
        local modelbutton = pmlist:Add( "SpawnIcon" )
        modelbutton:SetModel( mdl )

        function modelbutton:DoClick()
            mdlselected = modelbutton:GetModelName()
            mdlpreview:SetModel( mdlselected )

            mdlcolor = Vector( Rand( 0.0, 1.0 ), Rand( 0.0, 1.0 ), Rand( 0.0, 1.0 ) )
            mdlpreview.Entity.GetPlayerColor = GetPlayerColor


            PlaySound( "buttons/lightswitch2.wav" )
            vplist:SelectOptionByKey( mdlvplist[ mdlselected ] or "/NIL" )
        end
    end
end

RegisterLambdaPanel( "Playermodel Voice Profile", "Opens a panel that allows you to set a Lambda voice profile to a specific playermodel. YOU MUST UPDATE LAMBDA DATA AFTER ANY CHANGES! You must be a Super Admin to use this panel!", OpenModelVoiceProfilePanel )