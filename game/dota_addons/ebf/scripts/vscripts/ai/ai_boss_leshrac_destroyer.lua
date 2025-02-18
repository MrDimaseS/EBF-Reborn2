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
	
	thisEntity.split = thisEntity:FindAbilityByName("boss_leshrac_split_earth")
	thisEntity.lightning = thisEntity:FindAbilityByName("boss_leshrac_lightning_storm")
	thisEntity.nova = thisEntity:FindAbilityByName("boss_leshrac_pulse_nova")
	thisEntity.nihilism = thisEntity:FindAbilityByName("boss_leshrac_nihilism")
	
	thisEntity:AddNewModifier( thisEntity, nil, "modifier_item_aghanims_shard", {} )
	Timers:CreateTimer(0.1, function()
		thisEntity.split:SetLevel(GameRules.gameDifficulty)
		thisEntity.lightning:SetLevel(GameRules.gameDifficulty)
		thisEntity.nova:SetLevel(GameRules.gameDifficulty)
		thisEntity.nihilism:SetLevel(GameRules.gameDifficulty)
		
		thisEntity.nova:ToggleAbility()
	end)
end


function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.split:IsFullyCastable() then
			local castPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.split:GetTrueCastRange(), thisEntity.split:GetSpecialValueFor("radius") )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.split:entindex()
				})
				return AI_THINK_RATE
			end
		end
		if thisEntity.lightning:IsFullyCastable() and thisEntity:GetAttackTarget() then
			local target = thisEntity:GetAttackTarget()
			ExecuteOrderFromTable({
				UnitIndex = thisEntity:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
				AbilityIndex = thisEntity.lightning:entindex(),
				TargetIndex = target:entindex()
			})
			return AI_THINK_RATE
		end
		if not thisEntity.nova:GetToggleState() and thisEntity.nova:IsOwnersManaEnough() then
			thisEntity.nova:ToggleAbility()
		end
		
		if thisEntity.nihilism:IsFullyCastable() and AICore:NearestEnemyHeroInRange( thisEntity, 1000, true) then
			ExecuteOrderFromTable({
				UnitIndex = thisEntity:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
				AbilityIndex = thisEntity.nihilism:entindex()
			})
			return AI_THINK_RATE
		end
		-- no spells left to be cast and not currently attacking
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end