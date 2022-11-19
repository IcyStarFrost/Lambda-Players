local CurTime = CurTime
local min = math.min
local max = math.max
local random = math.random
local IsValid = LambdaIsValid

table.Merge( _LAMBDAPLAYERSWEAPONS, {

    medkit = {
        model = "models/weapons/w_medkit.mdl",
        origin = "Misc",
        prettyname = "Medkit",
        holdtype = "slam",
        bonemerge = true,

        clip = 100,

        OnEquip = function( self, wepent )
            self[ "HealEnemy" ] = function( self )              
                self:PreventWeaponSwitch( true )

                local moveResult = self:MoveToPos( self:GetEnemy(), { update = 0.4, tol = 64, callback = function()
                    if self:Health() < self:GetMaxHealth() then self:CancelMovement() end
                    if self:GetEnemy():Health() >= self:GetEnemy():GetMaxHealth() then self:CancelMovement() end
                end } )
                if moveResult != "ok" then self:SetState( "Idle" ); self:PreventWeaponSwitch( false ) return end

                self:LookTo( self:GetEnemy():WorldSpaceCenter(), 1 )
                self:UseWeapon( self:GetEnemy() )
                self:SetState( "Idle" ) 
                self:PreventWeaponSwitch( false )
            end

            self:Hook( "Think", "LambdaMedkit_Think", function()
                self.l_Clip = min( self.l_Clip + 2, self.l_MaxClip )

                if self:Health() < self:GetMaxHealth() then
                    self:UseWeapon( self ) 
                    return 
                end

                if self:GetState() == "Idle" and self.l_Clip >= 20 and random( 1, 2 ) == 1 and random( 1, 100 ) > self:GetCombatChance() then
                    local nearby = self:FindInSphere( self:GetPos(), 500, function( ent ) 
                        return ( self:CanTarget( ent ) and ent:Health() < ent:GetMaxHealth() ) 
                    end )
                    local rndEnt = nearby[ random( #nearby ) ]
                    if !IsValid( rndEnt ) then return end

                    self:SetState( "HealEnemy" )
                    self:SetEnemy( rndEnt )
                    self:CancelMovement()
                end
            end, false, 1 )
        end,

        callback = function( self, wepent, target )
            if self.l_Clip == 0 then return true end

            local hp = target:Health()
            local maxHp = target:GetMaxHealth()
            if hp >= maxHp then return true end

            local healNeed = min( maxHp - hp, 20 )
            if self.l_Clip < healNeed then return true end

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM )

            target:SetHealth( min( hp + healNeed, maxHp ) )
            wepent:EmitSound( "HealthKit.Touch" )

            self.l_WeaponUseCooldown = CurTime() + 2.166748046875
            self.l_Clip = max( 0, self.l_Clip - healNeed )

            return true
        end,

        OnUnequip = function( self, wepent )
            self[ "HealEnemy" ] = nil
            self:RemoveHook( "Think", "LambdaMedkit_Think" )
        end,

        islethal = false
    }

})