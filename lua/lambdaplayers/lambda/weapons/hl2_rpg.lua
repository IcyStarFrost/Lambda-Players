local IsValid = IsValid
local CurTime = CurTime
local ents_Create = ents.Create
local Rand = math.Rand
local TraceLine = util.TraceLine
local trTbl = { filter = {} }
local laserMat = Material( "sprites/redglow1" )
local reloadTime = 1.6666666269302

local SetMaterial, DrawSprite
if ( CLIENT ) then
    SetMaterial = render.SetMaterial
    DrawSprite = render.DrawSprite
end

local laserEnabled = CreateLambdaConvar( "lambdaplayers_weapons_rpg_enablelaserguidance", 1, true, false, true, "Enables HL2 Rocket Launcher's laser guidance system.", 0, 1, { type = "Bool", name = "RPG - Enable Laser Guidance", category = "Weapon Utilities" } )

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    rpg = {
        model = "models/weapons/w_rocket_launcher.mdl",
        origin = "Half-Life 2",
        prettyname = "RPG",
        holdtype = "rpg",
        killicon = "rpg_missile",
        bonemerge = true,
        dropentity = "weapon_rpg",
        
        keepdistance = 800,
        attackrange = 5000,
        islethal = true,

        OnDraw = function( self, wepent )
            if !laserEnabled:GetBool() then return end

            local attachData = wepent:GetAttachment( 1 )
            trTbl.start = ( attachData and attachData.Pos or wepent:GetPos() )
            trTbl.endpos = ( trTbl.start + ( attachData and attachData.Ang:Forward() or wepent:GetForward() ) * 32756 )
            trTbl.filter[ 1 ] = self
            trTbl.filter[ 2 ] = wepent
            trTbl.filter[ 3 ] = wepent:GetNW2Entity( "lambdahl2_rpgrocket", NULL )

            local trDot = TraceLine( trTbl )
            if trDot.HitSky then return end

            SetMaterial( laserMat )
            DrawSprite( ( trDot.HitPos + trDot.HitNormal * 3 - EyeVector() * 4 ), 16, 16, color_white ) 
        end,

        OnDeploy = function( self, wepent )
            wepent:SetNW2Entity( "lambdahl2_rpgrocket", NULL )
            wepent.RocketTargetTime = 0
            wepent.RocketIgniteTime = 0
            wepent.LastSeenEnemyPos = vector_origin
        end,

        OnHolster = function( self, wepent )
            wepent.RocketTargetTime = nil
            wepent.RocketIgniteTime = nil
            wepent.LastSeenEnemyPos = nil
        end,

        OnThink = function( self, wepent, isdead )
            if isdead then return end

            local rocket = wepent:GetNW2Entity( "lambdahl2_rpgrocket", NULL )
            if !IsValid( rocket ) then return end
            
            local curTime = CurTime()
            if ( self.l_WeaponUseCooldown - curTime ) <= reloadTime then
                self.l_WeaponUseCooldown = ( curTime + Rand( reloadTime, 2.5 ) )
            end
            if curTime < wepent.RocketTargetTime or curTime < wepent.RocketIgniteTime or !laserEnabled:GetBool() then return end

            local attachData = wepent:GetAttachment( 1 )
            local muzzlePos = ( attachData and attachData.Pos or wepent:GetPos() )

            trTbl.start = muzzlePos
            trTbl.filter[ 1 ] = self
            trTbl.filter[ 2 ] = wepent
            trTbl.filter[ 3 ] = rocket

            local ene = self:GetEnemy()
            if LambdaIsValid( ene ) then
                local aimPos = wepent.LastSeenEnemyPos
                if self:CanSee( ene ) then
                    aimPos = ene:GetPos()
                    wepent.LastSeenEnemyPos = aimPos
                end

                trTbl.endpos = ( muzzlePos + ( aimPos - muzzlePos ):GetNormalized() * 32756 )
            else
                local muzzleFwd = ( attachData and attachData.Ang:Forward() or wepent:GetForward() )
                trTbl.endpos = ( muzzlePos + muzzleFwd * 32756 )
            end

            vecTarget = ( TraceLine( trTbl ).HitPos - trTbl.start ):GetNormalized()
            rocket:SetAngles( vecTarget:Angle() )

            local speed = rocket:GetVelocity():Length()
            rocket:SetLocalVelocity( rocket:GetVelocity() * 0.2 + vecTarget * ( speed * 0.8 + 400 ) )
            if rocket:GetVelocity():Length() > 1500 then rocket:SetLocalVelocity( rocket:GetVelocity():GetNormalized() * 1500 ) end

            wepent.RocketTargetTime = ( curTime + 0.1 )
        end,

        OnAttack = function( self, wepent, target )
            local attachData = wepent:GetAttachment( 2 )
            trTbl.start = ( attachData and attachData.Pos or wepent:GetPos() + wepent:GetForward() * 20 )
            trTbl.endpos = target:GetPos()
            if self:GetForward():Dot( ( trTbl.endpos - trTbl.start ):GetNormalized() ) < 0.66 then return true end

            trTbl.filter = target          
            local tr = TraceLine( trTbl )
            
            if tr.Entity == self then self.l_WeaponUseCooldown = CurTime() + 0.25 return true end

            if tr.Fraction != 1.0 then 
                trTbl.endpos = target:WorldSpaceCenter()
                tr = TraceLine( trTbl )
                
                if tr.Fraction != 1.0 or tr.Entity == self then self.l_WeaponUseCooldown = CurTime() + 0.25 return true end
            end

            local rocket = ents_Create( "rpg_missile" )
            if !IsValid( rocket ) then return true end

            wepent:EmitSound( "Weapon_RPG.Single" )
            self.l_WeaponUseCooldown = ( CurTime() + Rand( reloadTime, 2.5 ) )

            self:RemoveGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG )
            self:AddGesture( ACT_HL2MP_GESTURE_RANGE_ATTACK_RPG )

            local spawnAng = ( trTbl.endpos - trTbl.start ):Angle()
            rocket:SetPos( trTbl.start )
            rocket:SetAngles( spawnAng )
            rocket:SetOwner( self )
            rocket:Spawn()

            rocket:SetSaveValue( "m_flDamage", 150 ) -- Gmod RPG only does 150 damage
            rocket:SetLocalVelocity( spawnAng:Forward() * 300 + vector_up * 128 )

            rocket:SetSaveValue( "m_flGracePeriodEndsAt", ( CurTime() + 0.3 ) ) -- Give the missile a slight grace period
            rocket:AddSolidFlags( FSOLID_NOT_SOLID )

            rocket:CallOnRemove( "LambdaPlayer_RPGRocket_" .. rocket:EntIndex(), function()
                rocket:StopSound( "weapons/rpg/rocket1.wav" ) -- Trying to prevent source being dumb
            end)

            wepent:SetNW2Entity( "lambdahl2_rpgrocket", rocket )
            wepent.RocketIgniteTime = ( CurTime() + 0.3 )

            return true
        end
    }
} )