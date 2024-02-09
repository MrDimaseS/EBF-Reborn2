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
	
	thisEntity.impale = thisEntity:FindAbilityByName("boss_psionic_assassin_impale")
	thisEntity.jolt = thisEntity:FindAbilityByName("boss_psionic_assassin_mind_flare")
	thisEntity.carapace = thisEntity:FindAbilityByName("boss_psionic_assassin_reflecting_carapace")
	thisEntity.vendetta = thisEntity:FindAbilityByName("boss_psionic_assassin_vendetta")
	Timers:CreateTimer(0.1, function()
		thisEntity.impale:SetLevel(4+GameRules.gameDifficulty)
		thisEntity.jolt:SetLevel(4+GameRules.gameDifficulty)
		thisEntity.carapace:SetLevel(4+GameRules.gameDifficulty)
		thisEntity.vendetta:SetLevel(4+GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.impale:IsFullyCastable() then
			if thisEntity:IsAttacking() then
				local castPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.impale:GetTrueCastRange(), thisEntity.impale:GetSpecialValueFor("unburrow_aoe") )
				if castPosition then
					ExecuteOrderFromTable({
						UnitIndex = thisEntity:entindex(),
						OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
						Position = castPosition,
						AbilityIndex = thisEntity.impale:entindex()
					})
					return thisEntity.impale:GetCastPoint() + 0.1
				end
			elseif thisEntity:GetAttackTarget() then
				local castPosition = thisEntity:GetAbsOrigin() + CalculateDirection( thisEntity:GetAttackTarget(), caster ) * thisEntity.impale:GetTrueCastRange()
				if castPosition then
					ExecuteOrderFromTable({
						UnitIndex = thisEntity:entindex(),
						OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
						Position = castPosition,
						AbilityIndex = thisEntity.impale:entindex()
					})
					return thisEntity.impale:GetCastPoint() + 0.1
				end
			end
		end
		if thisEntity.jolt:IsFullyCastable() and thisEntity:GetAttackTarget() then
			ExecuteOrderFromTable({
				UnitIndex = thisEntity:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
				AbilityIndex = thisEntity.jolt:entindex(),
				TargetIndex = thisEntity:GetAttackTarget():entindex()
			})
			return thisEntity.jolt:GetCastPoint() + 0.1
		end
		-- no spells left to be cast and not currently attacking
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end