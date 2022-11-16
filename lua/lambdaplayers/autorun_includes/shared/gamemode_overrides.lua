if CLIENT then return end
local canoverride = GetConVar( "lambdaplayers_lambda_overridegamemodehooks" )

hook.Add( "Initialize", "lambdaplayers_overridegamemodehooks", function() 

	if canoverride:GetBool() or true then

		function GAMEMODE:PlayerDeath( ply, inflictor, attacker )

			-- Don't spawn for at least 2 seconds
			ply.NextSpawnTime = CurTime() + 2
			ply.DeathTime = CurTime()

			if ( IsValid( attacker ) && attacker:GetClass() == "trigger_hurt" ) then attacker = ply end

			if ( IsValid( attacker ) && attacker:IsVehicle() && IsValid( attacker:GetDriver() ) ) then
				attacker = attacker:GetDriver()
			end

			if ( !IsValid( inflictor ) && IsValid( attacker ) ) then
				inflictor = attacker
			end

			-- Convert the inflictor to the weapon that they're holding if we can.
			-- This can be right or wrong with NPCs since combine can be holding a
			-- pistol but kill you by hitting you with their arm.
			if ( IsValid( inflictor ) && inflictor == attacker && ( inflictor:IsPlayer() || inflictor:IsNPC() ) ) then

				inflictor = inflictor:GetActiveWeapon()
				if ( !IsValid( inflictor ) ) then inflictor = attacker end

			end

			player_manager.RunClass( ply, "Death", inflictor, attacker )

			if ( attacker == ply ) then

				net.Start( "PlayerKilledSelf" )
					net.WriteEntity( ply )
				net.Broadcast()

				MsgAll( attacker:Nick() .. " suicided!\n" )

			return end

			if ( attacker:IsPlayer() ) then

				net.Start( "PlayerKilledByPlayer" )

					net.WriteEntity( ply )
					net.WriteString( inflictor:GetClass() )
					net.WriteEntity( attacker )

				net.Broadcast()

				MsgAll( attacker:Nick() .. " killed " .. ply:Nick() .. " using " .. inflictor:GetClass() .. "\n" )

			return end

			if !attacker.IsLambdaPlayer then
				net.Start( "PlayerKilled" )

					net.WriteEntity( ply )
					net.WriteString( inflictor:GetClass() )
					net.WriteString( attacker:GetClass() )

				net.Broadcast()
			end

			MsgAll( ply:Nick() .. " was killed by " .. attacker:GetClass() .. "\n" )

		end

		function GAMEMODE:OnNPCKilled( ent, attacker, inflictor )

			-- Don't spam the killfeed with scripted stuff
			if ( ent:GetClass() == "npc_bullseye" || ent:GetClass() == "npc_launcher" ) then return end
		
			if ( IsValid( attacker ) && attacker:GetClass() == "trigger_hurt" ) then attacker = ent end
			
			if ( IsValid( attacker ) && attacker:IsVehicle() && IsValid( attacker:GetDriver() ) ) then
				attacker = attacker:GetDriver()
			end
		
			if ( !IsValid( inflictor ) && IsValid( attacker ) ) then
				inflictor = attacker
			end
			
			-- Convert the inflictor to the weapon that they're holding if we can.
			if ( IsValid( inflictor ) && attacker == inflictor && ( inflictor:IsPlayer() || inflictor:IsNPC() ) ) then
			
				inflictor = inflictor:GetActiveWeapon()
				if ( !IsValid( attacker ) ) then inflictor = attacker end
			
			end
			
			local InflictorClass = "worldspawn"
			local AttackerClass = "worldspawn"
			
			if ( IsValid( inflictor ) ) then InflictorClass = inflictor:GetClass() end
			if ( IsValid( attacker ) and !ent.IsLambdaPlayer and !attacker.IsLambdaPlayer ) then
		
				AttackerClass = attacker:GetClass()
			
				if ( attacker:IsPlayer() ) then
		
					net.Start( "PlayerKilledNPC" )
				
						net.WriteString( ent:GetClass() )
						net.WriteString( InflictorClass )
						net.WriteEntity( attacker )
				
					net.Broadcast()
		
					return
				end
		
			end
		
			if ( ent:GetClass() == "npc_turret_floor" ) then AttackerClass = ent:GetClass() end

			if ent.IsLambdaPlayer or attacker.IsLambdaPlayer then return end
		
			net.Start( "NPCKilledNPC" )
			
				net.WriteString( ent:GetClass() )
				net.WriteString( InflictorClass )
				net.WriteString( AttackerClass )
			
			net.Broadcast()
		
		end

	end
end )