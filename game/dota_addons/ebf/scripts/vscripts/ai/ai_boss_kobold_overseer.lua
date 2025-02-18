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
	
	thisEntity.speed = thisEntity:FindAbilityByName("boss_kobold_speed_aura")
	thisEntity.swiftness = thisEntity:FindAbilityByName("boss_kobold_swiftness_aura")
	
	Timers:CreateTimer(0.1, function()
		thisEntity.speed:SetLevel(GameRules.gameDifficulty)
		thisEntity.swiftness:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if thisEntity:GetTeamNumber() == DOTA_TEAM_NEUTRALS and not thisEntity:IsChanneling() then-- no spells left to be cast and not currently attacking
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end