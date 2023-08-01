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
	
	thisEntity:Hold()
	
	thisEntity.sprint = thisEntity:FindAbilityByName("boss_slardar_sprint")
	thisEntity.crush = thisEntity:FindAbilityByName("boss_slardar_slithereen_crush")
	thisEntity.bash = thisEntity:FindAbilityByName("boss_slardar_bash")
	thisEntity.amplify = thisEntity:FindAbilityByName("boss_slardar_amplify_damage")
	Timers:CreateTimer(0.1, function()
		thisEntity.sprint:SetLevel(GameRules.gameDifficulty)
		thisEntity.crush:SetLevel(GameRules.gameDifficulty)
		thisEntity.bash:SetLevel(3+GameRules.gameDifficulty)
		thisEntity.amplify:SetLevel(GameRules.gameDifficulty)
	end)
end

function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.isMovingToCrushPosition then
			thisEntity.crushPositionBufferRadius = (thisEntity.crushPositionBufferRadius or thisEntity:GetPaddedCollisionRadius()) + 8
			if CalculateDistance(thisEntity, thisEntity.isMovingToCrushPosition ) < thisEntity.crushPositionBufferRadius then -- good enough
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
					AbilityIndex = thisEntity.crush:entindex()
				})
				thisEntity.isMovingToCrushPosition = nil
				thisEntity.crushPositionBufferRadius = nil
				return 0.1
			else
				thisEntity:MoveToPosition( thisEntity.isMovingToCrushPosition )
			end
			return 0.1
		else
			if thisEntity.sprint:IsFullyCastable() and not thisEntity:GetAttackTarget() or (thisEntity:GetAttackTarget() and CalculateDistance( thisEntity:GetAttackTarget(), thisEntity ) >= thisEntity:GetAttackRange() * 3) then
				ExecuteOrderFromTable({
							UnitIndex = thisEntity:entindex(),
							OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
							AbilityIndex = thisEntity.sprint:entindex(),
						})
				return 0.1
			end
			if thisEntity.amplify:IsFullyCastable() then
				for _, target in ipairs( thisEntity:FindEnemyUnitsInRadius( thisEntity:GetAbsOrigin(), thisEntity.amplify:GetTrueCastRange() ) ) do
					if not target:HasModifier("modifier_slardar_amplify_damage") then
						ExecuteOrderFromTable({
							UnitIndex = thisEntity:entindex(),
							OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
							AbilityIndex = thisEntity.amplify:entindex(),
							TargetIndex = target:entindex(),
						})
						return 0.1
					end
				end
			end
			if thisEntity.crush:IsFullyCastable() then
				local range = thisEntity:GetIdealSpeed()
				local orderPerformed = false
				if thisEntity:HasModifier("modifier_slardar_sprint") then
					range = range * (1 + thisEntity.sprint:GetSpecialValueFor("bonus_speed") / 100)
				end
				local optimalPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, range, thisEntity.crush:GetSpecialValueFor("crush_radius") )
				if optimalPosition then
					ExecuteOrderFromTable({
						UnitIndex = thisEntity:entindex(),
						OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
						Position = optimalPosition,
					})
					thisEntity.isMovingToCrushPosition = optimalPosition
					return 0.1
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
		end
		return AI_THINK_RATE
	else 
		return AI_THINK_RATE 
	end
end