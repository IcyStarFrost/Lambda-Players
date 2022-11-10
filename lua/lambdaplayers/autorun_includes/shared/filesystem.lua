local file = file
local JSONToTable = util.JSONToTable
local Decompress = util.Decompress
local TableToJSON = util.TableToJSON
local Compress = util.Compress
local table_insert = table.insert
local ipairs = ipairs
local table_Add = table.Add
file.CreateDir( "lambdaplayers" )
file.CreateDir( "lambdaplayers/custom_profilepictures" )
-- Lambda File System
LAMBDAFS = {}

function LAMBDAFS:WriteFile( filename, content, type ) 
	local f = file.Open( filename, "w", "DATA" )
	if !f then return end

    if type == "json" then 
        contents = TableToJSON( contents )
    elseif type == "compressed" then
        contents = TableToJSON( contents )
        contents = Compress( contents, #contents )
    end

	f:Write( contents )
	f:Close()
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

function LAMBDAFS:GetNameTable()
    local customcontent = LAMBDAFS:ReadFile( "lambdaplayers/customnames.json", "json" ) or {}
    local defaultcontent = LAMBDAFS:ReadFile( "materials/lambdaplayers/data/names.vmt", "json", "GAME" )
    local mergedtable = table_Add( defaultcontent, customcontent )
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
    return mergedtable
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