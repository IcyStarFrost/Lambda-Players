local file = file
local JSONToTable = util.JSONToTable
local Decompress = util.Decompress
local TableToJSON = util.TableToJSON
local Compress = util.Compress
local table_insert = table.insert
local table_RemoveByValue = table.RemoveByValue
local ipairs = ipairs
local table_HasValue = table.HasValue
local table_Add = table.Add
local mergevoicelines = GetConVar( "lambdaplayers_voice_mergeaddonvoicelines" )

file.CreateDir( "lambdaplayers" )
-- Lambda File System
LAMBDAFS = {}

function LAMBDAFS:WriteFile( filename, content, type ) 
	local f = file.Open( filename, "w", "DATA" )
	if !f then return end

    if type == "json" then 
        content = TableToJSON( content, true )
    elseif type == "compressed" then
        content = TableToJSON( content )
        content = Compress( content, #content )
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
    if !file.Exists( filename, "DATA" ) then return false end
    local contents = LAMBDAFS:ReadFile( filename, type, "DATA" )
    return table_HasValue( contents, value )
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


function LAMBDAFS:ReadFile( filename, type, path )
	if !path then path = "DATA" end

	local f = file.Open( filename, "r", path )
	if !f then return nil end

	local str = f:Read( f:Size() )

	f:Close()

	if !str then return nil end

    if str != "" and type == "json" then 
        str = JSONToTable( str )
    elseif str != "" and type == "compressed" then
        str = Decompress( str, #str )
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
        txtcontents = string.Explode( "\n", txtcontents )

        for k, v in ipairs( txtcontents ) do
            if !table.HasValue( default, v ) then 
                table_insert( tbl, v )
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
        local files, dirs = file.Find( "materials/" .. dir .. "*", "GAME", "nameasc" )
        for k, v in ipairs( files ) do table_Add( defaultcontent, HandleCustomNameFile( "materials/" .. dir .. v, defaultcontent ) ) end
        for k, v in ipairs( dirs ) do MergeDirectory( dir .. v ) end
    end
    MergeDirectory( "lambdaplayers/data/customnames" )


    return mergedtable
end

function LAMBDAFS:GetPropTable()
    local customcontent = LAMBDAFS:ReadFile( "lambdaplayers/customprops.json", "json" ) or {}
    local defaultcontent = LAMBDAFS:ReadFile( "materials/lambdaplayers/data/props.vmt", "json", "GAME" )
    local mergedtable = table_Add( defaultcontent, customcontent )
    return mergedtable
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
    LambdaVoiceLinesTable = { taunt = {}, idle = {}, death = {}, kill = {}, laugh = {} }

    local function MergeDirectory( dir, tbl )
        dir = dir .. "/"
        local files, dirs = file.Find( "sound/" .. dir .. "*", "GAME", "nameasc" )
        for k, v in ipairs( files ) do table_insert( tbl, dir .. v ) end
        for k, v in ipairs( dirs ) do MergeDirectory( dir .. v, tbl ) end
    end
    
    MergeDirectory( GetConVar( "lambdaplayers_voice_deathdir" ):GetString(), LambdaVoiceLinesTable.death )
    MergeDirectory( GetConVar( "lambdaplayers_voice_tauntdir" ):GetString(), LambdaVoiceLinesTable.taunt )
    MergeDirectory( GetConVar( "lambdaplayers_voice_idledir" ):GetString(), LambdaVoiceLinesTable.idle )
    MergeDirectory( GetConVar( "lambdaplayers_voice_killdir" ):GetString(), LambdaVoiceLinesTable.kill )
    MergeDirectory( GetConVar( "lambdaplayers_voice_laughdir" ):GetString(), LambdaVoiceLinesTable.laugh )

    -- This allows the ability to make addons that add voice lines
    if mergevoicelines:GetBool() then
        MergeDirectory( "lambdaplayers/vo/custom/death", LambdaVoiceLinesTable.death )
        MergeDirectory( "lambdaplayers/vo/custom/taunt", LambdaVoiceLinesTable.taunt )
        MergeDirectory( "lambdaplayers/vo/custom/idle", LambdaVoiceLinesTable.idle )
        MergeDirectory( "lambdaplayers/vo/custom/kill", LambdaVoiceLinesTable.kill )
        MergeDirectory( "lambdaplayers/vo/custom/laugh", LambdaVoiceLinesTable.laugh )
    end
    
    return LambdaVoiceLinesTable
end

function LAMBDAFS:GetProfilePictures()
    Lambdaprofilepictures = {}

    local function MergeDirectory( dir )
        dir = dir .. "/"
        local files, dirs = file.Find( "materials/" .. dir .. "*", "GAME", "nameasc" )
        for k, v in ipairs( files ) do table_insert( Lambdaprofilepictures, dir .. v ) end
        for k, v in ipairs( dirs ) do MergeDirectory( dir .. v ) end
    end

    MergeDirectory( "lambdaplayers/custom_profilepictures" )
    
    return Lambdaprofilepictures
end


local validvoicetypes = { "death", "kill", "idle", "taunt", "laugh" }
function LAMBDAFS:GetVoiceProfiles()
    local LambdaVoiceProfiles = {}

    local _,voiceprofiles  = file.Find( "sound/lambdaplayers/voiceprofiles/*", "GAME", "nameasc" )

    for i, profile in ipairs( voiceprofiles ) do
        LambdaVoiceProfiles[ profile ] = {} 

        for k, v in ipairs( validvoicetypes ) do 
            local voicelines,_  = file.Find( "sound/lambdaplayers/voiceprofiles/" .. profile .. "/" .. v .. "/*", "GAME", "nameasc" )

            if voicelines and #voicelines > 0 then
                LambdaVoiceProfiles[ profile ][ v ] = {}
                for index, voiceline in ipairs( voicelines ) do
                    table_insert( LambdaVoiceProfiles[ profile ][ v ], "lambdaplayers/voiceprofiles/" .. profile .. "/" .. v .. "/" .. voiceline )
                end
            else
                LambdaVoiceProfiles[ profile ][ v ] = LambdaVoiceLinesTable[ v ]
            end

        end

    end

    
    return LambdaVoiceProfiles
end


LambdaPersonalProfiles = LambdaPersonalProfiles or file.Exists( "lambdaplayers/profiles.json", "DATA" ) and LAMBDAFS:ReadFile( "lambdaplayers/profiles.json", "json" ) or nil
LambdaPlayerNames = LambdaPlayerNames or LAMBDAFS:GetNameTable()
LambdaPlayerProps = LambdaPlayerProps or LAMBDAFS:GetPropTable()
LambdaPlayerMaterials = LambdaPlayerMaterials or LAMBDAFS:GetMaterialTable()
Lambdaprofilepictures = Lambdaprofilepictures or LAMBDAFS:GetProfilePictures()
LambdaVoiceLinesTable = LambdaVoiceLinesTable or LAMBDAFS:GetVoiceLinesTable()
LambdaVoiceProfiles = LambdaVoiceProfiles or LAMBDAFS:GetVoiceProfiles()