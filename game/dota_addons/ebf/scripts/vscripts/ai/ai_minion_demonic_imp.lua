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
	
	thisEntity.explode = thisEntity:FindAbilityByName("minion_demonic_imp_explode")
	Timers:CreateTimer(0.1, function()
		thisEntity.explode:SetLevel(1)
	end)
end


function AIThink(thisEntity)
	if not thisEntity:IsAlive() then
		return
	end
	if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() then
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end