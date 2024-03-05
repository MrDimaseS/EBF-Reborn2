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
	
	thisEntity.fists = thisEntity:FindAbilityByName("boss_demonic_golem_flaming_fists")
	thisEntity.immolation = thisEntity:FindAbilityByName("boss_demonic_golem_permanent_immolation")
	thisEntity.explode = thisEntity:FindAbilityByName("minion_demonic_imp_explode")
	Timers:CreateTimer(0.1, function()
		thisEntity.fists:SetLevel(GameRules.gameDifficulty)
		thisEntity.immolation:SetLevel(GameRules.gameDifficulty)
		thisEntity.explode:SetLevel(2)
	end)
end


function AIThink(thisEntity)
	if not thisEntity:IsAlive() then
		return
	end
	if thisEntity:GetTeamNumber() == DOTA_TEAM_NEUTRALS and not thisEntity:IsChanneling() then
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end