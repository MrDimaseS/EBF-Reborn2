--[[ Ogre Destroyer AI ]]

function Spawn(entityKeyValues)
	if not IsServer() then
		return
	end
	
	Timers:CreateTimer(function()
		if thisEntity and not thisEntity:IsNull() and thisEntity:IsAlive() then
			return AIThink(thisEntity)
		end
	end)
	
	thisEntity.lust = thisEntity:FindAbilityByName("boss_ogre_tank_bloodlust")
	thisEntity.smash = thisEntity:FindAbilityByName("boss_ogre_destroyer_smash")
	
	Timers:CreateTimer(0.1, function()
		thisEntity.lust:SetLevel(GameRules.gameDifficulty)
		thisEntity.smash:SetLevel(GameRules.gameDifficulty)
	end)
end

function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.lust:IsFullyCastable() and thisEntity:GetAttackTarget() and not thisEntity:HasModifier("modifier_ogre_magi_bloodlust") then
			ExecuteOrderFromTable({
				UnitIndex = thisEntity:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
				AbilityIndex = thisEntity.lust:entindex(),
				TargetIndex = thisEntity:entindex()
			})
			return 0.1
		end
		if thisEntity.smash:IsFullyCastable() then
			local target = AICore:NearestEnemyHeroInRange(thisEntity, 450, true)
			if target then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = target:GetAbsOrigin(),
					AbilityIndex = thisEntity.smash:entindex()
				})
				return 0.1
			end
		end
		-- No spells left to be cast and not currently attacking
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end