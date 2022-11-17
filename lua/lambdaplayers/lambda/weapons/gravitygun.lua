local random = math.random
local math_min = math.min
local IsValid = IsValid
local util_Effect = util.Effect
local tracetbl = {}

-- Effects for gravity gun idle
local ggunGlowSprite = Material("sprites/glow04_noz")

-- Effects for pulling and grabbing active
--local ggunCapSprite = Material("sprites/orangeflare1")
--local ggunCoreSprite = Material("sprites/orangecore1")

local punted = false
local blastStart, smoothBlast, smoothBlastA = 0, 0, 255
local blastTarget = false
local color = Color(255,255,255,255)

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    gravgun = {
        model = "models/weapons/w_physics.mdl",
        origin = "Garry's Mod",
        prettyname = "Gravity Gun",
        killicon = "weapon_physcannon", -- No idea if this is needed but why not
        bonemerge = true,
        holdtype = "physgun",

        Draw = function( lambda, wepent )
            if IsValid( wepent ) then
                local attachtab = { "fork1m", "fork1t", "fork2m", "fork2t", "fork3m", "fork3t" }
                local sizeBlast = 0

                for i = 1, #attachtab do
                    local at = wepent:GetAttachment( wepent:LookupAttachment( attachtab[i] ) )
                    render.SetMaterial( ggunGlowSprite )
                    render.DrawSprite( at.Pos, 6, 6, Color(255, 128, 0, 64) )
                end

                -- For pulling and grabbing active effect
                --[[render.SetMaterial( ggunCapSprite )
                render.DrawSprite( wepent:GetAttachment( wepent:LookupAttachment( "fork1t" ) ).Pos, size, size, Color(255,255,255,255) )
                render.DrawSprite( wepent:GetAttachment( wepent:LookupAttachment( "fork2t" ) ).Pos, size, size, Color(255,255,255,255) )
                render.DrawSprite( wepent:GetAttachment( wepent:LookupAttachment( "fork3t" ) ).Pos, size, size, Color(255,255,255,255) )
                
                render.SetMaterial( ggunCoreSprite )
                render.DrawSprite( wepent:GetAttachment( wepent:LookupAttachment( "core" ) ).Pos, 13, 13, Color(255,255,255,255) )
                ]]
            end
        end,

        OnEquip = function( lambda, wepent )
            -- Pretty much will punt any prop they get close to
            lambda:Hook( "Think", "GravityGunPuntThink", function( )
                local find = lambda:FindInSphere( lambda:GetPos(), 150, function( ent ) if !ent:IsNPC() and ent:GetClass()=="prop_physics" and !ent:IsPlayer() and !ent:IsNextBot() and lambda:CanSee( ent ) and IsValid( ent:GetPhysicsObject() ) and lambda:HasPermissionToEdit( ent ) and ent:GetPhysicsObject():IsMoveable() then return true end end )
                local prop = find[ random( #find ) ]

                lambda:LookTo( prop, 3 )

                lambda:SimpleTimer( 1, function() -- To let the Lambda aim properly
                    if !IsValid( prop ) or !IsValid( wepent ) then return end
                    lambda:UseWeapon( prop )
                end)
            
            end, true, 1) -- "Attack" prop twice then do another check (1)
        end,

        callback = function( self, wepent, target )
            self.l_WeaponUseCooldown = CurTime() + 0.4

            local phys = target:GetPhysicsObjectNum(0)

            if IsValid( phys ) then
                if self:GetRangeSquaredTo( target ) > ( 175 * 175 ) then wepent:EmitSound( "weapons/physcannon/physcannon_dryfire.wav", 70 ) return end
                wepent:EmitSound( "weapons/physcannon/superphys_launch"..random( 1, 4 )..".wav", 70, random( 110, 120 ) )

                --[[
                    for i = 0, target:GetPhysicsObjectCount() - 1 do
                    local subphys = target:GetPhysicsObjectNum(i)
                    totalMass = totalMass + subphys:GetMass()
                    end

                    local actualMass = math_min(totalMass, 250)
                    local mainPhys = target:GetPhysicsObject()

                    for i = 0, target:GetPhysicsObjectCount() - 1 do
                        local subphys = target:GetPhysicsObjectNum(i)
                        local ratio = phys:GetMass() / totalMass
                        if subphys == mainPhys then
                            ratio = ratio + 0.5
                            ratio = math_min(ratio, 1.0)
                        else
                            ratio = ratio * 0.5
                        end

                        subphys:ApplyForceCenter( self:GetAimVector() * 15000 * ratio)
                        subphys:ApplyForceOffset( self:GetAimVector() * actualMass * 600 * ratio, trace.HitPos)
                    end
                ]]-- If we ever want to punt ragdolls

                local mainPhys = target:GetPhysicsObject()
                local trace = self:Trace( target:WorldSpaceCenter() )
                local randt1 = self:Trace( target:WorldSpaceCenter() + VectorRand(-5, 15) )

                mainPhys:ApplyForceCenter( self:GetAimVector() * 15000)
                mainPhys:ApplyForceOffset( self:GetAimVector() * math_min( mainPhys:GetMass(), 250) * 600, trace.HitPos)

                local core = wepent:GetAttachment( wepent:LookupAttachment( "core" ) )

                -- See lua/effects/gravitygunbeam and gravitygunblast
                -- Simulate the punt beam blast
                local effectBeam = EffectData()
                    effectBeam:SetStart( core.Pos )
                    effectBeam:SetOrigin( trace.HitPos ) 
                    effectBeam:SetEntity( wepent )
                util_Effect( "gravitygunbeam", effectBeam, true, true) -- Beam 1 to center of target
                local effectBlast = EffectData()
                    effectBlast:SetStart( core.Pos )
                    effectBlast:SetOrigin( core.Pos )
                    effectBlast:SetEntity( wepent )
                util_Effect( "gravitygunblast", effectBlast, true, true) -- Blast effect from Gravity gun

                -- Simulate the spark that emits from punted object
                local effectSpark = EffectData()
                    effectSpark:SetOrigin( trace.HitPos )
                    effectSpark:SetNormal( trace.HitNormal )
                    effectSpark:SetScale(2)
                util_Effect( "MetalSpark", effectSpark, true, true) -- 
                    effectSpark:SetOrigin( trace.HitPos )
                    effectSpark:SetNormal( trace.HitNormal )
                    effectSpark:SetScale(2)
                    effectSpark:SetMagnitude(3)
                    effectSpark:SetRadius(4)
                util_Effect( "Sparks", effectSpark, true, true)
            else
                wepent:EmitSound( "weapons/physcannon/physcannon_dryfire.wav", 70 )
            end

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_PHYSGUN )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_PHYSGUN )
            
            return true
        end,

        OnUnequip = function( lambda, wepent )
            lambda:RemoveHook( "Think", "GravityGunPuntThink" )
        end,

        islethal = false,

    }

})
