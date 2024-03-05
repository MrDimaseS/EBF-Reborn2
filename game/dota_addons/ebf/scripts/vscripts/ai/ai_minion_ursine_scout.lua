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
	
	thisEntity.swipes = thisEntity:FindAbilityByName("boss_ursine_fury_swipes")
	Timers:CreateTimer(0.1, function()
		print( GameRules.gameDifficulty, thisEntity.swipes:GetLevel() )
		thisEntity.swipes:SetLevel(GameRules.gameDifficulty)
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