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
	
	-- thisEntity.shot = thisEntity:FindAbilityByName("boss_treant_seed_shot")
	
	Timers:CreateTimer(0.1, function()
		-- thisEntity.shot:SetLevel(GameRules.gameDifficulty)
	end)
end

function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		-- if thisEntity.shot:IsFullyCastable() then
			-- target = thisEntity:FindRandomEnemyInRadius( thisEntity:GetAbsOrigin(), thisEntity.shot:GetTrueCastRange() )
			-- if target then
				-- ExecuteOrderFromTable({
					-- UnitIndex = thisEntity:entindex(),
					-- OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					-- AbilityIndex = thisEntity.shot:entindex(),
					-- TargetIndex = target:entindex(),
				-- })
				-- return 0.1
			-- end
		-- end
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