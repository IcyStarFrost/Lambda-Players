-- Function for the cvar callback
-- This seems to work alright
local uiscale = GetConVar( "lambdaplayers_uiscale" )
local function UpdateFonts()
    surface.CreateFont( "lambdaplayers_displayname", {
    font = "TargetID",
    extended = false,
    size = LambdaScreenScale( 7 + uiscale:GetFloat() ),
    weight = 0,
    blursize = 0,
    scanlines = 0,
    antialias = false,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = true,
    additive = false,
    outline = false,
    } )

    surface.CreateFont( "lambdaplayers_voicepopuptext", {
        font = "Trebuchet MS",
        size = LambdaScreenScale( 8 + uiscale:GetFloat() ),
        shadows = true
    })

    surface.CreateFont( "lambdaplayers_healthfont", {
        font = "ChatFont",
        size = LambdaScreenScale( 7 + uiscale:GetFloat() ),
        weight = 0,
        shadow = true
    })
end
UpdateFonts()


cvars.AddChangeCallback( "lambdaplayers_uiscale", UpdateFonts )