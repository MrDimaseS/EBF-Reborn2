--[[
Broodking AI
]]

function Spawn(entityKeyValues)
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
	
	thisEntity.roar = thisEntity:FindAbilityByName("roshan_revengeroar")
	thisEntity.slam = thisEntity:FindAbilityByName("roshan_slam")
	-- Removed passive abilities from being cast
	Timers:CreateTimer(0.1, function()
		thisEntity.roar:SetLevel(GameRules.gameDifficulty)
		thisEntity.slam:SetLevel(GameRules.gameDifficulty)
	end)
end

function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		-- Use Roar if there are multiple enemies around
		if thisEntity.roar:IsFullyCastable() and RollPercentage( 16 ) then
			local enemies = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, thisEntity.roar:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			if #enemies >= 1 then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
					AbilityIndex = thisEntity.roar:entindex()
				})
				return 0.1
			end
		end
		
		-- Use Slam if there are enemies in range
		if thisEntity.slam:IsFullyCastable() then
			local enemies = thisEntity:FindEnemyUnitsInRadius(thisEntity:GetAbsOrigin(), thisEntity.slam:GetSpecialValueFor("radius"))
			if #enemies > 0 then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
					AbilityIndex = thisEntity.slam:entindex()
				})
				return 0.1
			end
		end
		
		-- Attack nearest enemy hero if not attacking
		if not thisEntity:IsAttacking() then
			local target = AICore:NearestEnemyHeroInRange(thisEntity, -1, true)
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