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
	
	thisEntity.pulse = thisEntity:FindAbilityByName("boss_death_avatar_death_pulse")
	thisEntity.seeker = thisEntity:FindAbilityByName("boss_death_avatar_death_seeker")
	thisEntity.scythe = thisEntity:FindAbilityByName("boss_death_avatar_reapers_scythe")
	thisEntity.ward = thisEntity:FindAbilityByName("boss_death_avatar_plague_ward")
	thisEntity.nova = thisEntity:FindAbilityByName("boss_death_avatar_poison_nova")
	thisEntity.aura = thisEntity:FindAbilityByName("boss_death_avatar_heartstopper_aura")
	thisEntity.poison = thisEntity:FindAbilityByName("boss_death_avatar_poison_attack")
	Timers:CreateTimer(0.1, function()
		thisEntity.pulse:SetLevel(GameRules.gameDifficulty)
		thisEntity.seeker:SetLevel(GameRules.gameDifficulty)
		thisEntity.scythe:SetLevel(GameRules.gameDifficulty)
		thisEntity.ward:SetLevel(GameRules.gameDifficulty)
		thisEntity.nova:SetLevel(GameRules.gameDifficulty)
		thisEntity.aura:SetLevel(GameRules.gameDifficulty)
		thisEntity.poison:SetLevel(GameRules.gameDifficulty)
		thisEntity.poison:ToggleAutoCast()
	end)
end


function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.pulse:IsFullyCastable() then
			ExecuteOrderFromTable({
						UnitIndex = thisEntity:entindex(),
						OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
						AbilityIndex = thisEntity.pulse:entindex()
					})
			return thisEntity.pulse:GetCastPoint() + AI_THINK_RATE
		end
		if thisEntity.seeker:IsFullyCastable() then
			local target = AICore:FurthestEnemyHeroInRange( thisEntity, -1, true)
			if target then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.seeker:entindex(),
					TargetIndex = target:entindex()
				})
				return thisEntity.seeker:GetCastPoint() + AI_THINK_RATE
			end
		end
		if thisEntity.scythe:IsFullyCastable() then
			for _, enemy in ipairs( thisEntity:FindEnemyUnitsInRadius( thisEntity:GetAbsOrigin(), -1 ) ) do
				if enemy:GetHealthDeficit() * thisEntity.scythe:GetSpecialValueFor("damage_per_health") >= enemy:GetHealth() / enemy:GetMagicalArmorValue( false, thisEntity.scythe ) then
					ExecuteOrderFromTable({
						UnitIndex = thisEntity:entindex(),
						OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
						AbilityIndex = thisEntity.scythe:entindex()
					})
					return thisEntity.scythe:GetCastPoint() + AI_THINK_RATE
				end
			end
		end
		if thisEntity.ward:IsFullyCastable() then
			ExecuteOrderFromTable({
				UnitIndex = thisEntity:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
				AbilityIndex = thisEntity.ward:entindex()
			})
			return thisEntity.ward:GetCastPoint() + AI_THINK_RATE
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