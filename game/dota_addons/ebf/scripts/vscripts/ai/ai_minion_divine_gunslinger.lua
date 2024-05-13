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
	
	thisEntity.calling = thisEntity:FindAbilityByName("minion_divine_gunslinger_the_calling")
	thisEntity.gun = thisEntity:FindAbilityByName("minion_divine_gunslinger_gunslinger")
	
	Timers:CreateTimer(0.1, function()
		thisEntity.calling:SetLevel(GameRules.gameDifficulty)
		thisEntity.gun:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.calling:IsFullyCastable() then
			local castPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.calling:GetTrueCastRange(), thisEntity.calling:GetSpecialValueFor("dead_zone_distance") )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.calling:entindex()
				})
				return thisEntity.calling:GetCastPoint() + 0.1
			end
		end
		if not thisEntity.gun:GetToggleState() then
			thisEntity.gun:ToggleAbility()
		end
		-- no spells left to be cast and not currently attacking
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end