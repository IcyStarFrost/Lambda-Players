local random = math.random
local ents_Create = ents.Create
local Angle = Angle
local IsValid = IsValid
local CurTime = CurTime
local IsValid = IsValid

local function IsCharacter( ent )
    return ent:IsNPC() or ent:IsPlayer() or ent:IsNextBot()
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    bugbait = {
        model = "models/weapons/w_bugbait.mdl",
        origin = "Half-Life 2",
        prettyname = "Bug Bait",
        holdtype = "grenade",
        bonemerge = true,

        OnDeploy = function( self, wepent )
            wepent.NextSqueezeTime = CurTime() + random( 1, 20 )
            wepent.NextThrowTime = CurTime() + random( 1, 20 )
        end,

        OnHolster = function( self, wepent )
            wepent.NextSqueezeTime = nil
            wepent.NextThrowTime = nil
        end,

        OnThink = function( self, wepent, dead )
            if !dead then
                if CurTime() > wepent.NextSqueezeTime then
                    wepent:EmitSound( "weapons/bugbait/bugbait_squeeze" .. random( 1, 3 ) .. ".wav", 65, 100, 10, CHAN_WEAPON )
                    wepent.NextSqueezeTime = CurTime() + random( 1, 20 )
                end

                if CurTime() > wepent.NextThrowTime then
                    wepent.NextThrowTime = CurTime() + random( 1, 10 )

                    local nearby = self:FindInSphere( nil, 200, function( ent ) return ( IsCharacter( ent ) or self:HasVPhysics( ent ) ) end )
                    local rndent = nearby[ random( #nearby ) ]
                    local time = ( IsValid( rndent ) and 1 or 0 )
                    
                    self:LookTo( ( ( time == 1 ) and rndent or nil ), 3 )
                    
                    self:SimpleWeaponTimer( time, function()
                        self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )
                        self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE )

                        local bait = ents_Create( "npc_grenade_bugbait" )
                        bait:SetPos( wepent:GetPos() )
                        bait:SetSaveValue( "m_hThrower", self )
                        bait:SetOwner( self )
                        bait:Spawn()

                        bait:SetVelocity( ( self:GetEyeTrace().HitPos - bait:GetPos() ):GetNormalized() * 1000 )
                        bait:SetLocalAngularVelocity( Angle( 600, random( -1200, 1200 ), 0 ) )
                    end )
                end
            end

            return 1.0
        end,

        islethal = false
    }

})