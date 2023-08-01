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
	
	thisEntity.rage = thisEntity:FindAbilityByName("boss_troll_warlord_berserkers_rage")
	thisEntity.ranged_axes = thisEntity:FindAbilityByName("boss_troll_warlord_whirling_axes_ranged")
	thisEntity.melee_axes = thisEntity:FindAbilityByName("boss_troll_warlord_whirling_axes_melee")
	thisEntity.fervor = thisEntity:FindAbilityByName("boss_troll_warlord_fervor")
	thisEntity.berserker = thisEntity:FindAbilityByName("boss_troll_warlord_berserkers_blood")
	
	thisEntity:AddActivityModifier("melee")
	
	Timers:CreateTimer(0.1, function()
		thisEntity.rage:SetLevel(GameRules.gameDifficulty)
		thisEntity.ranged_axes:SetLevel(GameRules.gameDifficulty)
		thisEntity.ranged_axes:SetActivated(true)
		thisEntity.melee_axes:SetLevel(GameRules.gameDifficulty)
		thisEntity.melee_axes:SetActivated(true)
		thisEntity.fervor:SetLevel(GameRules.gameDifficulty)
		thisEntity.berserker:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		local attackTarget = thisEntity:GetAggroTarget()
		-- melee/ranged logic
		if thisEntity.rage:GetToggleState() then -- melee mode
			if attackTarget and DotProduct( attackTarget:GetForwardVector(), thisEntity:GetForwardVector() ) > 0 and not attackTarget:IsRooted() 
			and ( CalculateDistance(attackTarget, thisEntity) >= thisEntity:GetAttackRange() + 25 and CalculateDistance(attackTarget, thisEntity) < thisEntity:GetAttackRange() + thisEntity.rage:GetSpecialValueFor("bonus_range")-25 ) then -- attack target running away and out of attack range
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TOGGLE,
					AbilityIndex = thisEntity.rage:entindex(),
				})
				return 0.1
			end
		else -- ranged mode
			if (attackTarget and CalculateDistance(attackTarget, thisEntity) > thisEntity:GetAttackRange())
			or not thisEntity:IsAttacking()
			or attackTarget:HasModifier("modifier_troll_warlord_whirling_axes_slow")
			or DotProduct( attackTarget:GetForwardVector(), thisEntity:GetForwardVector() ) < 0 then -- attack target out of range or no target, speed up
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TOGGLE,
					AbilityIndex = thisEntity.rage:entindex(),
				})
				return 0.1
			end
		end
		if thisEntity.rage:GetToggleState() and thisEntity.melee_axes:IsFullyCastable() then
			local enemies = thisEntity:FindEnemyUnitsInRadius( thisEntity:GetAbsOrigin(), thisEntity.melee_axes:GetSpecialValueFor("max_range") )
			if #enemies >= 1 then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
					AbilityIndex = thisEntity.melee_axes:entindex()
				})
				return 0.1
			end
		end
		if not thisEntity.rage:GetToggleState() and thisEntity.ranged_axes:IsFullyCastable() then
			local castPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.ranged_axes:GetTrueCastRange(), thisEntity.ranged_axes:GetSpecialValueFor("axe_width") * thisEntity.ranged_axes:GetSpecialValueFor("axe_count") )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.ranged_axes:entindex()
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