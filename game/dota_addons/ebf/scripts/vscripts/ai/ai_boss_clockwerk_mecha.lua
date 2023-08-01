--[[
Broodking AI
]]


function Spawn( entityKeyValues )
	if not IsServer() then
		return
	end
	
	Timers:CreateTimer(function()
		if thisEntity and not thisEntity:IsNull() and thisEntity:IsAlive() then
			return AIThink(thisEntity)
		else
			-- CleanUpCogs( thisEntity )
		end
	end)
	
	thisEntity.battery = thisEntity:FindAbilityByName("boss_robot_battery_assault")
	thisEntity.cogs = thisEntity:FindAbilityByName("boss_robot_cogs")
	thisEntity.hook = thisEntity:FindAbilityByName("boss_robot_hookshot")
	Timers:CreateTimer(0.1, function()
		thisEntity.battery:SetLevel(GameRules.gameDifficulty)
		thisEntity.cogs:SetLevel(GameRules.gameDifficulty)
		thisEntity.hook:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.battery:IsFullyCastable() then
			local enemies = thisEntity:FindEnemyUnitsInRadius( thisEntity:GetAbsOrigin(), thisEntity.battery:GetSpecialValueFor("radius") )
			if #enemies > 0 then
				ExecuteOrderFromTable({
							UnitIndex = thisEntity:entindex(),
							OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
							AbilityIndex = thisEntity.battery:entindex()
						})
				return 0.1
			end
		end
		if thisEntity.cogs:IsFullyCastable() and thisEntity:HasModifier("modifier_rattletrap_battery_assault") then
			local enemies = thisEntity:FindEnemyUnitsInRadius( thisEntity:GetAbsOrigin(), thisEntity.cogs:GetSpecialValueFor("cogs_radius") - 25 )
			if #enemies > 0 then
				ExecuteOrderFromTable({
							UnitIndex = thisEntity:entindex(),
							OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
							AbilityIndex = thisEntity.cogs:entindex()
						})
				return 0.1
			end
		end
		if thisEntity.hook:IsFullyCastable() then
			local units = thisEntity:FindEnemyUnitsInRadius( thisEntity:GetAbsOrigin(), thisEntity.hook:GetTrueCastRange(), {order = FIND_FARTHEST} )
			local castPosition
			local interrupted
			for _, unit in ipairs( units ) do
				local straightLine = thisEntity:FindAllUnitsInLine( thisEntity:GetAbsOrigin(), unit:GetAbsOrigin(), thisEntity.hook:GetSpecialValueFor("latch_radius") * 2 )
				for _, target in ipairs( straightLine ) do
					if target:IsSameTeam( thisEntity ) and thisEntity ~= target then -- if allied units interrupt straight line, disregard
						interrupted = target
						break
					end
				end
				if not interrupted then
					castPosition = unit:GetAbsOrigin()
				elseif interrupted then -- look if enemies within stun radius
					local enemies = thisEntity:FindEnemyUnitsInRadius( interrupted:GetAbsOrigin(), thisEntity.hook:GetSpecialValueFor("stun_radius") )
					if #enemies > 0 then
						castPosition = interrupted:GetAbsOrigin()
					end
				end
			end
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.hook:entindex()
				})
				return 0.1
			end
			return 0.1
		end-- no spells left to be cast and not currently attacking
		if not thisEntity:IsAttacking() then
			local target = AICore:NearestEnemyHeroInRange( thisEntity, -1, true)
			if target and target ~= thisEntity:GetAttackTarget() then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
					Position = target:GetAbsOrigin()
				})
				return AI_THINK_RATE
			end
		end
		return AI_THINK_RATE
	else 
		return AI_THINK_RATE 
	end
end

function CleanUpCogs(thisEntity)
	for _,cog in pairs( FindUnitsInRadius( thisEntity:GetTeam(), thisEntity:GetOrigin(), nil, 99999, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, 0, false ) ) do
		if cog:GetUnitName() == "npc_dota_rattletrap_cog" or cog:GetName() == "npc_dota_rattletrap_cog" or cog:GetUnitLabel() == "npc_dota_rattletrap_cog" then
			if cog:GetOwnerEntity() == thisEntity then
				cog:ForceKill( false )
			end
		end
	end
end