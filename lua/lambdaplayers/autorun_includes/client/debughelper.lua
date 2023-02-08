local debugmode = GetConVar( "lambdaplayers_debug" )
local cam = cam
local draw = draw 
local render = render 
local ipairs = ipairs 
local ents = ents

local function AddTextToQueue( tbl, text, color )
    tbl[ #tbl + 1 ] = { text, color }
end

local entitycol = Color( 155, 0, 0)
local stringcol = Color( 163, 106, 0)
local boolcol = Color( 0, 89, 255)

-- Pretty much to help debugging or testing
hook.Add( "PreDrawEffects", "lambdaplayers-debughelper", function()
    if !debugmode:GetBool() then return end

    for k, lambda in ipairs( ents.FindByClass( "npc_lambdaplayer" ) ) do 
        if IsValid( lambda ) and lambda:GetPos():DistToSqr( LocalPlayer():GetPos() ) < 2000 ^ 2 then
            local ang = EyeAngles()
            local pos = lambda:GetPos() + lambda:GetUp() * ( lambda:GetModelRadius()  * 1.2 )
            local queue = {}
            local hp = lambda:GetNW2Float( "lambda_health", "NAN" )
            hp = hp == "NAN" and lambda:GetNWFloat( "lambda_health", "NAN" ) or hp

            ang:RotateAroundAxis( ang:Up(), -90 )
            ang:RotateAroundAxis( ang:Forward(), 90 )
            

            render.DepthRange( 0, 0 )
            cam.Start3D2D( pos, ang, 0.1 )

                AddTextToQueue( queue, "LAMBDA IS CROUCHING: " .. tostring( lambda:GetCrouch() ), boolcol )
                AddTextToQueue( queue, "LAMBDA IS DEAD: " .. tostring( lambda:GetIsDead() ), boolcol )
                AddTextToQueue( queue, "LAMBDA IS TYPING: " .. tostring( lambda:GetIsTyping() ), boolcol )
                AddTextToQueue( queue, "LAMBDA IS RELOADING: " .. tostring( lambda:GetIsReloading() ), boolcol )
                AddTextToQueue( queue, "LAMBDA IS NOCLIPPING: " .. tostring( lambda:GetNoClip() ), boolcol )
                AddTextToQueue( queue, "LAMBDA FAKE STEAMID: " .. lambda:GetNW2String( "lambda_steamid", "{ UNAVAILABLE }" ), stringcol )
                AddTextToQueue( queue, "LAMBDA TEXT PROFILE: " .. lambda:GetNW2String( "lambda_tp", "{ UNAVAILABLE }" ), stringcol )
                AddTextToQueue( queue, "LAMBDA VOICE PROFILE: " .. lambda:GetNW2String( "lambda_vp", "{ UNAVAILABLE }" ), stringcol )
                AddTextToQueue( queue, "LAMBDA LAST STATE: " .. lambda:GetNW2String( "lambda_laststate", "{ UNAVAILABLE }" ), stringcol )
                AddTextToQueue( queue, "LAMBDA STATE: " .. lambda:GetNW2String( "lambda_state", "{ UNAVAILABLE }" ), stringcol )
                AddTextToQueue( queue, "LAMBDA CURRENT PROFILE PICTURE: " .. lambda:GetProfilePicture(), stringcol )
                AddTextToQueue( queue, "LAMBDA CURRENT WEAPON: " .. lambda:GetWeaponName(), stringcol )
                AddTextToQueue( queue, "LAMBDA ENEMY: " .. tostring( lambda:GetEnemy() ), entitycol )
                AddTextToQueue( queue, "LAMBDA TIME SINCE INITIALIZE: " .. string.NiceTime( math.Round( SysTime() - lambda.debuginitstart, 2 ) ), color_white )
                AddTextToQueue( queue, "LAMBDA ENT INDEX: " .. lambda:EntIndex(), color_white )
                AddTextToQueue( queue, "LAMBDA MAX ARMOR: " .. lambda:GetMaxArmor(), color_white )
                AddTextToQueue( queue, "LAMBDA MAX HEALTH: " .. lambda:GetNWMaxHealth(), color_white )
                AddTextToQueue( queue, "LAMBDA ARMOR: " .. lambda:GetArmor(), color_white )
                AddTextToQueue( queue, "LAMBDA HEALTH: " .. hp, color_white )
                AddTextToQueue( queue, "LAMBDA NAME: " .. lambda:GetLambdaName(), stringcol )

                for i = 1, #queue do
                    local tbl = queue[ i ]
                    draw.DrawText( tbl[ 1 ], "Trebuchet24", 0, 30 - ( 30 * i ), tbl[ 2 ], TEXT_ALIGN_CENTER )
                end


            cam.End3D2D()

            render.DepthRange( 0, 1 )

            lambda.l_debugpfpcache = lambda.l_debugpfpcache or Material( lambda:GetProfilePicture() )
            render.SetMaterial( lambda.l_debugpfpcache )
            render.DrawSprite( lambda:WorldSpaceCenter() + EyeAngles():Right() * 36, 32, 32, color_white )
            
        end
    end
end )