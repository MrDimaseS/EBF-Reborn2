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
	
	thisEntity.servitude = thisEntity:FindAbilityByName("minion_hellish_servant_infernal_servitude")
	thisEntity.previousHealth = thisEntity:GetHealth()
	Timers:CreateTimer(0.1, function()
		thisEntity.servitude:SetLevel(1)
	end)
end


function AIThink(thisEntity)
	if not thisEntity:IsAlive() then
		return
	end
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() then
		if AICore:BeingAttacked( thisEntity ) > 0 or thisEntity.previousHealth*0.85 > thisEntity:GetHealth() then
			AICore:BeAHugeCoward( thisEntity, 300 )
		else
			local hero = thisEntity:FindFriendlyUnitsInRadius(thisEntity:GetAbsOrigin(), -1, {order = FIND_CLOSEST, type = DOTA_UNIT_TARGET_HERO})[1]
			if hero then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
					Position = hero:GetAbsOrigin() + ActualRandomVector( thisEntity.servitude:GetSpecialValueFor("radius") * 0.5, thisEntity.servitude:GetSpecialValueFor("radius") * 0.9 )
				})
			else
				return AICore:HandleBasicAI( thisEntity )
			end
		end
		thisEntity.previousHealth = thisEntity:GetHealth()
		return AI_THINK_RATE
	end
end