local AddNotification = notification.AddLegacy
local PlayClientSound = surface.PlaySound
local CreateVGUI = vgui.Create
local RealTime = RealTime
local ipairs = ipairs
local pairs = pairs
local SortedPairs = SortedPairs
local GetAllValidModel = player_manager.AllValidModels

local Round = math.Round
local table_Empty = table.Empty
local table_remove = table.remove
local lower = string.lower
local match = string.match

local searchUpdateTime = 0
local mdlChangeTime = 0
local mdlRngBgTime = 0
local mdlAng = Angle()
local mdlColor = Vector( LambdaRNG( 0, 1, true ), LambdaRNG( 0, 1, true ), LambdaRNG( 0, 1, true ) )
local function GetPlayerColor() return mdlColor end

local Explode = string.Explode
local Implode = string.Implode
local len = string.len
local Left = string.Left
local Right = string.Right
local upper = string.upper
local function MakeNiceName( str )
    local newName = {}

    for _, s in ipairs( Explode( "_", str ) ) do
        if ( len( s ) == 1 ) then newName[ #newName + 1 ] = upper( s ) continue end
        newName[ #newName + 1 ] = upper( Left( s, 1 ) ) .. Right( s, len( s ) - 1 )
    end

    return Implode( " ", newName )
end

local function OpenPMBodyGroupSetsPanel( ply )
    if !ply:IsSuperAdmin() then
        AddNotification( "You must be a Super Admin in order to use this!", 1, 4 )
        PlayClientSound( "buttons/button10.wav" )
        return
    end

    local frame = LAMBDAPANELS:CreateFrame( "Playermodel Bodygroup Sets", 1200, 600 )
    LAMBDAPANELS:CreateLabel( "Select the model from the browser on the right, adjust the skin and bodygroup sliders and save the set.", frame, TOP )
    LAMBDAPANELS:CreateLabel( "Left click on a set in a row on the left to copy the values from it, or right click to remove it. Setting the slider to -1 will make the model use a random skin or bodygroup from it.", frame, TOP )

    local mdlSetList = {}

    if !LocalPlayer():IsListenServerHost() then
        LAMBDAPANELS:RequestDataFromServer( "lambdaplayers/pmbodygroupsets.json", "json", function( data )
            if !data then return end
            mdlSetList = data
        end )
    else
        local data = LAMBDAFS:ReadFile( "lambdaplayers/pmbodygroupsets.json", "json" )
        if !data then return end
        mdlSetList = data
    end

    local listPanel = LAMBDAPANELS:CreateBasicPanel( frame, LEFT )
    listPanel:SetSize( 100, 600 )

    local setList = CreateVGUI( "DListView", listPanel )
    setList:Dock( FILL )
    setList:AddColumn( "Sets" ):SetTextAlign( 5 )

    local sbPanel = LAMBDAPANELS:CreateBasicPanel( frame )
    sbPanel:SetSize( 375, 600 )
    sbPanel:DockPadding( 10, 0, 0, 0 )
    sbPanel:Dock( LEFT )

    local sbScroll = LAMBDAPANELS:CreateScrollPanel( sbPanel, false, FILL )
    local hasGroups, mdlPreview, skinSlider, noBgLabel = false
    local bodygroupData = {}
    local UpdateSBSliders = function()
        local ent = mdlPreview:GetEntity()

        for k, v in pairs( bodygroupData ) do
            if v then v:Remove() end
            bodygroupData[ k ] = nil
        end

        hasGroups = false
        if IsValid( skinSlider ) then skinSlider:Remove() end
        if IsValid( noBgLabel ) then noBgLabel:Remove() end

        local skinCount = ent:SkinCount()
        if skinCount > 1 then
            hasGroups = true
            skinSlider = LAMBDAPANELS:CreateNumSlider( sbScroll, TOP, 0, "Skin", -1, ( skinCount - 1 ), 0 )

            function skinSlider:OnValueChanged( val )
                ent:SetSkin( Round( val, 0 ) )
            end
        end

        local groups = ( ent:GetBodyGroups() or {} )
        for _, v in ipairs( groups ) do
            local mdls = #v.submodels
            if mdls == 0 then continue end

            local index = v.id
            local bgSlider = LAMBDAPANELS:CreateNumSlider( sbScroll, TOP, 0, MakeNiceName( v.name ), -1, mdls, 0 )
            function bgSlider:OnValueChanged( val )
                ent:SetBodygroup( index, Round( val, 0 ) )
            end

            hasGroups = true
            bodygroupData[ index ] = bgSlider
        end

        if !hasGroups then
            sbPanel:DockPadding( 55, -55, 0, 0 )
            noBgLabel = LAMBDAPANELS:CreateLabel( "NO BODYGROUPS/SKINS FOUND FOR THIS MODEL", sbPanel, FILL )
            noBgLabel:SetFont( "Trebuchet18" )
        else
            sbPanel:DockPadding( 10, 0, 0, 0 )
        end
    end

    function setList:DoDoubleClick( id, line )
        local setData = line:GetSortValue( 1 )
        if IsValid( skinSlider ) then skinSlider:SetValue( setData.skin ) end

        local bgData = setData.bodygroups
        for index, panel in pairs( bodygroupData ) do
            panel:SetValue( bgData[ index ] )
        end

        mdlRngBgTime = RealTime()
        mdlChangeTime = RealTime()
        PlayClientSound( "buttons/button15.wav" )
    end

    local mdlIcons, showAllIcons = {}, true
    function setList:OnRowRightClick( id )
        for index, _ in ipairs( setList:GetLines() ) do
            setList:RemoveLine( index )
        end
        
        local pmMdl = mdlPreview:GetModel()
        local mdlSets = mdlSetList[ pmMdl ]
        table_remove( mdlSets, id )
        
        if #mdlSets > 0 then
            local addCount = 1
            for index, data in ipairs( mdlSets ) do
                print( index, addCount )
                local setLine = setList:AddLine( "Set #" .. addCount )
                setLine:SetSortValue( 1, data )
                addCount = ( addCount + 1 )
            end
        else
            mdlSetList[ pmMdl ] = nil
            
            if !showAllIcons then
                local icon = mdlIcons[ pmMdl ]
                if icon then icon:Remove() end
                mdlIcons[ pmMdl ] = nil
            end
        end

        PlayClientSound( "buttons/button15.wav" )
        LAMBDAFS:WriteFile( "lambdaplayers/pmbodygroupsets.json", mdlSetList, "json" )
    end

    local pmList, CreateModelButton
    LAMBDAPANELS:CreateButton( setList, BOTTOM, "Create Set", function()
        if !IsValid( mdlPreview:GetEntity() ) then
            AddNotification( "You haven't selected any playermodel from the list!", 1, 4 )
            PlayClientSound( "buttons/button10.wav" )
            return
        end
        if !hasGroups then
            AddNotification( "The selected playermodel doesn't have any skins or bodygroups!", 1, 4 )
            PlayClientSound( "buttons/button10.wav" )
            return
        end
        
        local mdlSkin = ( IsValid( skinSlider ) and Round( skinSlider:GetValue(), 0 ) or 0 )
        local mdlBgData = {}
        for index, panel in pairs( bodygroupData ) do
            mdlBgData[ index ] = Round( panel:GetValue(), 0 )
        end
        
        local pmMdl = mdlPreview:GetModel()
        local mdlSet, setData = mdlSetList[ pmMdl ], {
            [ "skin" ] = mdlSkin,
            [ "bodygroups" ] = mdlBgData
        }
        
        local setNum = 1
        if !mdlSet then
            mdlSetList[ pmMdl ] = { setData }
            if !showAllIcons then CreateModelButton( pmMdl ) end
        else
            setNum = ( #mdlSetList[ pmMdl ] + 1 )
            mdlSetList[ pmMdl ][ setNum ] = setData
        end
        
        local setLine = setList:AddLine( "Set #" .. setNum, setNum )
        setLine:SetSortValue( 1, setData )
        LAMBDAFS:UpdateKeyValueFile( "lambdaplayers/pmbodygroupsets.json", mdlSetList, "json" )
        
        PlayClientSound( "buttons/button15.wav" )
        AddNotification( "Created new set #" .. setNum .. " for " .. pmMdl .. "!", 0, 4 )
    end )
    
    local mdlPanel = LAMBDAPANELS:CreateBasicPanel( frame, RIGHT )
    mdlPanel:SetSize( 390, 600 )
    
    local mdlScroll = LAMBDAPANELS:CreateScrollPanel( mdlPanel, false, FILL )
    
    mdlPreview = CreateVGUI( "DModelPanel", frame )
    mdlPreview:SetSize( 350, 600 )
    mdlPreview:Dock( RIGHT )
    mdlPreview:SetModel( "" )
    mdlPreview:SetFOV( 45 )
    
    function mdlPreview:LayoutEntity( ent )
        mdlAng.y = ( ( RealTime() - mdlChangeTime ) * 35 % 360 )
        ent:SetAngles( mdlAng )
        
        if ( RealTime() - mdlRngBgTime ) > 1.5 then
            mdlRngBgTime = RealTime()
            
            if IsValid( skinSlider ) and Round( skinSlider:GetValue() ) == -1 then
                ent:SetSkin( LambdaRNG( 0, skinSlider:GetMax() ) )
            end
            
            for index, slider in pairs( bodygroupData ) do
                if Round( slider:GetValue() ) != -1 then continue end
                ent:SetBodygroup( index, LambdaRNG( 0, slider:GetMax() ) )
            end
        end
        
        ent:SetEyeTarget( ent:GetPos() + ent:GetForward() * 50 + vector_up * 50 )
    end
    
    CreateModelButton = function( mdl )
        local mdlButton = pmList:Add( "SpawnIcon" )
        mdlButton:SetModel( mdl )
        mdlIcons[ mdl ] = mdlButton
        
        function mdlButton:DoClick()
            local mdlName = lower( mdlButton:GetModelName() )
            mdlPreview:SetModel( mdlName )
            UpdateSBSliders()
            
            mdlRngBgTime = RealTime()
            mdlChangeTime = RealTime()
            
            mdlColor[ 1 ] = LambdaRNG( 0, 1, true )
            mdlColor[ 2 ] = LambdaRNG( 0, 1, true )
            mdlColor[ 3 ] = LambdaRNG( 0, 1, true )
            
            local ent = mdlPreview:GetEntity()
            ent.GetPlayerColor = GetPlayerColor
            
            for id, line in ipairs( setList:GetLines() ) do
                setList:RemoveLine( id )
            end
            
            local mdlSets = mdlSetList[ mdlName ]
            if mdlSets and #mdlSets > 0 then
                for id, data in ipairs( mdlSets ) do
                    local setLine = setList:AddLine( "Set #" .. id )
                    setLine:SetSortValue( 1, data )
                end
            end
            
            PlayClientSound( "buttons/lightswitch2.wav" )
        end
    end
    
    local validMdls = GetAllValidModel()
    local function RefreshPlayerIcons( filter )
        if pmList then pmList:Remove() end
        pmList = CreateVGUI( "DIconLayout", mdlScroll )
        
        pmList:Dock( FILL )
        pmList:SetSpaceY( 12 )
        pmList:SetSpaceX( 12 )
        
        table_Empty( mdlIcons )
        for _, mdl in SortedPairs( validMdls ) do
            if filter and filter( lower( mdl ) ) == true then continue end
            CreateModelButton( mdl )
        end
        
        mdlScroll:InvalidateLayout()
    end
    local function ShowAllPlayerModels()
        if pmList then PlayClientSound( "buttons/button15.wav" ) end
        showAllIcons = true
        RefreshPlayerIcons()
    end
    
    local searchBar = LAMBDAPANELS:CreateTextEntry( mdlPanel, TOP, "Search Bar" )
    function searchBar:OnChange()
        if CurTime() <= searchUpdateTime then return end 
        local text = searchBar:GetText()

        RefreshPlayerIcons( function( mdl )
            if !showAllIcons and ( !mdlSetList[ mdl ] or #mdlSetList[ mdl ] == 0 ) then return true end
            if #text > 0 and !match( mdl, text ) then return true end
        end )
        searchUpdateTime = ( CurTime() + 0.2 )
    end
    searchBar.OnEnter = searchBar.OnChange

    LAMBDAPANELS:CreateButton( mdlPanel, BOTTOM, "Show Assigned Only", function()
        PlayClientSound( "buttons/button15.wav" )
        showAllIcons = false
        RefreshPlayerIcons( function( mdl ) return ( !mdlSetList[ mdl ] or #mdlSetList[ mdl ] == 0 ) end )
    end )
    LAMBDAPANELS:CreateButton( mdlPanel, BOTTOM, "Show All Models", ShowAllPlayerModels )

    ShowAllPlayerModels()
end

RegisterLambdaPanel( "Playermodel Bodygroup Sets", "Opens a panel that allows you to create bodygroup sets of playermodels for Lambdas. YOU MUST UPDATE LAMBDA DATA AFTER ANY CHANGES! You must be a Super Admin to use this panel!", OpenPMBodyGroupSetsPanel )