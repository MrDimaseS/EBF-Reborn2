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
	
	thisEntity.sprout = thisEntity:FindAbilityByName("boss_forest_summoner_sprout")
	thisEntity.call = thisEntity:FindAbilityByName("boss_forest_summoner_force_of_nature")
	thisEntity.wrath = thisEntity:FindAbilityByName("boss_forest_summoner_wrath_of_nature")
	
	Timers:CreateTimer(0.1, function()
		thisEntity.sprout:SetLevel(GameRules.gameDifficulty)
		thisEntity.call:SetLevel(GameRules.gameDifficulty)
		thisEntity.wrath:SetLevel(GameRules.gameDifficulty)
	end)
end

function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.sprout:IsFullyCastable() then
			local target
			if thisEntity:GetAggroTarget() and CalculateDistance( thisEntity, thisEntity:GetAggroTarget() ) < thisEntity.sprout:GetTrueCastRange() and DotProduct( thisEntity:GetAggroTarget():GetForwardVector(), thisEntity:GetForwardVector() ) > 0 then
				target = thisEntity:GetAggroTarget()
			elseif thisEntity.call:IsFullyCastable() then
				target = thisEntity:FindRandomEnemyInRadius( thisEntity:GetAbsOrigin(), thisEntity.sprout:GetTrueCastRange() )
			end
			if target then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.sprout:entindex(),
					TargetIndex = target:entindex(),
				})
				return 0.1
			end
		end
		if thisEntity.call:IsFullyCastable() then
			ExecuteOrderFromTable({
						UnitIndex = thisEntity:entindex(),
						OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
						AbilityIndex = thisEntity.call:entindex()
					})
			return 0.1
		end
		if thisEntity.wrath:IsFullyCastable() and RollPercentage( 15 ) then
			ExecuteOrderFromTable({
						UnitIndex = thisEntity:entindex(),
						OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
						AbilityIndex = thisEntity.wrath:entindex()
					})
			return 0.1
		end
		-- no spells left to be cast and not currently attacking
		if not thisEntity:IsAttacking() then
			local target = AICore:NearestEnemyHeroInRange( thisEntity, -1, true)
			if target then
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