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
		else
			-- CleanUpCogs( thisEntity )
		end
	end)
	
	thisEntity.fire = thisEntity:FindAbilityByName("creature_fire_breath")
	thisEntity.slam = thisEntity:FindAbilityByName("roshan_slam")
	thisEntity.bash = thisEntity:FindAbilityByName("roshan_bash")
	thisEntity.block = thisEntity:FindAbilityByName("roshan_spell_block")
	Timers:CreateTimer(0.1, function()
		thisEntity.fire:SetLevel(GameRules.gameDifficulty)
		thisEntity.slam:SetLevel(GameRules.gameDifficulty)
		thisEntity.bash:SetLevel(GameRules.gameDifficulty)
		thisEntity.block:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.fire:IsFullyCastable() then
			local optimalPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.fire:GetTrueCastRange() / 2, thisEntity.fire:GetTrueCastRange() / 2 )
			if optimalPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = optimalPosition,
					AbilityIndex = thisEntity.fire:entindex()
				})
				return 0.1
			end
		end
		if thisEntity.slam:IsFullyCastable() then
			local enemies = thisEntity:FindEnemyUnitsInRadius( thisEntity:GetAbsOrigin(), thisEntity.slam:GetSpecialValueFor("radius") )
			if #enemies > 0 then
				ExecuteOrderFromTable({
							UnitIndex = thisEntity:entindex(),
							OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
							AbilityIndex = thisEntity.slam:entindex()
						})
				return 0.1
			end
		end
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
		return AI_THINK_RATE
	else 
		return AI_THINK_RATE 
	end
end

function CleanUpCogs(thisEntity)
	for _,cog in pairs( FindUnitsInRadius( thisEntity:GetTeam(), thisEntity:GetOrigin(), nil, 99999, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, 0, false ) ) do
		if cog:GetUnitName() == "npc_dota_rattletrap_cog" or cog:GetName() == "npc_dota_rattletrap_cog" or cog:GetUnitLabel() == "npc_dota_rattletrap_cog" then
			if cog:GetOwnerEntity() == thisEntity then
				cog:ForceKill( false )
			end
		end
	end
end