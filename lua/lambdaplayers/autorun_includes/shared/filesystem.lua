local file = file
local JSONToTable = util.JSONToTable
local Decompress = util.Decompress
local TableToJSON = util.TableToJSON
local Compress = util.Compress
local table_insert = table.insert
local table_RemoveByValue = table.RemoveByValue
local file_Find = file.Find
local file_Open = file.Open
local file_Exists = file.Exists
local string_StripExtension = string.StripExtension
local string_Explode = string.Explode
local ipairs = ipairs
local pairs = pairs
local table_HasValue = table.HasValue
local table_Add = table.Add
local GetConVar = GetConVar
local mergevoicelines = GetConVar( "lambdaplayers_voice_mergeaddonvoicelines" )
local mergedefaulttextlines = GetConVar( "lambdaplayers_text_usedefaultlines" )
local mergeaddontextlines = GetConVar( "lambdaplayers_text_useaddonlines" )

file.CreateDir( "lambdaplayers" )
-- Lambda File System
LAMBDAFS = {}

-- Writes to a file. If content is a table, input json or compressed for the type arg
function LAMBDAFS:WriteFile( filename, content, type )
	local f = file_Open( filename, ( ( type == "binary" or type == "compressed" ) and "wb" or "w" ), "DATA" )
	if !f then return end

    if type == "json" then
        content = TableToJSON( content, true )
    elseif type == "compressed" then
        content = TableToJSON( content )
        content = Compress( content )
    end

	f:Write( content )
	f:Close()
end

-- Updates or creates a new file containing a sequential table
-- type should be json or compressed
function LAMBDAFS:UpdateSequentialFile( filename, addcontent, type )
    local contents = LAMBDAFS:ReadFile( filename, type, "DATA" )

    if contents then
        table_insert( contents, addcontent )
        LAMBDAFS:WriteFile( filename, contents, type )
    else
        LAMBDAFS:WriteFile( filename, { addcontent }, type )
    end

end

-- Updates or creates a new file containing a table that uses strings as keys
-- type should be json or compressed
function LAMBDAFS:UpdateKeyValueFile( filename, addcontent, type )
    local contents = LAMBDAFS:ReadFile( filename, type, "DATA" )

    if contents then
        for k, v in pairs( addcontent ) do contents[ k ] = v end
        LAMBDAFS:WriteFile( filename, contents, type )
    else
        local tbl = {}
        for k, v in pairs( addcontent ) do tbl[ k ] = v end
        LAMBDAFS:WriteFile( filename, tbl, type )
    end

end

-- If a file has the provided value
-- Only works if the file contains a sequential table
function LAMBDAFS:FileHasValue( filename, value, type )
    if !file_Exists( filename, "DATA" ) then return false end
    local contents = LAMBDAFS:ReadFile( filename, type, "DATA" )
    return table_HasValue( contents, value )
end

-- Returns if the specified key's value is valid
function LAMBDAFS:FileKeyIsValid( filename, key, type )
    if !file_Exists( filename, "DATA" ) then return false end
    local contents = LAMBDAFS:ReadFile( filename, type, "DATA" )
    return contents[ key ] != nil
end

-- SQ short for Sequential
-- Removes a value from the specified file containing a sequential table
function LAMBDAFS:RemoveVarFromSQFile( filename, var, type )
    local contents = LAMBDAFS:ReadFile( filename, type, "DATA" )
    table_RemoveByValue( contents, var )
    LAMBDAFS:WriteFile( filename, contents, type )
end

-- KV short for Key Value
-- Removes a key from the specified file containing a table that uses strings as keys
function LAMBDAFS:RemoveVarFromKVFile( filename, key, type )
    local contents = LAMBDAFS:ReadFile( filename, type, "DATA" )
    contents[ key ] = nil
    LAMBDAFS:WriteFile( filename, contents, type )
end

-- Reads from a file. If the file is a raw json, input json into the type arg and this function will return the table. If compressed json, input compressed
function LAMBDAFS:ReadFile( filename, type, path )
	if !path then path = "DATA" end

	local f = file_Open( filename, ( type == "compressed" and "rb" or "r" ), path )
	if !f then return nil end

	local str = f:Read( f:Size() )

	f:Close()

	if !str then return nil end

    if str != "" and type == "json" then
        str = JSONToTable( str )
    elseif str != "" and type == "compressed" then
        str = Decompress( str )
        str = JSONToTable( str )
    end

	return str
end



local function HandleCustomNameFile( path, default )
    local isjson = string.EndsWith( path, ".json" )
    local tbl = {}
    if isjson then
        local jsoncontents = LAMBDAFS:ReadFile( path, "json", "GAME" )

        for k, v in ipairs( jsoncontents ) do
            if !table.HasValue( default, v ) then
                table_insert( tbl, v )
            end
        end

    else
        local txtcontents = LAMBDAFS:ReadFile( path, nil, "GAME" )
        txtcontents = txtcontents and string_Explode( "\n", txtcontents ) or nil

        if txtcontents then
            for k, v in ipairs( txtcontents ) do
                if !table.HasValue( default, v ) then
                    table_insert( tbl, v )
                end
            end
        end

    end

    return tbl
end



function LAMBDAFS:GetNameTable()
    local customcontent = LAMBDAFS:ReadFile( "lambdaplayers/customnames.json", "json" ) or {}
    local defaultcontent = LAMBDAFS:ReadFile( "materials/lambdaplayers/data/names.vmt", "json", "GAME" )
    local mergedtable = table_Add( defaultcontent, customcontent )

    local function MergeDirectory( dir )
        dir = dir .. "/"
        local files, dirs = file_Find( "materials/" .. dir .. "*", "GAME", "nameasc" )
        for k, v in ipairs( files ) do table_Add( defaultcontent, HandleCustomNameFile( "materials/" .. dir .. v, defaultcontent ) ) end
        for k, v in ipairs( dirs ) do MergeDirectory( dir .. v ) end
    end
    MergeDirectory( "lambdaplayers/data/customnames" )


    return mergedtable
end

function LAMBDAFS:GetPropTable()
    local content = LAMBDAFS:ReadFile( "lambdaplayers/proplist.json", "json" )
    if !content or #content == 0 then print( "LAMBDA PLAYERS WARNING: THERE ARE NO PROPS REGISTERED!" ) end
    return content
end

function LAMBDAFS:GetMaterialTable()
    local customcontent = LAMBDAFS:ReadFile( "lambdaplayers/custommaterials.json", "json" ) or {}
    local defaultcontent = LAMBDAFS:ReadFile( "materials/lambdaplayers/data/materials.vmt", "json", "GAME" )
    local mergedtable = table_Add( defaultcontent, customcontent )

    local overridemats = list.Get( "OverrideMaterials" )

    for k, v in ipairs( overridemats ) do
        if !table_HasValue( defaultcontent, v ) then table_insert( defaultcontent, v ) end
    end

    return mergedtable
end


function LAMBDAFS:GetVoiceLinesTable()
    LambdaVoiceLinesTable = {}

    for k, v in ipairs( LambdaValidVoiceTypes ) do
        LambdaVoiceLinesTable[ v[ 1 ] ] = {}
    end

    local function MergeDirectory( dir, tbl )
        dir = dir .. "/"
        local files, dirs = file_Find( "sound/" .. dir .. "*", "GAME", "nameasc" )
        for k, v in ipairs( files ) do table_insert( tbl, dir .. v ) end
        for k, v in ipairs( dirs ) do MergeDirectory( dir .. v, tbl ) end
    end

    for k, v in ipairs( LambdaValidVoiceTypes ) do
        MergeDirectory( GetConVar( v[ 2 ] ):GetString(), LambdaVoiceLinesTable[ v[ 1 ] ] )
    end

    -- This allows the ability to make addons that add voice lines
    if mergevoicelines:GetBool() then
        for k, v in ipairs( LambdaValidVoiceTypes ) do
            MergeDirectory( "lambdaplayers/vo/custom/" .. v[ 1 ], LambdaVoiceLinesTable[ v[ 1 ] ] )
        end
    end

    return LambdaVoiceLinesTable
end

function LAMBDAFS:GetProfilePictures()
    Lambdaprofilepictures = {}

    local function MergeDirectory( dir )
        dir = dir .. "/"
        local files, dirs = file_Find( "materials/" .. dir .. "*", "GAME", "nameasc" )
        for k, v in ipairs( files ) do table_insert( Lambdaprofilepictures, dir .. v ) end
        for k, v in ipairs( dirs ) do MergeDirectory( dir .. v ) end
    end

    MergeDirectory( "lambdaplayers/custom_profilepictures" )

    return Lambdaprofilepictures
end


function LAMBDAFS:GetTextTable()
    LambdaTextTable = {}

    local function MergeDirectory( dir, path, allowed )
        dir = dir .. "/"
        local files, dirs = file_Find( path .. "/" .. dir .. "*", "GAME", "nameasc" )

        for k, v in ipairs( files ) do
            local filename = string_StripExtension( v )
            local texttype = string_Explode( "_", filename )[ 1 ] -- 1st result to the left of the underscore should always be the text type. The rest to the right is simply used for having unique names to prevent conflicts
            local content = LAMBDAFS:ReadFile( path .. "/" .. dir .. v, "json", "GAME" )

            if !content then
                local txtcontents = LAMBDAFS:ReadFile( path .. "/" .. dir .. v, nil, "GAME" )
                content = txtcontents and string_Explode( "\n", txtcontents ) or nil
            end

            if content then
                LambdaTextTable[ texttype ] = LambdaTextTable[ texttype ] or {}
                if allowed then table_Add( LambdaTextTable[ texttype ], content ) end
            end
        end

        for k, v in ipairs( dirs ) do
            MergeDirectory( dir .. v )
        end
    end


    MergeDirectory( "lambdaplayers/data/texttypes", "materials", mergedefaulttextlines:GetBool() )
    MergeDirectory( "lambdaplayers/texttypes", "materials", mergeaddontextlines:GetBool() )
    MergeDirectory( "lambdaplayers/texttypes", "data", true )

    return LambdaTextTable
end

function LAMBDAFS:GetSprays()
    LambdaPlayerSprays = {}

    local function MergeDirectory( dir )
        dir = dir .. "/"
        local files, dirs = file_Find( "materials/" .. dir .. "*", "GAME", "nameasc" )
        for k, v in ipairs( files ) do table_insert( LambdaPlayerSprays, dir .. v ) end
        for k, v in ipairs( dirs ) do MergeDirectory( dir .. v ) end
    end

    MergeDirectory( "lambdaplayers/sprays" )

    return LambdaPlayerSprays
end

function LAMBDAFS:GetVoiceProfiles()
    LambdaVoiceProfiles = {}

    local _, profileFiles = file_Find( "sound/lambdaplayers/voiceprofiles/*", "GAME", "nameasc" )
    for _, profile in ipairs( profileFiles ) do
        local profileTbl = {}
        for _, v in ipairs( LambdaValidVoiceTypes ) do
            local typeName = v[ 1 ]
            local voicelines = file_Find( "sound/lambdaplayers/voiceprofiles/" .. profile .. "/" .. typeName .. "/*", "GAME", "nameasc" )
            if !voicelines or #voicelines == 0 then continue end

            profileTbl[ typeName ] = {}
            for _, voiceline in ipairs( voicelines ) do
                table_insert( profileTbl[ typeName ], "lambdaplayers/voiceprofiles/" .. profile .. "/" .. typeName .. "/" .. voiceline )
            end
        end

        if !profileTbl[ "fall" ] and profileTbl[ "panic" ] then
            profileTbl[ "fall" ] = profileTbl[ "panic" ]
        elseif !profileTbl[ "panic" ] and profileTbl[ "fall" ] then
            profileTbl[ "panic" ] = profileTbl[ "fall" ]
        end
        LambdaVoiceProfiles[ profile ] = profileTbl
    end

    -- Zeta vp support I guess
    local _, zetavp = file_Find( "sound/zetaplayer/custom_vo/vp_*", "GAME", "nameasc" )
    for _, profile in ipairs( zetavp ) do
        local profileTbl = {}
        for _, v in ipairs( LambdaValidVoiceTypes ) do
            local typeName = v[ 1 ]
            local voicelines = file_Find( "sound/zetaplayer/custom_vo/" .. profile .. "/" .. typeName .. "/*", "GAME", "nameasc" )
            if !voicelines or #voicelines == 0 then continue end

            profileTbl[ typeName ] = {}
            for _, voiceline in ipairs( voicelines ) do
                table_insert( profileTbl[ typeName ], "zetaplayer/custom_vo/" .. profile .. "/" .. typeName .. "/" .. voiceline )
            end
        end

        if !profileTbl[ "fall" ] and profileTbl[ "panic" ] then
            profileTbl[ "fall" ] = profileTbl[ "panic" ]
        elseif !profileTbl[ "panic" ] and profileTbl[ "fall" ] then
            profileTbl[ "panic" ] = profileTbl[ "fall" ]
        end
        LambdaVoiceProfiles[ profile ] = profileTbl
    end

    return LambdaVoiceProfiles
end

function LAMBDAFS:GetTextProfiles()
    LambdaTextProfiles = {}

    local _, profileFiles = file_Find( "materials/lambdaplayers/textprofiles/*", "GAME", "nameasc" )
    for _, profile in ipairs( profileFiles ) do
        LambdaTextProfiles[ profile ] = {}

        for _, texttype in ipairs( file_Find( "materials/lambdaplayers/textprofiles/" .. profile .. "/*", "GAME", "nameasc" ) ) do
            LambdaTextProfiles[ profile ][ string_StripExtension( texttype ) ] = {}

            local content = LAMBDAFS:ReadFile( "materials/lambdaplayers/textprofiles/" .. profile .. "/" .. texttype, "json", "GAME" )
            if !content then
                local txtcontents = LAMBDAFS:ReadFile( "materials/lambdaplayers/textprofiles/" .. profile .. "/" .. texttype, nil, "GAME" )
                content = txtcontents and string_Explode( "\n", txtcontents ) or nil
            end
            if content then table_Add( LambdaTextProfiles[ profile ][ string_StripExtension( texttype ) ], content ) end
        end
    end

    return LambdaTextProfiles
end

function LAMBDAFS:GetModelVoiceProfiles()
    return LAMBDAFS:ReadFile( "lambdaplayers/modelvoiceprofiles.json", "json" ) or {}
end

function LAMBDAFS:GetPlayermodelBodySkinSets()
    return LAMBDAFS:ReadFile( "lambdaplayers/pmbodygroupsets.json", "json" ) or {}
end

function LAMBDAFS:GetQuickNadeWeapons()
    return LAMBDAFS:ReadFile( "lambdaplayers/quicknades.json", "json" ) or {}
end

function LAMBDAFS:GetEntsToFearFrom()
    return LAMBDAFS:ReadFile( "lambdaplayers/npcstofear.json", "json" ) or {}
end

if ( SERVER ) then

    if !file_Exists( "lambdaplayers/npclist.json", "DATA" ) then
        LAMBDAFS:WriteFile( "lambdaplayers/npclist.json", LAMBDAFS:ReadFile( "materials/lambdaplayers/data/defaultnpcs.vmt", nil, "GAME", false ) )
    end

    if !file_Exists( "lambdaplayers/entitylist.json", "DATA" ) then
        LAMBDAFS:WriteFile( "lambdaplayers/entitylist.json", LAMBDAFS:ReadFile( "materials/lambdaplayers/data/defaultentities.vmt", nil, "GAME", false ) )
    end

    if !file_Exists( "lambdaplayers/proplist.json", "DATA" ) then
        LAMBDAFS:WriteFile( "lambdaplayers/proplist.json", LAMBDAFS:ReadFile( "materials/lambdaplayers/data/props.vmt", nil, "GAME", false ) )
    end

    if !file_Exists( "lambdaplayers/modelvoiceprofiles.json", "DATA" ) then
        LAMBDAFS:WriteFile( "lambdaplayers/modelvoiceprofiles.json", {}, "json" )
    end

    if !file_Exists( "lambdaplayers/pmbodygroupsets.json", "DATA" ) then
        LAMBDAFS:WriteFile( "lambdaplayers/pmbodygroupsets.json", {}, "json" )
    end

    if !file_Exists( "lambdaplayers/npcstofear.json", "DATA" ) then
        LAMBDAFS:WriteFile( "lambdaplayers/npcstofear.json", {}, "json" )
    end

    if !file_Exists( "lambdaplayers/quicknades.json", "DATA" ) then
        LAMBDAFS:WriteFile( "lambdaplayers/quicknades.json", {
            "grenade",
            "slam"
        }, "json" )
    end

end