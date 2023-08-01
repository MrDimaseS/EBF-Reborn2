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
	
	thisEntity.call = thisEntity:FindAbilityByName("boss_axe_berserkers_call")
	thisEntity.hunger = thisEntity:FindAbilityByName("boss_axe_battle_hunger")
	thisEntity.helix = thisEntity:FindAbilityByName("boss_axe_counter_helix")
	thisEntity.cull = thisEntity:FindAbilityByName("boss_axe_culling_blade")
	
	Timers:CreateTimer(0.1, function()
		thisEntity.call:SetLevel(GameRules.gameDifficulty)
		thisEntity.hunger:SetLevel(GameRules.gameDifficulty)
		thisEntity.helix:SetLevel(GameRules.gameDifficulty)
		thisEntity.cull:SetLevel(3+GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.hunger:IsFullyCastable() then
			local target 
			for _, enemy in ipairs( thisEntity:FindEnemyUnitsInRadius(thisEntity:GetAbsOrigin(), thisEntity.hunger:GetTrueCastRange() ) ) do
				if not enemy:HasModifier("modifier_boss_axe_battle_hunger") then
					target = enemy
					break
				end
			end
			if target then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.hunger:entindex(),
					TargetIndex = target:entindex()
				})
				return 0.1
			end
		end
		if thisEntity.cull:IsFullyCastable() then
			local target
			thisEntity._cullingThreshold = thisEntity._cullingThreshold or thisEntity.cull:GetSpecialValueFor("damage") * ( 1+thisEntity:GetSpellAmplification(false) )
			thisEntity.impatienceChance = thisEntity.impatienceChance or 10
			for index, enemy in ipairs( thisEntity:FindEnemyUnitsInRadius( thisEntity:GetAbsOrigin(), thisEntity:GetIdealSpeed() + thisEntity.cull:GetTrueCastRange(), {order = FIND_CLOSEST} ) ) do
				if enemy:GetHealth() <= thisEntity._cullingThreshold or (RollPercentage( thisEntity.impatienceChance ) and index == 1) then
					target = enemy
					break
				end
			end
			if target then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.cull:entindex(),
					TargetIndex = target:entindex()
				})
				return 0.1
			else
				thisEntity.impatienceChance = thisEntity.impatienceChance + 2.5
			end
		end
		if thisEntity.call:IsFullyCastable() then
			if AICore:BeingAttacked( thisEntity ) >= HeroList:GetActiveHeroCount() / 2 
			or ( thisEntity:GetAggroTarget() and CalculateDistance( thisEntity:GetAggroTarget(), thisEntity ) <= thisEntity.call:GetSpecialValueFor("radius") and DotProduct( thisEntity:GetAggroTarget():GetForwardVector(), thisEntity:GetForwardVector() ) > 0) then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
					AbilityIndex = thisEntity.call:entindex()
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