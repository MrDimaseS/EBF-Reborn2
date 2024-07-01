--[[ Ogre Defender AI ]]

function Spawn(entityKeyValues)
	if not IsServer() then
		return
	end
	
	thisEntity.cone_push = thisEntity:FindAbilityByName("boss_ogre_defender_cone_push")

	if thisEntity.cone_push then
		thisEntity.cone_push:ToggleAutoCast()
	end

	Timers:CreateTimer(function()
		if thisEntity and not thisEntity:IsNull() and thisEntity:IsAlive() then
			return AIThink(thisEntity)
		end
	end)
end

function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.cone_push and thisEntity.cone_push:IsFullyCastable() then
			ExecuteOrderFromTable({
				UnitIndex = thisEntity:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
				AbilityIndex = thisEntity.cone_push:entindex()
			})
			return 1
		end
		
		if not thisEntity:IsAttacking() then
			local target = AICore:NearestEnemyHeroInRange(thisEntity, -1, true)
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