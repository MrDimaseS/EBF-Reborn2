--[[
Broodking AI
]]


function Spawn( entityKeyValues )
	if not IsServer() then
		return
	end
	
	Timers:CreateTimer(function()
		if thisEntity and not thisEntity:IsNull() then
			return AIThink(thisEntity)
		end
	end)
	
	thisEntity.howl = thisEntity:FindAbilityByName("boss_kobold_howl")
	Timers:CreateTimer(0.1, function()
		thisEntity.howl:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if not thisEntity:IsAlive() then
		return
	end
	if thisEntity:GetTeamNumber() == DOTA_TEAM_NEUTRALS and not thisEntity:IsChanneling() then
		if thisEntity.howl:IsFullyCastable() and ( AICore:TotalEnemyHeroesInRange( thisEntity, thisEntity.howl:GetSpecialValueFor("radius")) >= math.ceil(HeroList:GetActiveHeroCount() / 2) or thisEntity:IsAttacking() ) then
			ExecuteOrderFromTable({
				UnitIndex = thisEntity:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
				AbilityIndex = thisEntity.howl:entindex()
			})
			return AI_THINK_RATE
		end
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