local sin = math.sin
local IsValid = IsValid
local null_vector = Vector(0, 0, 0)
local color_white_vector = Vector(1, 1, 1)
local random = math.random
local Vector = Vector
local LerpVector = LerpVector
local VectorRand = VectorRand
local table_insert = table.insert
local table_remove = table.remove

_LAMBDAPLAYERS_ClientSideEnts = {}
_LAMBDAPLAYERS_Voicechannels = {}

-- Physgun color proxy
matproxy.Add({
    name = "LambdaPlayerWeaponColor",
    init = function( self, mat, values )
        self.ResultTo = values.resultvar
    end,
    bind = function( self, mat, ent )
        if !IsValid( ent ) then return end

        local wepClr = ent:GetNW2Vector( "lambda_weaponcolor", null_vector )
        if wepClr != null_vector then
            local mul = ( ( 1 + sin( CurTime() * 5 ) ) * 0.5 )
            mat:SetVector( self.ResultTo, ( wepClr + wepClr * mul ) )
            return
        end

        local owner = ent:GetOwner()
        if !IsValid( owner ) or !owner.IsLambdaPlayer then return end

        local col = owner:GetNW2Vector( "lambda_weaponcolor", color_white_vector )    
        local mul = ( (1 + sin( CurTime() * 5 ) ) * 0.5 )
        mat:SetVector( self.ResultTo, ( col + col * mul ) )
    end
})

local EntMeta = FindMetaTable("Entity")
local downvector = Vector( 0, 0, -100 )
local upvector = Vector( 0, 0, 50 )
local disintegratingents = {}

local function ClearInvalids( tbl )
    for k, v in ipairs( tbl ) do if !IsValid( v ) then table_remove( tbl, k ) end end
end

-- The Disintegration effect used in corpse cleanup
function EntMeta:LambdaDisintegrate()
    ClearInvalids( disintegratingents )
    if #disintegratingents > 8 then self:Remove() return end -- The effect is limitted so we don't overload the emitters

    local id = random( 1, 10000000 )
    local curpos
    local pos
    local nextparticle = 0
    local endtime = RealTime() + 5
    local norm = Angle( 0, random( 360 ), 0 ):Forward()
    self:SetRenderClipPlaneEnabled( true )
    self:EmitSound( "lambdaplayers/misc/disintegrate.mp3", 65, random( 80, 100 ) )

    table_insert( disintegratingents, self )
    
    hook.Add( "Think", "lambdadisintegrateeffect" .. id, function()
        if !IsValid( self ) then hook.Remove( "Think", "lambdadisintegrateeffect" .. id ) return end
        if RealTime() > endtime then self:Remove() hook.Remove( "Think", "lambdadisintegrateeffect" .. id ) return end
        

        local uppos = self:GetPos() + norm * ( self:GetModelRadius() - 25 )
        local downpos = self:GetPos() - norm * ( self:GetModelRadius() )

        curpos = curpos and LerpVector( 0.25 * FrameTime(), curpos, downpos ) or uppos
        pos = -norm:Dot( curpos )

        if RealTime() > nextparticle then

            local emitpos = curpos + VectorRand( -10, 10 )
            local emitter = ParticleEmitter( emitpos )
            if emitter then
                local part = emitter:Add( "effects/spark", emitpos )
                if part then
                    part:SetDieTime( 4 )
                    part:SetStartAlpha( 255 )
                    part:SetEndAlpha( 0 )
                    part:SetStartSize( 3 )
                    part:SetEndSize( 0 )
                    part:SetCollide( true )
                    part:SetGravity( random( 1, 10 ) == 1 and upvector or downvector )
                    part:SetVelocity( VectorRand() * 40 )
                    part:SetAngleVelocity( AngleRand( -10, 10 ) )
                    part:SetColor( 255, 174, 0 )
                end
                emitter:Finish()
            end

            nextparticle = RealTime() + 0.01
        end

        self:SetRenderClipPlane( -norm, pos )
    end )
    
end
