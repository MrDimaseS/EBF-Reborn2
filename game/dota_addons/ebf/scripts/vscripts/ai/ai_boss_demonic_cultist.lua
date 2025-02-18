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
	
	thisEntity.bonds = thisEntity:FindAbilityByName("boss_demonic_cultist_fatal_bonds")
	thisEntity.word = thisEntity:FindAbilityByName("boss_demonic_cultist_shadow_word")
	thisEntity.upheaval = thisEntity:FindAbilityByName("boss_demonic_cultist_upheaval")
	thisEntity.chaos = thisEntity:FindAbilityByName("boss_demonic_cultist_rain_of_chaos")
	thisEntity.explode = thisEntity:FindAbilityByName("minion_demonic_imp_explode")
	
	Timers:CreateTimer(0.1, function()
		thisEntity.bonds:SetLevel(GameRules.gameDifficulty)
		thisEntity.word:SetLevel(GameRules.gameDifficulty)
		thisEntity.upheaval:SetLevel(GameRules.gameDifficulty)
		thisEntity.chaos:SetLevel(GameRules.gameDifficulty)
		
		thisEntity.explode:SetLevel(2)
	end)
end

function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.word:IsFullyCastable() and RollPercentage( 35 ) then
			local castPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.word:GetTrueCastRange(), thisEntity.word:GetAOERadius(), nil, true )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.word:entindex()
				})
				return 0.1
			end
		end
		if thisEntity.upheaval:IsFullyCastable() and RollPercentage( 25 ) then
			local castPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.upheaval:GetTrueCastRange(), thisEntity.upheaval:GetAOERadius() )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.upheaval:entindex()
				})
				return 0.1
			end
		end
		if thisEntity.chaos:IsFullyCastable() and RollPercentage( 10 ) then
			local castPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.chaos:GetTrueCastRange(), thisEntity.chaos:GetAOERadius() )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.chaos:entindex()
				})
				return 0.1
			end
		end
		if thisEntity.bonds:IsFullyCastable() then
			local target = AICore:FindOptimalTargetInRangeForEntity(thisEntity, thisEntity.bonds:GetTrueCastRange(), thisEntity.bonds:GetSpecialValueFor("search_aoe"))
			if target then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.bonds:entindex(),
					TargetIndex = target:entindex()
				})
				return 0.1
			end
		end
		-- no spells left to be cast and not currently attacking
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end