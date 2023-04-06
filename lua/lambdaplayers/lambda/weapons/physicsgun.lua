

local physgunGlowMat = Material("sprites/physg_glow1")
local physgunGlowMat2 = Material("sprites/physg_glow2")

local physgunbeam = Material( "sprites/physbeama" )

local random = math.random
local IsValid = IsValid
local TraceEntity = util.TraceEntity
local LerpVector = LerpVector
local Angle = Angle
local min = math.min
local max = math.max
local util_TraceEntity = util.TraceEntity
local math_ApproachAngle = math.ApproachAngle
local render = render or nil
local trace = {}

local allowphysgunuse = GetConVar( "lambdaplayers_lambda_allowphysgunpickup" )

--[[ local function CreatePhysgunBeam( owner )
    local wep = owner:GetWeaponENT()
    local attach = wep:GetAttachment( 1 )

    local beam = ents.Create( "lambda_physgunbeam" )
    beam:SetPos( attach.Pos )
    beam:SetAngles( attach.Ang )
    beam:SetParent( wep, 1 ) 
    beam:Spawn()
    beam:SetPhysColor( owner:GetPhysColor() )

    return beam
end ]]

local ignoreentclasses = {
    [ "func_door" ] = true,
    [ "func_door_rotating" ] = true,
    [ "prop_door_rotating" ] = true,
    [ "prop_dynamic" ] = true,
    [ "prop_dynamic_override" ] = true,
    [ "func_button" ] = true,
}

local function ApproachAngle( a1, a2 )
    local p = math_ApproachAngle( a1[ 1 ], a2[ 1 ], 5 )
    local y = math_ApproachAngle( a1[ 2 ], a2[ 2 ], 5 )
    local r = math_ApproachAngle( a1[ 3 ], a2[ 3 ], 5 )
    return Angle( p, y, r )
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    physgun = {
        model = "models/weapons/w_physics.mdl",
        origin = "Garry's Mod",
        prettyname = "Physics Gun",
        bonemerge = true,
        holdtype = "physgun",
        killicon = "weapon_physcannon",

        OnDeploy = function( lambda, wepent )
            wepent:SetSkin( 1 )
            wepent:SetSubMaterial( 1, "models/lambdaplayers/weapons/physgun/w_physics_sheet2")

            
            if allowphysgunuse:GetBool() then
                local endpos = Vector()
                local physgunactive = false
                lambda.l_physdistance = 0
                lambda.l_physgungrabbedent = nil

                lambda:Hook( "Think", "physgunthink", function()
                    wepent:SetNW2Vector( "lambda_physgunendpos", endpos )
                    wepent:SetNW2Bool( "lambda_physgundraw", IsValid( lambda.l_physgungrabbedent ) )

                    if IsValid( lambda.l_physgungrabbedent ) then

                        if lambda.l_physgungrabbedent:IsPlayer() or lambda.l_physgungrabbedent:IsNPC() or lambda.l_physgungrabbedent:IsNextBot() then
                            trace.start = lambda.l_physgungrabbedent:GetPos()
                            trace.endpos = wepent:GetPos() + wepent:GetForward() * lambda.l_physdistance
                            trace.filter = function( ent ) return ent == lambda.l_physgungrabbedent end
                
                            local result = TraceEntity( trace, lambda.l_physgungrabbedent )
                            lambda.l_physgungrabbedent:SetPos( result.HitPos )
                        else
                
                            local phys = lambda.l_physgungrabbedent:GetPhysicsObject()
                
                            if phys:IsValid() then
                                phys:EnableMotion( true )
                                local dist = ( !lambda.l_physholdpos and ( wepent:GetPos() + wepent:GetForward() * lambda.l_physdistance ) or lambda.l_physholdpos ) - lambda.l_physgungrabbedent:GetPos()
                                local dir = dist:GetNormalized()

                                local speed = min( 5000 / 2, dist:Dot( dir ) * 5 ) * dir + lambda.l_physgungrabbedent:GetVelocity() * 0.5
                                speed = max( min( 5000, speed:Dot( dir ) ), -1000 )
                                    
                                phys:SetVelocity( ( speed ) * dir )

                                if lambda.l_physholdang then
                                    local ang = ApproachAngle( lambda.l_physgungrabbedent:GetAngles(), lambda.l_physholdang )
                                    phys:SetAngles( ang )
                                end

                            else
                                trace.start = lambda.l_physgungrabbedent:GetPos()
                                trace.endpos = wepent:GetPos() + wepent:GetForward() * lambda.l_physdistance
                                trace.filter = function( ent ) return ent == lambda.l_physgungrabbedent end
                
                                local traceResult = util_TraceEntity( trace, lambda.l_physgungrabbedent )
                                lambda.l_physgungrabbedent:SetPos( traceResult.HitPos )
                            end
                        end


                    end


                end )
                
                lambda:Thread( function()

                    while true do 
                        if lambda:GetState() == "Idle" and !lambda:IsDisabled() and !physgunactive and random( 1, 3 ) == 1 then
                            local possibleents = lambda:FindInSphere( nil, 1500, function( ent ) return !ignoreentclasses[ ent:GetClass() ] and lambda:HasVPhysics( ent ) and lambda:HasPermissionToEdit( ent ) and lambda:CanSee( ent ) end )
                            local ent = possibleents[ random( #possibleents ) ]

                            if IsValid( ent ) then

                                lambda:LookTo( ent, 2 )

                                coroutine.wait( 1 )
                                if IsValid( ent ) then

                                    local result = lambda:Trace( ent )
                                    endpos = ent:WorldToLocal( result.HitPos )
                                    
                                    wepent:SetNW2Entity( "lambda_physgunent", ent )
                                    wepent:SetNW2Vector( "lambda_physgunendpos", endpos )
                                    wepent:SetNW2Bool( "lambda_physgundraw", true )
                                    physgunactive = true

                                    local range = lambda:GetRangeTo( ent )
                                    lambda.l_physdistance = range < 100 and 200 or range
                                    lambda.l_physgungrabbedent = ent

                                end

                            end

                        elseif physgunactive and !lambda.l_allowdropphys and random( 1, 6 ) == 1 then
                            lambda.l_physgungrabbedent = nil
                            wepent:SetNW2Bool( "lambda_physgundraw", false )
                        end

                        coroutine.wait( 3 )
                    end

                end, "PhysgunThread" )
            end

        end,

        OnTakeDamage = function( lambda, wepent, info )
            if info:GetInflictor() == lambda.l_physgungrabbedent then return true end
        end,

        OnAttack = function( lambda, wepent, ent )
            if IsValid( ent ) then

                local result = lambda:Trace( ent )
                endpos = ent:WorldToLocal( result.HitPos )
                
                wepent:SetNW2Entity( "lambda_physgunent", ent )
                wepent:SetNW2Vector( "lambda_physgunendpos", endpos )
                wepent:SetNW2Bool( "lambda_physgundraw", true )
                physgunactive = true

                local range = lambda:GetRangeTo( ent )
                lambda.l_physdistance = range < 100 and 200 or range
                lambda.l_physgungrabbedent = ent

            else
                wepent:SetNW2Entity( "lambda_physgunent", NULL )
                wepent:SetNW2Vector( "lambda_physgunendpos", Vector() )
                wepent:SetNW2Bool( "lambda_physgundraw", false )
                physgunactive = false
                lambda.l_physdistance = 0
                lambda.l_physgungrabbedent = nil
            end
            return true
        end,

        -- Custom rendering effects
        OnDraw = function( lambda, wepent )

            if IsValid( wepent ) then
                
                local size = random( 30, 50 )
                local drawPos = ( wepent:GetPos() + wepent:GetUp() * 2 )
                local color = lambda:GetPhysColor()

                render.SetMaterial( physgunGlowMat )
                render.DrawSprite( drawPos + wepent:GetForward() * 25, size, size, color:ToColor() )

                render.SetMaterial( physgunGlowMat2 )
                render.DrawSprite( drawPos + wepent:GetForward() * 30, size, size, color:ToColor() )



                if wepent:GetNW2Bool( "lambda_physgundraw", false ) then

                local attach = wepent:GetAttachment( 1 )

                local s = attach.Pos
                local e = wepent:GetNW2Vector( "lambda_physgunendpos", Vector() )
                local forward = wepent:GetForward()
                local target = wepent:GetNW2Entity( "lambda_physgunent", nil )
                local segments = 10
                local color = lambda:GetPhysColor():ToColor()
                local size = random( 10, 15 )
        
                -- Apparently this how we make the pointer and beam "Stick" to a certain spot of the target with a localized endpos to them
                if IsValid( target ) then
                    e = target:GetPos() + target:GetForward() * e[ 1 ] + target:GetRight() * -e[ 2 ] + target:GetUp() * e[ 3 ]
                end
        
                render.SetMaterial( physgunbeam )
        
                render.StartBeam( segments + 2 )
        
                    render.AddBeam( s, random( 1, 2 ), random( 1, 10 ), color )
        
                    for i=1, segments do
                        
                        -- This actually makes a pretty decent beam
                        local lerp = LerpVector( i / 15, s + forward * ( 2 + i * 10 ), e )
        
                        render.AddBeam( lerp, random( 1, 2 ), random( 1, 10 ), color )
        
                    end
        
                    render.AddBeam( e, random( 1, 2 ), random( 1, 10 ), color )
        
                render.EndBeam()
        
                -- End of the beam glowy bit
                render.SetMaterial( physgunGlowMat )
                render.DrawSprite( e, size, size, color )
        
        
            end

            end

        end,

        OnHolster = function( lambda, wepent )
            lambda:KillThread( "PhysgunThread" )
            lambda:RemoveHook( "Think", "physgunthink" )
            lambda.l_physgungrabbedent = nil
            wepent:SetNW2Entity( "lambda_physgunent", nil )
            wepent:SetNW2Bool( "lambda_physgundraw", false )
            wepent:SetSkin( 0 )
            wepent:SetSubMaterial( 1 )
        end,


        islethal = false,

    }

})