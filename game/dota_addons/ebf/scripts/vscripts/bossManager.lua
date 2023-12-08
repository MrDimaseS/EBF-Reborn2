

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

LinkLuaModifier( "bossHealthRescale", "modifier/bossHealthRescale.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "bossPowerScale", "modifier/bossPowerScale.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "status_immune", "modifier/status_immune.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_healthbar_dummy", "modifier/modifier_healthbar_dummy.lua", LUA_MODIFIER_MOTION_NONE )


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
	local currentRound = GameRules._currentRound
			
	if not spawnedUnit:IsAlive() then spawnedUnit:RespawnUnit() end -- fix undead creatures
	spawnedUnit.hasBeenProcessed = true
	
	local HP_difficulty_multiplier = currentRound._HP_difficulty_multiplier
	if spawnedUnit._spawnerOrigin then
		HP_difficulty_multiplier = spawnedUnit._spawnerOrigin.HealthMultiplier
	end
	local EHP_multiplier = currentRound._EHP_multiplier
	
	if GetGameDifficulty() >= 3 and spawnedUnit.Holdout_IsCore then
		HP_difficulty_multiplier = HP_difficulty_multiplier * 1.5
		spawnedUnit:SetBaseAttackTime( spawnedUnit:GetBaseAttackTime() * 0.65 )
	end
	
	if not spawnedUnit.Holdout_IsCore then
		HP_difficulty_multiplier = 1 + (HP_difficulty_multiplier-1)*0.25
	end
	
	spawnedUnit.MaxEHP = HP_difficulty_multiplier*spawnedUnit:GetMaxHealth()
	spawnedUnit:SetHealth(spawnedUnit:GetMaxHealth())
	
	local currentReduction = spawnedUnit:GetPhysicalArmorMultiplier()
	local newEHPReduction = currentReduction * EHP_multiplier
	
	local newArmor = spawnedUnit:GetPhysicalArmorBaseValue()
	while currentReduction > newEHPReduction  do
		newArmor = newArmor + 0.1
		currentReduction = CalculatePhysicalArmorMultiplier( newArmor )
	end
	spawnedUnit:SetPhysicalArmorBaseValue( newArmor )
	spawnedUnit:SetBaseMagicalResistanceValue( 100-(100-spawnedUnit:GetBaseMagicalResistanceValue())*EHP_multiplier )
	self:NewGamePlusBoss(spawnedUnit)
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
	
	local powerScale = spawnedUnit:AddNewModifier(spawnedUnit, nil, "bossPowerScale",{})
	powerScale:SetStackCount( GetRoundNumber() * 100 + GetGameDifficulty()*10 + (TeamCount() - 1) )
	powerScale:ForceRefresh( ) -- force client/server update
	
	if spawnedUnit.Holdout_IsCore then
		spawnedUnit:AddNewModifier( spawnedUnit, nil, "modifier_rune_haste", {duration = 3} )
		spawnedUnit:SetUnitCanRespawn( true )
		GameRules._getDeadCoreUnitsForGarbageCollection = GameRules._getDeadCoreUnitsForGarbageCollection or {}
		GameRules._getDeadCoreUnitsForGarbageCollection[GetRoundNumber()] = GameRules._getDeadCoreUnitsForGarbageCollection[GetRoundNumber()] or {}
		table.insert( GameRules._getDeadCoreUnitsForGarbageCollection[GetRoundNumber()], spawnedUnit )
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
			spawnedUnit.EHP_MULT = 1
			spawnedUnit:RespawnUnit()
		end
	end
end

function bossManager:ManageBossScaling(spawnedUnit)
	if spawnedUnit:GetUnitName() == "npc_dota_healthbar_dummy" then return end
	if spawnedUnit:GetTeam() == DOTA_TEAM_BADGUYS and not IsInToolsMode() then return end -- only way to get these is with console commands
	if spawnedUnit:IsCreature() then
		if spawnedUnit.hasBeenProcessed then
			if spawnedUnit:IsConsideredHero() and spawnedUnit:GetUnitName() ~= "npc_dota_healthbar_dummy" then
				local dummy = CreateUnitByName("npc_dota_healthbar_dummy", spawnedUnit:GetAbsOrigin(), false, nil, nil, spawnedUnit:GetTeam())
				dummy:SetHealthBarOffsetOverride( spawnedUnit:GetBaseHealthBarOffset() )
				dummy:AddNewModifier(spawnedUnit, nil, "modifier_healthbar_dummy", {})
				spawnedUnit:AddNewModifier(spawnedUnit, nil, "modifier_hide_healthbar", {})
			end
			return
		end
		if self._currentRound == nil then return end
		spawnedUnit:SetHullRadius( math.min( 48, 24 * (1 + (spawnedUnit:GetModelScale()-1)/2) ) )
		Timers:CreateTimer(function()
			if spawnedUnit.hasBeenProcessed then return end
			if self._currentRound == nil then return end
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
	else
		return 0
	end
end

function GetRoundNumber()
	return GameRules._roundnumber
end