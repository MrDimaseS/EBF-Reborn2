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
	
	thisEntity.basicAbilities = {}
	for i = 0, thisEntity:GetAbilityCount() - 1 do
        local ability = thisEntity:GetAbilityByIndex( i )
        if ability then
			thisEntity.basicAbilities[ability:GetName()] = ability
        end
    end
	Timers:CreateTimer(0.1, function()
		for abilityName, abilityEntity in pairs( thisEntity.basicAbilities ) do
			abilityEntity:SetLevel(GameRules.gameDifficulty)
		end
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