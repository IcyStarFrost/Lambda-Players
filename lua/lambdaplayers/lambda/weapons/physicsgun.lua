

local physgunGlowMat = Material("sprites/physg_glow1")
local physgunGlowMat2 = Material("sprites/physg_glow2")

local physgunbeam = Material( "sprites/physbeama" )

local random = math.random
local IsValid = IsValid
local TraceEntity = util.TraceEntity
local LerpVector = LerpVector
local min = math.min
local max = math.max
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

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    physgun = {
        model = "models/weapons/w_physics.mdl",
        origin = "Garry's Mod",
        prettyname = "Physics Gun",
        bonemerge = true,
        holdtype = "physgun",

        OnEquip = function( lambda, wepent )
            wepent:SetSkin( 1 )
            wepent:SetSubMaterial( 1, "lambdaplayers/physgun/w_physics_sheet2")

            
            if allowphysgunuse:GetBool() then
                local endpos = Vector()
                local physgunactive = false
                local physdistance = 0
                lambda.l_physgungrabbedent = nil

                lambda:Hook( "Think", "physgunthink", function()
                    wepent:SetNW2Vector( "lambda_physgunendpos", endpos )
                    wepent:SetNW2Bool( "lambda_physgundraw", IsValid( lambda.l_physgungrabbedent ) )

                    if IsValid( lambda.l_physgungrabbedent ) then

                        if lambda.l_physgungrabbedent:IsPlayer() or lambda.l_physgungrabbedent:IsNPC() or lambda.l_physgungrabbedent:IsNextBot() then
                            trace.start = lambda.l_physgungrabbedent:GetPos()
                            trace.endpos = wepent:GetPos() + wepent:GetForward() * physdistance
                            trace.filter = function( ent ) return ent == lambda.l_physgungrabbedent end
                
                            local result = TraceEntity( trace, lambda.l_physgungrabbedent )
                            lambda.l_physgungrabbedent:SetPos( result.HitPos )
                        else
                
                            local phys = lambda.l_physgungrabbedent:GetPhysicsObject()
                
                            if phys:IsValid() then
                                phys:EnableMotion( true )
                                local dist = ( ( wepent:GetPos() + wepent:GetForward() * physdistance ) + Vector( 0, 0, 50 ) ) - lambda.l_physgungrabbedent:GetPos()
                                local dir = dist:GetNormalized()
                                local speed = min( 5000 / 2, dist:Dot( dir ) * 5 ) * dir + lambda.l_physgungrabbedent:GetVelocity() * 0.5
                                speed = max( min( 5000, speed:Dot( dir ) ), -1000 )
                                    
                                phys:SetVelocity( ( speed ) * dir )
                            else
                                traceData.start = lambda.l_physgungrabbedent:GetPos()
                                traceData.endpos = wepent:GetPos() + wepent:GetForward() * self.PhysgunBeamDistance
                                traceData.filter = function( ent ) return ent == lambda.l_physgungrabbedent end
                
                                local traceResult = util.TraceEntity( traceData, lambda.l_physgungrabbedent )
                                lambda.l_physgungrabbedent:SetPos( traceResult.HitPos )
                            end
                        end


                    end


                end )
                
                lambda:Thread( function()

                    while true do 
                        if lambda:GetState() == "Idle" and !physgunactive then
                            local possibleents = lambda:FindInSphere( nil, 1500, function( ent ) return lambda:HasVPhysics( ent ) and lambda:HasPermissionToEdit( ent ) and lambda:CanSee( ent ) end )
                            local ent = possibleents[ random( #possibleents ) ]

                            if IsValid( ent ) then

                                lambda:LookTo( ent, 2 )

                                coroutine.wait( 1 )

                                local result = lambda:Trace( ent )
                                endpos = ent:WorldToLocal( result.HitPos )
                                
                                wepent:SetNW2Entity( "lambda_physgunent", ent )
                                wepent:SetNW2Vector( "lambda_physgunendpos", endpos )
                                wepent:SetNW2Bool( "lambda_physgundraw", true )
                                physgunactive = true

                                local range = lambda:GetRangeTo( ent )
                                physdistance = range < 100 and 200 or range
                                lambda.l_physgungrabbedent = ent

                            end

                        elseif physgunactive and random( 1, 6 ) == 1 then
                            lambda.l_physgungrabbedent = nil
                            wepent:SetNW2Bool( "lambda_physgundraw", false )
                        end

                        coroutine.wait( 3 )
                    end

                end, "PhysgunThread" )
            end

        end,

        OnDamage = function( lambda, wepent, info )
            if info:GetInflictor() == lambda.l_physgungrabbedent then info:SetDamage( 0 ) end
        end,

        -- Custom rendering effects
        Draw = function( lambda, wepent )

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

        OnUnequip = function( lambda, wepent )
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