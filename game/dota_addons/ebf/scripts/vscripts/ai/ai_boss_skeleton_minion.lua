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
	
	thisEntity.crit = thisEntity:FindAbilityByName("boss_skeleton_mortal_strike")
	Timers:CreateTimer(0.1, function()
		thisEntity.crit:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if not thisEntity:IsAlive() then
		return
	end
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() then-- no spells left to be cast and not currently attacking
		for _, enemy in ipairs( thisEntity:FindEnemyUnitsInRadius( thisEntity:GetAbsOrigin(), thisEntity:GetIdealSpeed() * 1.5 ) ) do
			if enemy:HasModifier("modifier_skeleton_king_hellfire_blast") then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
					TargetIndex = enemy:entindex()
				})
				return AI_THINK_RATE
			end
		end
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end