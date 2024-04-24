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
	
	thisEntity.maim = thisEntity:FindAbilityByName("boss_gnoll_berserker_maim")
	thisEntity.powerThroe = thisEntity:FindAbilityByName("boss_gnoll_berserker_enrage_damage")
	thisEntity.speedThroe = thisEntity:FindAbilityByName("boss_gnoll_berserker_enrage_speed")
	thisEntity.blood = thisEntity:FindAbilityByName("boss_gnoll_berserkers_blood")
	Timers:CreateTimer(0.1, function()
		thisEntity.maim:SetLevel(GameRules.gameDifficulty)
		thisEntity.powerThroe:SetLevel(GameRules.gameDifficulty)
		thisEntity.speedThroe:SetLevel(GameRules.gameDifficulty)
		thisEntity.blood:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if not thisEntity:IsAlive() then
		return
	end
	if thisEntity:GetTeamNumber() == DOTA_TEAM_NEUTRALS and not thisEntity:IsChanneling() then-- no spells left to be cast and not currently attacking
		if not thisEntity:IsAttacking() then
			local target = AICore:WeakestEnemyHeroInRange( thisEntity, thisEntity:GetAttackRange() + thisEntity:GetIdealSpeed(), true) or AICore:NearestEnemyHeroInRange( thisEntity, -1, true)
			if target and target ~= thisEntity:GetAttackTarget() then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
					Position = target:GetAbsOrigin()
				})
				return AI_THINK_RATE
			end
		end
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end