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
	
	thisEntity.rage = thisEntity:FindAbilityByName("boss_lifestealer_rage")
	thisEntity.feast = thisEntity:FindAbilityByName("boss_lifestealer_feast")
	thisEntity.boss_lifestealer_frenzy = thisEntity:FindAbilityByName("boss_lifestealer_frenzy")
	thisEntity.wounds = thisEntity:FindAbilityByName("boss_lifestealer_open_wounds")
	Timers:CreateTimer(0.1, function()
		thisEntity.feast:SetLevel(GameRules.gameDifficulty)
		thisEntity.wounds:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.rage:IsFullyCastable() then
			if (thisEntity:GetAggroTarget() and not thisEntity:IsAttacking()) -- catch up to target
			or thisEntity:IsDisabled() then -- shake off debuffs
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
					AbilityIndex = thisEntity.rage:entindex()
				})
			end
		end
		if thisEntity.wounds:IsFullyCastable() then
			local target = thisEntity:GetAttackTarget()
			if target and DotProduct( target:GetForwardVector(), thisEntity:GetForwardVector() ) > 0 and not target:HasModifier("modifier_life_stealer_open_wounds") then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.wounds:entindex(),
					TargetIndex = target:entindex()
				})
				return 0.1
			elseif RollPercentage( 10 ) then
				local randomTarget = thisEntity:FindRandomEnemyInRadius( thisEntity:GetAbsOrigin(), thisEntity.wounds:GetTrueCastRange() )
				if randomTarget and not randomTarget:HasModifier("modifier_life_stealer_open_wounds") then
					ExecuteOrderFromTable({
						UnitIndex = thisEntity:entindex(),
						OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
						AbilityIndex = thisEntity.wounds:entindex(),
						TargetIndex = randomTarget:entindex()
					})
					return 0.1
				end
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