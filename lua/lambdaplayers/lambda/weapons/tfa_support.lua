if true then return end

for index, swep in ipairs( weapons.GetList() ) do
    if !string.StartsWith( swep.Base, "tfa" ) then continue end

    local className = swep.ClassName
    print( className )
    if string.EndsWith( className, "_base" ) then continue end

    swep = weapons.Get( className )
    local primData = swep.Primary
    local damage = primData.Damage
    local viewModel = swep.ViewModel    
    local bulletCount = primData.NumShots
    local rateOfFire = ( 60 / primData.RPM )
    local spread = ( primData.Spread * ( bulletCount > 1 and 1 or 13 ) )
    local attackAnim, reloadAnim
    local deployTime = 0.1
    local loopedReload = swep.LoopedReload
    
    local attackDist = 1500
    if primData.RangeFalloffLUT and primData.RangeFalloffLUT.lut then
        attackDist = ( primData.RangeFalloffLUT.lut[ 1 ].range / 4 )
    end

    local bulletTbl = {}
    local clipSize = primData.ClipSize
    if clipSize == -1 then
        clipSize = 1
        bulletTbl.clipdrain = true
    end

    if ( SERVER ) then
        attackAnim = _LAMBDAPLAYERSHoldTypeAnimations[ swep.HoldType ].attack
        reloadAnim = ( _LAMBDAPLAYERSHoldTypeAnimations[ swep.HoldType ].reload or ACT_HL2MP_GESTURE_RELOAD_AR2 )

        print( className, spread )
        if primData.Spread > 0.2 then 
            spread = ( spread / 5 )

            if swep.Secondary and swep.Secondary.IronSightsEnabled == true then
                rateOfFire = ( rateOfFire * 1.5 )
            end
        end
        if !primData.Automatic then
            rateOfFire = math.max( rateOfFire * 1.33 * ( primData.Spread * 10 / 0.15 ), rateOfFire )
        end
        print( className, spread )
    end

    local wmOffset
    if swep.WorldModelOffset and istable( swep.WorldModelOffset ) and !table.IsEmpty( swep.WorldModelOffset ) then
        wmOffset = swep.WorldModelOffset
    elseif swep.Offset and istable( swep.Offset ) and !table.IsEmpty( swep.Offset ) then
        wmOffset = swep.Offset
    end

    _LAMBDAPLAYERSWEAPONS[ className ] = {
        model = swep.WorldModel,
        origin = "[TFA] " .. swep.Category,
        prettyname = swep.PrintName,
        holdtype = swep.HoldType,
        bonemerge = false,
        killicon = className,
        dropentity = className,
        deploydelay = deployTime,
        speedmultiplier = swep.RegularMoveSpeedMultiplier,

        islethal = true,
        attackrange = attackDist,
        keepdistance = ( attackDist / 2 ),
        clip = clipSize,
        damage = damage,
        force = ( damage / 3 ),
        bulletcount = bulletCount,
        rateoffire = rateOfFire,
        spread = spread,
        muzzleflash = false,
        shelleject = false,
        attackanim = attackAnim,
        attacksnd = primData.Sound,

        OnDraw = function( lambda, wepent )
            local renderAng
            local handBone = lambda:LookupBone( "ValveBiped.Bip01_R_Hand" )
            if handBone then
                local pos
                local mat = lambda:GetBoneMatrix( handBone )
                if mat then
                    pos, renderAng = mat:GetTranslation(), mat:GetAngles()
                else
                    pos, renderAng = lambda:GetBonePosition( handBone )
                end

                if wmOffset and wmOffset.Pos and wmOffset.Ang and !wepent:IsEffectActive( EF_BONEMERGE ) then        
                    local opos, oang, oscale = wmOffset.Pos, wmOffset.Ang, wmOffset.Scale
                    pos = ( pos + renderAng:Forward() * opos.Forward + renderAng:Right() * opos.Right + renderAng:Up() * opos.Up )
        
                    renderAng:RotateAroundAxis( renderAng:Up(), oang.Up )
                    renderAng:RotateAroundAxis( renderAng:Right(), oang.Right )
                    renderAng:RotateAroundAxis( renderAng:Forward(), oang.Forward )

                    wepent:SetRenderOrigin( pos )
                    wepent:SetRenderAngles( renderAng )
                    wepent:SetModelScale( oscale or 1, 0 )   
                else
                    renderAng:RotateAroundAxis( renderAng:Forward(), 180 )
                    renderAng:RotateAroundAxis( renderAng:Right(), 10 )
                end
            end

            local vmEnt = wepent:GetNW2Entity( "lambdaswep_vmmdl" )
            if IsValid( vmEnt ) then
                local vmAttach = vmEnt:GetAttachment( 1 )
                local wepAttach = wepent:GetAttachment( 1 )

                vmEnt:SetRenderOrigin( vmEnt:GetPos() + ( wepAttach.Pos - vmAttach.Pos ) )
                vmEnt:SetRenderAngles( renderAng or vmEnt:GetAngles() + ( wepAttach.Ang - vmAttach.Ang ) )
            end
        end,

        OnDeploy = function( lambda, wepent )
            if wepent:LookupBone( "ValveBiped.Bip01_R_Hand" ) then 
                wepent:AddEffects( EF_BONEMERGE ) 
            else 
                wepent:RemoveEffects( EF_BONEMERGE ) 
            end

            local vmEnt = wepent:GetNW2Entity( "lambdaswep_vmmdl" )
            if !IsValid( vmEnt ) then
                vmEnt = ents.Create( "base_anim" ) 
                vmEnt:SetModel( viewModel )
                vmEnt:SetPos( wepent:GetPos() )
                vmEnt:SetAngles( wepent:GetAngles() )
                vmEnt:SetOwner( wepent )
                vmEnt:SetParent( wepent )
                vmEnt:Spawn()
                vmEnt:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )

                -- vmEnt:SetMaterial( "null" )
                -- vmEnt:DrawShadow( false )

                PrintTable( weapons.GetList()[ index ] )

                vmEnt.AutomaticFrameAdvance = true
                wepent.l_tfa_attackanim = vmEnt:SelectWeightedSequence( ACT_VM_PRIMARYATTACK )

                local reloadTime = 1.5
                if !loopedReload then
                    wepent.l_tfa_reloadanim = vmEnt:SelectWeightedSequence( ACT_VM_RELOAD )
                    if wepent.l_tfa_reloadanim > 0 then reloadTime = vmEnt:SequenceDuration( wepent.l_tfa_reloadanim ) end
                else
                    reloadTime = {}
    
                    local reloadSeq = vmEnt:SelectWeightedSequence( ACT_SHOTGUN_RELOAD_START )
                    if reloadSeq > 0 then 
                        reloadTime[ 1 ] = { 
                            reloadSeq, 
                            vmEnt:SequenceDuration( reloadSeq ) 
                        } 
                    end
                    reloadSeq = vmEnt:SelectWeightedSequence( ACT_VM_RELOAD )
                    if reloadSeq > 0 then 
                        reloadTime[ 2 ] = { 
                            reloadSeq, 
                            vmEnt:SequenceDuration( reloadSeq ) 
                        } 
                    end
                    reloadSeq = vmEnt:SelectWeightedSequence( ACT_SHOTGUN_RELOAD_FINISH )
                    if reloadSeq > 0 then 
                        reloadTime[ 3 ] = { 
                            reloadSeq, 
                            vmEnt:SequenceDuration( reloadSeq ) 
                        } 
                    end
                end
                wepent.l_tfa_reloadtime = reloadTime

                function vmEnt:Think()
                    vmEnt:NextThink( CurTime() )
                    return true
                end

                function wepent:PlayViewMdlAnim( seq )
                    local vmEnt = wepent:GetNW2Entity( "lambdaswep_vmmdl" )
                    if !IsValid( vmEnt ) then return end

                    seq = ( seq or vmEnt:SelectWeightedSequence( ACT_VM_IDLE ) )
                    vmEnt:SetSequence( seq )
                    vmEnt:ResetSequenceInfo()
                    vmEnt:SetCycle( 0 )
                end

                wepent:DeleteOnRemove( vmEnt )
                wepent:SetNW2Entity( "lambdaswep_vmmdl", vmEnt )
            else
                vmEnt:SetModel( viewModel )
            end

            local deploySeq = vmEnt:SelectWeightedSequence( ACT_VM_DRAW )
            if deploySeq > 0 then
                vmEnt:PlayAnim( deploySeq )
                lambda.l_WeaponUseCooldown = ( CurTime() + vmEnt:SequenceDuration( deploySeq ) )
            end
        end,

        OnHolster = function( lambda, wepent )
            wepent:PlayViewMdlAnim()
        end,
        
        OnDeath = function( lambda, wepent )
            wepent:PlayViewMdlAnim()
        end,

        OnAttack = function( lambda, wepent )
            wepent:PlayViewMdlAnim( wepent.l_tfa_attackanim ) 
            return bulletTbl
        end,

        OnReload = function( lambda, wepent )
            lambda:SetIsReloading( true )

            local reloadTime = wepent.l_tfa_reloadtime
            if istable( reloadTime ) then
                lambda:AddGesture( reloadAnim )
                
                lambda:Thread( function()
                    wepent:PlayViewMdlAnim( reloadTime[ 1 ][ 1 ] )
                    coroutine.wait( reloadTime[ 1 ][ 2 ] )
    
                    while ( lambda.l_Clip < lambda.l_MaxClip ) do
                        local ene = lambda:GetEnemy()
                        if lambda.l_Clip > 0 and LambdaRNG( 2 ) == 1 and lambda:InCombat() and lambda:IsInRange( ene, 512 ) and lambda:CanSee( ene ) then break end

                        lambda.l_Clip = ( lambda.l_Clip + 1 )
                        wepent:PlayViewMdlAnim( reloadTime[ 2 ][ 1 ] )
                        coroutine.wait( reloadTime[ 2 ][ 2 ] )
                    end
    
                    local ene = lambda:GetEnemy()
                    if lambda.l_Clip > 0 and LambdaRNG( 2 ) == 1 and lambda:InCombat() and lambda:IsInRange( ene, 512 ) and lambda:CanSee( ene ) then 
                        wepent:EmitSound( "Weapon_Shotgun.Special1" )
                    else
                        wepent:PlayViewMdlAnim( reloadTime[ 3 ][ 1 ] )
                        coroutine.wait( reloadTime[ 3 ][ 2 ] )
                    end
    
                    lambda:RemoveGesture( ACT_HL2MP_GESTURE_RELOAD_SHOTGUN )
                    lambda:SetIsReloading( false )
                end, "TFA_ShotgunReload" )
            else
                wepent:PlayViewMdlAnim( wepent.l_tfa_reloadanim )

                local reloadLayer = lambda:AddGesture( reloadAnim )
                lambda:SetLayerPlaybackRate( reloadLayer, ( lambda:GetLayerDuration( reloadLayer ) / reloadTime ) )
    
                lambda:NamedWeaponTimer( "Reload", reloadTime, 1, function()
                    if !lambda:GetIsReloading() then return end
                    lambda.l_Clip = lambda.l_MaxClip
                    lambda:SetIsReloading( false )
                end )
            end

            return true
        end
    }
end