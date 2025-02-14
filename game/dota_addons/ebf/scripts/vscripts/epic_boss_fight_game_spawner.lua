--[[
	CHoldoutGameSpawner - A single unit spawner for Holdout.
]]
if CHoldoutGameSpawner == nil then
	CHoldoutGameSpawner = class({})
end


function CHoldoutGameSpawner:ReadConfiguration( name, kv, gameRound )
	self._gameRound = gameRound
	self._dependentSpawners = {}

	self._szChampionNPCClassName = kv.ChampionNPCName or ""
	self._szGroupWithUnit = kv.GroupWithUnit or ""
	self._szName = name
	self._szNPCClassName = kv.NPCName or ""
	self._szSpawnerName = kv.SpawnerName or ""
	self._szWaitForUnit = kv.WaitForUnit or ""
	self._szWaypointName = kv.Waypoint or ""
	self._waypointEntity = nil

	self._nChampionLevel = tonumber( kv.ChampionLevel or 1 )
	self._nChampionMax = tonumber( kv.ChampionMax or 1 )
	self._nCreatureLevel = tonumber( kv.CreatureLevel or 1 )
	self._nTotalUnitsToSpawn = TernaryOperator( -1, kv.TotalUnitsToSpawn == 'X', tonumber( kv.TotalUnitsToSpawn or 0 ) )
	self._nTotalCoreUnitsToSpawn = 0
	if GameRules.BossKV[self._szNPCClassName] and GameRules.BossKV[self._szNPCClassName].ConsideredHero and tonumber( GameRules.BossKV[self._szNPCClassName].ConsideredHero ) == 1 then
		self._nTotalCoreUnitsToSpawn = self._nTotalUnitsToSpawn
	end	
	self._nUnitsPerSpawn = tonumber( kv.UnitsPerSpawn or 1 )
	self._nInitialUnitsSpawned = tonumber( kv.InitialUnitsSpawned or self._nUnitsPerSpawn )
	self._flChampionChance = tonumber( kv.ChampionChance or 0 )
	self._flInitialWait = tonumber( kv.WaitForTime or 0 )
	self._flSpawnInterval = tonumber( kv.SpawnInterval or 0 )

	self._bDontGiveGoal = ( tonumber( kv.DontGiveGoal or 0 ) ~= 0 )
	self._bDontOffsetSpawn = ( tonumber( kv.DontOffsetSpawn or 0 ) ~= 0 )
	self._NoCountScaling = tonumber(kv.NoCountScaling or "0") == 1
	
	-- modifiers
	if GameRules.BossKV[self._szNPCClassName] and GameRules.BossKV[self._szNPCClassName].ConsideredHero and tonumber( GameRules.BossKV[self._szNPCClassName].ConsideredHero ) == 1 then
		self._nTotalCoreUnitsToSpawn = self._nTotalUnitsToSpawn
	end
	if GetMapName() == "mayhem_gamemode" then
		if self._nTotalCoreUnitsToSpawn > 0 then
			self._flInitialWait = 0
			self._flSpawnInterval = 0
		end
	end
end


function CHoldoutGameSpawner:PostLoad( spawnerList )
	self._waitForUnit = spawnerList[ self._szWaitForUnit ]
	if self._szWaitForUnit ~= "" and not self._waitForUnit then
		print( "%s has a wait for unit %s that is missing from the round data.", self._szName, self._szWaitForUnit )
	elseif self._waitForUnit then
		table.insert( self._waitForUnit._dependentSpawners, self )
	end

	self._groupWithUnit = spawnerList[ self._szGroupWithUnit ]
	if self._szGroupWithUnit ~= "" and not self._groupWithUnit then
		print ("%s has a group with unit %s that is missing from the round data.", self._szName, self._szGroupWithUnit )
	elseif self._groupWithUnit then
		table.insert( self._groupWithUnit._dependentSpawners, self )
	end
end


function CHoldoutGameSpawner:Precache()
	PrecacheUnitByNameAsync( self._szNPCClassName, function( sg ) self._sg = sg end )
	if self._szChampionNPCClassName ~= "" then
		PrecacheUnitByNameAsync( self._szChampionNPCClassName, function( sg ) self._sgChampion = sg end )
	end
end


function CHoldoutGameSpawner:Begin()
	self._nUnitsSpawnedThisRound = 0
	self._nChampionsSpawnedThisRound = 0
	self._nUnitsCurrentlyAlive = 0
	
	self._vecSpawnLocation = nil
	if self._szSpawnerName ~= "" then
		local entSpawner = Entities:FindByName( nil, self._szSpawnerName )
		if not entSpawner then
			print( string.format( "Failed to find spawner named %s for %s\n", self._szSpawnerName, self._szName ) )
		end
		self._vecSpawnLocation = entSpawner:GetAbsOrigin()
	end
	self._entWaypoint = nil
	if self._szWaypointName ~= "" and not self._bDontGiveGoal then
		self._entWaypoint = Entities:FindByName( nil, self._szWaypointName )
		if not self._entWaypoint then
			print( string.format( "Failed to find waypoint named %s for %s", self._szWaypointName, self._szName ) )
		end
	end
	-- difficulty scaling for strategy
	if self._nTotalCoreUnitsToSpawn == 0 then
		self._nMaxUnitsToSpawn = self._nInitialUnitsSpawned + self._nUnitsPerSpawn * 2
	else
		if GetMapName() == "strategy_gamemode" then
			self._flInitialWait = self._flInitialWait * (1-GameRules.gameDifficulty*0.1666)
			self._flSpawnInterval = self._flSpawnInterval * (1-GameRules.gameDifficulty*0.1666)
		end
	end
	
	if self._waitForUnit ~= nil or self._groupWithUnit ~= nil then
		self._flNextSpawnTime = GameRules:GetGameTime()
	else
		self._flNextSpawnTime = GameRules:GetGameTime() + self._flInitialWait
	end
end


function CHoldoutGameSpawner:End()
	if self._sg ~= nil then
		UnloadSpawnGroupByHandle( self._sg )
		self._sg = nil
	end
	if self._sgChampion ~= nil then
		UnloadSpawnGroupByHandle( self._sgChampion )
		self._sgChampion = nil
	end
end


function CHoldoutGameSpawner:ParentSpawned( parentSpawner )
	if parentSpawner == self._groupWithUnit then
		-- Make sure we use the same spawn location as parentSpawner.
		self:_DoSpawn()
	elseif parentSpawner == self._waitForUnit then
		if parentSpawner:IsFinishedSpawning() and self._flNextSpawnTime == nil then
			self._flNextSpawnTime = parentSpawner._flNextSpawnTime + self._flInitialWait
		end
	end
end


function CHoldoutGameSpawner:Think()
	if not self._flNextSpawnTime then
		return
	end
	
	if GameRules:GetGameTime() >= self._flNextSpawnTime then
		if self._nTotalUnitsToSpawn == -1 then
			local unitsSpawned = 0
			local heroesAlive = 0
			for _, unit in ipairs( FindUnitsInRadius( DOTA_TEAM_NEUTRALS, Vector(0,0), nil, -1, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false) ) do
				if unit:GetUnitName() == self._szNPCClassName then
					unitsSpawned = unitsSpawned + 1
				end
				if unit:IsConsideredHero() then
					heroesAlive = heroesAlive + 1
				end
			end
			 -- wait with spawning if cap reached OR no heroes currently alive OR max units reached (initial + 2 spawns max)
			if heroesAlive == 0 then
				self._flNextSpawnTime = self._flNextSpawnTime + 1
				return
			end
		end
		
		self:_DoSpawn()
		for _,s in pairs( self._dependentSpawners ) do
			s:ParentSpawned( self )
		end
		if self:IsFinishedSpawning() then
			self._flNextSpawnTime = nil
			return
		else
			self._flNextSpawnTime = self._flNextSpawnTime + self._flSpawnInterval
			print( self._flNextSpawnTime, self._flSpawnInterval )
		end
	end
end


function CHoldoutGameSpawner:GetTotalUnitsToSpawn( coreOnly )
	if not coreOnly then
		return self._nTotalUnitsToSpawn
	else
		return self._nTotalCoreUnitsToSpawn
	end
end


function CHoldoutGameSpawner:IsFinishedSpawning()
	if self._nTotalUnitsToSpawn == -1 then -- spawn while any core unit is alive or must still be spawned
		return (self._gameRound._nCoreUnitsTotal - self._gameRound._nCoreUnitsKilled) <= 0
	else
		return (self._nTotalUnitsToSpawn <= self._nUnitsSpawnedThisRound) or ( self._groupWithUnit ~= nil )
	end
end


function CHoldoutGameSpawner:_GetSpawnLocation()
	if self._groupWithUnit then
		return self._groupWithUnit:_GetSpawnLocation()
	else
		return self._vecSpawnLocation
	end
end


function CHoldoutGameSpawner:_GetSpawnWaypoint()
	if self._groupWithUnit then
		return self._groupWithUnit:_GetSpawnWaypoint()
	else
		return self._entWaypoint
	end
end


function CHoldoutGameSpawner:_UpdateRandomSpawn()
	self._vecSpawnLocation = Vector( 0, 0, 0 )
	self._entWaypoint = nil

	local spawnInfo = self._gameRound:ChooseRandomSpawnInfo()
	if spawnInfo == nil then
		print( string.format( "Failed to get random spawn info for spawner %s.", self._szName ) )
		return
	end
	local entSpawner = Entities:FindByName( nil, spawnInfo.szSpawnerName )
	if not entSpawner then
		print( string.format( "Failed to find spawner named %s for %s.", spawnInfo.szSpawnerName, self._szName ) )
		return
	end
	self._vecSpawnLocation = entSpawner:GetAbsOrigin()

	if not self._bDontGiveGoal then
		self._entWaypoint = Entities:FindByName( nil, spawnInfo.szFirstWaypoint )
		if not self._entWaypoint then
			print( string.format( "Failed to find a waypoint named %s for %s.", spawnInfo.szFirstWaypoint, self._szName ) )
			return
		end
	end
end


function CHoldoutGameSpawner:_DoSpawn()
	local nUnitsToSpawn = self._nUnitsPerSpawn
	if self._nTotalUnitsToSpawn > 0 then
		nUnitsToSpawn = math.min( nUnitsToSpawn, self._nTotalUnitsToSpawn - self._nUnitsSpawnedThisRound )
	elseif self._nUnitsSpawnedThisRound == 0 then
		nUnitsToSpawn = self._nInitialUnitsSpawned
	end
	if self._currentlyAttemptingToSpawnUnit then return false end
	if nUnitsToSpawn <= 0 then
		return
	elseif self._nUnitsSpawnedThisRound == 0 then
		print( string.format( "Started spawning %s at %.2f", self._szName, GameRules:GetGameTime() ) )
	end

	if self._szSpawnerName == "" then
		self:_UpdateRandomSpawn()
	end
	for iUnit = 1,nUnitsToSpawn do
		local szNPCClassToSpawn = self._szNPCClassName
		
		local vBaseSpawnLocation = self:_GetSpawnLocation()
		self:_UpdateRandomSpawn()
		if not vBaseSpawnLocation then return end
		
		local vSpawnLocation = vBaseSpawnLocation
		if not self._bDontOffsetSpawn then
			vSpawnLocation = vSpawnLocation + RandomVector( RandomFloat( 0, 200 ) )
		end
		if self._nMaxUnitsToSpawn then
			local minions = {}
			for _, enemy in ipairs( FindAllUnits({team = DOTA_UNIT_TARGET_TEAM_ENEMY}) ) do
				if enemy:GetUnitName() == szNPCClassToSpawn then
					table.insert( minions, enemy )
				end
			end
			if #minions >= self._nMaxUnitsToSpawn then -- upgrade an existing unit
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
				return
			end
		end
		self._currentlyAttemptingToSpawnUnit = true
		
		AddFOWViewer(DOTA_TEAM_GOODGUYS, vSpawnLocation, 400, 3, false)
		CreateUnitByNameAsync( szNPCClassToSpawn, vSpawnLocation, true, nil, nil, DOTA_TEAM_NEUTRALS,
		function(entUnit)
			if entUnit:IsCreature() then
				if bIsChampion then
					self._nChampionsSpawnedThisRound = self._nChampionsSpawnedThisRound + 1
					entUnit:CreatureLevelUp( ( self._nChampionLevel - 1 ) )
					entUnit:SetChampion( true )
					local nParticle = ParticleManager:CreateParticle( "heavens_halberd", PATTACH_ABSORIGIN_FOLLOW, entUnit )
					ParticleManager:ReleaseParticleIndex( nParticle )
					entUnit:SetModelScale( 1.1, 0 )
				else
					entUnit:CreatureLevelUp( self._nCreatureLevel - 1 )
				end
			end
			entUnit._spawnerOrigin = self
			self._nUnitsSpawnedThisRound = self._nUnitsSpawnedThisRound + 1
			self._currentlyAttemptingToSpawnUnit = false
			
			target = entUnit:FindEnemyUnitsInRadius( vSpawnLocation, -1 )[1]
			if target then
				entUnit:MoveToPositionAggressive( target:GetAbsOrigin() )
			end
			-- local entWp = self:_GetSpawnWaypoint()
			-- if entWp ~= nil then
				-- entUnit:SetInitialGoalEntity( entWp )
			-- end
			self._nUnitsCurrentlyAlive = self._nUnitsCurrentlyAlive + 1
			entUnit.Holdout_IsCore = self._nTotalCoreUnitsToSpawn > 0
			entUnit:SetDeathXP( 0 )
			bossManager:ProcessBossScaling(entUnit)
			entUnit:AddNewModifier( entUnit, nil, "modifier_rune_haste", {duration = 3} )
			entUnit:MakeVisibleToTeam(DOTA_TEAM_GOODGUYS, 2)
		end)
	end
end


function CHoldoutGameSpawner:StatusReport()
	print( string.format( "** Spawner %s", self._szNPCClassName ) )
	print( string.format( "%d of %d spawned", self._nUnitsSpawnedThisRound, self._nTotalUnitsToSpawn ) )
end