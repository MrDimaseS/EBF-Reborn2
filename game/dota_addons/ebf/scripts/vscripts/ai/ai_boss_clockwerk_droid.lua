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
	
	thisEntity.flare = thisEntity:FindAbilityByName("boss_robot_rocket_flare")
	Timers:CreateTimer(0.1, function()
		thisEntity.flare:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.flare:IsFullyCastable() then
			local castPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.flare:GetTrueCastRange(), thisEntity.flare:GetSpecialValueFor("radius") )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.flare:entindex()
				})
				return 0.1
			end
		end
		-- no spells left to be cast and not currently attacking
		if RollPercentage( 25 ) then
			ExecuteOrderFromTable({
				UnitIndex = thisEntity:entindex(),
				OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
				Position = thisEntity:GetAbsOrigin() + RandomVector( thisEntity:GetIdealSpeed() )
			})
			return AI_THINK_RATE
		end
		return AI_THINK_RATE
	else 
		return AI_THINK_RATE 
	end
end