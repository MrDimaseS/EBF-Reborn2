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
	
	thisEntity.inner_beast = thisEntity:FindAbilityByName("boss_ursine_shaman_inner_beast")
	thisEntity.howl = thisEntity:FindAbilityByName("boss_ursine_shaman_howl")
	thisEntity.primal_roar = thisEntity:FindAbilityByName("boss_ursine_shaman_primal_roar")
	thisEntity.drums_of_slom = thisEntity:FindAbilityByName("boss_ursine_shaman_drums_of_slom")
	Timers:CreateTimer(0.1, function()
		thisEntity.inner_beast:SetLevel(GameRules.gameDifficulty)
		thisEntity.howl:SetLevel(GameRules.gameDifficulty)
		thisEntity.primal_roar:SetLevel(GameRules.gameDifficulty)
		thisEntity.drums_of_slom:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if not thisEntity:IsAlive() then
		return
	end
	if not thisEntity:IsChanneling() then
		local target = thisEntity:GetAttackTarget()
		if thisEntity.howl:IsFullyCastable() and AICore:TotalEnemyHeroesInRange( thisEntity, thisEntity.howl:GetSpecialValueFor( "radius" ) ) > 0 then
			ExecuteOrderFromTable({
				UnitIndex = thisEntity:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
				AbilityIndex = thisEntity.howl:entindex()
			})
			 return AI_THINK_RATE
		end
		if thisEntity.primal_roar:IsFullyCastable() then
			local target = thisEntity:GetAttackTarget()
			if target then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.primal_roar:entindex(),
					TargetIndex = target:entindex()
				})
				return AI_THINK_RATE
			elseif RollPercentage( 10 ) then
				local randomTarget = thisEntity:FindRandomEnemyInRadius( thisEntity:GetAbsOrigin(), thisEntity.primal_roar:GetTrueCastRange() )
				if randomTarget then
					ExecuteOrderFromTable({
						UnitIndex = thisEntity:entindex(),
						OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
						AbilityIndex = thisEntity.primal_roar:entindex(),
						TargetIndex = randomTarget:entindex()
					})
					return AI_THINK_RATE
				end
			end
		end
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end