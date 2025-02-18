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
	
	thisEntity.venom = thisEntity:FindAbilityByName("boss_gnoll_assassin_envenomed_weapon")
	thisEntity.coup = thisEntity:FindAbilityByName("boss_gnoll_assassin_coup_de_grace")
	Timers:CreateTimer(0.1, function()
		thisEntity.venom:SetLevel(GameRules.gameDifficulty)
		thisEntity.coup:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if not thisEntity:IsAlive() then
		return
	end
	if thisEntity:GetTeamNumber() == DOTA_TEAM_NEUTRALS and not thisEntity:IsChanneling() then-- no spells left to be cast and not currently attacking
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end