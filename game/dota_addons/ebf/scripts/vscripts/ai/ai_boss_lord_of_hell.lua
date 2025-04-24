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
		end
	end)
	
	thisEntity.devour = thisEntity:FindAbilityByName("boss_lord_of_hell_devour")
	thisEntity.scorch = thisEntity:FindAbilityByName("boss_lord_of_hell_scorched_earth")
	thisEntity.blade = thisEntity:FindAbilityByName("boss_lord_of_hell_infernal_blade")
	thisEntity.doom = thisEntity:FindAbilityByName("boss_lord_of_hell_doom")
	thisEntity.blink = thisEntity:FindItemInInventory("item_lord_of_hell_overwhelming_blink")
	thisEntity.shiva = thisEntity:FindItemInInventory("item_lord_of_hell_shivas")
	
	Timers:CreateTimer(0.1, function()
		thisEntity.devour:SetLevel(GameRules.gameDifficulty)
		thisEntity.scorch:SetLevel(GameRules.gameDifficulty)
		thisEntity.blade:SetLevel(GameRules.gameDifficulty)
		thisEntity.doom:SetLevel(GameRules.gameDifficulty)
	end)
end

function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.blade:IsFullyCastable() and not thisEntity.blade:GetAutoCastState() then
			thisEntity.blade:ToggleAutoCast()
		end
		
		if thisEntity.devour:IsFullyCastable() then
			local target = AICore:NearestEnemyHeroInRange(thisEntity, thisEntity.devour:GetCastRange(thisEntity:GetAbsOrigin(), thisEntity.devour), true)
			if target then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.devour:entindex(),
					TargetIndex = target:entindex()
				})
				return thisEntity.devour:GetCastPoint() + AI_THINK_RATE
			end
		end
		
		if thisEntity.scorch:IsFullyCastable() then
			ExecuteOrderFromTable({
				UnitIndex = thisEntity:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
				AbilityIndex = thisEntity.scorch:entindex()
			})
			return thisEntity.scorch:GetCastPoint() + AI_THINK_RATE
		end
		
		if thisEntity.doom:IsFullyCastable() then
			ExecuteOrderFromTable({
				UnitIndex = thisEntity:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
				AbilityIndex = thisEntity.doom:entindex(),
				TargetIndex = thisEntity:entindex()
			})
			return thisEntity.doom:GetCastPoint() + AI_THINK_RATE
		end
		
		if thisEntity.blink and thisEntity.blink:IsFullyCastable() then
			local position = AICore:FindOptimalRadiusInRangeForEntity(thisEntity, thisEntity.blink:GetSpecialValueFor("blink_range"), thisEntity.blink:GetSpecialValueFor("radius"))
			if not position then
				local target = AICore:NearestEnemyHeroInRange(thisEntity, thisEntity.blink:GetSpecialValueFor("blink_range"), true)
				if target then position = target:GetAbsOrigin() end
			end
			if position then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = position,
					AbilityIndex = thisEntity.blink:entindex()
				})
				return AI_THINK_RATE
			end
		end
		
		if thisEntity.shiva and thisEntity.shiva:IsFullyCastable() then
			local enemiesInRange = AICore:TotalEnemyHeroesInRange(thisEntity, thisEntity.shiva:GetSpecialValueFor("blast_radius"))
			if enemiesInRange >= 1 then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
					AbilityIndex = thisEntity.shiva:entindex()
				})
				return AI_THINK_RATE
			end
		end
		
		-- no spells left to be cast and not currently attacking
		return AICore:HandleBasicAI(thisEntity)
	else 
		return AI_THINK_RATE 
	end
end
