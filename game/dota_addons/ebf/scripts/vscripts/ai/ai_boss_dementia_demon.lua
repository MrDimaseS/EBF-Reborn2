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
	
	thisEntity.cloak = thisEntity:FindAbilityByName("boss_dementia_demon_cloak_of_dementia")
	thisEntity.disruption = thisEntity:FindAbilityByName("boss_dementia_demon_mass_dementia")
	thisEntity.share = thisEntity:FindAbilityByName("boss_dementia_demon_share_pain")
	thisEntity.wave = thisEntity:FindAbilityByName("boss_dementia_demon_wave_of_melancholy")
	thisEntity.release = thisEntity:FindAbilityByName("boss_dementia_demon_release_melancholy")
	thisEntity.purge = thisEntity:FindAbilityByName("boss_dementia_demon_demented_purge")
	Timers:CreateTimer(0.1, function()
		thisEntity.cloak:SetLevel(GameRules.gameDifficulty)
		thisEntity.disruption:SetLevel(GameRules.gameDifficulty)
		thisEntity.share:SetLevel(GameRules.gameDifficulty)
		thisEntity.wave:SetLevel(GameRules.gameDifficulty)
		thisEntity.purge:SetLevel(GameRules.gameDifficulty)
	end)
end

function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		local disruptionTargets = thisEntity:FindEnemyUnitsInRadius( thisEntity:GetAbsOrigin(), thisEntity.disruption:GetTrueCastRange() )
		if thisEntity.disruption:IsCooldownReady() then
			if AICore:BeingAttacked( thisEntity ) 
			or #disruptionTargets >= RandomInt( 2, HeroList:GetActiveHeroes() ) then
				ExecuteOrderFromTable({
							UnitIndex = thisEntity:entindex(),
							OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
							AbilityIndex = thisEntity.disruption:entindex()
						})
				return  thisEntity.disruption:GetCastPoint()
			end
		end
		if thisEntity.share:IsFullyCastable() then
			local castTarget = AICore:FindOptimalTargetInRangeForEntity( thisEntity, thisEntity.share:GetTrueCastRange() + thisEntity:GetIdealSpeed(), thisEntity.share:GetSpecialValueFor("radius"), nil, true )
			if castTarget then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.share:entindex(),
					TargetIndex = castTarget:entindex()
				})
				return thisEntity.share:GetCastPoint() + CalculateDistance( castTarget, thisEntity ) / thisEntity:GetIdealSpeed() + 0.1
			end
		end
		if thisEntity.purge:IsFullyCastable() and RollPercentage( 15 ) then
			local target = AICore:WeakestEnemyHeroInRange( thisEntity, thisEntity.purge:GetTrueCastRange() + thisEntity:GetIdealSpeed() )
			if target and not target:HasModifier("modifier_shadow_demon_purge_slow") then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.purge:entindex(),
					TargetIndex = target:entindex()
				})
				return thisEntity.purge:GetCastPoint() + CalculateDistance( target, thisEntity ) / thisEntity:GetIdealSpeed() + 0.1
			end
		end
		if thisEntity.wave:IsFullyCastable() then
			local castPosition = AICore:FindOptimalLineInRangeForEntity( thisEntity, thisEntity.wave:GetTrueCastRange(), thisEntity.wave:GetSpecialValueFor("radius")*2, thisEntity.wave:GetTrueCastRange() )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.wave:entindex()
				})
				return thisEntity.purge:GetCastPoint() + CalculateDistance( castPosition, thisEntity ) / thisEntity:GetIdealSpeed() + 0.1
			end
		end
		local enemies = HeroList:GetActiveHeroes()
		for _, enemy in ipairs( enemies ) do
			local poison = enemy:FindModifierByName("modifier_boss_dementia_demon_wave_of_melancholy_poison")
			if poison and poison:OnTooltip() > enemy:GetHealth() then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
					AbilityIndex = thisEntity.release:entindex()
				})
				return AI_THINK_RATE
			end
		end
		-- no spells left to be cast and not currently attacking
		if not thisEntity:IsAttacking() then
			local target
			local potentialTargets = thisEntity:FindEnemyUnitsInRadius( thisEntity:GetAbsOrigin(), thisEntity:GetAttackRange() + thisEntity:GetIdealSpeed() )
			for _, enemy in ipairs( potentialTargets ) do
				local disseminate = enemy:FindModifierByName("modifier_shadow_demon_disseminate")
				if disseminate and disseminate:GetCaster():GetTeam() == thisEntity:GetTeam() then -- prioritize units affected by allied disseminate
					target = enemy
					break
				elseif ( not target or CalculateDistance( enemy, thisEntity ) < CalculateDistance( target, thisEntity ) ) then
					target = enemy
				end
			end
			if target and target ~= thisEntity:GetAttackTarget() then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
					Position = target:GetAbsOrigin()
				})
				return AI_THINK_RATE
			end
		end
		return AI_THINK_RATE
	else 
		return AI_THINK_RATE 
	end
end