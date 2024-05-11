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
	
	thisEntity.orb = thisEntity:FindAbilityByName("boss_trickster_dragon_illusory_orb")
	thisEntity.rift = thisEntity:FindAbilityByName("boss_trickster_dragon_waning_rift")
	thisEntity.shift = thisEntity:FindAbilityByName("boss_trickster_dragon_phase_shift")
	thisEntity.coil = thisEntity:FindAbilityByName("boss_trickster_dragon_dream_coil")
	thisEntity.duplicate = thisEntity:FindAbilityByName("boss_trickster_dragon_ethereal_duplicate")
	
	thisEntity:AddNewModifier( thisEntity, nil, "modifier_item_aghanims_shard", {} )
	Timers:CreateTimer(0.1, function()
		thisEntity.orb:SetLevel(GameRules.gameDifficulty)
		thisEntity.rift:SetLevel(GameRules.gameDifficulty)
		thisEntity.shift:SetLevel(GameRules.gameDifficulty)
		thisEntity.coil:SetLevel(GameRules.gameDifficulty)
		thisEntity.duplicate:SetLevel(GameRules.gameDifficulty)
	end)
end

function AIThink(thisEntity)
	if thisEntity:IsChanneling() and RollPercentage( 25 ) then -- end phase shift whenever
		thisEntity:Stop()
	end
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity:HasModifier("modifier_boss_trickster_dragon_ethereal_duplicate_illusion") then
			return AICore:HandleBasicAI( thisEntity )
		end
		if thisEntity.rift:IsFullyCastable() and RollPercentage( 35 ) then
			local castPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.rift:GetTrueCastRange(), thisEntity.rift:GetAOERadius(), nil, true )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.rift:entindex()
				})
				return thisEntity.rift:GetCastPoint() + 0.1
			end
		end
		if thisEntity.coil:IsFullyCastable() and RollPercentage( 35 ) then
			local castPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.coil:GetTrueCastRange(), thisEntity.coil:GetAOERadius(), nil, true )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.coil:entindex()
				})
				return thisEntity.coil:GetCastPoint() + 0.1
			end
		end
		if thisEntity.orb:IsFullyCastable() and RollPercentage( 35 ) then
			local castPosition = AICore:FindOptimalLineInRangeForEntity( thisEntity, thisEntity.orb:GetSpecialValueFor("max_distance"), thisEntity.orb:GetSpecialValueFor("radius"), thisEntity.orb:GetSpecialValueFor("max_distance") )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.orb:entindex()
				})
				return thisEntity.orb:GetCastPoint() + 0.1
			end
		end
		-- if thisEntity.shift:IsFullyCastable() and RollPercentage( 50 ) then
			-- local units = thisEntity:FindEnemyUnitsInRadius( thisEntity:GetAbsOrigin(), thisEntity:GetAttackRange() + thisEntity.shift:GetSpecialValueFor("shard_attack_range_bonus") )
			-- if #units > 0 then
				-- ExecuteOrderFromTable({
					-- UnitIndex = thisEntity:entindex(),
					-- OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
					-- AbilityIndex = thisEntity.shift:entindex()
				-- })
				-- return thisEntity.shift:GetCastPoint() + 0.5
			-- end
		-- end
		-- no spells left to be cast and not currently attacking
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end