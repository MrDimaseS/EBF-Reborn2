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
	
	thisEntity.gush = thisEntity:FindAbilityByName("boss_tidehunter_gush")
	thisEntity.shell = thisEntity:FindAbilityByName("boss_tidehunter_kraken_shell")
	thisEntity.smash = thisEntity:FindAbilityByName("boss_tidehunter_anchor_smash")
	thisEntity.ravage = thisEntity:FindAbilityByName("boss_tidehunter_ravage")
	
	Timers:CreateTimer(0.1, function()
		thisEntity.gush:SetLevel(GameRules.gameDifficulty)
		thisEntity.shell:SetLevel(GameRules.gameDifficulty)
		thisEntity.smash:SetLevel(GameRules.gameDifficulty)
		thisEntity.ravage:SetLevel(GameRules.gameDifficulty)
	end)
end

function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.isMovingToCastPosition then
			thisEntity.castPositionBufferRadius = (thisEntity.castPositionBufferRadius or thisEntity:GetPaddedCollisionRadius()) + 8
			if CalculateDistance(thisEntity, thisEntity.isMovingToCastPosition ) < thisEntity.castPositionBufferRadius then -- good enough
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
					AbilityIndex = thisEntity.smash:entindex()
				})
				thisEntity.isMovingToCastPosition = nil
				thisEntity.castPositionBufferRadius = nil
			else
				thisEntity:MoveToPosition( thisEntity.isMovingToCastPosition )
			end
			return 0.1
		elseif thisEntity.smash:IsFullyCastable() then
			local range = thisEntity:GetIdealSpeed()
			local orderPerformed = false
			local optimalPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, range, thisEntity.smash:GetSpecialValueFor("radius") )
			if optimalPosition then
				local randomizedPos = optimalPosition + RandomVector( 32 )
				ExecuteOrderFromTable({
							UnitIndex = thisEntity:entindex(),
							OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
							Position = randomizedPos,
						})
				thisEntity.isMovingToCastPosition = randomizedPos
				return CalculateDistance( randomizedPos, thisEntity ) / thisEntity:GetIdealSpeed()
			end
		end
		if thisEntity.ravage:IsFullyCastable() and #thisEntity:FindEnemyUnitsInRadius( thisEntity:GetAbsOrigin(), thisEntity.ravage:GetSpecialValueFor("radius") * 0.75, {flag = DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE } ) >= math.max( 1, math.floor( HeroList:GetActiveHeroCount() / 2 ) ) then
			ExecuteOrderFromTable({
						UnitIndex = thisEntity:entindex(),
						OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
						AbilityIndex = thisEntity.ravage:entindex()
					})
			return 0.1
		end
		if thisEntity.gush:IsFullyCastable() then
			local castPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.gush:GetTrueCastRange(), thisEntity.gush:GetSpecialValueFor("aoe_scepter") )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.gush:entindex()
				})
				return 0.1
			end
		end
		-- no spells left to be cast and not currently attacking
		if not thisEntity:IsAttacking() then
			local target = AICore:NearestEnemyHeroInRange( thisEntity, -1, true)
			if target then
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