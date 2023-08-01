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
	
	thisEntity.blast = thisEntity:FindAbilityByName("boss_skeleton_king_hellfire_blast")
	thisEntity.summon = thisEntity:FindAbilityByName("boss_skeleton_king_summon_skeletons")
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
		if thisEntity.blast:IsFullyCastable() then
			local target = thisEntity:FindRandomEnemyInRadius( thisEntity:GetAbsOrigin(), thisEntity.blast:GetTrueCastRange() )
			if target then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.blast:entindex(),
					TargetIndex = target:entindex()
				})
				return 0.1
			end
		end
		if thisEntity.summon:IsFullyCastable() and #thisEntity:FindEnemyUnitsInRadius( thisEntity:GetAbsOrigin(), 650 ) > 0 then
			ExecuteOrderFromTable({
				UnitIndex = thisEntity:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
				AbilityIndex = thisEntity.summon:entindex()
			})
			return 0.1
		end
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end