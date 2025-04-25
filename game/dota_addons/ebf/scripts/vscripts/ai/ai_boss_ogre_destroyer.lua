--[[ Ogre Destroyer AI ]]

function Spawn(entityKeyValues)
	if not IsServer() then
		return
	end
	
	Timers:CreateTimer(function()
		if thisEntity and not thisEntity:IsNull() and thisEntity:IsAlive() then
			return AIThink(thisEntity)
		end
	end)
	
	thisEntity.lust = thisEntity:FindAbilityByName("boss_ogre_tank_bloodlust")
	thisEntity.smash = thisEntity:FindAbilityByName("boss_ogre_destroyer_smash")
	
	Timers:CreateTimer(0.1, function()
		thisEntity.lust:SetLevel(GameRules.gameDifficulty)
		thisEntity.smash:SetLevel(GameRules.gameDifficulty)
	end)
end

function AIThink(thisEntity)
    if thisEntity:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS and not thisEntity:IsChanneling() and not thisEntity:GetCurrentActiveAbility() then
        if thisEntity.lust:IsFullyCastable() then
            if not thisEntity:HasModifier("modifier_ogre_magi_bloodlust") then
                ExecuteOrderFromTable({
                    UnitIndex = thisEntity:entindex(),
                    OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
                    AbilityIndex = thisEntity.lust:entindex(),
                    TargetIndex = thisEntity:entindex()
                })
                return 0.1
            else
                -- If self already has Bloodlust, find an ally to buff
                local allies = FindUnitsInRadius(
                    thisEntity:GetTeamNumber(),
                    thisEntity:GetAbsOrigin(),
                    nil,
                    thisEntity.lust:GetCastRange(),
                    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
                    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
                    DOTA_UNIT_TARGET_FLAG_NONE,
                    FIND_ANY_ORDER,
                    false
                )
                
                -- Find first ally without Bloodlust
                for _, ally in pairs(allies) do
                    if ally ~= thisEntity and not ally:HasModifier("modifier_ogre_magi_bloodlust") then
                        ExecuteOrderFromTable({
                            UnitIndex = thisEntity:entindex(),
                            OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
                            AbilityIndex = thisEntity.lust:entindex(),
                            TargetIndex = ally:entindex()
                        })
                        return 0.1
                    end
                end
            end
        end
		if thisEntity.smash:IsFullyCastable() then
			local target = AICore:NearestEnemyHeroInRange(thisEntity, 450, true)
			if target then
				ExecuteOrderFromTable({
					UnitIndex = thisEntity:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
					Position = target:GetAbsOrigin(),
					AbilityIndex = thisEntity.smash:entindex()
				})
				return 0.1
			end
		end
		-- No spells left to be cast and not currently attacking
		return AICore:HandleBasicAI( thisEntity )
	else 
		return AI_THINK_RATE 
	end
end