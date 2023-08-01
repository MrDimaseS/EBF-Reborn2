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
	
	thisEntity.strafe = thisEntity:FindAbilityByName("boss_skeleton_archer_strafe")
	thisEntity.tar = thisEntity:FindAbilityByName("boss_skeleton_archer_tar_bomb")
	thisEntity.crit = thisEntity:FindAbilityByName("boss_skeleton_mortal_strike")
	Timers:CreateTimer(0.1, function()
		thisEntity.strafe:SetLevel(GameRules.gameDifficulty)
		thisEntity.tar:SetLevel(GameRules.gameDifficulty)
		thisEntity.crit:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if not thisEntity:IsAlive() then
		return
	end
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() then-- no spells left to be cast and not currently attacking
		local target = thisEntity:GetAggroTarget()
		if target then
			if thisEntity.tar:IsFullyCastable() then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.tar:entindex(),
					TargetIndex = target:entindex()
				})
				return 0.1
			elseif thisEntity.strafe:IsFullyCastable() then -- only cast if tar bomb was used
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
					AbilityIndex = thisEntity.strafe:entindex()
				})
				return 0.1
			end
		end
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end