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
		end
	end)
	
	thisEntity.swarm = thisEntity:FindAbilityByName("boss_death_prophet_carrion_swarm")
	thisEntity.stun = thisEntity:FindAbilityByName("boss_death_prophet_split_earth")
	thisEntity.siphon = thisEntity:FindAbilityByName("boss_death_prophet_spirit_siphon")
	thisEntity.exorcism = thisEntity:FindAbilityByName("boss_death_prophet_exorcism")
	
	Timers:CreateTimer(0.1, function()
		thisEntity.swarm:SetLevel(GameRules.gameDifficulty)
		thisEntity.stun:SetLevel(GameRules.gameDifficulty)
		thisEntity.siphon:SetLevel(GameRules.gameDifficulty)
		thisEntity.exorcism:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.swarm:IsFullyCastable() then
			local target = thisEntity:FindRandomEnemyInRadius( thisEntity:GetAbsOrigin(), thisEntity.swarm:GetTrueCastRange() )
			if target then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = target:GetAbsOrigin(),
					AbilityIndex = thisEntity.swarm:entindex()
				})
				return 0.1
			end
		end
		if thisEntity.stun:IsFullyCastable() then
			local castPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.stun:GetTrueCastRange(), thisEntity.stun:GetSpecialValueFor("radius") )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.stun:entindex()
				})
				return 0.1
			end
		end
		if thisEntity.siphon:IsFullyCastable() then
			local target = thisEntity:FindRandomEnemyInRadius( thisEntity:GetAbsOrigin(), thisEntity.siphon:GetTrueCastRange() )
			if target then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.siphon:entindex(),
					TargetIndex = target:entindex()
				})
				return 0.1
			end
		end
		if thisEntity.exorcism:IsFullyCastable() then
			local target = thisEntity:FindRandomEnemyInRadius( thisEntity:GetAbsOrigin(), thisEntity.exorcism:GetSpecialValueFor("radius") )
			if target then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
					AbilityIndex = thisEntity.exorcism:entindex()
				})
				return 0.1
			end
		end
		-- no spells left to be cast and not currently attacking
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