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
	
	thisEntity.burn = thisEntity:FindAbilityByName("boss_winter_wyvern_arctic_burn")
	thisEntity.blast = thisEntity:FindAbilityByName("boss_winter_wyvern_splinter_blast")
	thisEntity.embrace = thisEntity:FindAbilityByName("boss_winter_wyvern_cold_embrace")
	Timers:CreateTimer(0.1, function()
		thisEntity.burn:SetLevel(GameRules.gameDifficulty)
		thisEntity.blast:SetLevel(GameRules.gameDifficulty)
		thisEntity.embrace:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.burn:IsFullyCastable() and thisEntity:IsAttacking() then
			ExecuteOrderFromTable({
				UnitIndex = thisEntity:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
				AbilityIndex = thisEntity.burn:entindex()
			})
			return thisEntity.burn:GetCastPoint() + 0.1
		end
		if thisEntity.blast:IsFullyCastable() then
			local target = AICore:FindOptimalTargetInRangeForEntity(thisEntity, thisEntity.blast:GetTrueCastRange(), thisEntity.blast:GetSpecialValueFor("split_radius"), nil, false, 1 ) or thisEntity
			if thisEntity == target then -- check if we're actually hitting anyone when self-casting
				local unitsToHit = thisEntity:FindEnemyUnitsInRadius( thisEntity:GetAbsOrigin(), thisEntity.blast:GetSpecialValueFor("split_radius"), {type = DOTA_UNIT_TARGET_HERO, flag = DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE } )
				if unitsToHit == 0 then
					target = nil
				end
			end
			if target then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.blast:entindex(),
					TargetIndex = target:entindex()
				})
				return thisEntity.blast:GetCastPoint() + 0.1
			end
		end
		if thisEntity.embrace:IsFullyCastable() then
			if thisEntity:GetHealthPercent() > 50 then
				local target = AICore:WeakestEnemyHeroInRange( thisEntity, thisEntity.embrace:GetTrueCastRange() )
				if target then
					ExecuteOrderFromTable({
						UnitIndex = thisEntity:entindex(),
						OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
						AbilityIndex = thisEntity.embrace:entindex(),
						TargetIndex = target:entindex()
					})
					return thisEntity.embrace:GetCastPoint() + 0.1
				end
			else
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.embrace:entindex(),
					TargetIndex = thisEntity:entindex()
				})
				return thisEntity.embrace:GetCastPoint() + 0.1
			end
		end
		-- no spells left to be cast and not currently attacking
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end