--[[
	CHoldoutGameRound - A single round of Holdout
]]

if CHoldoutGameRound == nil then
	CHoldoutGameRound = class({})
end

require("libraries/Timers")


function CHoldoutGameRound:ReadConfiguration( kv, gameMode, roundNumber )
	self._gameMode = gameMode
	self._nRoundNumber = roundNumber

	self._szRoundQuestTitle = kv.RoundName

	self._nMaxGold = 500 + math.floor(roundNumber/6) * 500
	self._nFixedXP = 250*(roundNumber+1) + 500*roundNumber
	self._Tier = 0
	
	self._RoundEndDeadline = kv.RoundEndDeadline or -1
	self._RoundEndDeadlineDifficultyMultiplier = kv.RoundEndDeadlineDifficultyMultiplier or -1
	self.PrepTimeBetweenRounds = kv.PrepTimeBetweenRounds or 0
	self._PrepTimeBetweenRoundDifficultyMultipliers = kv.PrepTimeBetweenRoundDifficultyMultipliers or -1
	
	self._GoldPerSecond = 0.5 + roundNumber*0.1
	self._GoldToGive = 0

	self._vSpawners = {}
	for stageID, stageData in pairs( kv.Stages ) do
		local cStage = string.gsub( stageID, "Stage", "") or 0
		local stageNumber = tonumber( cStage ) + 1
		local spawner = CHoldoutGameSpawner()
		spawner:ReadConfiguration( stageData, stageNumber, self )
		
		self._vSpawners[ stageNumber ] = spawner
	end
	if self._vSpawners[ 1 ] == nil then -- fix ipairs by initializing row
		self._vSpawners[ 1 ] = false
	end
end


function CHoldoutGameRound:Precache()
	for _, spawner in pairs( self._vSpawners ) do
		spawner:Precache()
	end
end

function CHoldoutGameRound:Begin()
	print("round has started", self._szRoundQuestTitle )
	self._RoundStartTime = GameRules:GetGameTime()
	self._vEventHandles = {
		ListenToGameEvent( "entity_killed", Dynamic_Wrap( CHoldoutGameRound, "OnEntityKilled" ), self ),
	}
	
	self._MaxPlayTime = -1
	if GetMapName() == "mayhem_gamemode" then
		self._MaxPlayTime = 180 - 30 * (GameRules.gameDifficulty-1)
	end

	local roundNumber = self._nRoundNumber
	self._nMaxGoldForUnits = self._nMaxGold / 2
	self._nMaxGoldForVictory = self._nMaxGold / 2
	self._nGoldRemainingInRound = self._nMaxGoldForUnits

	CustomGameEventManager:Send_ServerToAllClients("UpdateRound", {roundNumber = self._nRoundNumber,roundTitle = self._szRoundQuestTitle})
	self._nExpRemainingInRound = self._nFixedXP
	
	-- handle unit count scaling
	local playerCount = 0
    for i = 0, PlayerResource:GetPlayerCount() -1 do
        if PlayerResource:IsValidPlayerID(i) and PlayerResource:GetConnectionState(i) == DOTA_CONNECTION_STATE_CONNECTED then
	        playerCount = playerCount + 1
		end
	end
	
	self._OGHP_difficulty_multiplier = 1 + ((playerCount-1) * 1.5)^0.85
	self._EHP_multiplier = self._OGHP_difficulty_multiplier/(1 + 0.8*(playerCount-1))
	self._HP_difficulty_multiplier = self._OGHP_difficulty_multiplier * self._EHP_multiplier
	
	self._spawnedLivingUnits = {}
	for stageNumber, spawner in ipairs( self._vSpawners ) do
		if spawner then
			spawner:Initialize()
			if stageNumber == 1 then
				spawner:Begin()
			elseif stageNumber == 2 then
				spawner:Begin()
			end
		end
	end
	
	if GetMapName() == "mayhem_gamemode" then
		CustomGameEventManager:Send_ServerToAllClients("Display_RoundVote", {})
	end
	
	GameRules._currentRound = self
	self.currentlyActive = true
end

function CHoldoutGameRound:End(bWon)
	for _, eID in pairs( self._vEventHandles ) do
		StopListeningToGameEvent( eID )
	end
	self._vEventHandles = {}
	
	self.currentlyActive = false
	local roundNumber = self._nRoundNumber
	if GetMapName() ~= "mayhem_gamemode" then
		Timers:CreateTimer( function()
			for _,unit in pairs( Entities:FindAllByClassname("npc_dota_creature") ) do
				if unit:IsAlive() then
					unit:ForceKill( true )
				end
			end
		end)
	end
	if bWon and self._nGoldRemainingInRound > 0 then
		self._heroesDiedThisRound = self._heroesDiedThisRound or {}
		local goldMuliplierTeam = 0.5
		local deathReduction = goldMuliplierTeam / HeroList:GetActiveHeroCount()
		
		for hero, deaths in pairs( self._heroesDiedThisRound ) do
			if deaths > 0 then
				goldMuliplierTeam = goldMuliplierTeam - deathReduction
			end
		end
		local expToProvide = self._nExpRemainingInRound
		
		for _, hero in ipairs( HeroList:GetRealHeroes() ) do
			local goldMuliplierSolo = TernaryOperator( 0.25, (self._heroesDiedThisRound[hero] or 0 == 0), 0)
			local goldForLiving = self._nMaxGoldForVictory * (goldMuliplierTeam + goldMuliplierSolo)
			local goldToProvide = self._nMaxGoldForVictory + self._nGoldRemainingInRound
			
			local player = hero:GetPlayerOwner()
			if hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS then 
				if PlayerResource:GetConnectionState( hero:GetPlayerID() ) ~= DOTA_CONNECTION_STATE_ABANDONED then
					if GetMapName() ~= "epic_boss_fight_event" then
						Timers:CreateTimer( 0.5, function()
							hero:AddGold( goldToProvide )
							hero:AddExperience(expToProvide, DOTA_ModifyXP_HeroKill, false, true)
						end)
						if goldMuliplierTeam + goldMuliplierSolo > 0 then
							Timers:CreateTimer( 1.5, function()
								hero:AddGold( goldForLiving )
							end)
						end
					end
				end
			end
		end
		self._nGoldRemainingInRound = 0
		self._nExpRemainingInRound = 0
	end
	for _,spawner in pairs( self._vSpawners ) do
		if spawner then
			spawner:End()
		end
	end
	for _,illusion in pairs ( FindAllUnits() ) do
		if illusion:HasModifier("modifier_illusion") or illusion:IsIllusion() == true then
			illusion:ForceKill(false)
		end
	end
	GameRules._processValuesForScaling = nil
end

function CHoldoutGameRound:GetSpawnLocations()
	if not GameRules._spawns then
		GameRules._spawns = {}
		for _, entity in ipairs( Entities:FindAllByClassname("npc_dota_scripted_spawner") ) do
			table.insert( GameRules._spawns, entity:GetAbsOrigin() )
		end
	end
	return GameRules._spawns
end

function CHoldoutGameRound:GetRandomSpawnLocation()
	local spawns = self:GetSpawnLocations()
	return spawns[RandomInt(1, #spawns)]
end

function CHoldoutGameRound:GetRemainingUnitsToSpawn( bIncludeMinions )
	local includeMinions = bIncludeMinions or true
	local totalSpawns = 0
	for _, spawner in ipairs( self._vSpawners ) do
		totalSpawns = totalSpawns + spawner:GetTotalRemainingSpawns( includeMinions )
	end
	return totalSpawns
end

function CHoldoutGameRound:GetAllRemainingUnits( bIncludeMinions )
	local livingUnits = 0
	local unitsToSpawn = 0
	local includeMinions = bIncludeMinions or true
	for stageID, spawner in ipairs( self._vSpawners ) do
		if spawner then
			if self._spawnedLivingUnits[stageID] then
				for i=#self._spawnedLivingUnits[stageID], 1, -1 do
					if self._spawnedLivingUnits[stageID][i]:IsNull() or not self._spawnedLivingUnits[stageID][i]:IsAlive() then
						table.remove( self._spawnedLivingUnits[stageID], i )
					end
				end
				livingUnits = livingUnits + #self._spawnedLivingUnits[stageID]
			end
			unitsToSpawn = unitsToSpawn + spawner:GetTotalRemainingSpawns( bIncludeMinions )
			for unitName, currentlySpawning in pairs( spawner._currentlySpawningQueuedUnits ) do
				if currentlySpawning then
					unitsToSpawn = unitsToSpawn + 1
				end
			end
		end
	end
	return livingUnits + unitsToSpawn
end

function CHoldoutGameRound:Think()
	if not self.currentlyActive then return end
	for _, spawner in pairs( self._vSpawners ) do
		if spawner then
			if spawner:IsActive() then
				spawner:Think()
			elseif spawner._StageWaitTime > 0 then
				spawner._StageWaitTime = spawner._StageWaitTime - 0.25
				if spawner._StageWaitTime <= 0 then
					spawner:Begin()
				end
			end
		end
	end
	-- mayhem UI
	if GetMapName() == "mayhem_gamemode" then
		CustomGameEventManager:Send_ServerToAllClients("UpdateTimeLeft", {nextRound = self._nRoundNumber, Time = self._RoundStartTime + self._MaxPlayTime - GameRules:GetGameTime()})
	end
	-- hero gold per tick
	for _, hero in ipairs( HeroList:GetActiveHeroes() ) do
		hero:AddGold( self._GoldPerSecond, false, DOTA_ModifyGold_GameTick )
	end
	-- clear cached units
	local delay = 1.5
	local numberOfUnits = 0
	for unit, _ in pairs( GameRules._getDeadCoreUnitsForGarbageCollection ) do
		numberOfUnits = numberOfUnits + 1
		if IsEntitySafe( unit ) then
			for i = 0, unit:GetAbilityCount() - 1 do
				local ability = unit:GetAbilityByIndex( i )
				if ability then
					local activeModifiers = ability:NumModifiersUsingAbility()
					if activeModifiers > 0 then
						for _, findUnit in ipairs( FindAllUnits() ) do
							for _, modifier in ipairs( findUnit:FindAllModifiers() ) do
								if modifier:GetAbility() == ability 
								and ( (findUnit:IsSameTeam( unit ) and not findUnit:IsAlive()) or 
									   not findUnit:IsSameTeam( unit ) and not modifier:GetAuraOwner() ) then
									modifier:Destroy()
									activeModifiers = activeModifiers - 1
									if activeModifiers <= 0 then
										break
									end
								end
							end
						end
						goto continue
					end
				end
			end
			for i=DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
				local item = unit:GetItemInSlot(i)
				if item and item:NumModifiersUsingAbility() > 0 then
					for _, findUnit in ipairs( FindAllUnits() ) do
						for _, modifier in ipairs( findUnit:FindAllModifiers() ) do
							if modifier:GetAbility() == item and modifier:GetRemainingTime() <= 0 then
								modifier:Destroy()
							end
						end
					end
					goto continue
				end
			end
		end
		GameRules._getDeadCoreUnitsForGarbageCollection[unit] = nil
		if IsEntitySafe( unit ) then
			Timers:CreateTimer( delay, function() UTIL_Remove( unit ) end)
			delay = delay + 0.1
		end
		::continue::
	end
end

function CHoldoutGameRound:OnNPCSpawned( event )
	local spawnedUnit = EntIndexToHScript( event.entindex )
	if not spawnedUnit or spawnedUnit:IsPhantom() or spawnedUnit:GetClassname() == "npc_dota_thinker" or spawnedUnit:GetUnitName() == "" or spawnedUnit:IsNeutralUnitType() then
		return
	end
	if spawnedUnit:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
		self._vEnemiesRemaining = self._vEnemiesRemaining or {}
		table.insert( self._vEnemiesRemaining, spawnedUnit )
		spawnedUnit:SetDeathXP( 0 )
		spawnedUnit.unitName = spawnedUnit:GetUnitName()
	end
	if spawnedUnit:IsCreature() then
		for i = 0, spawnedUnit:GetAbilityCount() - 1 do
			local ability = spawnedUnit:GetAbilityByIndex( i )
			if ability then
				ability:SetRefCountsModifiers(true)
			end
		end
		for i=DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
			local current_item = spawnedUnit:GetItemInSlot(i)
			if current_item then
				current_item:SetRefCountsModifiers(true)
			end
		end
		spawnedUnit:SetUnitCanRespawn( true )
	end
end


function CHoldoutGameRound:OnEntityKilled( event )
	local killedUnit = EntIndexToHScript( event.entindex_killed )
	
	if not killedUnit then return end
	if killedUnit:IsRealHero() and not killedUnit:IsReincarnating() then
		self._heroesDiedThisRound = self._heroesDiedThisRound or {}
		self._heroesDiedThisRound[killedUnit] = (self._heroesDiedThisRound[killedUnit] or 0) + 1
	end
	if not killedUnit:IsCreature() then
		return
	end
	
	if killedUnit._stageID then
		for id, unit in ipairs( self._spawnedLivingUnits[killedUnit._stageID] ) do
			if unit == killedUnit then
				table.remove( self._spawnedLivingUnits[killedUnit._stageID], id )
				break
			end
		end
	end
	
	GameRules._getDeadCoreUnitsForGarbageCollection[killedUnit] = true
	for _, modifier in ipairs( killedUnit:FindAllModifiers() ) do
		modifier:Destroy()
	end
	Timers:CreateTimer( 1.5, function()
		if IsEntitySafe( killedUnit ) then killedUnit:AddNoDraw() end
	end)
	
	if killedUnit.Holdout_IsCore then
		if #self._spawnedLivingUnits[killedUnit._stageID] == 0 then -- no more living units in stage
			local spawner = self._vSpawners[killedUnit._stageID]
			if spawner:GetRemainingSpawns( ) == 0 then -- everything has been spawned
				local nextSpawner = self._vSpawners[killedUnit._stageID + 1]
				local minionSpawner = self._vSpawners[1]
				if nextSpawner and not nextSpawner:IsActive() then -- start next stage if not already active
					nextSpawner:Begin()
					if minionSpawner then
						-- speed up next minion spawn to align Stages
						for unitName, spawnGroups in pairs( minionSpawner._loadedSpawnQueue ) do
							local spawnData = spawnGroups[1]
							if spawnData then
								spawnData.spawnInterval = 1
							end
						end
					end
				elseif minionSpawner then -- all bosses are dead and spawned, stop spawning minions
					minionSpawner:End()
				end
			end
		end
	end
end

function CHoldoutGameRound:IsFinished()
	if self.currentlyActive == false then return true end
	return self:GetAllRemainingUnits( false ) <= 0
end

function CHoldoutGameRound:StatusReport( )
	print( string.format( "Enemies remaining: %d", #self._vEnemiesRemaining ) )
	for _,e in pairs( self._vEnemiesRemaining ) do
		if e:IsNull() then
			print( string.format( "<Unit %s Deleted from C++>", e.unitName ) )
		else
			print( e:GetUnitName() )
		end
	end
	print( string.format( "Spawners: %d", #self._vSpawners ) )
	for _,s in pairs( self._vSpawners ) do
		s:StatusReport()
	end
end