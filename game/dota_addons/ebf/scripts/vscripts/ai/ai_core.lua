--[[
Tower Defense AI
These are the valid orders, in case you want to use them (easier here than to find them in the C code):
DOTA_UNIT_ORDER_NONE
DOTA_UNIT_ORDER_MOVE_TO_POSITION 
DOTA_UNIT_ORDER_MOVE_TO_TARGET 
DOTA_UNIT_ORDER_ATTACK_MOVE
DOTA_UNIT_ORDER_ATTACK_TARGET
DOTA_UNIT_ORDER_CAST_POSITION
DOTA_UNIT_ORDER_CAST_TARGET
DOTA_UNIT_ORDER_CAST_TARGET_TREE
DOTA_UNIT_ORDER_CAST_NO_TARGET
DOTA_UNIT_ORDER_CAST_TOGGLE
DOTA_UNIT_ORDER_HOLD_POSITION
DOTA_UNIT_ORDER_TRAIN_ABILITY
DOTA_UNIT_ORDER_DROP_ITEM
DOTA_UNIT_ORDER_GIVE_ITEM
DOTA_UNIT_ORDER_PICKUP_ITEM
DOTA_UNIT_ORDER_PICKUP_RUNE
DOTA_UNIT_ORDER_PURCHASE_ITEM
DOTA_UNIT_ORDER_SELL_ITEM
DOTA_UNIT_ORDER_DISASSEMBLE_ITEM
DOTA_UNIT_ORDER_MOVE_ITEM
DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO
DOTA_UNIT_ORDER_STOP
DOTA_UNIT_ORDER_TAUNT
DOTA_UNIT_ORDER_BUYBACK
DOTA_UNIT_ORDER_GLYPH
DOTA_UNIT_ORDER_EJECT_ITEM_FROM_STASH
DOTA_UNIT_ORDER_CAST_RUNE
]]

AICore = {}


AI_BEHAVIOR_AGGRESSIVE = 1 -- Threat is weighted towards damage
AI_BEHAVIOR_CAUTIOUS = 2 -- Threat is weighted towards health
AI_BEHAVIOR_SAFE = 3 -- Threat is weighted towards heals and debuffs, requires bigger threat difference to switch aggro

AI_THINK_RATE = 0.5

TARGET_NEAREST = 0
TARGET_WEAKEST = 1

function AICore:RandomEnemyHeroInRange( entity, range , magic_immune)
	local flags = DOTA_UNIT_TARGET_FLAG_NO_INVIS 
	if magic_immune then
		flags = flags + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	end
	if entity:IsTauntedBy() then return entity:IsTauntedBy() end
	local enemies = FindUnitsInRadius( entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, range / 2, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, flags, 0, false )
	if #enemies > 0 then
		local index = RandomInt( 1, #enemies )
		return enemies[index]
	end
	enemies = FindUnitsInRadius( entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, range / 2, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, flags, 0, false )
	if #enemies > 0 then
		local index = RandomInt( 1, #enemies )
		return enemies[index]
	end
end

function AICore:NearestEnemyHeroInRange( entity, range , magic_immune)
	local flags = DOTA_UNIT_TARGET_FLAG_NO_INVIS 
	if magic_immune then
		flags = flags + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	end
	if entity:IsTauntedBy() then return entity:IsTauntedBy() end
	
	local enemies = FindUnitsInRadius( entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HEROES_AND_CREEPS, flags, FIND_CLOSEST, false )
	for _, enemy in ipairs( enemies ) do
		if not enemy:IsInvisible() then
			return enemy
		end
	end
end

function AICore:FurthestEnemyHeroInRange( entity, range, magic_immune )
	local flags = DOTA_UNIT_TARGET_FLAG_NO_INVIS 
	if magic_immune then
		flags = flags + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	end
	if entity:IsTauntedBy() then return entity:IsTauntedBy() end
	
	local enemies = FindUnitsInRadius( entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, flags, FIND_FARTHEST, false )
	if #enemies > 0 then return enemies[1] end
	enemies = FindUnitsInRadius( entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, range/2, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, flags, FIND_FARTHEST, false )
	if #enemies > 0 then return enemies[1] end
	
	local target = enemies[1]
	if entity:IsTauntedBy() then 
		target = entity:IsTauntedBy()
	end
	return target
end

function AICore:BeingAttacked( entity )
	local enemies = FindUnitsInRadius( entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, 9999, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false )
	local count = 0
	
	for _,enemy in pairs(enemies) do
		if enemy:IsAlive() and enemy:IsAttackingEntity(entity) then
			count = (count or 0) + 1
		end
	end
	return count
end

function AICore:BeingAttackedBy( entity )
	local enemies = FindUnitsInRadius( entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, 9999, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false )
	local attackers = {}
	
	for _,enemy in pairs(enemies) do
		if enemy:IsAlive() and enemy:IsAttackingEntity(entity) then
			table.insert(attackers, enemy)
		end
	end
	return attackers
end

function AICore:GetHighestPriorityTarget(entity)
	local target = entity.AIprevioustarget
	if not entity.AIprevioustarget then
		target = AICore:NearestEnemyHeroInRange( entity, 15000 , true )
	end
	if entity:IsTauntedBy() then 
		target = entity:IsTauntedBy()
	end
	return target
end

function AICore:AttackHighestPriority( entity )
	if not entity and not entity:IsAlive() then return end
	local flag = DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NO_INVIS 
	local range = entity:GetBaseAttackRange() + entity:GetIdealSpeed() * 1.5
	if range < 900 then range = 900 end
	if not entity:IsDominated() then
		local enemies = FindUnitsInRadius( entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, flag, 0, false )
		local target = nil
		local minThreat = 0
		if not entity.AIPreviousTargetTimerTicker then entity.AIPreviousTargetTimerTicker = 0 end
		if entity.AIprevioustarget and not entity.AIprevioustarget:IsNull() and not entity:CanEntityBeSeenByMyTeam( entity.AIprevioustarget ) then
			if not entity.AIPreviousTargetTimer then
				entity.AIPreviousTargetTimerTicker = 0 
				entity.AIPreviousTargetTimerEntity = entity.AIprevioustarget:entindex()
				entity.AIPreviousTargetTimer = Timers:CreateTimer(0.1, function()
					if entity.AIPreviousTargetTimerEntity == entity.AIprevioustarget:entindex() then
						entity.AIPreviousTargetTimerTicker = entity.AIPreviousTargetTimerTicker + 0.1
					end
				end)
			elseif entity.AIPreviousTargetTimerEntity ~= entity.AIprevioustarget:entindex() then
				Timers:RemoveTimer( entity.AIPreviousTargetTimer )
				entity.AIPreviousTargetTimerTicker = 0 
				entity.AIPreviousTargetTimerEntity = entity.AIprevioustarget:entindex()
				entity.AIPreviousTargetTimer = Timers:CreateTimer(0.1, function()
					if entity.AIPreviousTargetTimerEntity == entity.AIprevioustarget:entindex() then
						entity.AIPreviousTargetTimerTicker = entity.AIPreviousTargetTimerTicker + 0.1
					end
				end)
			end
		elseif entity.AIPreviousTargetTimer then
			Timers:RemoveTimer( entity.AIPreviousTargetTimer )
			entity.AIPreviousTargetTimerTicker = 0 
			entity.AIPreviousTargetTimerEntity = nil
		end
		if entity.AIprevioustarget and not entity.AIprevioustarget:IsNull() and entity.AIprevioustarget:IsAlive() and not entity.AIprevioustarget:IsInvisible() and not entity.AIprevioustarget:IsNull() and entity.AIPreviousTargetTimerTicker < 1.5 then 
			target = entity.AIprevioustarget
			target.threat = target.threat or 0
			minThreat = target.threat
		end
		for _,enemy in pairs(enemies) do
			if entity:IsTauntedBy() then 
				target = entity:IsTauntedBy()
				break
			end
			local distanceToEnemy = (entity:GetAbsOrigin() - enemy:GetAbsOrigin()):Length2D()
			if not enemy.threat then enemy.threat = 0 end
			if not minThreat then minThreat = 0 end
			if enemy:IsAlive() and (enemy.threat or 0) > minThreat and distanceToEnemy < range and not entity.AIprevioustarget then
				minThreat = enemy.threat
				target = enemy
				entity.AIprevioustarget = target
			elseif entity.AIprevioustarget and enemy:IsAlive() and enemy.threat > minThreat + 5*(entity.AIbehavior or 1) and distanceToEnemy < range then
				minThreat = enemy.threat
				target = enemy
				entity.AIprevioustarget = target
			end
		end
		if not target then 
			local minHP = nil
			local target = nil
			enemies = FindUnitsInRadius( entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, range*2, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, flag, 0, false )
			for _,enemy in pairs(enemies) do
				local distanceToEnemy = (entity:GetAbsOrigin() - enemy:GetAbsOrigin()):Length2D()
				local HP = enemy:GetHealth()
				if enemy:IsAlive() and (minHP == nil or HP < minHP) and distanceToEnemy < range then
					minHP = HP
					target = enemy
					entity.AIprevioustarget = target
				end
			end
		end
		if not target then 
			local minRange = 9999
			local target = nil
			enemies = FindUnitsInRadius( entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, minRange, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, flag, 0, false )
			for _,enemy in pairs(enemies) do
				local distanceToEnemy = (entity:GetAbsOrigin() - enemy:GetAbsOrigin()):Length2D()
				if enemy:IsAlive() and distanceToEnemy < minRange then
					minRange = distanceToEnemy
					target = enemy
					entity.AIprevioustarget = target
				end
			end
		end
		if entity:IsTauntedBy() then 
			target = entity:IsTauntedBy()
		end
		if target and not target:IsNull() then
			ExecuteOrderFromTable({
				UnitIndex = entity:entindex(),
				OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
				TargetIndex = target:entindex()
			})
			return 0.5
		else
			AICore:RunToRandomPosition( entity, 5 )
			return 0.1
		end
	end
end


function AICore:IsNearEnemyUnit(entity, radius)
	local iFlag = DOTA_UNIT_TARGET_FLAG_NO_INVIS  + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	local units = FindUnitsInRadius(entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, iFlag, 0, false)
	return (#units > 0)
end

function AICore:BeAHugeCoward( entity, runbuffer )
	local nearest = AICore:NearestEnemyHeroInRange( entity, 99999, true )
	if nearest and not entity:IsTauntedBy() then 
		local direction = (nearest:GetAbsOrigin()-entity:GetAbsOrigin()):Normalized()
		local distance = (nearest:GetAbsOrigin()-entity:GetAbsOrigin()):Length2D()
		if distance < runbuffer then
			ExecuteOrderFromTable({
				UnitIndex = entity:entindex(),
				OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
				Position = (-direction)*RandomInt(100,300)
			})
		end
	elseif entity:IsTauntedBy() then
		ExecuteOrderFromTable({
			UnitIndex = entity:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
			TargetIndex = entity:IsTauntedBy():entindex()
		})
	end
end

function AICore:RunToRandomPosition( entity, spasticness )
	local position = entity:GetAbsOrigin() + Vector( RandomInt(-1000, 1000), RandomInt(-1000, 1000), 0)
	if RollPercentage(spasticness) and not entity:IsTauntedBy() then
		ExecuteOrderFromTable({
			UnitIndex = entity:entindex(),
			OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
			Position = position
		})
	elseif entity:IsTauntedBy() then
		ExecuteOrderFromTable({
			UnitIndex = entity:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
			TargetIndex = entity:IsTauntedBy():entindex()
		})
	end
end

function AICore:RunToTarget( entity, target )
	if not entity or not target and not entity:IsTauntedBy() then 
		return 0.5 
	elseif entity:IsTauntedBy() then
		ExecuteOrderFromTable({
			UnitIndex = entity:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
			TargetIndex = entity:IsTauntedBy():entindex()
		})
		return 0.5
	end
	local position = target:GetAbsOrigin()
	ExecuteOrderFromTable({
		UnitIndex = entity:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = position
	})
end

function AICore:FarthestEnemyHeroInRange( entity, range , magic_immune)
	local flags = DOTA_UNIT_TARGET_FLAG_NO_INVIS 
	if magic_immune then
		flags = flags + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	end
	if entity:IsTauntedBy() then return entity:IsTauntedBy() end
	local enemies = FindUnitsInRadius( entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, flags, 0, false )
	
	local minRange = nil
	local target = nil
	
	for _,enemy in pairs(enemies) do
		local distanceToEnemy = (entity:GetAbsOrigin() - enemy:GetAbsOrigin()):Length2D()
		if enemy:IsAlive() and (minRange == nil or distanceToEnemy > minRange) and distanceToEnemy < range then
			minRange = distanceToEnemy
			target = enemy
		end
	end
	if entity:IsTauntedBy() then 
		target = entity:IsTauntedBy()
	end
	return target
end

function AICore:NearestDisabledEnemyHeroInRange( entity, range , magic_immune)
	local flags = DOTA_UNIT_TARGET_FLAG_NO_INVIS 
	if magic_immune then
		flags = flags + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	end
	if entity:IsTauntedBy() then return entity:IsTauntedBy() end
	local enemies = FindUnitsInRadius( entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, flags, 0, false )
	
	local minRange = range
	local target = nil
	for _,enemy in pairs(enemies) do
		local distanceToEnemy = (entity:GetAbsOrigin() - enemy:GetAbsOrigin()):Length2D()
		if enemy:IsAlive() and distanceToEnemy < minRange and enemy:IsDisabled() then
			minRange = distanceToEnemy
			target = enemy
		end
	end
	if entity:IsTauntedBy() then 
		target = entity:IsTauntedBy()
	end
	return target
end

function AICore:TotalEnemyHeroesInRange( entity, range)
	local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NO_INVIS 
	local enemies = FindUnitsInRadius( entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, flags, 0, false )
	
	return #enemies
end

function AICore:OptimalHitPosition(entity, range, radius, magic_immune)
	local flags = DOTA_UNIT_TARGET_FLAG_NO_INVIS 
	if magic_immune then
		flags = flags + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	end
	local enemies = FindUnitsInRadius( entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, range + radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, flags, 0, false )
	
	local initTarget = entity:IsTauntedBy() or AICore:HighestThreatHeroInRange(entity, range + radius, 0, (magic_immune or false) )
	
	
	local meanPos
	if initTarget then meanPos = initTarget:GetAbsOrigin() end
	for _,enemy in pairs(enemies) do
		local distanceToEnemy = CalculateDistance(enemy, entity)
		if not meanPos then withinRadius = 0
		else withinRadius = CalculateDistance(meanPos, enemy) end
		if enemy:IsAlive() and distanceToEnemy < range + radius and withinRadius < 2 * radius and not (enemy == initTarget) then
			if not meanPos then meanPos = enemy:GetAbsOrigin()
			elseif CalculateDistance(meanPos, entity) > range then meanPos = entity:GetAbsOrigin() + CalculateDirection(meanPos, entity) * range
			meanPos = (meanPos + enemy:GetAbsOrigin())/2 end
		end
	end
	if entity:IsTauntedBy() then meanPos = entity:IsTauntedBy():GetAbsOrigin() end
	return meanPos
end

function AICore:FindFarthestEnemyInLine(entity, range, width, magic_immune)
	local flags = DOTA_UNIT_TARGET_FLAG_NO_INVIS 
	if magic_immune then
		flags = flags + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	end
	local enemies = FindUnitsInLine(entity:GetTeamNumber(), entity:GetAbsOrigin(),  entity:GetAbsOrigin() + entity:GetForwardVector()*range, nil, width, DOTA_UNIT_TARGET_TEAM_ENEMY,DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, flags)
	local distance = 0
	local target
	for _, enemy in ipairs(enemies) do
		if CalculateDistance(enemy, entity) > distance then
			distance = CalculateDistance(enemy, entity)
			target = enemy 
		end
	end
	if entity:IsTauntedBy() then 
		target = entity:IsTauntedBy()
	end
	return target
end

function AICore:FindNearestEnemyInLine(entity, range, width, magic_immune)
	local flags = DOTA_UNIT_TARGET_FLAG_NO_INVIS 
	if magic_immune then
		flags = flags + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	end
	local enemies = FindUnitsInLine(entity:GetTeamNumber(), entity:GetAbsOrigin(),  entity:GetAbsOrigin() + entity:GetForwardVector()*range, nil, width, DOTA_UNIT_TARGET_TEAM_ENEMY,DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, flags)
	local distance = 0
	local target
	for _, enemy in ipairs(enemies) do
		if CalculateDistance(enemy, entity) < distance then
			distance = CalculateDistance(enemy, entity)
			target = enemy 
		end
	end
	if entity:IsTauntedBy() then 
		target = entity:IsTauntedBy()
	end
	return target
end

function AICore:TotalNotDisabledEnemyHeroesInRange( entity, range , magic_immune)
	local flags = DOTA_UNIT_TARGET_FLAG_NO_INVIS 
	if magic_immune then
		flags = flags + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	end
	
	local enemies = FindUnitsInRadius( entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, flags, 0, false )
	
	local count = 0
	
	for _,enemy in pairs(enemies) do
		local distanceToEnemy = (entity:GetAbsOrigin() - enemy:GetAbsOrigin()):Length2D()
		if enemy:IsAlive() and distanceToEnemy < range and not enemy:IsDisabled() then
			count = count + 1
		end
	end
	return count
end

function AICore:TotalUnitsInRange( entity, range )
	
	local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	local enemies = FindUnitsInRadius( entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, range, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, flags, 0, false )
	
	local count = 0
	
	for _,enemy in pairs(enemies) do
		local distanceToEnemy = (entity:GetAbsOrigin() - enemy:GetAbsOrigin()):Length2D()
		if enemy:IsAlive() and distanceToEnemy < range then
			count = count + 1
		end
	end
	return count
end

function AICore:TotalAlliedUnitsInRange( entity, range	)
	local enemies = FindUnitsInRadius( entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, range, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, 0, false )
	
	local count = 0
	
	for _,enemy in pairs(enemies) do
		local distanceToEnemy = (entity:GetAbsOrigin() - enemy:GetAbsOrigin()):Length2D()
		if enemy:IsAlive() and distanceToEnemy < range then
			count = count + 1
		end
	end
	return count
end

function AICore:AlliedUnitsAlive( entity )
	local allies = FindUnitsInRadius( entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, 99999, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, 0, false )
	
	local count = 0
	
	for _,ally in pairs(allies) do
		if ally:IsAlive() and ally ~= entity then
			count = count + 1
		end
	end
	return count
end

function AICore:WeakestAlliedUnitInRange( entity, range , magic_immune)
	local flags = DOTA_UNIT_TARGET_FLAG_NO_INVIS 
	if magic_immune then
		flags = flags + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	end
	local allies = FindUnitsInRadius( entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, range, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, flags, 0, false )

	local minHP = nil
	local target = nil

	for _,ally in pairs(allies) do
		local distanceToEnemy = (entity:GetAbsOrigin() - ally:GetAbsOrigin()):Length2D()
		local HP = ally:GetHealth()
		if ally:IsAlive() and (minHP == nil or HP < minHP) and distanceToEnemy < range then
			minHP = HP
			target = ally
		end
	end
	return target
end

function AICore:SpecificAlliedUnitsInRange( entity, name, range )
	local enemies = FindUnitsInRadius( entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, range, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, 0, false )
	
	for _,enemy in pairs(enemies) do
		if enemy:IsAlive() and enemy ~= entity and (enemy:GetUnitName() == name or enemy:GetName() == name or enemy:GetUnitLabel() == name) then
			return true
		end
	end
	return false
end

function AICore:SpecificAlliedUnitsAlive( entity, name )
	local enemies = FindUnitsInRadius( entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, 99999, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, 0, false )
	
	local count = 0
	
	for _,enemy in pairs(enemies) do
		if enemy:IsAlive() and enemy ~= entity and (enemy:GetUnitName() == name or enemy:GetName() == name or enemy:GetUnitLabel() == name) then
			count = count + 1
		end
	end
	return count
end

function AICore:EnemiesInLine(entity, range, width, magic_immune)
	local flags = DOTA_UNIT_TARGET_FLAG_NO_INVIS 
	if magic_immune then
		flags = flags + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	end
	local enemies = FindUnitsInLine(entity:GetTeamNumber(), entity:GetAbsOrigin(),  entity:GetAbsOrigin() + entity:GetForwardVector()*range, nil, width, DOTA_UNIT_TARGET_TEAM_ENEMY,DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, flags)
	if #enemies > 0 then
		if entity:IsTauntedBy() then
			return HasValInTable(enemies, entity:IsTauntedBy())
		end
		return true
	else
		return false
	end
end

function AICore:NumEnemiesInLine(entity, range, width, magic_immune)
	local flags = DOTA_UNIT_TARGET_FLAG_NO_INVIS 
	if magic_immune then
		flags = flags + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	end
	local enemies = FindUnitsInLine(entity:GetTeamNumber(), entity:GetAbsOrigin(),  entity:GetAbsOrigin() + entity:GetForwardVector()*range, nil, width, DOTA_UNIT_TARGET_TEAM_ENEMY,DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, flags)
	return #enemies
end

function AICore:WeakestEnemyHeroInRange( entity, range , magic_immune)
	local flags = DOTA_UNIT_TARGET_FLAG_NO_INVIS 
	if magic_immune then
		flags = flags + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	end
	if entity:IsTauntedBy() then return entity:IsTauntedBy() end
	local enemies = FindUnitsInRadius( entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, flags, 0, false )

	local minHP = nil
	local target = nil

	for _,enemy in pairs(enemies) do
		local distanceToEnemy = (entity:GetAbsOrigin() - enemy:GetAbsOrigin()):Length2D()
		local HP = enemy:GetHealth()
		if enemy:IsAlive() and (minHP == nil or HP < minHP) and distanceToEnemy < range then
			minHP = HP
			target = enemy
		end
	end
	if entity:IsTauntedBy() then 
		target = entity:IsTauntedBy()
	end
	return target
end

function AICore:StrongestEnemyHeroInRange( entity, range , magic_immune)
	local flags = DOTA_UNIT_TARGET_FLAG_NO_INVIS 
	if magic_immune then
		flags = flags + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	end
	if entity:IsTauntedBy() then return entity:IsTauntedBy() end
	local enemies = FindUnitsInRadius( entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, flags, 0, false )

	local minHP = nil
	local target = nil

	for _,enemy in pairs(enemies) do
		local distanceToEnemy = (entity:GetAbsOrigin() - enemy:GetAbsOrigin()):Length2D()
		local HP = enemy:GetHealth()
		if enemy:IsAlive() and (minHP == nil or HP > minHP) and distanceToEnemy < range then
			minHP = HP
			target = enemy
		end
	end
	if entity:IsTauntedBy() then 
		target = entity:IsTauntedBy()
	end
	return target
end

function AICore:HighestThreatHeroInRange(entity, range, basethreat, magic_immune)
	local flags = DOTA_UNIT_TARGET_FLAG_NO_INVIS 
	if magic_immune then
		flags = flags + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	end
	if entity:IsTauntedBy() then return entity:IsTauntedBy() end
    local enemies = FindUnitsInRadius( entity:GetTeamNumber(), entity:GetAbsOrigin(), nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, flags, 0, false )

	local target = nil
	local minThreat = basethreat
	for _,enemy in pairs(enemies) do
		local distanceToEnemy = (entity:GetAbsOrigin() - enemy:GetAbsOrigin()):Length2D()
		if not enemy.threat then enemy.threat = 0 end
		local threat = enemy.threat
		if enemy:IsAlive() and (minThreat == nil or threat > minThreat) and distanceToEnemy < range then
			minThreat = threat
			target = enemy
		end
	end
	if entity:IsTauntedBy() then 
		target = entity:IsTauntedBy()
	end
	return target
end

function AICore:FindOptimalRadiusInRangeForEntity(entity, range, radius, exclusionFct, bIncludeTeamMates)
	local totalRange = TernaryOperator( -1, range == -1, range + radius )
	local allEnemies = entity:FindEnemyUnitsInRadius( entity:GetAbsOrigin(), totalRange, {type = DOTA_UNIT_TARGET_HERO, flag = DOTA_UNIT_TARGET_FLAG_NO_INVIS  } )
	if bIncludeTeamMates then
		allEnemies = entity:FindAllUnitsInRadius( entity:GetAbsOrigin(), totalRange, {type = DOTA_UNIT_TARGET_HERO, flag = DOTA_UNIT_TARGET_FLAG_NO_INVIS  } )
	end
	local castPosition
	local maxTargets = 0
	if entity:IsTauntedBy() then
		allEnemies = {[1] = entity:IsTauntedBy()}
	end
	for _, enemy in ipairs( allEnemies ) do -- attempt to at least get a hero target, also serves to optimize
		if not exclusionFct or not exclusionFct( enemy ) then -- isn't already affected by a pool
			local potentialTargets = entity:FindEnemyUnitsInRadius( enemy:GetAbsOrigin(), radius * 2 )
			local centers = {}
			for _, target in ipairs( potentialTargets ) do -- find all possible circle centers
				table.insert( centers, (enemy:GetAbsOrigin() + target:GetAbsOrigin()) / 2 )
			end
			for _, center in ipairs( centers ) do -- find optimal center
				local centerTargets = entity:FindEnemyUnitsInRadius( center, radius )
				local actualTargets = 0
				for _, target in ipairs( centerTargets ) do
					if not exclusionFct or not exclusionFct( target ) then
						actualTargets = actualTargets + 1
					end
				end
				if actualTargets > maxTargets then
					castPosition = center
					maxTargets = actualTargets
				end
			end
		end
	end
	
	return castPosition
end

function AICore:FindOptimalRadiusInRangeForEntityClamped( entity, range, maxRange, radius, exclusionFct )
	local allEnemies = entity:FindEnemyUnitsInRing( entity:GetAbsOrigin(), maxRange, range, {type = DOTA_UNIT_TARGET_HERO, flag = DOTA_UNIT_TARGET_FLAG_NO_INVIS  } )
	local castPosition
	local maxTargets = 0
	if entity:IsTauntedBy() then
		allEnemies = {[1] = entity:IsTauntedBy()}
	end
	for _, enemy in ipairs( allEnemies ) do -- attempt to at least get a hero target, also serves to optimize
		if not exclusionFct or not exclusionFct( enemy ) then -- isn't already affected by a pool
			local potentialTargets = entity:FindEnemyUnitsInRadius( enemy:GetAbsOrigin(), radius )
			local centers = {}
			for _, target in ipairs( potentialTargets ) do -- find all possible circle centers
				table.insert( centers, (enemy:GetAbsOrigin() + target:GetAbsOrigin()) / 2 )
			end
			for _, center in ipairs( centers ) do -- find optimal center
				local centerTargets = entity:FindEnemyUnitsInRadius( center, radius )
				local actualTargets = 0
				for _, target in ipairs( centerTargets ) do
					if not exclusionFct or not exclusionFct( target ) then
						actualTargets = actualTargets + 1
					end
				end
				if actualTargets > maxTargets then
					castPosition = center
					maxTargets = actualTargets
				end
			end
		end
	end
	
	return castPosition
end

function AICore:FindOptimalLineInRangeForEntity(entity, range, width, distance, exclusionFct, bIncludeTeamMates)
	local allEnemies = entity:FindEnemyUnitsInRadius( entity:GetAbsOrigin(), range, {type = DOTA_UNIT_TARGET_HERO, flag = DOTA_UNIT_TARGET_FLAG_NO_INVIS  } )
	if bIncludeTeamMates then
		allEnemies = entity:FindAllUnitsInRadius( entity:GetAbsOrigin(), range, {type = DOTA_UNIT_TARGET_HERO, flag = DOTA_UNIT_TARGET_FLAG_NO_INVIS  } )
	end
	if entity:IsTauntedBy() then
		allEnemies = {[1] = entity:IsTauntedBy()}
	end
	local castPosition
	local currentTargets = {}
	for _, enemy in ipairs( allEnemies ) do -- attempt to at least get a hero target, also serves to optimize
		if not exclusionFct or not exclusionFct( enemy ) then -- isn't already affected by a pool
			local potentialTargets = entity:FindEnemyUnitsInLine( entity:GetAbsOrigin(), entity:GetAbsOrigin() + CalculateDirection( enemy, entity ) * distance, width )
			if #potentialTargets > #currentTargets then
				currentTargets = potentialTargets
				castPosition = enemy:GetAbsOrigin()
			end
		end
	end
	
	return castPosition
end

function AICore:FindOptimalTargetInRangeForEntity(entity, range, radius, exclusionFct, bIncludeTeamMates, flMinimumValue)
	local allEnemies = entity:FindEnemyUnitsInRadius( entity:GetAbsOrigin(), range + radius, {type = DOTA_UNIT_TARGET_HERO, flag = DOTA_UNIT_TARGET_FLAG_NO_INVIS  } )
	if bIncludeTeamMates then
		allEnemies = entity:FindAllUnitsInRadius( entity:GetAbsOrigin(), range + radius, {type = DOTA_UNIT_TARGET_HERO, flag = DOTA_UNIT_TARGET_FLAG_NO_INVIS  } )
	end
	if entity:IsTauntedBy() then
		allEnemies = {[1] = entity:IsTauntedBy()}
	end
	local castTarget
	local maxTargets = flMinimumValue or 0
	for _, enemy in ipairs( allEnemies ) do -- attempt to at least get a hero target, also serves to optimize
		if not exclusionFct or not exclusionFct( enemy, castTarget ) then -- isn't already affected by a pool
			local potentialTargets = entity:FindEnemyUnitsInRadius( enemy:GetAbsOrigin(), radius )
			if #potentialTargets > maxTargets then
				castTarget = enemy
				maxTargets = #potentialTargets
			end
		end
	end
	
	return castTarget
end

function AICore:FindOptimalAllyInRangeForEntity(entity, range, radius, exclusionFct)
	local allEnemies = entity:FindFriendlyUnitsInRadius( entity:GetAbsOrigin(), range + radius, {type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, flag = DOTA_UNIT_TARGET_FLAG_NO_INVIS  } )
	
	local castTarget
	local maxTargets = 0
	
	for _, ally in ipairs( allEnemies ) do -- attempt to at least get a hero target, also serves to optimize
		if not exclusionFct or not exclusionFct( ally ) then -- isn't already affected by a pool
			local potentialTargets = entity:FindEnemyUnitsInRadius( ally:GetAbsOrigin(), radius )
			if #potentialTargets > maxTargets then
				castTarget = ally
				maxTargets = #potentialTargets
			end
		end
	end
	
	return castTarget
end

EBF_AI_ROAMING = 0
EBF_AI_ATTACKING = 1

function AICore:HandleBasicAI( entity )
	if not entity._currentBasicBehaviorState then
		entity._currentBasicBehaviorState = EBF_AI_ROAMING
	end
	entity._moveToLastPosition = entity._moveToLastPosition or entity:GetAbsOrigin()
	if entity._currentAttackTarget then
		if not entity._currentAttackTarget:IsAlive() then
			entity._currentAttackTarget = nil
			entity:Stop()
			return 0.01
		elseif not entity._currentAttackTarget:IsInvisible( ) then
			entity._currentAttackTargetLastPosition = entity._currentAttackTarget:GetAbsOrigin()
			if entity._currentAttackTarget:IsMoving() then -- factor in movement to prevent cliff traps
				entity._currentAttackTargetLastPosition = entity._currentAttackTargetLastPosition + entity._currentAttackTarget:GetForwardVector() * entity:GetIdealSpeed() * 1.5
			end
		else
			entity._currentAttackTarget = nil
			entity:Stop()
			return 0.01
		end
	end
	if not entity:IsAttacking() then -- not processing attack order, look for mfer to hit with hammers
		if entity._currentAttackTarget and CalculateDistance( entity._currentAttackTarget, entity ) <= entity:GetIdealSpeed() then
			entity:MoveToPositionAggressive( entity._currentAttackTarget:GetAbsOrigin() )
			return AI_THINK_RATE
		else
			local target = AICore:NearestEnemyHeroInRange( entity, -1, true)
			if target then
				entity._currentAttackTarget = target
				entity._currentAttackTargetLastPosition = target:GetAbsOrigin()
				entity._moveToLastPosition = entity._currentAttackTargetLastPosition
				entity:MoveToPositionAggressive( entity._currentAttackTargetLastPosition )
				return AI_THINK_RATE
			elseif entity:GetAttackTarget() then
				entity:Stop()
			end
		end
		if CalculateDistance( entity._moveToLastPosition, entity ) <= 50 or not entity:IsMoving() then -- not processing move order, go find mfer to hit with hammers
			if entity._currentAttackTargetLastPosition then
				entity._moveToLastPosition = entity._currentAttackTargetLastPosition
				entity._currentAttackTargetLastPosition = nil
			else
				entity._moveToLastPosition = Vector(0,0,0) + ActualRandomVector( CalculateDistance( entity, Vector(0,0,0) ) + entity:GetIdealSpeed() * 3 )
			end
			entity:MoveToPositionAggressive( entity._moveToLastPosition )
			return AI_THINK_RATE
		end
	elseif RollPercentage( 12 ) then
		local newPos = ( entity._currentAttackTarget or entity ):GetAbsOrigin() + RandomVector( math.min( entity:GetAttackRange() * RandomFloat( 0.75, 1.0 ), entity:GetIdealSpeed() * 0.5 )  )
		entity:MoveToPosition( newPos )
		return CalculateDistance(newPos, entity:GetAbsOrigin()) / entity:GetIdealSpeed()
	end
	return AI_THINK_RATE
end

function AICore:FindOptimalFriendlyRadiusInRangeForEntity(entity, range, radius, bSelfish, exclusionFct)
	local allEnemies = entity:FindFriendlyUnitsInRadius( entity:GetAbsOrigin(), range + radius, {type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, flag = DOTA_UNIT_TARGET_FLAG_NO_INVIS  } )
	local castPosition
	local maxTargets = 0
	if bSelfish then
		local potentialTargets = entity:FindEnemyUnitsInRadius( entity:GetAbsOrigin(), radius * 2 )
		local centers = {}
		for _, target in ipairs( potentialTargets ) do -- find all possible circle centers
			table.insert( centers, (entity:GetAbsOrigin() + target:GetAbsOrigin()) / 2 )
		end
		for _, center in ipairs( centers ) do -- find optimal center
			local centerTargets = entity:FindFriendlyUnitsInRadius( center, radius )
			local actualTargets = 0
			for _, target in ipairs( centerTargets ) do
				if not exclusionFct or not exclusionFct( target ) then
					actualTargets = actualTargets + 1
				end
			end
			if actualTargets > maxTargets then
				castPosition = center
				maxTargets = actualTargets
			end
		end
	else
		for _, enemy in ipairs( allEnemies ) do -- attempt to at least get a hero target, also serves to optimize
			if not exclusionFct or not exclusionFct( enemy ) then -- isn't already affected by a pool
				local potentialTargets = entity:FindEnemyUnitsInRadius( enemy:GetAbsOrigin(), radius * 2 )
				local centers = {}
				for _, target in ipairs( potentialTargets ) do -- find all possible circle centers
					table.insert( centers, (enemy:GetAbsOrigin() + target:GetAbsOrigin()) / 2 )
				end
				for _, center in ipairs( centers ) do -- find optimal center
					local centerTargets = entity:FindEnemyUnitsInRadius( center, radius )
					local actualTargets = 0
					for _, target in ipairs( centerTargets ) do
						if not exclusionFct or not exclusionFct( target ) then
							actualTargets = actualTargets + 1
						end
					end
					if actualTargets > maxTargets then
						castPosition = center
						maxTargets = actualTargets
					end
				end
			end
		end
	end
	return castPosition
end

function AICore:CreateBehaviorSystem( behaviors )
	local BehaviorSystem = {}

	BehaviorSystem.possibleBehaviors = behaviors
	BehaviorSystem.thinkDuration = 1.0
	BehaviorSystem.repeatedlyIssueOrders = true -- if you're paranoid about dropped orders, leave this true

	BehaviorSystem.currentBehavior =
	{
		endTime = 0,
		order = { OrderType = DOTA_UNIT_ORDER_NONE }
	}

	function BehaviorSystem:Think()
		if GameRules:GetGameTime() >= self.currentBehavior.endTime then
			local newBehavior = self:ChooseNextBehavior()
			if newBehavior == nil then 
				-- Do nothing here... this covers possible problems with ChooseNextBehavior
			elseif newBehavior == self.currentBehavior then
				self.currentBehavior:Continue()
			else
				if self.currentBehavior.End then self.currentBehavior:End() end
				self.currentBehavior = newBehavior
				self.currentBehavior:Begin()
			end
		end

		if self.currentBehavior.order and self.currentBehavior.order.OrderType ~= DOTA_UNIT_ORDER_NONE then
			if self.repeatedlyIssueOrders or
				self.previousOrderType ~= self.currentBehavior.order.OrderType or
				self.previousOrderTarget ~= self.currentBehavior.order.TargetIndex or
				self.previousOrderPosition ~= self.currentBehavior.order.Position then

				-- Keep sending the order repeatedly, in case we forgot >.<
				ExecuteOrderFromTable( self.currentBehavior.order )
				self.previousOrderType = self.currentBehavior.order.OrderType
				self.previousOrderTarget = self.currentBehavior.order.TargetIndex
				self.previousOrderPosition = self.currentBehavior.order.Position
			end
		end

		if self.currentBehavior.Think then self.currentBehavior:Think(self.thinkDuration) end

		return self.thinkDuration
	end

	function BehaviorSystem:ChooseNextBehavior()
		local result = nil
		local bestDesire = nil
		for _,behavior in pairs( self.possibleBehaviors ) do
			local thisDesire = behavior:Evaluate()
			if bestDesire == nil or thisDesire > bestDesire then
				result = behavior
				bestDesire = thisDesire
			end
		end

		return result
	end

	function BehaviorSystem:Deactivate()
		print("End")
		if self.currentBehavior.End then self.currentBehavior:End() end
	end

	return BehaviorSystem
end

---
---

function CDOTA_BaseNPC:GetAIBehavior()
	self.AIbehavior = self.AIbehavior or RandomInt(1,3)
	return self.AIbehavior
end