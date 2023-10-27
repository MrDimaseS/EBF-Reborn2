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


	self._szRoundQuestTitle = kv.round_quest_title or "#DOTA_Quest_Holdout_Round"
	self._szRoundTitle = kv.round_title or string.format( "Round%d", roundNumber )

	self._nMaxGold = tonumber( kv.MaxGold or 0 )
	self._nBagCount = tonumber( kv.BagCount or 0 )
	self._nBagVariance = tonumber( kv.BagVariance or 0 )
	self._nFixedXP = tonumber( kv.FixedXP or 0 )

	self._vSpawners = {}
	for k, v in pairs( kv ) do
		if type( v ) == "table" and v.NPCName then
			local spawner = CHoldoutGameSpawner()
			spawner:ReadConfiguration( k, v, self )
			self._vSpawners[ k ] = spawner
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

function CHoldoutGameRound:spawn_treasure()
	random = math.random(0,100)
	if (random > 80) then
		local Item_spawn = CreateItem( "item_present_treasure", nil, nil )
		Timers:CreateTimer(0.03,function()
			local max_player = DOTA_MAX_TEAM_PLAYERS
			WID = math.random(0,max_player)
			if PlayerResource:GetConnectionState(WID) == 2 then
				local player = PlayerResource:GetPlayer(WID)
				local hero = player:GetAssignedHero() 
				hero:AddItem(Item_spawn)
			else
				return 0.03
			end
		end)
	end
end

function CHoldoutGameRound:Begin()
	
	self._vEnemiesRemaining = {}
	self._vEventHandles = {
		ListenToGameEvent( "npc_spawned", Dynamic_Wrap( CHoldoutGameRound, "OnNPCSpawned" ), self ),
		ListenToGameEvent( "entity_killed", Dynamic_Wrap( CHoldoutGameRound, "OnEntityKilled" ), self ),
		ListenToGameEvent( "dota_holdout_revive_complete", Dynamic_Wrap( CHoldoutGameRound, 'OnHoldoutReviveComplete' ), self )
	}
	self._DisconnectedPlayer = 0
	self._nAsuraCoreRemaining = 0

	--local PlayerNumber = PlayerResource:GetTeamPlayerCount() --tester
    local PlayerNumber = self:TeamCount()	
	
	ListenToGameEvent( "player_reconnected", Dynamic_Wrap( CHoldoutGameRound, 'OnPlayerReconnected' ), self )
	ListenToGameEvent( "player_disconnect", Dynamic_Wrap( CHoldoutGameRound, 'OnPlayerDisconnected' ), self )


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
	for _, spawner in pairs( self._vSpawners ) do
		spawner:Begin()
		self._nCoreUnitsTotal = self._nCoreUnitsTotal + spawner:GetTotalUnitsToSpawn( true )
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
	Timers:CreateTimer( function()
		for _,unit in pairs( Entities:FindAllByClassname("npc_dota_creature") ) do
			if unit:IsAlive() then
				unit:ForceKill( true )
			end
		end
	end)
	
	if bWon then
		
		self._heroesDiedThisRound = self._heroesDiedThisRound or {}
		local goldMuliplierTeam = 0.5
		local deathReduction = goldMuliplierTeam / HeroList:GetActiveHeroCount()
		
		for hero, deaths in pairs( self._heroesDiedThisRound ) do
			if deaths > 0 then
				goldMuliplierTeam = goldMuliplierTeam - deathReduction
			end
		end
		
		local goldToProvide = self._nMaxGoldForVictory + self._nGoldRemainingInRound
		local expToProvide = self._nExpRemainingInRound
		self._nGoldRemainingInRound = 0
		self._nExpRemainingInRound = 0
		for _, hero in ipairs( HeroList:GetRealHeroes() ) do
			local player = hero:GetPlayerOwner()
			if hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS then 
				if PlayerResource:GetConnectionState( hero:GetPlayerID() ) ~= DOTA_CONNECTION_STATE_ABANDONED then
					local goldMuliplierSolo = TernaryOperator( 0.25, (self._heroesDiedThisRound[hero] or 0 > 0), 0)
					Timers:CreateTimer( 0.5, function() hero:AddGold( goldToProvide ) end)
					if goldMuliplierTeam + goldMuliplierSolo > 0 then
						Timers:CreateTimer( 1.5, function()
							hero:AddGold( self._nMaxGoldForVictory * (goldMuliplierTeam + goldMuliplierSolo) )
						end)
					end
					
					print("ending loop")
					if roundNumber == 6 then
						hero:AddItemByName("item_tier2_token")
					elseif roundNumber == 12 then
						hero:AddItemByName("item_tier3_token")
					elseif roundNumber == 17 then
						hero:AddItemByName("item_tier4_token")
					elseif roundNumber == 21 then
						hero:AddItemByName("item_tier5_token")
					end
					if GameRules._NewGamePlus and player then
						if roundNumber == 2
						or roundNumber == 10 
						or roundNumber == 15 
						or roundNumber == 20 then
							local asuraShard = CreateItem( "item_orb_5", player, player )
							hero:AddItem( asuraShard )
						end
					end
				elseif expToProvide > 0 then
					unit:AddExperience(expToProvide, DOTA_ModifyXP_HeroKill, false, true)
				end
			end
		end
		
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
	-- clear cached units
	if GameRules._getDeadCoreUnitsForGarbageCollection[roundNumber-2] then
		local delay = 0
		for _, unit in ipairs( GameRules._getDeadCoreUnitsForGarbageCollection[roundNumber-2] ) do
			for _, checkTarget in ipairs( unit:FindAllUnitsInRadius(unit:GetAbsOrigin(), -1) ) do
				if checkTarget.FindAllModifiers then
					for _, modifier in ipairs( checkTarget:FindAllModifiers() ) do
						if modifier:GetCaster() == unit then
							modifier:Destroy()
						end
					end
				end
			end
			Timers:CreateTimer( delay, function() UTIL_Remove( unit ) end)
			delay = delay + 0.1
		end
		GameRules._getDeadCoreUnitsForGarbageCollection[roundNumber-2] = nil
	end
end


function CHoldoutGameRound:Think()
	for _, spawner in pairs( self._vSpawners ) do
		spawner:Think()
	end
end


function CHoldoutGameRound:ChooseRandomSpawnInfo()
	return self._gameMode:ChooseRandomSpawnInfo()
end


function CHoldoutGameRound:IsFinished()
	for _, spawner in pairs( self._vSpawners ) do
		if not spawner:IsFinishedSpawning() then
			return false
		end
	end
	local nEnemiesRemaining = #self._vEnemiesRemaining
	if nEnemiesRemaining == 0 then
		return true
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
		self:_CheckForGoldBagDrop( killedUnit )
		local nCoreUnitsRemaining = self._nCoreUnitsTotal - self._nCoreUnitsKilled
		if nCoreUnitsRemaining == 0 then
			self:spawn_treasure()
		end
	end
	
	Timers:CreateTimer( 1.5, function()
		for _, modifier in ipairs( killedUnit:FindAllModifiers() ) do
			modifier:Destroy()
		end
		killedUnit:AddNoDraw()
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