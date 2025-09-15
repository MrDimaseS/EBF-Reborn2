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
	
	thisEntity.rally = thisEntity:FindAbilityByName("boss_kobold_rally_troops")
	Timers:CreateTimer(0.1, function()
		thisEntity.rally:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if not thisEntity:IsAlive() then
		return
	end
	if thisEntity:GetTeamNumber() == DOTA_TEAM_NEUTRALS and not thisEntity:IsChanneling() then
		if thisEntity.rally:IsFullyCastable() and ( AICore:TotalEnemyHeroesInRange( thisEntity, thisEntity.rally:GetSpecialValueFor("radius") ) >= math.ceil(HeroList:GetActiveHeroCount() / 2) or thisEntity:IsAttacking() ) then
			ExecuteOrderFromTable({
				UnitIndex = thisEntity:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
				AbilityIndex = thisEntity.rally:entindex()
			})
			return AI_THINK_RATE
		end
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end