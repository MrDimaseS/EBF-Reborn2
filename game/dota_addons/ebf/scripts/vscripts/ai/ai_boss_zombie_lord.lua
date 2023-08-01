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
	
	thisEntity.decay = thisEntity:FindAbilityByName("boss_zombie_decay")
	thisEntity.rip = thisEntity:FindAbilityByName("boss_zombie_soul_rip")
	thisEntity.tombstone = thisEntity:FindAbilityByName("boss_zombie_tombstone")
	Timers:CreateTimer(0.1, function()
		thisEntity.decay:SetLevel(GameRules.gameDifficulty)
		thisEntity.rip:SetLevel(GameRules.gameDifficulty)
		thisEntity.tombstone:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.tombstone:IsFullyCastable() then
			ExecuteOrderFromTable({
						UnitIndex = thisEntity:entindex(),
						OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
						AbilityIndex = thisEntity.tombstone:entindex()
					})
			return 0.1
		end
		if thisEntity.decay:IsFullyCastable() then
			local castPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.decay:GetTrueCastRange(), thisEntity.decay:GetSpecialValueFor("radius") )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.decay:entindex()
				})
				return 0.1
			end
		end
		if thisEntity.rip:IsFullyCastable() then
			local target = AICore:WeakestEnemyHeroInRange( thisEntity, thisEntity.rip:GetTrueCastRange() )
			if target then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.rip:entindex(),
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