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
	
	thisEntity.hurl = thisEntity:FindAbilityByName("boss_troll_warlord_hurl_axe")
	thisEntity.dance = thisEntity:FindAbilityByName("boss_troll_warlord_dance_of_axes")
	thisEntity.meteor = thisEntity:FindAbilityByName("boss_troll_warlord_meteor_strike")
	thisEntity.warrior = thisEntity:FindAbilityByName("boss_troll_warlord_flexible_warrior")
	thisEntity.fervor = thisEntity:FindAbilityByName("boss_troll_warlord_fervor")
	thisEntity.trance = thisEntity:FindAbilityByName("boss_troll_warlord_battle_trance")
	
	thisEntity:AddActivityModifier("melee")
	
	Timers:CreateTimer(0.1, function()
		thisEntity.hurl:SetLevel(GameRules.gameDifficulty)
		thisEntity.dance:SetLevel(GameRules.gameDifficulty)
		thisEntity.meteor:SetLevel(GameRules.gameDifficulty)
		thisEntity.warrior:SetLevel(GameRules.gameDifficulty)
		thisEntity.fervor:SetLevel(GameRules.gameDifficulty)
		thisEntity.trance:SetLevel(GameRules.gameDifficulty)
	end)
end

function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		local attackTarget = thisEntity:GetAggroTarget()
		if attackTarget and thisEntity.hurl:IsFullyCastable() and CalculateDistance( attackTarget, thisEntity ) < thisEntity.hurl:GetSpecialValueFor("axe_range") and RollPercentage( 35 ) then
			ExecuteOrderFromTable({
						UnitIndex = thisEntity:entindex(),
						OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
						AbilityIndex = thisEntity.hurl:entindex()
					})
			return 0.1
		end
		if thisEntity.dance:IsFullyCastable() and thisEntity:IsAttacking() and RollPercentage( 35 ) then
			ExecuteOrderFromTable({
						UnitIndex = thisEntity:entindex(),
						OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
						AbilityIndex = thisEntity.dance:entindex()
					})
			return 0.1
		end
		if thisEntity.meteor:IsFullyCastable() then
			local radius = thisEntity.meteor:GetSpecialValueFor("radius")
			local target = thisEntity:FindEnemyUnitsInRadius( thisEntity:GetAbsOrigin(), radius, {order = FIND_FARTHEST})[1]
			if target then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = target:GetAbsOrigin() + ActualRandomVector( radius ),
					AbilityIndex = thisEntity.meteor:entindex()
				})
				return 0.1
			end
		end
		if thisEntity.trance:IsFullyCastable() then
			if ( thisEntity:IsAttacking() and RollPercentage( 8 ) ) then
				ExecuteOrderFromTable({
							UnitIndex = thisEntity:entindex(),
							OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
							AbilityIndex = thisEntity.trance:entindex()
						})
				return 0.1
			end
		end
		-- no spells left to be cast and not currently attacking
		return AICore:HandleBasicAI( thisEntity )
	else 
		return 0.1
	end
end