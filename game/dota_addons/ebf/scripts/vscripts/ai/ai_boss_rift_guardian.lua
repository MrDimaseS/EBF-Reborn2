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
	
	thisEntity.shield = thisEntity:FindAbilityByName("boss_rift_guardian_fire_shield")
	thisEntity.hell = thisEntity:FindAbilityByName("boss_rift_guardian_hell_on_earth")
	thisEntity.obliterate = thisEntity:FindAbilityByName("boss_rift_guardian_obliterate")
	thisEntity.fist = thisEntity:FindAbilityByName("boss_rift_guardian_flaming_fist")
	Timers:CreateTimer(0.1, function()
		thisEntity.shield:SetLevel(GameRules.gameDifficulty)
		thisEntity.hell:SetLevel(GameRules.gameDifficulty)
		thisEntity.obliterate:SetLevel(GameRules.gameDifficulty)
		thisEntity.fist:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.shield:IsFullyCastable() and AICore:TotalEnemyHeroesInRange( thisEntity, thisEntity.shield:GetSpecialValueFor("radius") ) >= 1 then
			ExecuteOrderFromTable({
						UnitIndex = thisEntity:entindex(),
						OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
						AbilityIndex = thisEntity.shield:entindex()
					})
			return thisEntity.shield:GetCastPoint() + AI_THINK_RATE
		end
		if thisEntity.hell:IsFullyCastable() and AICore:TotalEnemyHeroesInRange( thisEntity, thisEntity.hell:GetTrueCastRange() ) >= 1 then
			ExecuteOrderFromTable({
						UnitIndex = thisEntity:entindex(),
						OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
						AbilityIndex = thisEntity.hell:entindex()
					})
			return thisEntity.hell:GetCastPoint() + AI_THINK_RATE
		end
		-- if thisEntity.fist:IsFullyCastable()  then
			-- local castPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.fist:GetTrueCastRange(), thisEntity.fist:GetSpecialValueFor("radius") )
			-- if castPosition then
				-- ExecuteOrderFromTable({
					-- UnitIndex = thisEntity:entindex(),
					-- OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					-- Position = castPosition,
					-- AbilityIndex = thisEntity.fist:entindex()
				-- })
				-- return thisEntity.fist:GetCastPoint() + AI_THINK_RATE
			-- end
		-- end
		if thisEntity.obliterate:IsFullyCastable() then
			local target = AICore:NearestEnemyHeroInRange( thisEntity, -1, true)
			if target then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.obliterate:entindex(),
					TargetIndex = target:entindex()
				})
				return thisEntity.obliterate:GetCastPoint() + AI_THINK_RATE
			end
		end
		-- no spells left to be cast and not currently attacking
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end