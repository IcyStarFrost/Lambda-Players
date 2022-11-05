local sin = math.sin
local IsValid = IsValid
local null_vector = Vector(0, 0, 0)
local color_white_vector = Vector(1, 1, 1)

_LAMBDAPLAYERS_ClientSideEnts = {}
_LAMBDAPLAYERS_Voicechannels = {}

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


--[[ function EntMeta:LambdaDisintegrate()
    local id = self:EntIndex()
    local uppos = self:GetPos() + self:GetForward() * 100
    local downpos = self:GetPos() - self:GetForward() * 100
    local curpos = uppos
    self:SetRenderClipPlaneEnabled( true )
    local pos = -self:GetForward():Dot( curpos )
    hook.Add( "Think", "lambdadisintegrateeffect" .. id, function()
        if !IsValid( self ) then hook.Remove( "Think", "lambdadisintegrateeffect" .. id ) return end
        curpos = LerpVector( 0.2 * FrameTime(), curpos, downpos )
        pos = -self:GetForward():Dot( curpos )

        self:SetRenderClipPlane( -self:GetForward(), pos )
    end )
    
end
 ]]