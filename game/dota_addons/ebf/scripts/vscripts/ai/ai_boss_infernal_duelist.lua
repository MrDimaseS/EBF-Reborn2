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
	
	thisEntity.odds = thisEntity:FindAbilityByName("boss_infernal_duelist_overwhelming_odds")
	thisEntity.moment = thisEntity:FindAbilityByName("boss_infernal_duelist_moment_of_courage")
	thisEntity.duel = thisEntity:FindAbilityByName("boss_infernal_duelist_duel")
	thisEntity.spear = thisEntity:FindAbilityByName("boss_infernal_duelist_spear")
	thisEntity.rebuke = thisEntity:FindAbilityByName("boss_infernal_duelist_gods_rebuke")
	thisEntity.arena = thisEntity:FindAbilityByName("boss_infernal_duelist_arena")
	Timers:CreateTimer(0.1, function()
		thisEntity.odds:SetLevel(GameRules.gameDifficulty)
		thisEntity.moment:SetLevel(GameRules.gameDifficulty)
		thisEntity.duel:SetLevel(GameRules.gameDifficulty)
		thisEntity.spear:SetLevel(GameRules.gameDifficulty)
		thisEntity.rebuke:SetLevel(GameRules.gameDifficulty)
		thisEntity.arena:SetLevel(GameRules.gameDifficulty)
	end)
end	

function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.odds:IsFullyCastable() and thisEntity:IsAttacking() then
			ExecuteOrderFromTable({
				UnitIndex = thisEntity:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
				AbilityIndex = thisEntity.odds:entindex()
			})
			return thisEntity.odds:GetCastPoint() + 0.1
		end
		if thisEntity.duel:IsFullyCastable() and thisEntity:IsAttacking() then
			ExecuteOrderFromTable({
				UnitIndex = thisEntity:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
				AbilityIndex = thisEntity.duel:entindex()
			})
			return thisEntity.duel:GetCastPoint() + 0.1
		end
		if thisEntity.arena:IsFullyCastable() and RollPercentage( 45 )  then
			local castPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.arena:GetTrueCastRange(), thisEntity.arena:GetSpecialValueFor("radius") )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.arena:entindex()
				})
				return thisEntity.arena:GetCastPoint() + 0.1
			end
		end
		if thisEntity.rebuke:IsFullyCastable() and RollPercentage( 35 ) then
			local castPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.rebuke:GetTrueCastRange()/2, thisEntity.rebuke:GetSpecialValueFor("radius")/2 )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.rebuke:entindex()
				})
				return thisEntity.rebuke:GetCastPoint() + 0.1
			end
		end
		if thisEntity.spear:IsFullyCastable() and RollPercentage( 75 ) then
			local castPosition = AICore:FindOptimalLineInRangeForEntity( thisEntity, thisEntity.spear:GetSpecialValueFor("spear_range"), thisEntity.spear:GetSpecialValueFor("spear_width"), thisEntity.spear:GetSpecialValueFor("spear_range") )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.spear:entindex()
				})
				return thisEntity.spear:GetCastPoint() + 0.1
			end
		end
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end