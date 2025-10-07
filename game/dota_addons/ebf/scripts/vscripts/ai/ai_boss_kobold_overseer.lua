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
	
	thisEntity.banner = thisEntity:FindAbilityByName("boss_kobold_heralds_banner")
	thisEntity.lash = thisEntity:FindItemInInventory("item_kobold_overseers_rippers_lash")
	
	Timers:CreateTimer(0.1, function()
		thisEntity.banner:SetLevel(GameRules.gameDifficulty)
		thisEntity.lash:SetLevel(GameRules.gameDifficulty)
	end)
end


function AIThink(thisEntity)
	if not thisEntity:IsAlive() then
		return
	end
	if thisEntity:GetTeamNumber() == DOTA_TEAM_NEUTRALS and not thisEntity:IsChanneling() then
		if thisEntity.banner:IsFullyCastable() and ( AICore:TotalEnemyHeroesInRange( thisEntity, 900 ) >= math.ceil(HeroList:GetActiveHeroCount() / 2) or thisEntity:IsAttacking() ) then
			ExecuteOrderFromTable({
				UnitIndex = thisEntity:entindex(),
                OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
                Position = thisEntity:GetAbsOrigin() + thisEntity:GetForwardVector() * 150,
				AbilityIndex = thisEntity.banner:entindex()
			})
			return AI_THINK_RATE
		end
		if thisEntity.lash:IsFullyCastable() then
			local position = AICore:FindOptimalRadiusInRangeForEntity(thisEntity, thisEntity.lash:GetTrueCastRange(), thisEntity.lash:GetSpecialValueFor("thorn_area"))
			if position then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = position,
					AbilityIndex = thisEntity.lash:entindex()
				})
				return AI_THINK_RATE
			end
		end
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end