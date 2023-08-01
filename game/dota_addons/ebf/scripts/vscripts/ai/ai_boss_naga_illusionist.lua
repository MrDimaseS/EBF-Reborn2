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
	
	thisEntity.image = thisEntity:FindAbilityByName("boss_naga_mirror_image")
	thisEntity.ensnare = thisEntity:FindAbilityByName("boss_naga_ensnare")
	thisEntity.riptide = thisEntity:FindAbilityByName("boss_naga_riptide")
	
	Timers:CreateTimer(0.1, function()
		if thisEntity.image then thisEntity.image:SetLevel(GameRules.gameDifficulty) end
		thisEntity.ensnare:SetLevel(GameRules.gameDifficulty)
		thisEntity.riptide:SetLevel(GameRules.gameDifficulty)
	end)
end

function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.image:IsFullyCastable() and thisEntity.image:IsActivated() and #thisEntity:FindEnemyUnitsInRadius( thisEntity:GetAbsOrigin(), 650 ) > 0 then
			ExecuteOrderFromTable({
						UnitIndex = thisEntity:entindex(),
						OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
						AbilityIndex = thisEntity.image:entindex()
					})
			return 0.1
		end
		if thisEntity.ensnare and thisEntity.image:IsActivated()  and thisEntity.ensnare:IsFullyCastable() then
			for _, target in ipairs( thisEntity:FindEnemyUnitsInRadius( thisEntity:GetAbsOrigin(), thisEntity.ensnare:GetTrueCastRange() ) ) do
				if DotProduct( thisEntity:GetForwardVector(), target:GetForwardVector() ) > 0 and target:IsMoving() then
					ExecuteOrderFromTable({
						UnitIndex = thisEntity:entindex(),
						OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
						AbilityIndex = thisEntity.ensnare:entindex(),
						TargetIndex = target:entindex()
					})
					return 0.1
				end
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