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
	
	thisEntity.cloak = thisEntity:FindAbilityByName("boss_mania_demon_cloak_of_mania")
	thisEntity.razeN = thisEntity:FindAbilityByName("boss_mania_demon_manic_raze_near")
	thisEntity.razeM = thisEntity:FindAbilityByName("boss_mania_demon_manic_raze_medium")
	thisEntity.razeF = thisEntity:FindAbilityByName("boss_mania_demon_manic_raze_far")
	thisEntity.presence = thisEntity:FindAbilityByName("boss_mania_demon_presence_of_mania")
	thisEntity.requiem = thisEntity:FindAbilityByName("boss_mania_demon_requiem_of_insanity")
	
	Timers:CreateTimer(0.1, function()
		thisEntity.cloak:SetLevel(GameRules.gameDifficulty)
		thisEntity.razeN:SetLevel(GameRules.gameDifficulty)
		thisEntity.razeM:SetLevel(GameRules.gameDifficulty)
		thisEntity.razeF:SetLevel(GameRules.gameDifficulty)
		thisEntity.presence:SetLevel(GameRules.gameDifficulty)
		thisEntity.requiem:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		local presence = thisEntity:FindModifierByName("modifier_boss_mania_demon_presence_of_mania")
		if thisEntity.requiem:IsFullyCastable() and presence:GetStackCount() >= thisEntity.requiem:GetSpecialValueFor("max_stacks") then
			ExecuteOrderFromTable({
				UnitIndex = thisEntity:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
				AbilityIndex = thisEntity.requiem:entindex()
			})
			return thisEntity.requiem:GetCastPoint()
		end
		if thisEntity.razeN:IsFullyCastable() then
			local range = thisEntity.razeN:GetSpecialValueFor("shadowraze_range")
			local radius = thisEntity.razeN:GetSpecialValueFor("shadowraze_radius")
			
			local castPosition = AICore:FindOptimalRadiusInRangeForEntityClamped( thisEntity, range - radius*2, range + radius*2, radius, exclusionFct )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.razeN:entindex()
				})
				return thisEntity.razeN:GetCastPoint()
			end
		end
		if thisEntity.razeM:IsFullyCastable() then
			local range = thisEntity.razeM:GetSpecialValueFor("shadowraze_range")
			local radius = thisEntity.razeM:GetSpecialValueFor("shadowraze_radius")
			local castPosition = AICore:FindOptimalRadiusInRangeForEntityClamped( thisEntity, range - radius, range + radius, radius, exclusionFct )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.razeM:entindex()
				})
				return thisEntity.razeM:GetCastPoint()
			end
		end
		if thisEntity.razeF:IsFullyCastable() then
			local range = thisEntity.razeF:GetSpecialValueFor("shadowraze_range")
			local radius = thisEntity.razeF:GetSpecialValueFor("shadowraze_radius")
			local castPosition = AICore:FindOptimalRadiusInRangeForEntityClamped( thisEntity, range - radius, range + radius, radius, exclusionFct )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.razeF:entindex()
				})
				return thisEntity.razeF:GetCastPoint()
			end
		end
		-- no spells left to be cast and not currently attacking
		if not thisEntity:IsAttacking() then
			local target
			local potentialTargets = thisEntity:FindEnemyUnitsInRadius( thisEntity:GetAbsOrigin(), thisEntity:GetAttackRange() + thisEntity:GetIdealSpeed() )
			for _, enemy in ipairs( potentialTargets ) do
				local disseminate = enemy:FindModifierByName("modifier_shadow_demon_disseminate")
				if disseminate and disseminate:GetCaster():GetTeam() == thisEntity:GetTeam() then -- prioritize units affected by allied disseminate
					target = enemy
					break
				elseif ( not target or CalculateDistance( enemy, thisEntity ) < CalculateDistance( target, thisEntity ) ) then
					target = enemy
				end
			end
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