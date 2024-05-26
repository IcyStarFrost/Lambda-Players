local IsValid = IsValid
local ipairs = ipairs
local RealTime = RealTime
local isfunction = isfunction
local LambdaScreenScale = LambdaScreenScale
local gmatch = string.gmatch
local RunString = RunString
local ScrW = ScrW
local ScrH = ScrH

if SERVER then

    local wepDmgScalePlys = GetConVar( "lambdaplayers_combat_weapondmgmultiplier_players" )
    local wepDmgScaleLambdas = GetConVar( "lambdaplayers_combat_weapondmgmultiplier_lambdas" )
    local wepDmgScaleMisc = GetConVar( "lambdaplayers_combat_weapondmgmultiplier_misc" )

    function LambdaGetWeaponDamageScale( target )
        if target.IsLambdaPlayer then return wepDmgScaleLambdas:GetFloat() end
        if target:IsPlayer() then return wepDmgScalePlys:GetFloat() end
        return wepDmgScaleMisc:GetFloat()
    end

    -- God mode simple stuff
    hook.Add( "EntityTakeDamage", "LambdaMainDamageHook", function( ent, dmginfo )
        if ent.l_godmode then return true end

        if ent.IsLambdaPlayer then
            local lastDmg = ent.l_lastdamage
            if lastDmg and ( lastDmg / 4 ) == dmginfo:GetDamage() then
                dmginfo:ScaleDamage( 4 )
            end
        else
            local attacker = dmginfo:GetAttacker()
            if IsValid( attacker ) and attacker.IsLambdaPlayer then
                if ent.IsUltrakillNextbot then
                    dmginfo:SetDamage( ( ( dmginfo:GetDamage() / UltrakillBase.ConVars.TakeDmgMult:GetFloat() ) * UltrakillBase.ConVars.PlyDmgMult:GetFloat() ) * 10 )
                else
                    local class = ent:GetClass()
                    if class == "nb_klk_ryuko" or class == "nb_klk_satsuki" or class == "nb_klk_nui" then
                        local valBonus = ent.KLK_ValorDamageBonus
                        if class == "nb_klk_nui" then valBonus = ent.KLK_ValorResistanceBonus end

                        if ent.KLK_OwnDMGMult == 0.05 then
                            dmginfo:SetDamage( ( ( dmginfo:GetDamage() / ( 0.2 / valBonus ) ) * ( 1 / valBonus ) ) * ent.KLK_PlyDMGMult )
                        else
                            dmginfo:ScaleDamage( ent.KLK_PlyDMGMult )
                        end
                    end
                end
            end
        end

        local inflictor = dmginfo:GetInflictor()
        if IsValid( inflictor ) and ( inflictor.IsLambdaWeapon or inflictor.l_UseLambdaDmgModifier ) then
            dmginfo:ScaleDamage( LambdaGetWeaponDamageScale( ent ) )
        end
    end )

    -- Updates the map's spawn points when we clean the map
    hook.Add( "PostCleanupMap", "LambdaResetSpawnPoints", function()
        LambdaSpawnPoints = LambdaGetPossibleSpawns()
    end )

    -- So the client knows if the player is the host or not
    hook.Add("PlayerInitialSpawn", "Lambdasetserverhost", function( ply )
        if ply:IsListenServerHost() then ply:SetNW2Bool( "lambda_serverhost", true ) end

        LambdaGetPlayerBirthday( ply, function( ply, month, day )
            _LambdaPlayerBirthdays[ ply:SteamID() ] = { month = month, day = day }
        end )
    end )

    --

    local ai_ignoreplayers = GetConVar( "ai_ignoreplayers" )
    local GetConVar = GetConVar
    local FindInSphere = ents.FindInSphere
    local constraint_RemoveAll = constraint.RemoveAll
    local DamageInfo = DamageInfo

    local function Sanic_IsValidTarget( self, ent )
        if !IsValid( ent ) then return false end
        if ent.IsLambdaPlayer then return ent:Alive() end
        if ent:IsPlayer() then return ( ent:Alive() and !ai_ignoreplayers:GetBool() ) end

        local class = ent:GetClass()
        return ( ent:IsNPC() and ent:Health() > 0 and class != self:GetClass() and !class:find( "bullseye" ) )
    end

    local function Sanic_IsPointNearSpawn( point, distance )
        local spawnPoints = GAMEMODE.SpawnPoints
        if spawnPoints or #spawnPoints == 0 then return false end

        distance = ( distance * distance )
        for _, spawnPoint in ipairs( spawnPoints ) do
            if !IsValid( spawnPoint ) or point:DistToSqr( spawnPoint:GetPos() ) <= distance then continue end
            return true
        end

        return false
    end

    local function Sanic_GetNearestTarget( self )
        local selfClass = self:GetClass()

        local maxAcquireDist = GetConVar( selfClass .. "_acquire_distance" )
        maxAcquireDist = ( maxAcquireDist and maxAcquireDist:GetInt() or 2500 )

        local maxAcquireDistSqr = ( maxAcquireDist * maxAcquireDist )
        local selfPos = self:GetPos()
        local closestEnt

        local spawnProtect = GetConVar( selfClass .. "_spawn_protect" )
        spawnProtect = ( spawnProtect and spawnProtect:GetBool() or true )

        for _, ent in ipairs( FindInSphere( selfPos, maxAcquireDist ) ) do
            if !self:IsValidTarget( ent ) then continue end

            local entPos = ent:GetPos()
            if spawnProtect and ent:IsPlayer() and Sanic_IsPointNearSpawn( entPos, 200 ) then continue end

            local distSqr = entPos:DistToSqr( selfPos )
            if distSqr >= maxAcquireDistSqr then continue end

            closestEnt = ent
            maxAcquireDistSqr = distSqr
        end

        return closestEnt
    end

    local function Sanic_AttackNearbyTargets( self, radius )
        local selfClass = self:GetClass()

        local attackForce = GetConVar( selfClass .. "_attack_force" )
        attackForce = ( attackForce and attackForce:GetInt() or 800 )

        local smashProps = GetConVar( selfClass .. "_smash_props" )
        smashProps = ( smashProps and smashProps:GetBool() or true )

        local hit = false
        local hitSource = self:WorldSpaceCenter()

        for _, ent in ipairs( FindInSphere( hitSource, radius ) ) do
            if !self:IsValidTarget( ent ) then
                if smashProps and ent:GetMoveType() == MOVETYPE_VPHYSICS and ( !ent:IsVehicle() or !IsValid( ent:GetDriver() ) ) then
                    local phys = ent:GetPhysicsObject()
                    if IsValid( phys ) then
                        constraint_RemoveAll( ent )

                        local mass = phys:GetMass()
                        if mass >= 5 then ent:EmitSound( phys:GetMaterial() .. ".ImpactHard", 350, 120 ) end

                        local hitDirection = ( ent:WorldSpaceCenter() - hitSource ):GetNormalized()
                        local hitOffset = ent:NearestPoint( hitSource )
                        for i = 0, ( ent:GetPhysicsObjectCount() - 1 ) do
                            phys = ent:GetPhysicsObjectNum( i )
                            if !IsValid( phys ) then continue end

                            phys:EnableMotion(true)
                            phys:ApplyForceOffset( hitDirection * ( attackForce * mass ), hitOffset )
                        end
                    end
                    ent:TakeDamage( 25, self, self )
                end

                continue
            end

            if ent:IsPlayer() and IsValid( ent:GetVehicle() ) then
                local vehicle = ent:GetVehicle()

                local phys = vehicle:GetPhysicsObject()
                if IsValid(phys) then
                    phys:Wake()
                    local hitDirection = ( vehicle:WorldSpaceCenter() - hitSource ):GetNormalized()
                    phys:ApplyForceOffset( hitDirection * ( attackForce * phys:GetMass() ), vehicle:NearestPoint(hitSource) )
                end

                vehicle:TakeDamage( math.huge, self, self )
                vehicle:EmitSound( "physics/metal/metal_sheet_impact_hard" .. LambdaRNG( 6, 8 ) .. ".wav", 350, 120 )
            else
                ent:EmitSound( "physics/body/body_medium_impact_hard" .. LambdaRNG( 6 ) .. ".wav", 350, 120 )
            end

            local hitDirection = ( ent:GetPos() - hitSource ):GetNormalized()
            local hitForce = ( hitDirection * attackForce + vector_up * 500 )
            ent:SetVelocity( hitForce )

            local oldHealth = ent:Health()

            local dmginfo = DamageInfo()
            dmginfo:SetAttacker( self )
            dmginfo:SetInflictor( self )
            dmginfo:SetDamage( math.huge )
            dmginfo:SetDamagePosition( hitSource )
            dmginfo:SetDamageForce( hitForce * 100 )

            ent:TakeDamageInfo( dmginfo )
            if !hit then hit = ( ent:Health() < oldHealth )  end
        end

        return hit
    end

    --

    local function LambdaMedkitCanHeal( swep, ent )
        if ent.IsLambdaPlayer or ent:IsPlayer() or ent:IsNPC() then
            local takedamage = ent:GetInternalVariable( "m_takedamage" )
            return ( takedamage == nil or takedamage == 2 )
        end
        return false
    end

    --

    local ukParryConVar
    local Clamp = math.Clamp
    local parryFlash = Color( 255, 255, 255, 40 )

    function UltrakillCheckParry( self, Dmg )
        if !self:GetParryable() then return end

        ukParryConVar = ( ukParryConVar or GetConVar( "drg_ultrakill_parry" ) )
        if !ukParryConVar:GetBool() then return end

        local Ply = Dmg:GetAttacker()
        if !IsValid( Ply ) or !Ply.IsLambdaPlayer and !Ply:IsPlayer() or !self:IsInRange( Ply, 200 ) then return end

        if !Dmg:IsDamageType( DMG_CLUB + DMG_SLASH ) and ( !Dmg:IsDamageType( DMG_BUCKSHOT ) or !self:IsInRange( Ply, 50 ) ) then return end
        self:OnParry( Ply, Dmg )
    end

    function UltrakillOnParryPlayer( Ply )
        if !Ply.IsLambdaPlayer then
            if UltrakillBase.UltrakillMechanicsInstalled then
                RefreshStamina( Ply )
            end
            Ply:ScreenFade( SCREENFADE.IN, parryFlash, 0.1, 0.25 )
        end

        local health, mHealth = Ply:Health(), Ply:GetMaxHealth()
        Ply:SetHealth( health > mHealth and health or Clamp( mHealth, 0, mHealth - Ply:GetNW2Int( "UltrakillBase_HardDamage" ) ) )    
    end

    --

    -- Fixes ReAgdoll throwing errors when a ragdoll doesn't have bones it need to use (like head)
    hook.Add( "OnEntityCreated", "LambdaOnEntityCreated", function( ent )
        if !IsValid( ent ) then return end

        -- YOUR TOO SLOW
        if ent.LastPathingInfraction and ent:IsNextBot() then
            ent.GetNearestTarget = Sanic_GetNearestTarget
            ent.IsValidTarget = Sanic_IsValidTarget
            ent.AttackNearbyTargets = Sanic_AttackNearbyTargets
            return
        end

        -- Feedbacker + "F" + Enemy = Parry
        if ent.IsUltrakillNextbot then
            UltrakillBase.OnParryPlayer = UltrakillOnParryPlayer
            ent.CheckParry = UltrakillCheckParry
            return
        end

        local class = ent:GetClass()
        if class == "weapon_medkit" then
            ent.CanHeal = LambdaMedkitCanHeal
        elseif class == "lua_run" then
            function ent:RunCode( activator, caller, code )
                self:SetupGlobals( activator, caller )
                    if activator.IsLambdaPlayer then
                        for funcName in gmatch( code, "[%TRIGGER_PLAYER%ACTIVATOR]:([%w_]+)" ) do
                            if !isfunction( activator[ funcName ] ) then self:KillGlobals() return end
                        end
                    end
                    if caller.IsLambdaPlayer then
                        for funcName in gmatch( code, "CALLER:([%w_]+)" ) do
                            if !isfunction( caller[ funcName ] ) then self:KillGlobals() return end
                        end
                    end

                    RunString( code, "lua_run#" .. self:EntIndex() )
                self:KillGlobals()
            end

            function ent:SetupGlobals( activator, caller )
                ACTIVATOR = activator
                CALLER = caller

                if IsValid( activator ) and ( activator.IsLambdaPlayer or activator:IsPlayer() ) then
                    TRIGGER_PLAYER = activator
                end
            end
        end
    end )

    local specialkeywords = {
        "|birthday|",
        "|christmas|",
        "|newyears|",
        "|addonbirthday|",
        "|thanksgiving|",
        "|4thjuly|",
        "|easter|"
    }

    local function GetSpecialDayLine()
        local tbl = LambdaTextTable[ "idle" ]
        if !tbl then return end
        local speciallines = {}

        for k, str in ipairs( tbl ) do
            for i = 1, #specialkeywords do
                local keyword = specialkeywords[ i ]
                if string.find( str, keyword ) and LambdaConditionalKeyWordCheck( nil, str ) then
                    speciallines[ #speciallines + 1 ] = str
                end
            end
        end
        return speciallines[ LambdaRNG( #speciallines ) ]
    end

    hook.Add( "LambdaOnStartTyping", "LambdaSpecialDaytext", function( lambda, text, texttype )
        if texttype != "idle" or LambdaRNG( 0, 100 ) > 10 then return end

        local line = GetSpecialDayLine()

        if !line then return end

        return line
    end )

elseif CLIENT then

    local DrawText = draw.DrawText
    local tostring = tostring
    local uiscale = GetConVar( "lambdaplayers_uiscale" )
    local IsSinglePlayer = game.SinglePlayer()
    local input_LookupBinding = input.LookupBinding
    local input_GetKeyCode = input.GetKeyCode
    local input_IsKeyDown = input.IsKeyDown
    local surface_SetMaterial = surface.SetMaterial
    local surface_SetDrawColor = surface.SetDrawColor
    local surface_DrawTexturedRect = surface.DrawTexturedRect

    local displayProfilePicture = GetConVar( "lambdaplayers_displayprofilepicture" )
    local displayArmor = GetConVar( "lambdaplayers_displayarmor" )

    -- The little name and health display when you look at Lambdas
    hook.Add( "HUDPaint", "LambdaPlayers_NameDisplay", function()
        local sw, sh = ScrW(), ScrH()
        local traceent = LocalPlayer():GetEyeTrace().Entity

        if LambdaIsValid( traceent ) and traceent.IsLambdaPlayer then
            local result = LambdaRunHook( "LambdaShowNameDisplay", traceent )
            if result == false then return end
            
            local name = traceent:GetLambdaName()
            local color = traceent:GetDisplayColor()
            local hp = traceent:GetNW2Float( "lambda_health", "NAN" )
            local hpW = 2
            local armor = traceent:GetArmor()
            hp = hp == "NAN" and traceent:GetNWFloat( "lambda_health", "NAN" ) or hp

            if armor > 0 and displayArmor:GetBool() then
                hpW = 2.1
                DrawText( tostring( armor ) .. "%", "lambdaplayers_healthfont", ( sw / 1.9 ), ( sh / 1.87 ) + LambdaScreenScale( 1 + uiscale:GetFloat() ), color, TEXT_ALIGN_CENTER)
            end

            DrawText( name, "lambdaplayers_displayname", ( sw / 2 ), ( sh / 1.95 ) , color, TEXT_ALIGN_CENTER )
            DrawText( tostring( hp ) .. "%", "lambdaplayers_healthfont", ( sw / hpW ), ( sh / 1.87 ) + LambdaScreenScale( 1 + uiscale:GetFloat() ), color, TEXT_ALIGN_CENTER)
            
            if displayProfilePicture:GetBool() then
                traceent.l_name_display_mat_cache = traceent.l_name_display_mat_cache or traceent:GetPFPMat()
                surface_SetMaterial( traceent.l_name_display_mat_cache )
                surface_SetDrawColor(color_white)
                surface_DrawTexturedRect( ( sw / 1.9 ) + ( #name * 2.5 ), ( sh / 2.1 ) + LambdaScreenScale( 1 + uiscale:GetFloat() ), LambdaScreenScale( 30 ), LambdaScreenScale( 30 ) )
            end
        end

    end )


    -- Since Singleplayer prevents normal use of the Voice Chat bind, we force it on with this
    if IsSinglePlayer then
        local limit = false -- This is important so code doesn't run constantly
        hook.Add( "Think", "lambdaplayers_forceenablevoicechat", function()
            local vcbind = input_LookupBinding( "+voicerecord" )
            local bindenum = vcbind and input_GetKeyCode( vcbind ) or KEY_X

            if input_IsKeyDown( bindenum ) and !limit then
                limit = true
                GAMEMODE:PlayerStartVoice( LocalPlayer() )
            elseif !input_IsKeyDown( bindenum ) and limit then
                limit = false
                GAMEMODE:PlayerEndVoice( LocalPlayer() )
                net.Start( "lambdaplayers_realplayerendvoice", true )
                net.SendToServer()
            end
        end )
    end

    local table_Empty = table.Empty
    local max = math.max
    local ispanel = ispanel
    local surface_SetFont = surface.SetFont
    local surface_GetTextSize = surface.GetTextSize
    local surface_SetDrawColor = surface.SetDrawColor
    local surface_SetMaterial = surface.SetMaterial
    local DrawTexturedRect = surface.DrawTexturedRect
    local sub = string.sub
    local SortedPairsByMemberValue = SortedPairsByMemberValue
    local allowpopups = GetConVar( "lambdaplayers_voice_voicepopups" )
    local voicepopupx = GetConVar( "lambdaplayers_voice_voicepopupoffset_x" )
    local voicepopupy = GetConVar( "lambdaplayers_voice_voicepopupoffset_y" )

    local popupBaseColor = Color( 255, 255, 255, 255 )
    local popupVolColor = Color( 0, 255, 0, 240 )
    local drawPopupIndexes = {}

    -- This handles the rendering of the Voice Popups to the right side
    hook.Add( "HUDPaint", "LambdaPlayers_DrawVoicePopups", function()
        if !allowpopups:GetBool() then return end

        local realTime = RealTime()
        local timeOffset = 0
        local canDrawSomething = false
        table_Empty( drawPopupIndexes )

        for lambda, vcData in SortedPairsByMemberValue( _LAMBDAPLAYERS_VoicePopups, "FirstDisplayTime" ) do
            local playTime = vcData.PlayTime
            if playTime then
                if realTime >= playTime then
                    vcData.PlayTime = false
                else
                    continue
                end
            end

            local sndVol = 0
            local snd = vcData.Sound
            if IsValid( snd ) and snd:GetState() == GMOD_CHANNEL_PLAYING then
                local leftChan, rightChan = snd:GetLevel()
                sndVol = ( ( leftChan + rightChan ) * 0.5 )

                vcData.LastPlayTime = realTime
                if vcData.FirstDisplayTime == 0 then
                    vcData.FirstDisplayTime = ( realTime + timeOffset )
                    timeOffset = ( timeOffset + 0.1 )
                end
            end
            vcData.VoiceVolume = sndVol

            local drawAlpha = max( 0, 1 - ( ( realTime - vcData.LastPlayTime ) / 2 ) )
            if !IsValid( snd ) and drawAlpha == 0 then
                _LAMBDAPLAYERS_VoicePopups[ lambda ] = nil
                continue
            end

            vcData.AlphaRatio = drawAlpha
            if drawAlpha == 0 then
                vcData.FirstDisplayTime = 0
                continue
            end

            canDrawSomething = true
            drawPopupIndexes[ lambda ] = vcData
        end

        if !canDrawSomething then return end
        local drawX, drawY = ( ScrW() - 298 + voicepopupx:GetInt() ), ( ScrH() - 142 + voicepopupy:GetInt() )

        local plyPopups = g_VoicePanelList
        if ispanel( plyPopups ) then drawY = ( drawY - ( 44 * #plyPopups:GetChildren() ) ) end

        local popupIndex = 0
        surface_SetFont( "GModNotify" )

        for lambda, vcData in SortedPairsByMemberValue( drawPopupIndexes, "FirstDisplayTime" ) do
            local drawAlpha = vcData.AlphaRatio
            popupBaseColor.a = ( drawAlpha * 255 )

            local vol = ( vcData.VoiceVolume * drawAlpha )
            local vcClr = vcData.Color
            popupVolColor.r = ( vol * vcClr.r )
            popupVolColor.g = ( vol * vcClr.g )
            popupVolColor.b = ( vol * vcClr.b )

            popupVolColor.a = ( drawAlpha * 240 )
            draw.RoundedBox( 4, drawX, drawY, 246, 40, popupVolColor )

            surface_SetDrawColor( popupBaseColor )
            surface_SetMaterial( vcData.ProfilePicture )
            DrawTexturedRect( drawX + 4, drawY + 4, 32, 32 )

            local nickname = vcData.Nick
            local textWidth = surface_GetTextSize( nickname )
            if textWidth > 200 then
                nickname = sub( nickname, 0, ( ( #nickname * ( 202.5 / textWidth ) ) - 3 ) ) .. "..."
            end
            DrawText( nickname, "GModNotify", drawX + 43.5, drawY + 9, popupBaseColor, TEXT_ALIGN_LEFT )

            drawY = ( drawY - 44 )
            popupIndex = ( popupIndex + 1 )
        end
    end )


    -- Removes ragdolls that are were created while not drawn in clientside
    hook.Add( "PreCleanupMap", "LambdaPlayers_OnPreCleanupMap", function()
        for _, v in ipairs( _LAMBDAPLAYERS_ClientSideRagdolls ) do
            if IsValid( v ) then v:Remove() end
        end
    end )

end