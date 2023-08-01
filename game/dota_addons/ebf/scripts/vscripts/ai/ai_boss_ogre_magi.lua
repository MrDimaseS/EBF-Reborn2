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
		-- else
			-- for _, unit in ipairs( thisEntity:FindEnemyUnitsInRadius( thisEntity:GetAbsOrigin(), -1 ) ) do
				-- unit:RemoveModifierByNameAndCaster( "modifier_ogre_magi_ignite", thisEntity )
			-- end
		end
	end)
	
	thisEntity.ignite = thisEntity:FindAbilityByName("boss_ogre_magi_ignite")
	thisEntity.shield = thisEntity:FindAbilityByName("boss_ogre_magi_frost_shield")
	thisEntity.multicast = thisEntity:FindAbilityByName("boss_ogre_magi_multicast")
	
	Timers:CreateTimer(0.1, function()
		thisEntity.ignite:SetLevel(GameRules.gameDifficulty)
		thisEntity.shield:SetLevel(GameRules.gameDifficulty)
		thisEntity.multicast:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.ignite:IsFullyCastable() then
			local target = thisEntity:FindRandomEnemyInRadius(thisEntity:GetAbsOrigin(), thisEntity.ignite:GetTrueCastRange() )
			if target then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.ignite:entindex(),
					TargetIndex = target:entindex()
				})
				return 0.1
			end
		end
		if thisEntity.shield:IsFullyCastable() then
			local target = thisEntity:FindFriendlyUnitsInRadius(thisEntity:GetAbsOrigin(), thisEntity.ignite:GetTrueCastRange() )[1]
			if target then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.shield:entindex(),
					TargetIndex = target:entindex()
				})
				return 0.1
			end
		end-- no spells left to be cast and not currently attacking
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