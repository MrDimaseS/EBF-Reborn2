

if bossManager == nil then
	bossManager = class({})
end


function bossManager:Init(MainClass)
	self.MainClass = MainClass
end

function bossManager:EHPFix(EHP_GOAL,HP) --you enter the current HP
  local Multiplier = (EHP_GOAL/HP)
	return Multiplier
end

function bossManager:NewGamePlusBoss(spawnedUnit)

  if self.MainClass._NewGamePlus == true then
    local Number_Round = self.MainClass._nRoundNumber
    spawnedUnit.MaxEHP = (7500000 + 750000 * Number_Round + spawnedUnit.MaxEHP )

    spawnedUnit:SetBaseDamageMin( (spawnedUnit:GetBaseDamageMin()+1000000) + 80000 * Number_Round )
    spawnedUnit:SetBaseDamageMax( (spawnedUnit:GetBaseDamageMax()+1500000) + 100000 * Number_Round )
    spawnedUnit:SetPhysicalArmorBaseValue( (spawnedUnit:GetPhysicalArmorBaseValue() + 20 ) * math.log( 1+Number_Round ) )
    spawnedUnit:SetBaseMagicalResistanceValue( (1 - (1-spawnedUnit:GetBaseMagicalResistanceValue()/100)*0.7)*100 )
  end
end

function bossManager:ProcessBossScaling(spawnedUnit)
	local currentRound = GameRules._currentRound or {_HP_difficulty_multiplier = 1, _EHP_multiplier = 1}
			
	if not spawnedUnit:IsAlive() then spawnedUnit:RespawnUnit() end -- fix undead creatures
	spawnedUnit.hasBeenProcessed = true
	
	local maxHP = spawnedUnit:GetMaxHealth()
	local HP_difficulty_multiplier = currentRound._HP_difficulty_multiplier
	if spawnedUnit._spawnerOrigin then
		HP_difficulty_multiplier = spawnedUnit._spawnerOrigin.HealthMultiplier
	end
	if not spawnedUnit.Holdout_IsCore then
		HP_difficulty_multiplier = 1
	end
	local EHP_multiplier = 1 / currentRound._EHP_multiplier
	
	if GameRules._roundnumber > 1 then
		HP_difficulty_multiplier = HP_difficulty_multiplier * ((1 + 0.65 * (GameRules._roundnumber-1) + (0.15 * (GameRules._roundnumber-1))*(GameRules._roundnumber-1) + math.exp(0.67 * math.log(GameRules._roundnumber-1)^2)))
	end
	
	local baseDamage = spawnedUnit:GetAverageBaseDamage()
	local DMG_MULTIPLIER = 1 + 0.1 * (GameRules._roundnumber-1) + math.max(0, 0.97*((GameRules._roundnumber-1)^2)-3.2*(GameRules._roundnumber-1) )
	
	if not spawnedUnit.Holdout_IsCore then
		HP_difficulty_multiplier = HP_difficulty_multiplier * RandomFloat(0.8, 1.2)
	elseif GetMapName() == "strategy_gamemode" then
		HP_difficulty_multiplier = HP_difficulty_multiplier * 1.25
	end
	
	HP_difficulty_multiplier = HP_difficulty_multiplier * (1 + (GameRules.gameDifficulty-1)*0.5)
	spawnedUnit:SetBaseAttackTime( spawnedUnit:GetBaseAttackTime() * 1/((1 + (GameRules.gameDifficulty-1)*0.3) ) )
	spawnedUnit.MaxEHP = HP_difficulty_multiplier*spawnedUnit:GetMaxHealth()
	spawnedUnit.AttackDamageValue = baseDamage * DMG_MULTIPLIER
	local HEALTH_REGEN = math.max( 1, (spawnedUnit.MaxEHP/currentRound._HP_difficulty_multiplier) * 0.005 )
	if not spawnedUnit.Holdout_IsCore then
		HEALTH_REGEN = 0
	end
	
	-- self:NewGamePlusBoss(spawnedUnit)
	-- if GetMapName() == "epic_boss_fight_boss_master" then 
		-- if spawnedUnit:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
			-- if spawnedUnit:IsCreature() then
				-- Timers:CreateTimer(0.03,function()
					-- spawnedUnit:SetOwner(PlayerResource:GetSelectedHeroEntity(self.MainClass.boss_master_id))
					-- spawnedUnit:SetControllableByPlayer(self.MainClass.boss_master_id,true)

				-- end)
			-- end
		-- end
	-- end
	
	spawnedUnit:SetAverageBaseDamage( spawnedUnit.AttackDamageValue )
	local powerScale = spawnedUnit:AddNewModifier(spawnedUnit, nil, "bossPowerScale",{})
	if powerScale then
		powerScale:SetStackCount( GetRoundNumber() * 100 + GetGameDifficulty()*10 + (TeamCount() - 1) )
		powerScale:ForceRefresh()
	end
	
	spawnedUnit.EHP_MULT = 1
	if spawnedUnit:GetUnitName() ~= "npc_dota_boss36" then -- don't scale evil core ever
		if spawnedUnit.MaxEHP >= 800000000 then
			spawnedUnit:SetBaseMaxHealth(800000000)
			spawnedUnit:SetMaxHealth(800000000)
			spawnedUnit:SetHealth(800000000)
			local EHP_MULT = self:EHPFix(spawnedUnit.MaxEHP,800000000)
			spawnedUnit.EHP_MULT = EHP_MULT
			spawnedUnit:SetBaseHealthRegen(spawnedUnit:GetBaseHealthRegen()/EHP_MULT)
			spawnedUnit:AddNewModifier(spawnedUnit, spawnedUnit, "bossHealthRescale",{})
			spawnedUnit:RespawnUnit()
		else
			spawnedUnit:SetBaseMaxHealth(spawnedUnit.MaxEHP)
			spawnedUnit:SetMaxHealth(spawnedUnit.MaxEHP)
			spawnedUnit:SetHealth(spawnedUnit.MaxEHP)
			spawnedUnit:SetBaseHealthRegen( HEALTH_REGEN )
			spawnedUnit.EHP_MULT = 1
			spawnedUnit:RespawnUnit()
		end
	end
end

function bossManager:ManageBossScaling(spawnedUnit)
	if spawnedUnit:GetUnitName() == "npc_dota_healthbar_dummy" then return end
	if spawnedUnit:GetTeam() == DOTA_TEAM_BADGUYS and not (IsInToolsMode() or GameRules:IsCheatMode()) then return end -- only way to get these is with console commands
	if spawnedUnit:IsCreature() then
		if GameRules._currentRound == nil and not (IsInToolsMode() or GameRules:IsCheatMode()) then return end
		spawnedUnit:SetHullRadius( math.min( 48, 24 * (1 + (spawnedUnit:GetModelScale()-1)/2) ) )
		Timers:CreateTimer(function()
			if spawnedUnit:IsConsideredHero() and spawnedUnit:GetUnitName() ~= "npc_dota_healthbar_dummy" and not spawnedUnit._healthBarDummy then
				spawnedUnit._healthBarDummy = CreateUnitByName("npc_dota_healthbar_dummy", spawnedUnit:GetAbsOrigin(), false, nil, nil, spawnedUnit:GetTeam())
				spawnedUnit._healthBarDummy:SetHealthBarOffsetOverride( spawnedUnit:GetBaseHealthBarOffset() )
				spawnedUnit._healthBarDummy:AddNewModifier(spawnedUnit, nil, "modifier_healthbar_dummy", {})
				spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_hide_healthbar", {})
			end
			if spawnedUnit.Holdout_IsCore and not spawnedUnit:HasAbility("enemy_champion") then
				spawnedUnit:AddAbility("enemy_champion"):UpgradeAbility(true)
			end
			if not spawnedUnit.Holdout_IsCore and not spawnedUnit:HasAbility("enemy_minion") then
				spawnedUnit:AddAbility("enemy_minion"):UpgradeAbility(true)
			end
			if spawnedUnit.hasBeenProcessed then
				if not spawnedUnit:HasModifier("bossPowerScale") then
					local powerScale = spawnedUnit:AddNewModifier(spawnedUnit, nil, "bossPowerScale",{})
					if powerScale then
						powerScale:SetStackCount( GetRoundNumber() * 100 + GetGameDifficulty()*10 + (TeamCount() - 1) )
						powerScale:ForceRefresh()
					end
				end
				return 
			end
			if GameRules._currentRound == nil and not (IsInToolsMode() or GameRules:IsCheatMode()) then return end
			self:ProcessBossScaling( spawnedUnit )
		end);
	end
end

function TeamCount()
    local counter = 0
    for i = 0, PlayerResource:GetPlayerCount() -1 do
        if PlayerResource:IsValidPlayerID(i) and PlayerResource:GetConnectionState(i) == DOTA_CONNECTION_STATE_CONNECTED then
	        counter = counter + 1
		end
	end
	return counter
end

function GetGameDifficulty()
	if GetMapName() == "epic_boss_fight_hard" then
		return 1
	elseif GetMapName() == "epic_boss_fight_challenger" then
		return 2
	elseif GetMapName() == "epic_boss_fight_nightmare" then
		return 3
	elseif GetMapName() == "epic_boss_fight_event" then
		return 3
	else
		return 0
	end
end

function GetRoundNumber()
	return GameRules._roundnumber
end