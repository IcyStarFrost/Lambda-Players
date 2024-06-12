AddCSLuaFile()

if ( CLIENT ) then
    TOOL.Information = { { name = "left" }, { name = "right" } }
    TOOL.ClientConVar = { [ "spraypath" ] = "" }

    language.Add("tool.lambdasprayspawner", "Lambda Sprayer")
    language.Add("tool.lambdasprayspawner.name", "Lambda Sprayer")
    language.Add("tool.lambdasprayspawner.desc", "Creates Sprays" )
    language.Add("tool.lambdasprayspawner.left", "Fire onto a surface to spawn a random spray" )
    language.Add("tool.lambdasprayspawner.right", "Fire onto a surface to spawn a selected spray via spawn menu" )
end

TOOL.Tab = "Lambda Player"
TOOL.Category = "Tools"
TOOL.Name = "#tool.lambdasprayspawner"


local Entity = Entity
local IsValid = IsValid
local ipairs = ipairs
local file_Find = file.Find
local string_EndsWith = string.EndsWith
local string_Replace = string.Replace
local CreateMaterial = CreateMaterial
local Material = Material
local RunConsoleCommand = RunConsoleCommand

function TOOL:LeftClick( tr )
    if tr.Entity != Entity( 0 ) then return false end

    local spray = LambdaPlayerSprays[ LambdaRNG( #LambdaPlayerSprays ) ]
    if !spray then self:GetOwner():ChatPrint( "You do not have any sprays loaded!" ) return false end

    LambdaPlayers_Spray( spray, tr.HitPos, tr.HitNormal )
    return true
end

function TOOL:RightClick( tr )
    if tr.Entity != Entity( 0 ) then return false end

    local val = self:GetClientInfo( "spraypath" )
    if !val or val == "" then return false end

    LambdaPlayers_Spray( val, tr.HitPos, tr.HitNormal )
    return true
end

local index = 0

function TOOL.BuildCPanel( pnl )
    local lbl = pnl:Help( "Click on a spray to select it then use right click any where on the world to paste it.\n\nScanning sprays.." )

    local frame = vgui.Create( "DPanel", pnl )
    frame:SetSize( 300, 600 )
    pnl:AddItem( frame )

    local scroll = vgui.Create( "DScrollPanel", frame )
    scroll:Dock( FILL )

    local filecount = 0 
    local checkedcount = 0

    local function RecursiveFindNum( dir )
        local files, dirs = file_Find( dir .. "/*", "GAME", "datedesc" )
        filecount = filecount + #files
        for k, v in ipairs( dirs ) do while !pnl:IsVisible() do coroutine.yield() end RecursiveFindNum( dir .. "/" .. v ) end
        coroutine.yield()
    end

    local function RecursiveFind( dir )
        local files, dirs = file_Find( dir .. "/*", "GAME", "datedesc" )

        for k, v in ipairs( files ) do  
            if !IsValid( pnl ) then return end

            checkedcount = checkedcount + 1

            lbl:SetText( "Click on a spray to select it then use right click any where on the world to paste it.\n\nImporting Sprays.. " .. ( math.Round( math.Remap( checkedcount, 0, filecount, 0, 100 ), 0 ) ) .. "% imported"  )

            local isVTF = string_EndsWith( string_Replace( dir .. "/" .. v, "materials/", "" ), ".vtf" ) -- If the file is a VTF
            local material
        
            if isVTF then
                index = index + 1

                material = CreateMaterial( "lambdaspraytoolVTFmaterial" .. index, "UnlitGeneric", {
                    [ "$basetexture" ] = string_Replace( dir .. "/" .. v, "materials/", "" ),
                    [ "$translucent" ] = 1,
                    [ "Proxies" ] = {
                        [ "AnimatedTexture" ] = {
                            [ "animatedTextureVar" ] = "$basetexture",
                            [ "animatedTextureFrameNumVar" ] = "$frame",
                            [ "animatedTextureFrameRate" ] = 10
                        }
                    }
                })
            else
                material = Material( string_Replace( dir .. "/" .. v, "materials/", "" ) )
            end

            local image = vgui.Create( "DImageButton", scroll )
            image:SetSize( 300, 300 )
            image:Dock( TOP )
            image:SetMaterial( material )

            function image:DoClick()
                RunConsoleCommand( "lambdasprayspawner_spraypath", string_Replace( dir .. "/" .. v, "materials/", "" ) )
            end

            coroutine.wait( 0.05 )
        end

        for _, v in ipairs( dirs ) do if IsValid( pnl ) then RecursiveFind( dir .. "/" .. v ) end end
    end

    LambdaCreateThread( function()
        RecursiveFindNum( "materials/lambdaplayers/sprays" )
        RecursiveFind( "materials/lambdaplayers/sprays" )
        lbl:SetText( "Click on a spray to select it then use right click any where on the world to paste it.\n\nFinished!"  )
    end )
end