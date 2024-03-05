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
	
	thisEntity.storm = thisEntity:FindAbilityByName("boss_rift_general_firestorm")
	thisEntity.pit = thisEntity:FindAbilityByName("boss_rift_general_pit_of_malice")
	thisEntity.aura = thisEntity:FindAbilityByName("boss_rift_general_atrophy_aura")
	Timers:CreateTimer(0.1, function()
		thisEntity.storm:SetLevel(GameRules.gameDifficulty)
		thisEntity.pit:SetLevel(GameRules.gameDifficulty)
		thisEntity.aura:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.storm:IsFullyCastable() then
			local castPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.storm:GetTrueCastRange(), thisEntity.storm:GetSpecialValueFor("radius") )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.storm:entindex()
				})
				return thisEntity.storm:GetCastPoint() + AI_THINK_RATE
			end
		end
		if thisEntity.pit:IsFullyCastable() then
			local castPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.pit:GetTrueCastRange(), thisEntity.pit:GetSpecialValueFor("radius") )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.pit:entindex()
				})
				return thisEntity.pit:GetCastPoint() + AI_THINK_RATE
			end
		end
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end