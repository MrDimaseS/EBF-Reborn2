--[[
	CHoldoutGameSpawner - A single unit spawner for Holdout.
]]
if CHoldoutGameSpawner == nil then
	CHoldoutGameSpawner = class({})
end


function CHoldoutGameSpawner:ReadConfiguration( stageData, stageNumber, gameRound )
	self._gameRound = gameRound
	self._stageID = stageNumber
	self._stageSpawnQueues = {}
	self._currentlySpawningQueuedUnits = {}
	
	self._StageWaitTime = tonumber( stageData.StageWaitTime or "30" )
	if not stageData.Units then -- simplified KV
		local unitData = table.copy(stageData)
		stageData = {}
		stageData.Units = unitData
	end
	for unitName, unitData in pairs( stageData.Units ) do
		local queueData = {}
		queueData.unitName = unitName
		if type( unitData ) == "table" then
			queueData._bIsCoreSpawnQueue = stageNumber > 1
			queueData._nTotalUnitsToSpawn = TernaryOperator( -1, not queueData._bIsCoreSpawnQueue, tonumber( unitData.TotalUnitsToSpawn or 0 ) )
			queueData._nUnitsPerSpawn = tonumber( unitData.UnitsPerSpawn ) or 1
			queueData._nInitialUnitsSpawned = tonumber( unitData.InitialUnitsSpawned or queueData._nUnitsPerSpawn )
			queueData._flSpawnInterval = tonumber( unitData.SpawnInterval ) or 0
			queueData._flBonusUnitsPerPlayer = tonumber( unitData.BonusUnitsPerPlayer ) or TernaryOperator( 1, not  queueData._bIsCoreSpawnQueue, 0 )
		else
			queueData._bIsCoreSpawnQueue = stageNumber > 1
			queueData._nTotalUnitsToSpawn = tonumber(unitData) or 1
			queueData._nUnitsPerSpawn = 1
			queueData._nInitialUnitsSpawned = 1
			queueData._flSpawnInterval = 30
			queueData._flBonusUnitsPerPlayer = 0
		end
		table.insert( self._stageSpawnQueues, queueData )
	end
end

function CHoldoutGameSpawner:Precache()
	for unitID, unitData in ipairs( self._stageSpawnQueues ) do
		PrecacheUnitByNameAsync( unitData.unitName, function( sg ) self._sg = sg end )
	end
end

function CHoldoutGameSpawner:GetRemainingSpawnsForUnit( unitName )
	if not self._stageSpawnQueues then return 0 end
	return #self._loadedSpawnQueue[unitName]
end

function CHoldoutGameSpawner:GetTotalRemainingSpawnsForUnit( unitName )
	local totalSpawns = 0
	if not self._stageSpawnQueues then return 0 end
	for _, spawnData in ipairs( self._loadedSpawnQueue[unitName] ) do
		totalSpawns = totalSpawns + spawnData.unitsSpawned
	end
	return totalSpawns
end

function CHoldoutGameSpawner:GetRemainingSpawns( bIncludeMinions )
	local totalSpawns = 0
	if not self._stageSpawnQueues then return 0 end
	local includeMinions = bIncludeMinions or true
	for unitID, unitData in ipairs( self._stageSpawnQueues ) do
		if unitData._bIsCoreSpawnQueue or includeMinions then
			totalSpawns = totalSpawns + #unitData.activeSpawnQueue
		end
	end
	return totalSpawns
end

function CHoldoutGameSpawner:GetTotalRemainingSpawns( bIncludeMinions )
	local totalSpawns = 0
	if not self._stageSpawnQueues then return 0 end
	local includeMinions = bIncludeMinions or true
	for unitID, unitData in ipairs( self._stageSpawnQueues ) do
		if (unitData._bIsCoreSpawnQueue or includeMinions) and unitData.activeSpawnQueue then
			for _, spawnData in ipairs( unitData.activeSpawnQueue ) do
				totalSpawns = totalSpawns + spawnData.unitsSpawned
			end
		end
	end
	return totalSpawns
end

function CHoldoutGameSpawner:Initialize()
	-- initialize unit queue
	self._loadedSpawnQueue = {}
	self._gameRound._spawnedLivingUnits[self._stageID] = {}

	for unitID, unitData in ipairs( self._stageSpawnQueues ) do
		print( unitID, unitData.unitName )
		self._loadedSpawnQueue[unitData.unitName] = {}
		unitData.activeSpawnQueue = self._loadedSpawnQueue[unitData.unitName]
		local spawnTable = {}
		spawnTable.spawnInterval = 0
		local bonusUnits = math.floor(HeroList:GetRealHeroCount() * unitData._flBonusUnitsPerPlayer)
		if not unitData._bIsCoreSpawnQueue then
			spawnTable.doNotRemoveFromQueue = true
			spawnTable.unitsSpawned = unitData._nInitialUnitsSpawned + bonusUnits
			spawnTable._maxUnitsToSpawn = spawnTable.unitsSpawned * 2
			table.insert( self._loadedSpawnQueue[unitData.unitName], table.copy(spawnTable) )
			spawnTable.spawnInterval = unitData._flSpawnInterval
			spawnTable.unitsSpawned = unitData._nUnitsPerSpawn + bonusUnits
			table.insert( self._loadedSpawnQueue[unitData.unitName], table.copy(spawnTable) )
		elseif unitData._nTotalUnitsToSpawn > 0 then
			local unitSpawnMultiplier = (unitData._nTotalUnitsToSpawn + bonusUnits) / unitData._nTotalUnitsToSpawn
			unitData._nTotalUnitsToSpawn = unitData._nTotalUnitsToSpawn + bonusUnits
			unitData._nInitialUnitsSpawned = math.floor( unitData._nInitialUnitsSpawned * unitSpawnMultiplier )
			unitData._nUnitsPerSpawn = math.floor( unitData._nUnitsPerSpawn * unitSpawnMultiplier )
			while unitData._nTotalUnitsToSpawn > 0 do
				if #unitData.activeSpawnQueue == 0 then
					spawnTable.unitsSpawned = math.min( unitData._nTotalUnitsToSpawn, unitData._nInitialUnitsSpawned )
				else
					spawnTable.unitsSpawned = math.min( unitData._nTotalUnitsToSpawn, unitData._nUnitsPerSpawn )
					spawnTable.spawnInterval = unitData._flSpawnInterval
				end
				unitData._nTotalUnitsToSpawn = unitData._nTotalUnitsToSpawn - spawnTable.unitsSpawned 
				table.insert( self._loadedSpawnQueue[unitData.unitName], table.copy(spawnTable) )
			end
		end
	end
end

function CHoldoutGameSpawner:Begin()
	self._isActive = true
end

function CHoldoutGameSpawner:IsActive()
	return self._isActive or false
end

function CHoldoutGameSpawner:End()
	if self._isActive == false then return end
	self._isActive = false
	self._loadedSpawnQueue = nil
	if self._stageSpawnQueues then
		for unitID, unitData in ipairs( self._stageSpawnQueues ) do
			if unitData.activeSpawnQueue then unitData.activeSpawnQueue = nil end
		end
	end
	self._stageSpawnQueues = nil
	if self._sg ~= nil then
		UnloadSpawnGroupByHandle( self._sg )
		self._sg = nil
	end
end

function CHoldoutGameSpawner:Think()
	if not self._loadedSpawnQueue then return end
	for unitName, spawnGroups in pairs( self._loadedSpawnQueue ) do
		local spawnData = spawnGroups[1]
		if spawnData then
			if spawnData.spawnInterval <= 0 then
				if self:_DoSpawn( spawnData, unitName ) then
					if spawnData.doNotRemoveFromQueue then -- refresh minion if necessary
						local cycledSpawnGroup = table.copy( spawnGroups[2] )
						table.insert( spawnGroups, cycledSpawnGroup )
					end
					table.remove( spawnGroups, 1 )
				end
			else
				spawnData.spawnInterval = spawnData.spawnInterval - 0.25
			end
		end
	end
	if self:GetRemainingSpawns() <= 0 then -- everything's been spawned
		self:End( true )
	end
end

function CHoldoutGameSpawner:GetRandomSpawnLocation()
	return self._gameRound:GetRandomSpawnLocation()
end

function CHoldoutGameSpawner:_DoSpawn( spawnData, unitName )
	if self._currentlySpawningQueuedUnits[unitName] then return false end
	for i=1, tonumber(spawnData.unitsSpawned) do
		local vBaseSpawnLocation = self:GetRandomSpawnLocation()
		if not vBaseSpawnLocation then return false end
		local vSpawnLocation = vBaseSpawnLocation + RandomVector( RandomFloat( 0, 200 ) )
		if spawnData._maxUnitsToSpawn then
			local minions = {}
			for _, enemy in ipairs( FindAllUnits({team = DOTA_UNIT_TARGET_TEAM_ENEMY}) ) do
				if enemy:GetUnitName() == unitName then
					table.insert( minions, enemy )
				end
			end
			if #minions > 0 and #minions >= spawnData._maxUnitsToSpawn then -- upgrade an existing unit
				local unitToUpgrade = minions[RandomInt(1,#minions)]
				local bonusHP = unitToUpgrade.MaxEHP * RandomFloat( 0.8, 1.2 )
				local prevHP = unitToUpgrade:GetHealth()
				unitToUpgrade:SetCoreHealth( unitToUpgrade:GetMaxHealth() + bonusHP )
				unitToUpgrade:SetHealth( prevHP + bonusHP )
				unitToUpgrade:SetAverageBaseDamage( unitToUpgrade:GetAverageBaseDamage() + unitToUpgrade.AttackDamageValue, 10 )
				unitToUpgrade:SetModelScale( unitToUpgrade:GetModelScale() + 0.1 )
				ParticleManager:FireParticle("particles/econ/events/spring_2021/hero_levelup_spring_2021.vpcf", PATTACH_POINT_FOLLOW, unitToUpgrade )
				if not unitToUpgrade._wearingACrown then
					ParticleManager:ReleaseParticleIndex(  ParticleManager:CreateParticle( "particles/boss/minion_powerup_overhead.vpcf", PATTACH_OVERHEAD_FOLLOW, unitToUpgrade ) )
					unitToUpgrade._wearingACrown = true
				end
			end
		end
		
		self._currentlySpawningQueuedUnits[unitName] = true
		AddFOWViewer(DOTA_TEAM_GOODGUYS, vSpawnLocation, 400, 3, false)
		CreateUnitByNameAsync( unitName, vSpawnLocation, true, nil, nil, DOTA_TEAM_NEUTRALS,
		function(entUnit)
			
			target = entUnit:FindEnemyUnitsInRadius( vSpawnLocation, -1 )[1]
			if target then
				entUnit:MoveToPositionAggressive( target:GetAbsOrigin() )
			end
			
			entUnit._stageID = self._stageID
			self._gameRound._spawnedLivingUnits[self._stageID] = self._gameRound._spawnedLivingUnits[self._stageID] or {}
			table.insert( self._gameRound._spawnedLivingUnits[self._stageID], entUnit )
			entUnit.Holdout_IsCore = not spawnData.doNotRemoveFromQueue
			entUnit:SetDeathXP( 0 )
			bossManager:ProcessBossScaling(entUnit)
			entUnit:AddNewModifier( entUnit, nil, "modifier_rune_haste", {duration = 3} )
			entUnit:MakeVisibleToTeam(DOTA_TEAM_GOODGUYS, 2)
			
			self._currentlySpawningQueuedUnits[unitName] = false
		end)
	end
	return true
end


function CHoldoutGameSpawner:StatusReport()
	print( string.format( "** Spawner %s", self._szNPCClassName ) )
	print( string.format( "%d of %d spawned", self._nUnitsSpawnedThisRound, self._nTotalUnitsToSpawn ) )
end