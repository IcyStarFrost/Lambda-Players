local random = math.random
local rand = math.Rand
local ents_Create = ents and ents.Create or nil
local Angle = Angle
local IsValid = IsValid

local function IsCharacter( ent )
    return ent:IsNPC() or ent:IsPlayer() or ent:IsNextBot()
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    bugbait = {
        model = "models/weapons/w_bugbait.mdl",
        origin = "Half Life: 2",
        prettyname = "Bug Bait",
        holdtype = "grenade",
        bonemerge = true,

        

        OnEquip = function( self, wepent )

            local nextthrow = CurTime() + rand( 1, 10 )
            local nextsqueeze = CurTime() + rand( 1, 20 )
            

            self:Hook( "Tick", "Bugbaitthrowing", function()

                if CurTime() > nextsqueeze then
                    wepent:EmitSound( "weapons/bugbait/bugbait_squeeze" .. random( 1, 3 ) .. ".wav", 65, 100, 10, CHAN_WEAPON )
                    nextsqueeze = CurTime() + rand( 1, 20 )
                end

                if CurTime() < nextthrow then return end

                local nearby = self:FindInSphere( nil, 200, function( ent ) return IsCharacter( ent ) or self:HasVPhysics( ent ) end )
                local rndent = nearby[ random( #nearby ) ]
                local time = IsValid( rndent ) and 1 or 0
                self:LookTo( IsValid( rndent ) and rndent or nil )
            
                self:SimpleTimer( time, function()

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


                nextthrow = CurTime() + rand( 1, 10 )
            end )

        end,
        
        OnUnequip = function( self, wepent )
            self:RemoveHook( "Tick", "Bugbaitthrowing" )
        end,

        islethal = false,
    }

})