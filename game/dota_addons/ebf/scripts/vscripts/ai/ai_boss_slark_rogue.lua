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
	
	thisEntity.rite = thisEntity:FindAbilityByName("boss_slark_bloodrite")
	thisEntity.shift = thisEntity:FindAbilityByName("boss_slark_essence_shift")
	thisEntity.rage = thisEntity:FindAbilityByName("boss_slark_bloodrage")
	Timers:CreateTimer(0.1, function()
		thisEntity.rite:SetLevel(GameRules.gameDifficulty)
		thisEntity.shift:SetLevel(GameRules.gameDifficulty)
		thisEntity.rage:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.rite:IsFullyCastable() then
			local castPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.rite:GetTrueCastRange(), thisEntity.rite:GetSpecialValueFor("radius") )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.rite:entindex()
				})
				return AI_THINK_RATE
			end
		end
		if thisEntity.rage:IsFullyCastable() then
			local allies = thisEntity:FindFriendlyUnitsInRadius( thisEntity:GetAbsOrigin(), thisEntity.rage:GetTrueCastRange() )
			local target
			for _, ally in ipairs( allies ) do
				if ally:HasModifier("modifier_bloodseeker_bloodrage") then
					if target then
						local targetRage = target:FindModifierByName("modifier_bloodseeker_bloodrage")
						local allyRage = target:FindModifierByName("modifier_bloodseeker_bloodrage")
						if targetRage and allyRage and allyRage:GetRemainingTime() < targetRage:GetRemainingTime() then
							target = ally
						end
					else
						target = ally
					end
				else
					target = ally
					break
				end
			end
			if target then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.rage:entindex(),
					TargetIndex = target:entindex()
				})
				return AI_THINK_RATE
			end
		end
		-- no spells left to be cast and not currently attacking
		if not thisEntity:IsAttacking() then
			local target = AICore:NearestEnemyHeroInRange( thisEntity, -1, true)
			if target and target ~= thisEntity:GetAttackTarget() then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
					Position = target:GetAbsOrigin()
				})
				return AI_THINK_RATE
			end
		end
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end