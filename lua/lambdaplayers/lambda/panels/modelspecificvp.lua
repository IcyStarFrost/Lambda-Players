local CreateVGUI = vgui.Create
local pairs = pairs
local SortedPairs = SortedPairs
local GetAllValidModel = player_manager.AllValidModels
local AddNotification = notification.AddLegacy
local RealTime = RealTime
local PlaySound = surface.PlaySound
local lower = string.lower


local function OpenModelVoiceProfilePanel( ply )
    if !ply:IsSuperAdmin() then 
        AddNotification( "You must be a Super Admin in order to use this!", 1, 4 )
        PlaySound( "buttons/button10.wav" ) 
        return 
    end

    local frame = LAMBDAPANELS:CreateFrame( "Playermodel Voice Profile", 1100, 600 )
    LAMBDAPANELS:CreateLabel( "Select a playermodel from the right panel and pick a voice profile from the list below it", frame, TOP )
    LAMBDAPANELS:CreateLabel( "Changes are applied by a button below the list", frame, TOP )

    function frame:OnClose()
        chat.AddText( "Remember to Update Lambda Data after any changes!" )
    end

    local listpanel = LAMBDAPANELS:CreateBasicPanel( frame, LEFT )
    listpanel:SetSize( 400, 200 )

    local mdlvplist = CreateVGUI( "DListView", listpanel )
    mdlvplist:Dock( FILL )
    mdlvplist:AddColumn( "Model", 1 )
    mdlvplist:AddColumn( "VP", 2 )

    local mdlpreview = CreateVGUI( "DModelPanel", frame )
    mdlpreview:SetSize( 375, 200 )
    mdlpreview:Dock( RIGHT )
    mdlpreview:SetModel( "" )
    mdlpreview:SetFOV( 45 )
    
    function mdlpreview:LayoutEntity( Entity )
        Entity:SetAngles( Angle( 0, RealTime() * 20 % 360, 0 ) )
    end

    local mdlcolor = Vector( LambdaRNG( 0.0, 1.0, true ), LambdaRNG( 0.0, 1.0, true ), LambdaRNG( 0.0, 1.0, true ) )
    local function GetPlayerColor() return mdlcolor end

    local mdllist = {}

    if !LocalPlayer():IsListenServerHost() then
        LAMBDAPANELS:RequestDataFromServer( "lambdaplayers/modelvoiceprofiles.json", "json", function( data ) 
            if !data then return end 
            mdllist = data 
            
            for mdl, vp in SortedPairs( data ) do
                mdlvplist:AddLine( mdl, vp )
            end
        end )
    else
        local data = LAMBDAFS:ReadFile( "lambdaplayers/modelvoiceprofiles.json", "json" )
        if !data then return end 
        mdllist = data 
        
        for mdl, vp in SortedPairs( data ) do
            mdlvplist:AddLine( mdl, vp )
        end
    end

    local mdlselected, vpselected, listId

    local mdlpanel = LAMBDAPANELS:CreateBasicPanel( frame, RIGHT )
    mdlpanel:SetSize( 312, 200 )

    LAMBDAPANELS:CreateButton( mdlpanel, BOTTOM, "Apply", function()
        if !mdlselected then
            AddNotification( "You haven't selected any playermodel from the list!", 1, 4 )
            PlaySound( "buttons/button10.wav" ) 
            return 
        end
        if mdllist[ mdlselected ] == vpselected then return end

        if vpselected == "/NIL" then 
            if !mdllist[ mdlselected ] then return end
            if listId then mdlvplist:RemoveLine( listId ) end
            LAMBDAPANELS:RemoveVarFromKVFile( "lambdaplayers/modelvoiceprofiles.json", mdlselected, "json" ) 
            AddNotification( 'Removed model voice profile from "' .. mdlselected .. '"!', 0, 4 )
        else
            listId = mdlvplist:AddLine( mdlselected, vpselected ):GetID()
            LAMBDAPANELS:UpdateKeyValueFile( "lambdaplayers/modelvoiceprofiles.json", { [ lower( mdlselected ) ] = vpselected }, "json" )
            AddNotification( 'Assigned "' .. vpselected .. '" voice profile to "' .. mdlselected .. '"!', 0, 4 )
        end

        PlaySound( "buttons/button15.wav" )
        mdllist[ mdlselected ] = vpselected
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
            
            mdlcolor = Vector( LambdaRNG( 0.0, 1.0, true ), LambdaRNG( 0.0, 1.0, true ), LambdaRNG( 0.0, 1.0, true ) )
            mdlpreview.Entity.GetPlayerColor = GetPlayerColor
            
            for id, line in ipairs( mdlvplist:GetLines() ) do
                if line:GetColumnText( 1 ) != mdlselected then continue end
                listId = id; break
            end

            PlaySound( "buttons/lightswitch2.wav" )
            vplist:SelectOptionByKey( mdllist[ mdlselected ] or "/NIL" )
        end
    end
    
    function mdlvplist:DoDoubleClick( id, line )
        mdlselected = line:GetColumnText( 1 )
        mdlpreview:SetModel( mdlselected )
        
        mdlcolor = Vector( LambdaRNG( 0.0, 1.0, true ), LambdaRNG( 0.0, 1.0, true ), LambdaRNG( 0.0, 1.0, true ) )
        mdlpreview.Entity.GetPlayerColor = GetPlayerColor
        
        listId = id
        PlaySound( "buttons/lightswitch2.wav" )
        vplist:SelectOptionByKey( vptbl[ line:GetColumnText( 2 ) ] or "/NIL" )
    end

    function mdlvplist:OnRowRightClick( id, line )
        if listId == id then listId = nil end
        
        local mdl = line:GetColumnText( 1 )
        AddNotification( 'Removed model voice profile from "' .. mdl .. '"!', 0, 4 )
        PlaySound( "buttons/button15.wav" )

        mdllist[ mdl ] = nil
        mdlvplist:RemoveLine( id )
        LAMBDAPANELS:RemoveVarFromKVFile( "lambdaplayers/modelvoiceprofiles.json", mdl, "json" ) 
    end
end

RegisterLambdaPanel( "Playermodel Voice Profile", "Opens a panel that allows you to set a Lambda voice profile to a specific playermodel. YOU MUST UPDATE LAMBDA DATA AFTER ANY CHANGES! You must be a Super Admin to use this panel!", OpenModelVoiceProfilePanel )