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
	
	thisEntity.split = thisEntity:FindAbilityByName("boss_golem_split")
	thisEntity.throw = thisEntity:FindAbilityByName("boss_golem_rock_throw")
	thisEntity.difficulty = thisEntity:FindAbilityByName("boss_golem_difficulty")
	thisEntity.avalanche = thisEntity:FindAbilityByName("boss_golem_avalanche")
	
	thisEntity:AddNewModifier( thisEntity, nil, "modifier_item_aghanims_shard", {} )
	Timers:CreateTimer(0.1, function()
		if thisEntity.hasBeenProcessed then return end
		thisEntity.split:SetLevel(4)
		thisEntity.throw:SetLevel(4)
		thisEntity.avalanche:SetLevel(4)
		thisEntity.difficulty:SetLevel(4)
	end)
end


function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.throw:IsFullyCastable() then
			local castPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.throw:GetTrueCastRange(), thisEntity.throw:GetSpecialValueFor("search_radius") )
			if castPosition and RollPercentage( 15 ) then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.throw:entindex()
				})
				return 0.1
			end
		end
		if thisEntity.avalanche:IsFullyCastable() then
			local castPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.avalanche:GetTrueCastRange(), thisEntity.avalanche:GetSpecialValueFor("radius") )
			if castPosition and RollPercentage( 25 ) then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.avalanche:entindex()
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