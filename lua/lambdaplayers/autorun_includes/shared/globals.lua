local pairs = pairs
local string_find = string.find
local tostring = tostring
local iconColor = Color(255, 80, 0, 255)

_LAMBDAPLAYERSWEAPONS = {}

-- Merge all weapon lua files
function LambdaMergeWeapons()
    local weaponluafiles = file.Find( "lambdaplayers/lambda/weapons/*", "LUA", "nameasc" )
    for _, luafile in ipairs( weaponluafiles ) do
        AddCSLuaFile( "lambdaplayers/lambda/weapons/" .. luafile )
        include( "lambdaplayers/lambda/weapons/" .. luafile )
        print( "Lambda Players: Merged Weapon from [ " .. luafile .. " ]" )
    end

    if ( CLIENT ) then
        _LAMBDAPLAYERSWEAPONORIGINS = {}
    end
    _LAMBDAWEAPONALLOWCONVARS = {}
    _LAMBDAWEAPONCLASSANDPRINTS = { [ "No Weapon" ] = "none" }

    for name, data in pairs( _LAMBDAPLAYERSWEAPONS ) do
        if name == "none" then continue end -- Don't count the empty hands
        
        local convar = CreateLambdaConvar( "lambdaplayers_weapons_allow_" .. name, 1, true, false, false, "Allows the Lambda Players to equip " .. data.prettyname .. " from " .. data.origin .. " category", 0, 1 )
        _LAMBDAWEAPONALLOWCONVARS[ name ] = convar

        data.notagprettyname = ( data.prettyname != nil and data.prettyname or "" )
        data.prettyname = "[" .. data.origin .. "] " .. data.prettyname

        if ( CLIENT ) then 
            _LAMBDAPLAYERSWEAPONORIGINS[ data.origin ] = data.origin 

            local killIcon = data.killicon
            if killIcon then
                local iskilliconfilepath = string_find( killIcon, "/" )
                if iskilliconfilepath then
                    killicon.Add( "lambdaplayers_weaponkillicons_" .. name, killIcon, iconColor )
                else
                    killicon.AddAlias( "lambdaplayers_weaponkillicons_" .. name, killIcon )
                end
            end
        end

        _LAMBDAWEAPONCLASSANDPRINTS[ data.prettyname ] = name
    end

    if SERVER and LambdaHasFirstMergedWeapons then
        net.Start( "lambdaplayers_mergeweapons" )
        net.Broadcast()
    end

    LambdaHasFirstMergedWeapons = true
end

LambdaMergeWeapons()
concommand.Add( "lambdaplayers_dev_mergeweapons", LambdaMergeWeapons )

local spawnWep = CreateLambdaConvar( "lambdaplayers_lambda_spawnweapon", "physgun", true, true, true, "The weapon Lambda Players will spawn with only if the specified weapon is allowed", 0, 1 )

local net = net
local PlaySound = ( CLIENT and surface.PlaySound )
local AddNotification = ( CLIENT and notification.AddLegacy )
local ipairs = ipairs
local SortedPairs = SortedPairs
local max = math.max

local function OpenSpawnWeaponPanel() 
    local mainframe = LAMBDAPANELS:CreateFrame( "Spawn Weapon Selection", 700, 500 )
    local mainscroll = LAMBDAPANELS:CreateScrollPanel( mainframe, true, FILL )

    local weplinelist = {}
    local weplistlist = {}

    local currentWep = spawnWep:GetString()
    if currentWep == "random" then 
        currentWep = "Random Weapon"
    else
        currentWep = _LAMBDAPLAYERSWEAPONS[ currentWep ].prettyname
    end
    LAMBDAPANELS:CreateLabel( "Currenly selected spawn weapon: " .. currentWep, mainframe, TOP )

    for weporigin, _ in pairs( _LAMBDAPLAYERSWEAPONORIGINS ) do
        local originlist = vgui.Create( "DListView", mainscroll )
        originlist:SetSize( 200, 400 )
        originlist:Dock( LEFT )
        originlist:AddColumn( weporigin, 1 )
        originlist:SetMultiSelect( false )

        function originlist:DoDoubleClick( id, line )
            spawnWep:SetString( line:GetSortValue( 1 ) )
            AddNotification( "Selected " .. line:GetColumnText( 1 ) .. " from " .. weporigin .. " as a spawn weapon!", NOTIFY_GENERIC, 3 )
            PlaySound( "buttons/button15.wav" )
            mainframe:Close()
        end

        mainscroll:AddPanel( originlist )

        for name, data in pairs( _LAMBDAPLAYERSWEAPONS ) do
            if name == "none" then continue end
            if data.origin != weporigin then continue end

            local allowCvar = _LAMBDAWEAPONALLOWCONVARS[ name ]
            if allowCvar and !allowCvar:GetBool() then continue end

            local line = originlist:AddLine( data.notagprettyname )
            line:SetSortValue( 1, name )

            function line:OnSelect()
                for _, v in ipairs( weplinelist ) do
                    if v != line then v:SetSelected( false ) end
                end
            end
            
            weplinelist[ #weplinelist + 1 ] = line
        end

        if #originlist:GetLines() == 0 then
            originlist:Remove()
            continue
        end

        originlist:SortByColumn( 1 )
        weplistlist[ #weplistlist + 1 ] = originlist
    end

    if #weplistlist > 0 then
        function mainframe:OnSizeChanged( width )
            local columnWidth = max( 200, ( width - 10 ) / #weplistlist )
            for _, list in ipairs( weplistlist ) do
                list:SetWidth( columnWidth )
            end
        end

        mainframe:OnSizeChanged( mainframe:GetWide() )
    else
        LAMBDAPANELS:CreateLabel( "You currenly have every weapon restricted and disallowed to be used by Lambda Players!", mainframe, TOP )
    end

    LAMBDAPANELS:CreateButton( mainframe, BOTTOM, "Select None", function()
        spawnWep:SetString( "none" )
        AddNotification( "Selected none as a spawn weapon!", NOTIFY_GENERIC, 3 )
        PlaySound( "buttons/button15.wav" )
        mainframe:Close()
    end )

    LAMBDAPANELS:CreateButton( mainframe, BOTTOM, "Select Random", function()
        spawnWep:SetString( "random" )
        AddNotification( "Selected random as a spawn weapon!", NOTIFY_GENERIC, 3 )
        PlaySound( "buttons/button15.wav" )
        mainframe:Close()
    end )
end

local function OpenWeaponPermissionPanel( ply ) 
    if !ply:IsSuperAdmin() then 
        AddNotification( "You must be a Super Admin in order to use this!", 1, 4 )
        PlaySound( "buttons/button10.wav" ) 
        return 
    end

    local mainframe = LAMBDAPANELS:CreateFrame( "Weapon Permissions", 700, 500 )
    local mainscroll = LAMBDAPANELS:CreateScrollPanel( mainframe, true, FILL )

    LAMBDAPANELS:CreateLabel( "Press the weapon category button to toggle all weapons at once", mainframe, TOP )

    local weporiginlist = {}
    local wepcheckboxlist = {}

    for weporigin, _ in pairs( _LAMBDAPLAYERSWEAPONORIGINS ) do
        wepcheckboxlist[ weporigin ] = {}

        local originpanel = LAMBDAPANELS:CreateBasicPanel( mainscroll, LEFT )
        originpanel:SetSize( 200, 400 )
        weporiginlist[ #weporiginlist + 1 ] = originpanel

        LAMBDAPANELS:CreateButton( originpanel, TOP, weporigin, function()
            local checkedcount, uncheckcount = 0, 0
            for _, checkbox in pairs( wepcheckboxlist[ weporigin ] ) do
                if checkbox:GetChecked() then
                    checkedcount = ( checkedcount + 1 )
                else
                    uncheckcount = ( uncheckcount + 1 )
                end
            end

            for cvarName, checkbox in pairs( wepcheckboxlist[ weporigin ] ) do
                local value = ( checkedcount <= uncheckcount )
                checkbox:SetChecked( value )

                net.Start( "lambdaplayers_updateconvar" )
                    net.WriteString( cvarName )
                    net.WriteString( value and "1" or "0" )
                net.SendToServer()
            end
        end )

        local originscroll = LAMBDAPANELS:CreateScrollPanel( originpanel, false, FILL )
        mainscroll:AddPanel( originpanel )

        local wepcheckboxdata = {}

        for name, data in pairs( _LAMBDAPLAYERSWEAPONS ) do
            if name == "none" then continue end
            if data.origin != weporigin then continue end
            wepcheckboxdata[ data.notagprettyname ] = _LAMBDAWEAPONALLOWCONVARS[ name ]
        end

        for name, cvar in SortedPairs( wepcheckboxdata ) do
            local checkbox, checkpanel = LAMBDAPANELS:CreateCheckBox( originscroll, TOP, cvar:GetBool(), name )
            checkpanel:DockMargin( 2, 2, 0, 2 )

            function checkbox:OnChange( value )
                net.Start( "lambdaplayers_updateconvar" )
                    net.WriteString( cvar:GetName() )
                    net.WriteString( value and "1" or "0" )
                net.SendToServer()
            end

            wepcheckboxlist[ weporigin ][ cvar:GetName() ] = checkbox
        end
    end

    function mainframe:OnSizeChanged( width )
        local columnWidth = max( 200, ( width - 10 ) / #weporiginlist )
        for _, list in ipairs( weporiginlist ) do
            list:SetWidth( columnWidth )
        end
    end
    mainframe:OnSizeChanged( mainframe:GetWide() )
end

CreateLambdaConsoleCommand( "lambdaplayers_lambda_openspawnweaponpanel", OpenSpawnWeaponPanel, true, "Opens a panel that allows you to select the weapon the next spawned Lambda Player by you will start with", { name = "Select Spawn Weapon", category = "Lambda Weapons" } )
CreateLambdaConsoleCommand( "lambdaplayers_lambda_openweaponpermissionpanel", OpenWeaponPermissionPanel, true, "Opens a panel that allows you to allow and disallow certain weapons to be used by Lambda Players", { name = "Select Weapon Permissions", category = "Lambda Weapons" } )

-- One part of the duplicator support
-- Register the Lambdas so the duplicator knows how to handle these guys
duplicator.RegisterEntityClass( "npc_lambdaplayer", function( ply, Pos, Ang, info )

	local lambda = ents.Create( "npc_lambdaplayer" )
	lambda:SetPos( Pos )
	lambda:SetAngles( Ang )
	lambda:Spawn()

	lambda:ApplyLambdaInfo( info ) -- Apply our exported info when we were originally copied

	return lambda
end, "Pos", "Ang", "LambdaPlayerPersonalInfo" )



-- Custom ScreenScale function
-- Mostly used for testing but it's here if we want to do something with it
function LambdaScreenScale( x )
	return x * ( ScrW() / 640.0 )
end

local EntMeta = FindMetaTable("Entity")

function EntMeta:LambdaMoveMouth( weight )
    local flexID = self:GetFlexIDByName("jaw_drop")
    if flexID then self:SetFlexWeight(flexID, weight) end

    flexID = self:GetFlexIDByName("left_drop")
    if flexID then self:SetFlexWeight(flexID, weight) end

    flexID = self:GetFlexIDByName("right_drop")
    if flexID then self:SetFlexWeight(flexID, weight) end

    flexID = self:GetFlexIDByName("left_mouth_drop")
    if flexID then self:SetFlexWeight(flexID, weight) end

    flexID = self:GetFlexIDByName("right_mouth_drop")
    if flexID then self:SetFlexWeight(flexID, weight) end
end

function EntMeta:SetNWVar( key, value )
    
    if IsEntity( value ) then
        self:SetNWEntity( key, value )
    elseif isvector( value ) then
        self:SetNWVector( key, value )
    elseif isangle( value ) then
        self:SetNWAngle( key, value )
    elseif isbool( value ) then
        self:SetNWBool( key, value )
    elseif isnumber( value ) and string_find( tostring( value ), "." ) then
        self:SetNWFloat( key, value )
    elseif isnumber( value ) then
        self:SetNWInt( key, value )
    end
    
end

function EntMeta:LambdaHookTick( name, func )
    local id = self:EntIndex()
    hook.Add( "Tick", "lambdaplayers_hooktick" .. name .. id, function()
        if !IsValid( self ) then hook.Remove( "Tick", "lambdaplayers_hooktick" .. name .. id ) return end
        local result = func( self )
        if result == true then hook.Remove( "Tick", "lambdaplayers_hooktick" .. name .. id ) return end
    end )
end

function EntMeta:RemoveLambdaHookTick( name )
    local id = self:EntIndex()
    hook.Remove( "Tick", "lambdaplayers_hooktick" .. name .. id )
end

if SERVER then
    _LambdaOldEntitySetHealth = _LambdaOldEntitySetHealth or EntMeta.SetHealth
    function EntMeta:SetHealth( newHealth )
        if self.IsLambdaPlayer then self:UpdateHealthDisplay( newHealth ) end
        _LambdaOldEntitySetHealth( self, newHealth )
    end
end

local VecMeta = FindMetaTable( "Vector" )

-- Checks if the vector position is underwater. Might perform faster than ENT:WaterLevel()
local bit_band = bit.band
local util_PointContents = util.PointContents
function VecMeta:IsUnderwater()
    return ( bit_band( util_PointContents( self ), CONTENTS_WATER ) == CONTENTS_WATER )
end


local IsValid = IsValid
function LambdaIsValid( object )
	if !object then return false end

	local isvalid = object.IsValid
	if !isvalid then return false end

	if IsValid( object ) and object.IsLambdaPlayer and object:GetIsDead() then return false end

	return IsValid( object )
end


-- Used for lua_run testing purposes. It is faster to type this than Entity(1):GetEyeTrace().Entity
function _tr()
	return Entity(1):GetEyeTrace().Entity
end


-- Changes certain functions in entities that derive from base_gmodentity to support Lambda Players
function LambdaHijackGmodEntity( ent, lambda )

    function ent:SetPlayer( ply )

        self.Founder = ply
    
        if ( IsValid( ply ) ) then
    
            self:SetNWString( "FounderName", ply:Nick() )

        else
    
            self:SetNWString( "FounderName", "" )
    
        end
    
    end

	function ent:GetOverlayText()

		local txt = self:GetNWString( "GModOverlayText" )
	
		if ( txt == "" ) then
			return ""
		end
	
		local PlayerName = self:GetPlayerName()
	
		return txt .. "\n(" .. PlayerName .. ")"
	
	end

    function ent:GetPlayer()

        if ( self.Founder == nil ) then
    
            -- SetPlayer has not been called
            return NULL
    
        elseif ( IsValid( self.Founder ) ) then
    
            -- Normal operations
            return self.Founder
    
        end
    
        -- See if the player has left the server then rejoined
        local ply = lambda
        if ( !IsValid( ply ) ) then
    
            -- Oh well
            return NULL
    
        end
    
        -- Save us the check next time
        self:SetPlayer( ply )
        return ply
    
    end

end

local ents_GetAll = ents.GetAll
local lower = string.lower

-- Gets all Lambda Players currently active
function GetLambdaPlayers()
    local lambdas = {}
    for k, v in ipairs( ents_GetAll() ) do
        if IsValid( v ) and v.IsLambdaPlayer then lambdas[ #lambdas + 1 ] = v end
    end
    return lambdas
end

-- Gets a Lambda Player by their name
function GetLambdaPlayerByName( name )
    for k, v in ipairs( GetLambdaPlayers() ) do
        if lower( v:GetLambdaName() ) == lower( name ) then return v end
    end
end

function LambdaCreateThread( func )
    local thread = coroutine.create( func ) 
    hook.Add( "Think", "lambdaplayersThread_" .. tostring( func ), function() 
        if coroutine.status( thread ) != "dead" then
            local ok, msg = coroutine.resume( thread )
            if !ok then ErrorNoHaltWithStack( msg ) end
        else
            hook.Remove( "Think", "lambdaplayersThread_" .. tostring( func ) )
        end
    end )
end