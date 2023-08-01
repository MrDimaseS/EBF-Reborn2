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
	
	thisEntity.fireball = thisEntity:FindAbilityByName("boss_ancient_dragon_fireball")
	thisEntity.splash = thisEntity:FindAbilityByName("boss_ancient_dragon_splash_attack")
	thisEntity.aura = thisEntity:FindAbilityByName("boss_ancient_dragon_dragonhide_aura")
	Timers:CreateTimer(0.1, function()
		thisEntity.fireball:SetLevel(GameRules.gameDifficulty)
		thisEntity.splash:SetLevel(GameRules.gameDifficulty)
		thisEntity.aura:SetLevel(GameRules.gameDifficulty)
	end)
end

function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
		if thisEntity.fireball:IsFullyCastable() then
			local castPosition = AICore:FindOptimalRadiusInRangeForEntity( thisEntity, thisEntity.fireball:GetTrueCastRange(), thisEntity.fireball:GetSpecialValueFor("radius") )
			if castPosition then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = castPosition,
					AbilityIndex = thisEntity.fireball:entindex()
				})
				return 0.1
			end
		end
		-- no spells left to be cast and not currently attacking
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end