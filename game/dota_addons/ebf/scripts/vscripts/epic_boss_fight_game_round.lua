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

	self._szRoundQuestTitle = kv.RoundName or kv.round_quest_title or "#DOTA_Quest_Holdout_Round"
	self._szRoundTitle = kv.RoundName or kv.round_title or string.format( "Round%d", roundNumber )

	self._nMaxGold = tonumber( kv.MaxGold or (500 + roundNumber * 500) )
	self._nBagCount = tonumber( kv.BagCount or 0 )
	self._nBagVariance = tonumber( kv.BagVariance or 0 )
	self._nFixedXP = tonumber( kv.FixedXP or (475 + roundNumber * 25 + 500*roundNumber) )
	self._Tier = tonumber( kv.Tier or 0 )
	
	self._RoundEndDeadline = kv.RoundEndDeadline or -1
	self._RoundEndDeadlineDifficultyMultiplier = kv.RoundEndDeadlineDifficultyMultiplier or -1
	self._RoundEndDeadlineDifficultyMultiplier = kv.RoundEndDeadlineDifficultyMultiplier or 0
	self._PrepTimeBetweenRoundDifficultyMultipliers = kv.PrepTimeBetweenRoundDifficultyMultipliers or -1
	
	self._GoldPerSecond = 0.5 + roundNumber*0.1
	self._GoldToGive = 0

	self._vSpawners = {}
	for unitName, unitData in pairs( kv ) do
		if type( unitData ) == "table" then
			if not unitData.NPCName then unitData.NPCName = unitName end
			local spawner = CHoldoutGameSpawner()
			spawner:ReadConfiguration( unitName.."_spawner", unitData, self )
			self._vSpawners[ unitName.."_spawner" ] = spawner
		end
	end

	for _, spawner in pairs( self._vSpawners ) do
		spawner:PostLoad( self._vSpawners )
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
	self._vEnemiesRemaining = {}
	self._vEventHandles = {
		ListenToGameEvent( "entity_killed", Dynamic_Wrap( CHoldoutGameRound, "OnEntityKilled" ), self ),
		ListenToGameEvent( "dota_holdout_revive_complete", Dynamic_Wrap( CHoldoutGameRound, 'OnHoldoutReviveComplete' ), self )
	}
	self._DisconnectedPlayer = 0
	self._nAsuraCoreRemaining = 0

	--local PlayerNumber = PlayerResource:GetTeamPlayerCount() --tester
    local PlayerNumber = self:TeamCount()	
	
	ListenToGameEvent( "player_reconnected", Dynamic_Wrap( CHoldoutGameRound, 'OnPlayerReconnected' ), self )
	ListenToGameEvent( "player_disconnect", Dynamic_Wrap( CHoldoutGameRound, 'OnPlayerDisconnected' ), self )
	
	self._MaxPlayTime = -1
	if GetMapName() == "mayhem_gamemode" then
		self._MaxPlayTime = 180 - 30 * (GameRules.gameDifficulty-1)
	end

	local roundNumber = self._nRoundNumber
	self._nMaxGoldForUnits = self._nMaxGold / 2
	self._nMaxGoldForVictory = self._nMaxGold / 2
	self._nGoldRemainingInRound = self._nMaxGoldForUnits
	--new--
	if GameRules._NewGamePlus == true then
		self._nGoldRemainingInRound = self._nGoldRemainingInRound * 5 + 10000
	end

	CustomGameEventManager:Send_ServerToAllClients("UpdateRound", {roundNumber = self._nRoundNumber,roundTitle = self._szRoundQuestTitle})
	
	for _, hero in ipairs( HeroList:GetActiveHeroes() ) do
		if PlayerResource:GetPatronTier( hero:GetPlayerID() ) >= 3 then
			local rune = RandomInt(1,#DOTA_RUNES)
			CreateRune( hero:GetAbsOrigin() + RandomVector( 250 ), rune )
		end
	end
	
	self._nGoldBagsRemaining = self._nBagCount
	self._nGoldBagsExpired = 0
	self._nCoreUnitsTotal = 0
	if GameRules._NewGamePlus == true then
		self._nFixedXP = (50000 + self._nFixedXP) * (roundNumber^0.1)
	end
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
	
	local MAX_TIME_TO_RESOLVE_SPAWNS = 60
	for spawnGroup, spawnTable in pairs( self._vSpawners ) do
		if spawnTable._nTotalUnitsToSpawn > 0 then
			MAX_TIME_TO_RESOLVE_SPAWNS = math.max( MAX_TIME_TO_RESOLVE_SPAWNS, spawnTable._flInitialWait + math.ceil(spawnTable._nTotalUnitsToSpawn / spawnTable._nUnitsPerSpawn) * spawnTable._flSpawnInterval )
		end
	end
	MAX_BONUS_UNITS = TernaryOperator( 5, GetMapName() == "mayhem_gamemode", 3 )
	local unitMultiplier =  math.min( MAX_BONUS_UNITS, math.floor( self._HP_difficulty_multiplier / 2 + 0.5 ) )
	self._HP_difficulty_multiplier = self._HP_difficulty_multiplier / unitMultiplier
	for spawnGroup, spawnTable in pairs( self._vSpawners ) do
		if not spawnTable._NoCountScaling then
			if spawnTable._nTotalUnitsToSpawn == -1 then -- infinite spawner acts differently
				spawnTable._nOrignalInitialUnitsSpawned = spawnTable._nOrignalInitialUnitsSpawned or spawnTable._nInitialUnitsSpawned
				spawnTable._nOrignalUnitsPerSpawn = spawnTable._nOrignalUnitsPerSpawn or spawnTable._nUnitsPerSpawn
				
				spawnTable._nInitialUnitsSpawned = spawnTable._nOrignalInitialUnitsSpawned * unitMultiplier
				spawnTable._nUnitsPerSpawn = spawnTable._nOrignalUnitsPerSpawn * unitMultiplier
			else
				spawnTable._nOriginalTotalUnitsToSpawn = spawnTable._nOriginalTotalUnitsToSpawn or spawnTable._nTotalUnitsToSpawn
				spawnTable._nOrignalUnitsPerSpawn = spawnTable._nOrignalUnitsPerSpawn or spawnTable._nUnitsPerSpawn
				spawnTable._flOriginalSpawnInterval = spawnTable._flOriginalSpawnInterval or spawnTable._flSpawnInterval
				local newUnitCount = spawnTable._nOriginalTotalUnitsToSpawn * unitMultiplier
				
				
				local timeForMaxSpawn = spawnTable._flInitialWait + math.ceil(newUnitCount / spawnTable._nOrignalUnitsPerSpawn) * spawnTable._flOriginalSpawnInterval
				if timeForMaxSpawn >= MAX_TIME_TO_RESOLVE_SPAWNS then
					local newSpawnInterval = (MAX_TIME_TO_RESOLVE_SPAWNS - spawnTable._flInitialWait) / math.ceil(newUnitCount / spawnTable._nOrignalUnitsPerSpawn)
					if newSpawnInterval <= spawnTable._flOriginalSpawnInterval / 2 then
						spawnTable._nUnitsPerSpawn = spawnTable._nOrignalUnitsPerSpawn * 2
					end
					spawnTable._flSpawnInterval = (MAX_TIME_TO_RESOLVE_SPAWNS - spawnTable._flInitialWait) / math.ceil(newUnitCount / spawnTable._nUnitsPerSpawn)
				end
				spawnTable._nTotalUnitsToSpawn = newUnitCount
			end
			spawnTable.HealthMultiplier = self._HP_difficulty_multiplier
		else
			spawnTable.HealthMultiplier = self._OGHP_difficulty_multiplier
		end
	end
	for _, spawner in pairs( self._vSpawners ) do
		spawner:Begin()
		self._nCoreUnitsTotal = self._nCoreUnitsTotal + math.max( 0, spawner:GetTotalUnitsToSpawn( true ) )
		if self._nRoundNumber == 36 then
			self._nCoreUnitsTotal = self._nCoreUnitsTotal + 1
		end
		--if self._nRoundNumber == 37 then --tester
		--[[if self._nRoundNumber == 39 then
				self._NewGamePlus = true
				self._nRoundNumber = 1
				self._flPrepTimeEnd = GameRules:GetGameTime() + 70-time
		end]]
	end
	self._nCoreUnitsKilled = 0

	self._entQuest = SpawnEntityFromTableSynchronous( "quest", {
		name = self._szRoundTitle,
		title =  self._szRoundQuestTitle
	})
	self._entQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_ROUND, self._nRoundNumber )
	self._entQuest:SetTextReplaceString( self._gameMode:GetDifficultyString() )

	self._entKillCountSubquest = SpawnEntityFromTableSynchronous( "subquest_base", {
		show_progress_bar = true,
		progress_bar_hue_shift = -119
	} )
	self._entQuest:AddSubquest( self._entKillCountSubquest )
	self._entKillCountSubquest:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, self._nCoreUnitsTotal )
	
	if GetMapName() == "mayhem_gamemode" then
		CustomGameEventManager:Send_ServerToAllClients("Display_RoundVote", {})
	end
	
	GameRules._currentRound = self
	self.currentlyActive = true
end

function CHoldoutGameRound:OnHoldoutReviveComplete( event )
	local castingHero = EntIndexToHScript( event.caster )
	
	if castingHero then
		castingHero.Ressurect = castingHero.Ressurect + 1
		local totalgold = castingHero:GetGold() + self._nRoundNumber*5
		castingHero:SetGold(0 , false)
		castingHero:SetGold(totalgold, true)
	end
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
				
		local tier5Thr = self._gameMode._tier5DropChance + self._gameMode._tier4DropChance + self._gameMode._tier3DropChance + self._gameMode._tier2DropChance + self._gameMode._tier1DropChance
		local tier4Thr = self._gameMode._tier4DropChance + self._gameMode._tier3DropChance + self._gameMode._tier2DropChance + self._gameMode._tier1DropChance
		local tier3Thr = self._gameMode._tier3DropChance + self._gameMode._tier2DropChance + self._gameMode._tier1DropChance
		local tier2Thr = self._gameMode._tier2DropChance + self._gameMode._tier1DropChance
		local tier1Thr = self._gameMode._tier1DropChance
		
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
					else
						Timers:CreateTimer( 0.5, function()
							local totalGoldInPool = (goldToProvide + goldForLiving) + (hero._currentGoldDebt or 0)
							hero:AddExperience(expToProvide, DOTA_ModifyXP_HeroKill, false, true)
							
							local roll = RandomFloatWrapper( 1, 100 )
							
							local rolledTier
							if roll <= tier5Thr and roll > tier4Thr then
								rolledTier = 5
							elseif roll <= tier4Thr and roll > tier3Thr then
								rolledTier = 4
							elseif roll <= tier3Thr and roll > tier2Thr then
								rolledTier = 3
							elseif roll <= tier2Thr and roll > tier1Thr then
								rolledTier = 2
							else
								rolledTier = 1
							end
							if rolledTier < 5 then
								local oldItems = 0
								-- pity system, if all 6 items are of the tier rolled or higher, give an upgraded one; random choice if multiple options
								for i=DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
									local current_item = hero:GetItemInSlot(i)
									if current_item then
										for i= rolledTier, 5 do
											if self._gameMode._vLootItemDropsTable["Tier"..(i-1)][current_item:GetAbilityName()] then
												oldItems = oldItems + 1
												break
											end
										end
									end
								end
								if oldItems >= 6 then
									rolledTier = rolledTier + 1
								end
							end
							
							local totalItems = #self._gameMode._vLootItemDropsList[rolledTier]
							local itemDropData = self._gameMode._vLootItemDropsList[rolledTier][RandomInt(1,totalItems)]
							local itemToDrop = itemDropData.szItemName
							local itemDrop = CreateItem( itemToDrop, player, hero )
							hero:AddItem( itemDrop )
							-- while itemsCreated < 2 and totalGoldInPool > 0 and attempts > 0 do
								-- local itemsPossible = #self._gameMode._vLootItemDropsList[self._Tier+1]
								-- local itemRange = self._gameMode._vLootItemDropsList[self._Tier+1][itemsPossible].nWeight
								-- local itemDropResult = RandomFloat( 0, itemRange )
								-- for i = itemsPossible, 1, -1 do
									-- local itemDropData = self._gameMode._vLootItemDropsList[self._Tier+1][i]
									-- local itemWeight = itemDropData.nWeight
									-- if itemWeight <= itemDropResult then
										-- itemToDrop = itemDropData.szItemName
										-- break
									-- end
								-- end
								-- attempts = attempts - 1
								-- if itemToDrop and player then
									-- itemsCreated = itemsCreated + 1
									-- totalGoldInPool = totalGoldInPool - math.ceil( GetItemCost( itemToDrop ) )
									-- local itemDrop = CreateItem( itemToDrop, player, hero )
									-- hero:AddItem( itemDrop )
								-- else
									-- attempts = 0
									-- break
								-- end
							-- end
							-- hero._currentGoldDebt = totalGoldInPool
						end)
					end
					-- if roundNumber == 6 then
						-- hero:AddItemByName("item_tier2_token")
					-- elseif roundNumber == 12 then
						-- hero:AddItemByName("item_tier3_token")
					-- elseif roundNumber == 17 then
						-- hero:AddItemByName("item_tier4_token")
					-- elseif roundNumber == 21 then
						-- hero:AddItemByName("item_tier5_token")
					-- end
					if GameRules._NewGamePlus and player then
						if roundNumber == 2
						or roundNumber == 10 
						or roundNumber == 15 
						or roundNumber == 20 then
							local asuraShard = CreateItem( "item_orb_5", player, player )
							hero:AddItem( asuraShard )
						end
					end
				end
			end
		end
		self._nGoldRemainingInRound = 0
		self._nExpRemainingInRound = 0
	end
	-- for _,unit in pairs( Entities:FindAllByClassname("npc_dota_thinker") ) do
		-- if not ( unit:IsTower() or unit:IsHero() or unit:IsNeutralUnitType() ) then
			-- UTIL_Remove( unit )
		-- end
	-- end
	-- for _,unit in pairs( Entities:FindAllInSphere( Vector(0,0,0), 999999 ) ) do
		-- if unit.GetUnitName then print( unit:GetClassname(), unit:GetUnitName() )
		-- else print( unit:GetClassname() ) end
	-- end
	for _,spawner in pairs( self._vSpawners ) do
		spawner:End()
	end
	GameRules._processValuesForScaling = nil
	
	if self._gameMode._tier1DropChance > 0 then
		self._gameMode._tier1DropChance = self._gameMode._tier1DropChance - 8
		self._gameMode._tier2DropChance = self._gameMode._tier2DropChance + 4
		self._gameMode._tier3DropChance = self._gameMode._tier3DropChance + 2
		self._gameMode._tier4DropChance = self._gameMode._tier4DropChance + 1.25
		self._gameMode._tier5DropChance = self._gameMode._tier5DropChance + 0.75
	elseif self._gameMode._tier2DropChance > 0 then
		self._gameMode._tier2DropChance = self._gameMode._tier2DropChance - 5
		self._gameMode._tier3DropChance = self._gameMode._tier3DropChance + 2.5
		self._gameMode._tier4DropChance = self._gameMode._tier4DropChance + 1.5
		self._gameMode._tier5DropChance = self._gameMode._tier5DropChance + 1
	elseif self._gameMode._tier3DropChance > 0 then
		self._gameMode._tier3DropChance = self._gameMode._tier3DropChance - 10
		self._gameMode._tier4DropChance = self._gameMode._tier4DropChance + 9
		self._gameMode._tier5DropChance = self._gameMode._tier5DropChance + 1
	end
	-- if GameRules._getDeadCoreUnitsForGarbageCollection[roundNumber-1] then
		-- local delay = 0
		-- for _, unit in ipairs( GameRules._getDeadCoreUnitsForGarbageCollection[roundNumber-1] ) do
			-- for _, checkTarget in ipairs( unit:FindAllUnitsInRadius(unit:GetAbsOrigin(), -1) ) do
				-- if checkTarget.FindAllModifiers then
					-- for _, modifier in ipairs( checkTarget:FindAllModifiers() ) do
						-- if modifier:GetCaster() == unit then
							-- modifier:Destroy()
						-- end
					-- end
				-- end
			-- end
			-- Timers:CreateTimer( delay, function() UTIL_Remove( unit ) end)
			-- delay = delay + 0.1
		-- end
		-- GameRules._getDeadCoreUnitsForGarbageCollection[roundNumber-1] = nil
	-- end
end


function CHoldoutGameRound:Think()
	for _, spawner in pairs( self._vSpawners ) do
		spawner:Think()
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


function CHoldoutGameRound:ChooseRandomSpawnInfo()
	return self._gameMode:ChooseRandomSpawnInfo()
end

function CHoldoutGameRound:IsFinished()
	for _, spawner in pairs( self._vSpawners ) do
		if not spawner:IsFinishedSpawning() and spawner:GetTotalUnitsToSpawn() > 0 then
			return false
		end
	end
	local nEnemiesRemaining = #self._vEnemiesRemaining
	if nEnemiesRemaining == 0 then
		return true
	end
	if self._MaxPlayTime > 0 and self._RoundStartTime + self._MaxPlayTime < GameRules:GetGameTime() then
		if self._nRoundNumber < GameRules._nMaxRoundNumber then -- dont auto end final round
			return true
		end
	end
	
	for _, unit in ipairs( FindAllUnits() ) do
		if unit:GetTeam() == DOTA_TEAM_NEUTRALS and unit:IsAlive() and unit:IsCreature() then
			return false
		end
	end

	if not self._lastEnemiesRemaining == nEnemiesRemaining then
		self._lastEnemiesRemaining = nEnemiesRemaining
		print ( string.format( "%d enemies remaining in the round...", #self._vEnemiesRemaining ) )
	end
	return true
end


-- Rather than use the xp granting from the units keyvalues file,
-- we let the round determine the xp per unit to grant as a flat value.
-- This is done to make tuning of rounds easier.


function CHoldoutGameRound:OnNPCSpawned( event )
	local spawnedUnit = EntIndexToHScript( event.entindex )
	if not spawnedUnit or spawnedUnit:IsPhantom() or spawnedUnit:GetClassname() == "npc_dota_thinker" or spawnedUnit:GetUnitName() == "" or spawnedUnit:IsNeutralUnitType() then
		return
	end
	local nCoreUnitsRemaining = self._nCoreUnitsTotal - self._nCoreUnitsKilled
	
	if spawnedUnit:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
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
	
	for i, unit in pairs( self._vEnemiesRemaining ) do
		if killedUnit == unit then
			table.remove( self._vEnemiesRemaining, i )
			break
		end
	end
	if killedUnit.Holdout_IsCore then
		self._nCoreUnitsKilled = self._nCoreUnitsKilled + 1
		-- self:_CheckForGoldBagDrop( killedUnit )
		local nCoreUnitsRemaining = self._nCoreUnitsTotal - self._nCoreUnitsKilled
	end
	
	GameRules._getDeadCoreUnitsForGarbageCollection[killedUnit] = true
	for _, modifier in ipairs( killedUnit:FindAllModifiers() ) do
		modifier:Destroy()
	end
	Timers:CreateTimer( 1.5, function()
		if IsEntitySafe( killedUnit ) then killedUnit:AddNoDraw() end
	end)
	
	for _,unit in pairs( FindUnitsInRadius( DOTA_TEAM_NEUTRALS, Vector( 0, 0, 0 ), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false )) do
		if unit:IsCreature() and unit:IsAlive() then
			return
		end
	end
	-- find earliest spawn
	local nextSpawn
	for _, spawner in pairs( self._vSpawners ) do
		if spawner._flNextSpawnTime and (not nextSpawn or spawner._flNextSpawnTime <= nextSpawn._flNextSpawnTime) then
			nextSpawn = spawner
		end
	end
	if nextSpawn then
		nextSpawn._flNextSpawnTime = GameRules:GetGameTime()
	end
end



function CHoldoutGameRound:_CheckForGoldBagDrop( killedUnit )
	if self._nGoldRemainingInRound <= 0 then return end
	if not killedUnit:IsConsideredHero() then return end
	local nCoreUnitsRemaining = self._nCoreUnitsTotal - self._nCoreUnitsKilled
	local tBagDrops = {}
	--local PlayerNumber = PlayerResource:GetTeamPlayerCount() --tester
	local PlayerNumber = self:TeamCount()
	
	-- EXPERIENCE
	local exptogain = 0
	if nCoreUnitsRemaining > 0 then
		exptogain = math.min( self._nExpRemainingInRound, math.ceil( self._nFixedXP / self._nCoreUnitsTotal ) )
	elseif nCoreUnitsRemaining <= 0 then
		exptogain =  math.ceil(self._nExpRemainingInRound)
	end
	-- GOLD
	local goldToGain = 0
	if nCoreUnitsRemaining <= 0 then
		goldToGain = self._nGoldRemainingInRound
	else
		goldToGain = math.min( self._nGoldRemainingInRound, self._nMaxGoldForUnits / self._nCoreUnitsTotal )
	end
	for _,unit in ipairs ( HeroList:GetRealHeroes() ) do
		if unit:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
			unit:AddExperience(exptogain, DOTA_ModifyXP_HeroKill, false, true)
			if PlayerResource:GetConnectionState( unit:GetPlayerID() ) ~= DOTA_CONNECTION_STATE_ABANDONED then unit:AddGold( goldToGain ) end
		end
	end

	self._nExpRemainingInRound = math.max( 0,self._nExpRemainingInRound - exptogain)
	self._nGoldRemainingInRound = math.max( 0,self._nGoldRemainingInRound - goldToGain)
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

--tester
function CHoldoutGameRound:TeamCount()
    local counter = 0
    for i = 0, PlayerResource:GetPlayerCount() -1 do
        if PlayerResource:IsValidPlayerID(i) and PlayerResource:GetConnectionState(i) == DOTA_CONNECTION_STATE_CONNECTED then
	        counter = counter + 1
		end
	end
	return counter
end