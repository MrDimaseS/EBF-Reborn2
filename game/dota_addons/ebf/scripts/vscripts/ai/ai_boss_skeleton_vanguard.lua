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
	
	thisEntity.crit = thisEntity:FindAbilityByName("boss_skeleton_mortal_strike")
	thisEntity.aura = thisEntity:FindAbilityByName("boss_skeleton_vanguard_war_drums")
	Timers:CreateTimer(0.1, function()
		thisEntity.crit:SetLevel(GameRules.gameDifficulty)
		thisEntity.aura:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if not thisEntity:IsAlive() then
		return
	end
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() then-- no spells left to be cast and not currently attacking
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end