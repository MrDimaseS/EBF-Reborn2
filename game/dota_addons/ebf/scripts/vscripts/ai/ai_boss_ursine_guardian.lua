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
	
	thisEntity.earthshock = thisEntity:FindAbilityByName("boss_ursine_guardian_earthshock")
	thisEntity.overpower = thisEntity:FindAbilityByName("boss_ursine_guardian_overpower")
	thisEntity.swipes = thisEntity:FindAbilityByName("boss_ursine_fury_swipes")
	thisEntity.enrage = thisEntity:FindAbilityByName("boss_ursine_guardian_enrage")
	Timers:CreateTimer(0.1, function()
		thisEntity.earthshock:SetLevel(GameRules.gameDifficulty)
		thisEntity.overpower:SetLevel(GameRules.gameDifficulty)
		thisEntity.swipes:SetLevel(GameRules.gameDifficulty)
		thisEntity.enrage:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if not thisEntity:IsAlive() then
		return
	end
	if thisEntity:GetTeamNumber() == DOTA_TEAM_NEUTRALS and not thisEntity:IsChanneling() then
		local target = thisEntity:GetAttackTarget()
		if thisEntity.earthshock:IsFullyCastable() and RollPercentage(10) or (target and DotProduct( target:GetForwardVector(), thisEntity:GetForwardVector() ) > 0) then
			ExecuteOrderFromTable({
				UnitIndex = thisEntity:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
				AbilityIndex = thisEntity.earthshock:entindex()
			})
			return AI_THINK_RATE 
		end
		if thisEntity.overpower:IsFullyCastable() and (RollPercentage(25) or thisEntity:IsAttacking()) then
			ExecuteOrderFromTable({
				UnitIndex = thisEntity:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
				AbilityIndex = thisEntity.overpower:entindex()
			})
			return AI_THINK_RATE 
		end
		if thisEntity.enrage:IsFullyCastable() and thisEntity:GetHealthPercent() < 50 and RollPercentage(25) then
			ExecuteOrderFromTable({
				UnitIndex = thisEntity:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
				AbilityIndex = thisEntity.enrage:entindex()
			})
			return AI_THINK_RATE 
		end
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end