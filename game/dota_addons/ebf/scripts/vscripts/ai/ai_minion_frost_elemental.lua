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
	
	thisEntity.vortex = thisEntity:FindAbilityByName("minion_frost_elemental_ice_vortex")
	thisEntity.blast = thisEntity:FindAbilityByName("minion_frost_elemental_ice_blast")
	Timers:CreateTimer(0.1, function()
		thisEntity.vortex:SetLevel(GameRules.gameDifficulty)
		thisEntity.blast:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.vortex:IsFullyCastable() then
			local castPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.vortex:GetTrueCastRange(), thisEntity.vortex:GetSpecialValueFor("radius"), function( unit ) return unit:HasModifier("modifier_ice_vortex") end )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.vortex:entindex()
				})
				return thisEntity.vortex:GetCastPoint() + 0.1
			end
		end
		if thisEntity.blast:IsFullyCastable() then
			local castPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, -1, thisEntity.blast:GetSpecialValueFor("radius") )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.blast:entindex()
				})
				return thisEntity.blast:GetCastPoint() + 0.1
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