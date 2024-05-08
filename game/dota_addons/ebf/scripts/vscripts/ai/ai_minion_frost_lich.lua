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
	
	thisEntity.chain = thisEntity:FindAbilityByName("minion_frost_lich_chain_frost")
	
	Timers:CreateTimer(0.1, function()
		thisEntity.chain:SetLevel(GameRules.gameDifficulty)
	end)
end

function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.chain:IsFullyCastable() then
			local target
			if thisEntity:GetAggroTarget() and CalculateDistance( thisEntity, thisEntity:GetAggroTarget() ) < thisEntity.chain:GetTrueCastRange() then
				target = thisEntity:GetAggroTarget()
			end
			if target then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.chain:entindex(),
					TargetIndex = target:entindex(),
				})
				return 0.1
			end
		end
		-- no spells left to be cast and not currently attacking
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end