local SortedPairsByMemberValue = SortedPairsByMemberValue
local CreateVGUI = vgui.Create
local pairs = pairs
local list_Get = list.Get
local lower = string.lower
local AddNotification = notification.AddLegacy
local Material = Material
local PlayClientSound = surface.PlaySound
local npcNameBgColor = Color( 72, 72, 72 )

local function OpenNPCFearListPanel( ply )
    if !ply:IsSuperAdmin() then
        AddNotification( "You must be a Super Admin in order to use this!", 1, 4 )
        PlayClientSound( "buttons/button10.wav" )
        return
    end

    local frame = LAMBDAPANELS:CreateFrame( "Entities To Fear From", 800, 500 )

    local npcSelectPanel = LAMBDAPANELS:CreateBasicPanel( frame, LEFT )
    npcSelectPanel:SetSize( 430, 500 )

    local scrollPanel = LAMBDAPANELS:CreateScrollPanel( npcSelectPanel, false, FILL )

    local npcIconLayout = CreateVGUI( "DIconLayout", scrollPanel )
    npcIconLayout:Dock( FILL )
    npcIconLayout:SetSpaceX( 5 )
    npcIconLayout:SetSpaceY( 5 )

    local npcListPanel = CreateVGUI( "DListView", frame )
    npcListPanel:SetSize( 350, 500 )
    npcListPanel:DockMargin( 10, 0, 0, 0 )
    npcListPanel:Dock( LEFT )
    npcListPanel:AddColumn( "NPC", 1 )

    local textEntry = LAMBDAPANELS:CreateTextEntry( npcListPanel, BOTTOM, "Enter entity's class here if it's not on the list" )
    local npcList = list_Get( "NPC" )

    function textEntry:OnEnter( class )
        if !class or #class == 0 then return end

        class = lower( class )
        textEntry:SetText( "" )

        for _, line in ipairs( npcListPanel:GetLines() ) do
            if lower( line:GetColumnText( 2 ) ) != class then continue end
            PlayClientSound( "buttons/button11.wav" )
            AddNotification( "The class is already registered in the list!", 1, 4 )
            return
        end

        local prettyName = ( npcList[ class ] and npcList[ class ].Name or false )
        npcListPanel:AddLine( ( prettyName and prettyName .. " (" .. class .. ")" or class ), class )

        for _, panel in ipairs( npcIconLayout:GetChildren() ) do
            if panel:GetNPC() == class then panel:Remove() break end
        end

        PlayClientSound( "buttons/lightswitch2.wav" )
        LAMBDAFS:UpdateKeyValueFile( "lambdaplayers/npcstofear.json", { [ class ] = true }, "json" )
    end

    local function AddNPCPanel( class )
        for _, v in ipairs( npcIconLayout:GetChildren() ) do
            if v:GetNPC() == class then return end
        end

        local npcPanel = npcIconLayout:Add( "DPanel" )
        npcPanel:SetSize( 100, 120 )
        npcPanel:SetBackgroundColor( npcNameBgColor )

        local npcImg = CreateVGUI( "DImageButton", npcPanel )
        npcImg:SetSize( 100, 100 )
        npcImg:Dock( TOP )

        local iconMat = Material( "entities/" .. class .. ".png" )
        if iconMat:IsError() then iconMat = Material( "entities/" .. class .. ".jpg" ) end
        if iconMat:IsError() then iconMat = Material( "vgui/entities/" .. class ) end
        if !iconMat:IsError() then npcImg:SetMaterial( iconMat ) end

        local prettyName = ( npcList[ class ] and npcList[ class ].Name or false )
        local npcName = LAMBDAPANELS:CreateLabel( ( prettyName or class ), npcPanel, TOP )

        function npcImg:DoClick()
            npcListPanel:AddLine( ( prettyName and prettyName .. " (" .. class .. ")" or class ), class )
            npcPanel:Remove()

            PlayClientSound( "buttons/lightswitch2.wav" )
            LAMBDAFS:UpdateKeyValueFile( "lambdaplayers/npcstofear.json", { [ class ] = true }, "json" )
        end

        function npcPanel:GetNPC()
            return class
        end
    end

    for _, v in SortedPairsByMemberValue( npcList, "Category" ) do
        AddNPCPanel( v.Class )
    end

    function npcListPanel:OnRowRightClick( id, line )
        local class = line:GetColumnText( 2 )
        if npcList[ class ] then AddNPCPanel( class ) end
        npcListPanel:RemoveLine( id )

        PlayClientSound( "buttons/combine_button3.wav" )
        LAMBDAFS:RemoveVarFromKVFile( "lambdaplayers/npcstofear.json", class, "json" )
    end

    if !LocalPlayer():IsListenServerHost() then
        LAMBDAPANELS:RequestDataFromServer( "lambdaplayers/npcstofear.json", "json", function( data )
            if !data then return end

            for class, _ in pairs( data ) do
                local listData = npcList[ class ]
                local prettyName = ( listData and listData.Name or false )
                npcListPanel:AddLine( ( prettyName and prettyName .. " (" .. class .. ")" or class ), class )

                for _, panel in ipairs( npcIconLayout:GetChildren() ) do
                    if panel:GetNPC() == class then panel:Remove() break end
                end
            end
        end )
    else 
        local data = LAMBDAFS:ReadFile( "lambdaplayers/npcstofear.json", "json" )
        if !data then return end

        for class, _ in pairs( data ) do
            local listData = npcList[ class ]
            local prettyName = ( listData and listData.Name or false )
            npcListPanel:AddLine( ( prettyName and prettyName .. " (" .. class .. ")" or class ), class )

            for _, panel in ipairs( npcIconLayout:GetChildren() ) do
                if panel:GetNPC() == class then panel:Remove() break end
            end
        end
    end
end

RegisterLambdaPanel( "Entities To Fear From", "Opens a panel that allows you to add a specific entity that Lambda Players will fear and run away from.\nNote that the list only has NPCs, but you can add any entity by its classname and it will work fine. YOU MUST UPDATE LAMBDA DATA AFTER ANY CHANGES! You must be a Super Admin to use this panel!", OpenNPCFearListPanel )