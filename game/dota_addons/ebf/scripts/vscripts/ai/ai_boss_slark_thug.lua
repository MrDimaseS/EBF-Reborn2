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
	
	thisEntity.pounce = thisEntity:FindAbilityByName("boss_slark_pounce")
	thisEntity.shift = thisEntity:FindAbilityByName("boss_slark_essence_shift")
	Timers:CreateTimer(0.1, function()
		thisEntity.pounce:SetLevel(GameRules.gameDifficulty)
		thisEntity.shift:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.pounce:IsFullyCastable() then
			local enemy = thisEntity:FindEnemyUnitsInLine(thisEntity:GetAbsOrigin(), thisEntity:GetAbsOrigin() + thisEntity:GetForwardVector() * thisEntity.pounce:GetSpecialValueFor("pounce_distance"), thisEntity.pounce:GetSpecialValueFor("pounce_radius"), {})[1]
			if enemy and DotProduct( enemy:GetForwardVector(), thisEntity:GetForwardVector() ) > 0 then
				ExecuteOrderFromTable({
							UnitIndex = thisEntity:entindex(),
							OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
							AbilityIndex = thisEntity.pounce:entindex()
						})
				return 0.1
			end
		end
		-- no spells left to be cast and not currently attacking
		if not thisEntity:IsAttacking() then
			local target = AICore:NearestEnemyHeroInRange( thisEntity, -1, true)
			if target and target ~= thisEntity:GetAttackTarget() then
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