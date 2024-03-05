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
	
	thisEntity.stroke = thisEntity:FindAbilityByName("minion_rift_cleric_dark_artistry")
	thisEntity.ink = thisEntity:FindAbilityByName("minion_rift_cleric_ink_creature")
	thisEntity.walk = thisEntity:FindAbilityByName("minion_rift_cleric_spirit_walk")
	thisEntity.chain = thisEntity:FindAbilityByName("minion_rift_cleric_soul_chain")
	Timers:CreateTimer(0.1, function()
		thisEntity.stroke:SetLevel(GameRules.gameDifficulty)
		thisEntity.ink:SetLevel(GameRules.gameDifficulty)
		thisEntity.walk:SetLevel(GameRules.gameDifficulty)
		thisEntity.chain:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.stroke:IsFullyCastable() then
			local castPosition = AICore:FindOptimalLineInRangeForEntity(thisEntity, thisEntity.stroke:GetTrueCastRange(), thisEntity.stroke:GetSpecialValueFor("end_radius"), thisEntity.stroke:GetTrueCastRange())
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.stroke:entindex()
				})
				return thisEntity.stroke:GetCastPoint() + AI_THINK_RATE
			end
		end
		if thisEntity.walk:IsFullyCastable() then
			local castTarget = AICore:FindOptimalAllyInRangeForEntity(thisEntity, thisEntity.walk:GetTrueCastRange(), thisEntity.walk:GetSpecialValueFor("radius"))
			if castTarget then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.walk:entindex(),
					TargetIndex = castTarget:entindex()
				})
				return thisEntity.walk:GetCastPoint() + AI_THINK_RATE
			end
		end
		if thisEntity.ink:IsFullyCastable() then
			local castTarget = AICore:WeakestEnemyHeroInRange( thisEntity, thisEntity.ink:GetTrueCastRange() )
			if castTarget then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.ink:entindex(),
					TargetIndex = castTarget:entindex()
				})
				return thisEntity.ink:GetCastPoint() + AI_THINK_RATE
			end
		end
		if thisEntity.chain:IsFullyCastable() then
			local castTarget = AICore:FindOptimalTargetInRangeForEntity(thisEntity, thisEntity.chain:GetTrueCastRange(), thisEntity.chain:GetSpecialValueFor("chain_latch_radius"), nil, false, 1)
			if castTarget then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.chain:entindex(),
					TargetIndex = castTarget:entindex()
				})
				return thisEntity.chain:GetCastPoint() + AI_THINK_RATE
			end
		end
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end