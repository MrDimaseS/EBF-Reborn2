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
	
	-- thisEntity.grasp = thisEntity:FindAbilityByName("boss_forest_guardian_natures_grasp")
	thisEntity.leech = thisEntity:FindAbilityByName("boss_forest_guardian_leech_seed")
	thisEntity.armor = thisEntity:FindAbilityByName("boss_forest_guardian_living_armor")
	thisEntity.overgrowth = thisEntity:FindAbilityByName("boss_forest_guardian_overgrowth")
	
	Timers:CreateTimer(0.1, function()
		-- thisEntity.grasp:SetLevel(GameRules.gameDifficulty)
		thisEntity.leech:SetLevel(GameRules.gameDifficulty)
		thisEntity.armor:SetLevel(GameRules.gameDifficulty)
		thisEntity.overgrowth:SetLevel(GameRules.gameDifficulty)
	end)
end

function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		-- if thisEntity.grasp:IsFullyCastable() then
			-- local optimalPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.grasp:GetTrueCastRange(), thisEntity.grasp:GetSpecialValueFor("latch_range") )
			-- if optimalPosition then
				-- ExecuteOrderFromTable({
					-- UnitIndex = thisEntity:entindex(),
					-- OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					-- Position = optimalPosition,
					-- AbilityIndex = thisEntity.grasp:entindex()
				-- })
				-- return 0.1
			-- end
		-- end
		if thisEntity.armor:IsFullyCastable() then
			local optimalPosition = AICore:FindOptimalFriendlyRadiusInRangeForEntity(thisEntity, 9999, thisEntity.armor:GetSpecialValueFor("radius"), thisEntity:HasModifier("modifier_treant_living_armor"), function(unit) return unit:HasModifier("modifier_treant_living_armor") end )
			if optimalPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = optimalPosition,
					AbilityIndex = thisEntity.armor:entindex()
				})
				return 0.1
			end
		end
		if thisEntity.leech:IsFullyCastable() then
			local target
			if thisEntity:GetAggroTarget() and CalculateDistance( thisEntity:GetAggroTarget(), thisEntity ) <= thisEntity.leech:GetTrueCastRange() and not thisEntity:GetAggroTarget():HasModifier("modifier_treant_leech_seed") then
				target = thisEntity:GetAggroTarget()
			else
				target = thisEntity:FindEnemyUnitsInRadius( thisEntity:GetAbsOrigin(), thisEntity.leech:GetTrueCastRange() )[1]
			end
			if target then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.leech:entindex(),
					TargetIndex = target:entindex(),
				})
				return 0.1
			end
		end
		if thisEntity.overgrowth:IsFullyCastable() and #thisEntity:FindEnemyUnitsInRadius( thisEntity:GetAbsOrigin(), thisEntity.overgrowth:GetSpecialValueFor("radius") * 0.75, {flag = DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE } ) >= math.max( 1, math.floor( HeroList:GetActiveHeroCount() / 2 ) ) then
			ExecuteOrderFromTable({
						UnitIndex = thisEntity:entindex(),
						OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
						AbilityIndex = thisEntity.overgrowth:entindex()
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