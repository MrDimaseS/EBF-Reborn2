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
	
	thisEntity.devour = thisEntity:FindAbilityByName("boss_lord_of_hell_devour")
	thisEntity.scorch = thisEntity:FindAbilityByName("boss_lord_of_hell_scorched_earth")
	thisEntity.blade = thisEntity:FindAbilityByName("boss_lord_of_hell_infernal_blade")
	thisEntity.doom = thisEntity:FindAbilityByName("boss_lord_of_hell_doom")
	thisEntity.blink = thisEntity:FindItemInInventory("item_lord_of_hell_overwhelming_blink")
	thisEntity.shiva = thisEntity:FindItemInInventory("item_lord_of_hell_shivas")
	Timers:CreateTimer(0.1, function()
		thisEntity.devour:SetLevel(GameRules.gameDifficulty)
		thisEntity.scorch:SetLevel(GameRules.gameDifficulty)
		thisEntity.blade:SetLevel(GameRules.gameDifficulty)
		thisEntity.blade:ToggleAutoCast()
		thisEntity.doom:SetLevel(GameRules.gameDifficulty)
	end)
end

function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.devour:IsFullyCastable() then
			local potentialTargets = thisEntity:FindAllUnitsInRadius( thisEntity:GetAbsOrigin(), thisEntity:GetIdealSpeed() * 4 )
			local castTarget
			for _, target in ipairs( potentialTargets ) do
				if target:IsNeutralUnitType() then
					for i = 0, target:GetAbilityCount() - 1 do
						local ability = target:GetAbilityByIndex( i )
						if ability and ability:IsPassive() and not ability:IsAttributeBonus() then
							if not thisEntity:HasAbility( ability:GetAbilityName() ) then
								castTarget = target
								break
							end
						end
					end
				end
			end
			if not castTarget then
				for _, target in ipairs( potentialTargets ) do
					if not target:IsConsideredHero() then
						for i = 0, target:GetAbilityCount() - 1 do
							local ability = target:GetAbilityByIndex( i )
							if ability and ability:IsPassive() and not ability:IsAttributeBonus() then
								if not thisEntity:HasAbility( ability:GetAbilityName() ) then
									castTarget = target
									break
								end
							end
						end
					end
				end
			end
			if not castTarget then
				for _, target in ipairs( potentialTargets ) do
					for i = 0, target:GetAbilityCount() - 1 do
						local ability = target:GetAbilityByIndex( i )
						if ability and ability:IsPassive() and not ability:IsAttributeBonus() then
							if not thisEntity:HasAbility( ability:GetAbilityName() ) then
								castTarget = target
								break
							end
						end
					end
				end
			end
			if not castTarget then
				for _, target in ipairs( potentialTargets ) do
					castTarget = target
					break
				end
			end
			if castTarget then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.devour:entindex(),
					TargetIndex = castTarget:entindex()
				})
				return thisEntity.devour:GetCastPoint() + AI_THINK_RATE
			end
		end
		if thisEntity.scorch:IsFullyCastable() and AICore:TotalEnemyHeroesInRange( thisEntity, thisEntity.scorch:GetSpecialValueFor("radius") ) >= 1 then
			local target = AICore:FurthestEnemyHeroInRange( thisEntity, -1, true)
			if target then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
					AbilityIndex = thisEntity.scorch:entindex()
				})
				return thisEntity.scorch:GetCastPoint() + AI_THINK_RATE
			end
		end
		if thisEntity.doom:IsFullyCastable() then
			local target = AICore:FindOptimalTargetInRangeForEntity( thisEntity, thisEntity.doom:GetTrueCastRange(), thisEntity.doom:GetSpecialValueFor("scepter_aura_radius"), nil, true)
			if target then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
					AbilityIndex = thisEntity.doom:entindex(),
					TargetIndex = target:entindex()
				})
				return thisEntity.doom:GetCastPoint() + AI_THINK_RATE
			end
		end
		if thisEntity.blink:IsFullyCastable() then
			local position = AICore:FindOptimalRadiusInRangeForEntity(thisEntity, thisEntity.blink:GetSpecialValueFor("blink_range"), thisEntity.blink:GetSpecialValueFor("radius"))
			if not position then
				local target = AICore:NearestEnemyHeroInRange( thisEntity, thisEntity.blink:GetSpecialValueFor("blink_range"), true )
				if target then position = target:GetAbsOrigin() end
			end
			if position then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = position,
					Position = position,
					AbilityIndex = thisEntity.blink:entindex()
				})
				return AI_THINK_RATE
			end
		end
		if thisEntity.shiva:IsFullyCastable() and AICore:TotalEnemyHeroesInRange( thisEntity, thisEntity.scorch:GetSpecialValueFor("radius") ) >= 1  then
			ExecuteOrderFromTable({
				UnitIndex = thisEntity:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
				AbilityIndex = thisEntity.shiva:entindex()
			})
			return AI_THINK_RATE
		end
		-- no spells left to be cast and not currently attacking
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end