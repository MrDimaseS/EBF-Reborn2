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
		else
			-- CleanUpCogs( thisEntity )
		end
	end)
	
	thisEntity.roar = thisEntity:FindAbilityByName("roshan_revengeroar")
	thisEntity.slam = thisEntity:FindAbilityByName("roshan_slam")
	thisEntity.bash = thisEntity:FindAbilityByName("roshan_bash")
	thisEntity.block = thisEntity:FindAbilityByName("roshan_spell_block")
	Timers:CreateTimer(0.1, function()
		thisEntity.roar:SetLevel(GameRules.gameDifficulty)
		thisEntity.slam:SetLevel(GameRules.gameDifficulty)
		thisEntity.bash:SetLevel(GameRules.gameDifficulty)
		thisEntity.block:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.roar:IsFullyCastable() then
			local optimalPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.roar:GetTrueCastRange() / 2, thisEntity.roar:GetTrueCastRange() / 2 )
			if optimalPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = optimalPosition,
					AbilityIndex = thisEntity.roar:entindex()
				})
				return 0.1
			end
		end
		if thisEntity.slam:IsFullyCastable() then
			local enemies = thisEntity:FindEnemyUnitsInRadius( thisEntity:GetAbsOrigin(), thisEntity.slam:GetSpecialValueFor("radius") )
			if #enemies > 0 then
				ExecuteOrderFromTable({
							UnitIndex = thisEntity:entindex(),
							OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
							AbilityIndex = thisEntity.slam:entindex()
						})
				return 0.1
			end
		end
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