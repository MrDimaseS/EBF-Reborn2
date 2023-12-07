EHP_PER_ARMOR = 0.01
DOTA_LIFESTEAL_SOURCE_NONE = 0
DOTA_LIFESTEAL_SOURCE_ATTACK = 1
DOTA_LIFESTEAL_SOURCE_ABILITY = 2

DOTA_RUNES = {DOTA_RUNE_DOUBLEDAMAGE,DOTA_RUNE_HASTE,DOTA_RUNE_ILLUSION,DOTA_RUNE_INVISIBILITY,DOTA_RUNE_REGENERATION,DOTA_RUNE_BOUNTY,DOTA_RUNE_ARCANE}

function Context_Wrap(o, funcname)
	return function(...) o[funcname](o, ...) end
end

function HasValInTable(checkTable, val)
	for key, value in pairs(checkTable) do
		if value == val then return true end
	end
	return false
end

function TernaryOperator(value, bCheck, default)
	if bCheck then 
		return value 
	else 
		return default
	end
end

function GetPerpendicularVector(vector)
	return Vector(vector.y, -vector.x)
end

function ActualRandomVector(maxLength, flMinLength)
	local minLength = flMinLength or 0
	return RandomVector(RandomInt(minLength, maxLength))
end

function HasBit(checker, value)
	return bit.band(checker, value) == value
end

function math.sum( lowLimit, upLimit, summation )
	if upLimit == 0 then return 0 end
	local sum = 0
	for i = lowLimit or 0, upLimit do
		sum = sum + summation
	end
	return sum
end

function math.sumT( lowLimit, upLimit, summation )
	if upLimit == 0 then return 0 end
	local sum = 0
	for i = lowLimit or 0, upLimit do
		sum = sum + summation * i
	end
	return sum
end

function splitString( input, seperator)
	seperator = seperator or "%s"
	local output = {}
	for str in input:gmatch("([^"..seperator.."]+)") do
		table.insert( output, str )
	end
	return output
end

function toboolean(thing)
	if type(thing) == "number" then
		if thing == 1 then return true
		elseif thing == 0 then return false
		else error("number type not 1 or 0") end
	elseif type(thing) == "string" then
		if thing == "true" or thing == "1" then return true
		elseif thing == "false" or thing == "0" then return false
		else error("string type not true or false") end
	end
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function CalculateDistance(ent1, ent2)
	local pos1 = ent1
	local pos2 = ent2
	if ent1.GetAbsOrigin then pos1 = ent1:GetAbsOrigin() end
	if ent2.GetAbsOrigin then pos2 = ent2:GetAbsOrigin() end
	local distance = (pos1 - pos2):Length2D()
	return distance
end

function CalculateDirection(ent1, ent2)
	local pos1 = ent1
	local pos2 = ent2
	if ent1.GetAbsOrigin then pos1 = ent1:GetAbsOrigin() end
	if ent2.GetAbsOrigin then pos2 = ent2:GetAbsOrigin() end
	local direction = (pos1 - pos2):Normalized()
	direction.z = 0
	return direction
end

function CDOTA_BaseNPC:CreateDummy(position, duration)
	local dummy = CreateUnitByName("npc_dummy_unit", position, false, nil, nil, self:GetTeam())
	dummy:AddNewModifier(self, nil, "modifier_hidden_generic", {})
	if duration and duration > 0 then
		local kill = dummy:AddNewModifier(self, nil, "modifier_kill", {duration = duration})
	end
	return dummy
end

function CDOTABaseAbility:CreateDummy(position, duration)
	local dummy = CreateUnitByName("npc_dummy_unit", position, false, nil, nil, self:GetCaster():GetTeam())
	dummy:AddNewModifier(self:GetCaster(), nil, "modifier_hidden_generic", {})
	if duration and duration > 0 then
		local kill = dummy:AddNewModifier(self, nil, "modifier_kill", {duration = duration})
	end
	return dummy
end

function CDOTA_BaseNPC_Hero:CreateSummon(unitName, position, duration)
	local summon = CreateUnitByName(unitName, position, true, self, nil, self:GetTeam())
	summon:SetControllableByPlayer(self:GetPlayerID(), true)
	self.summonTable = self.summonTable or {}
	table.insert(self.summonTable, summon)
	summon:SetOwner(self)
	if duration and duration > 0 then
		summon:AddNewModifier(self, nil, "modifier_kill", {duration = duration})
	end
	
	summon:StartGesture( ACT_DOTA_SPAWN )
	return summon
end

function CDOTA_BaseNPC:CreateSummon(unitName, position, duration)
	local summon = CreateUnitByName(unitName, position, true, self, nil, self:GetTeam())
	
	if duration and duration > 0 then
		summon:AddNewModifier(self, nil, "modifier_kill", {duration = duration})
	end
	
	summon:StartGesture( ACT_DOTA_SPAWN )
	return summon
end

function CDOTA_BaseNPC_Hero:RemoveSummon(entity)
	for id,ent in pairs(self.summonTable) do
		if ent == entity then
			table.remove(self.summonTable, id)
		end
	end
end

function CDOTA_BaseNPC:IsBeingAttacked()
	local enemies = FindUnitsInRadius(self:GetTeam(), self:GetAbsOrigin(), nil, 999999, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, 0, false)
	for _, enemy in pairs(enemies) do
		if enemy:IsAttackingEntity(self) then return true end
	end
	return false
end

function CDOTA_BaseNPC:PerformAbilityAttack(target, bProcs, ability)
	self.autoAttackFromAbilityState = {} -- basically the same as setting it to true
	self.autoAttackFromAbilityState.ability = ability
	self:PerformAttack(target,bProcs,bProcs,true,false,false,false,true)
	Timers:CreateTimer(function() self.autoAttackFromAbilityState = nil end)
end

function CDOTA_BaseNPC:PerformGenericAttack(target, immediate, neverMiss)
	self:PerformAttack(target, true, true, true, false, not immediate, false, neverMiss or false)
end

function CDOTA_Modifier_Lua:AttachEffect(pID)
	self:AddParticle(pID, false, false, 0, false, false)
end

function CDOTA_Modifier_Lua:GetSpecialValueFor(specVal)
	return self:GetAbility():GetSpecialValueFor(specVal)
end

function CDOTABaseAbility:DealDamage(attacker, victim, damage, data, spellText)
	--OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, OVERHEAD_ALERT_DAMAGE, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, OVERHEAD_ALERT_MANA_LOSS
	local internalData = data or {}
	local damageType =  internalData.damage_type or self:GetAbilityDamageType()
	if damageType == 0 or damageType == nil then
		damageType = DAMAGE_TYPE_MAGICAL
	end
	local damageFlags = internalData.damage_flags or DOTA_DAMAGE_FLAG_NONE
	local localdamage = damage or self:GetAbilityDamage() or 0
	local ability = self or internalData.ability
	
	if not IsEntitySafe( victim ) or not victim:IsAlive() then return end
	if not IsEntitySafe( attacker ) or not attacker:IsAlive() then return end
	if not IsEntitySafe( ability ) then return end
	
	local returnDamage = ApplyDamage({victim = victim, attacker = attacker, ability = ability, damage_type = damageType, damage = localdamage, damage_flags = damageFlags})
	if victim and IsEntitySafe( victim ) then
		if spellText then
			SendOverheadEventMessage( nil,spellText,victim,returnDamage,nil)
		end
	end
	
	return returnDamage
end

function IsEntitySafe( entity )
	return entity and IsValidEntity( entity ) and not entity:IsNull() 
end

function IsModifierSafe( entity )
	return entity and not entity:IsNull() 
end

function FindUnitsInCone(teamNumber, vDirection, vPosition, flSideRadius, flLength, hCacheUnit, targetTeam, targetUnit, targetFlags, findOrder, bCache)
	local vDirectionCone = Vector( vDirection.y, -vDirection.x, 0.0 )
	local enemies = FindUnitsInRadius(teamNumber, vPosition, hCacheUnit, flSideRadius + flLength, targetTeam, targetUnit, targetFlags, findOrder, bCache )
	local unitTable = {}
	if #enemies > 0 then
		for _,enemy in pairs(enemies) do
			if enemy ~= nil then
				local vToPotentialTarget = enemy:GetOrigin() - vPosition
				local flSideAmount = math.abs( vToPotentialTarget.x * vDirectionCone.x + vToPotentialTarget.y * vDirectionCone.y + vToPotentialTarget.z * vDirectionCone.z )
				local flLengthAmount = ( vToPotentialTarget.x * vDirection.x + vToPotentialTarget.y * vDirection.y + vToPotentialTarget.z * vDirection.z )
				if ( flSideAmount < flSideRadius ) and ( flLengthAmount > 0.0 ) and ( flLengthAmount < flLength ) then
					table.insert(unitTable, enemy)
				end
			end
		end
	end
	return unitTable
end


function CDOTA_BaseNPC:FindEnemyUnitsInCone(vDirection, vPosition, flSideRadius, flLength, hData)
	if not self:IsNull() then
		local vDirectionCone = Vector( vDirection.y, -vDirection.x, 0.0 )
		local team = self:GetTeamNumber()
		local data = hData or {}
		local iTeam = data.team or DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = data.type or DOTA_UNIT_TARGET_ALL
		local iFlag = data.flag or DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = data.order or FIND_ANY_ORDER
		local enemies = self:FindEnemyUnitsInRadius(vPosition, flSideRadius + flLength, hData)
		local unitTable = {}
		if #enemies > 0 then
			for _,enemy in pairs(enemies) do
				if enemy ~= nil then
					local vToPotentialTarget = enemy:GetOrigin() - vPosition
					local flSideAmount = math.abs( vToPotentialTarget.x * vDirectionCone.x + vToPotentialTarget.y * vDirectionCone.y + vToPotentialTarget.z * vDirectionCone.z )
					local flLengthAmount = ( vToPotentialTarget.x * vDirection.x + vToPotentialTarget.y * vDirection.y + vToPotentialTarget.z * vDirection.z )
					if ( flSideAmount < flSideRadius ) and ( flLengthAmount > 0.0 ) and ( flLengthAmount < flLength ) then
						table.insert(unitTable, enemy)
					end
				end
			end
		end
		return unitTable
	else return {} end
end

function CDOTA_BaseNPC:AddAbilityPrecache(abName)
	PrecacheItemByNameAsync( abName, function() end)
	return self:AddAbility(abName)
end

function AllPlayersAbandoned()
	local playerCounter = 0
	local dcCounter = 0
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
			playerCounter = playerCounter + 1
			local hero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
			if hero then
				if hero:HasOwnerAbandoned() then
					dcCounter = dcCounter + 1
				end
				if PlayerResource:GetConnectionState(hero:GetPlayerID()) == 3 then
					if not hero.lastActiveTime then hero.lastActiveTime = GameRules:GetGameTime() end
					if hero.lastActiveTime + 60*3 < GameRules:GetGameTime() then
						dcCounter = dcCounter + 1
					end
				else
					hero.lastActiveTime = GameRules:GetGameTime()
				end
			else
				dcCounter = dcCounter + 1
			end
		end
	end
	if dcCounter >= playerCounter then
		return true
	else
		return false
	end
end

function CDOTA_PlayerResource:FindActivePlayerCount()
	local playerCounter = 0
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
			local hero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
			if hero then
				if PlayerResource:GetConnectionState(hero:GetPlayerID()) == 2 then
					if not hero.lastActiveTime then hero.lastActiveTime = GameRules:GetGameTime() end
					if hero.lastActiveTime + 60*3 > GameRules:GetGameTime() then
						playerCounter = playerCounter + 1
					end
				end
			end
		end
	end
	return playerCounter
end

function CDOTA_PlayerResource:GetPatronTier(playerID)
	self.patronData = self.patronData or LoadKeyValues( "scripts/kv/patrons.kv" )
	local steamID = self:GetSteamID(playerID)
	local tier = tonumber( self.patronData[tostring(steamID)] ) or -1

	return tier
end

function MergeTables( t1, t2 )
    for name,info in pairs(t2) do
		if type(info) == "table"  and type(t1[name]) == "table" then
			MergeTables(t1[name], info)
		else
			t1[name] = info
		end
	end
end

function PrintAll(t)
	print( "-------",t,"-------" )
	for k,v in pairs(t) do
		print(k,v)
	end
end

function table.removekey(t1, key)
    for k,v in pairs(t1) do
		if k == key then
			table.remove(t1,k)
		end
	end
end

function table.removeval(t1, val)
    for k,v in pairs(t1) do
		if t1[k] == val then
			table.remove(t1,k)
		end
	end
end

function table.shuffle( tbl )
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
end

function table.copy(t1)
	if t1 == nil then
		return t1
	end
	if type(t1) == 'table' then
		local copy = {}
		for k,v in pairs(t1) do
			local kCopy = table.copy(k)
			local vCopy = table.copy(v)
			copy[kCopy] = vCopy
		end
		return copy
	else
		local copy = t1
		return copy
	end
end

function CDOTA_BaseNPC:HasTalent(talentName)
	if self:HasAbility(talentName) then
		if self:FindAbilityByName(talentName):GetLevel() > 0 then return true end
	end
	return false
end

function CDOTA_BaseNPC:HasActiveAbility()
	return self:GetCurrentActiveAbility() ~= nil or self:IsChanneling()
end

function FindAllEntitiesByClassname(name)
	local entList = {}
	local sortList = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0,0,0), nil, 99999, 3, 63, DOTA_UNIT_TARGET_FLAG_DEAD + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, -1, false)
	for _, unit in pairs(sortList) do
		if unit:GetClassname() == name then
			table.insert(entList, unit)
		end
	end
	return entList
end

function GetTableLength(rndTable)
	local counter = 0
	for k,v in pairs(rndTable) do
		counter = counter + 1
	end
	return counter
end

function CDOTA_BaseNPC:FindTalentValue(talentName, value)
	if self:HasAbility(talentName) then
		return self:FindAbilityByName(talentName):GetSpecialValueFor(value or "value")
	end
	return 0
end

function CDOTA_BaseNPC:NotDead()
	if self:IsAlive() or 
	self:IsReincarnating() or 
	self.resurrectionStoned then
		return true
	else
		return false
	end
end

function CDOTA_BaseNPC:SetCoreHealth(newHP)
	self:SetBaseMaxHealth(newHP)
	self:SetMaxHealth(newHP)
	self:SetHealth(newHP)
end

function CDOTA_BaseNPC:GetAverageBaseDamage()
	return (self:GetBaseDamageMax() + self:GetBaseDamageMin())/2
end

function CDOTA_BaseNPC:SetAverageBaseDamage(average, variance) -- variance is in percent (50 not 0.5)
	local var = variance or 0
	self:SetBaseDamageMax(average*(1+(var/100)))
	self:SetBaseDamageMin(average*(1+(var/100)))
end

function CDOTA_BaseNPC:GetAverageBaseDamageVariance()
	return ( 1 - self:GetBaseDamageMin()/self:GetAverageBaseDamage() ) * 100
end

function CDOTABaseAbility:Refresh()
	-- if not self:IsActivated() then
		-- self:SetActivated(true)
	-- end
	if self.delayedCooldownTimer then self:EndDelayedCooldown() end
    self:EndCooldown()
	if self:GetMaxAbilityCharges( self:GetLevel() ) > 0 then
		self:SetCurrentAbilityCharges( self:GetMaxAbilityCharges( self:GetLevel() ) )
	end
end

function CDOTABaseAbility:GetTrueCastRange()
	local castrange = self:GetCastRange(self:GetCaster():GetAbsOrigin(), self:GetCaster())
	castrange = castrange + self:GetCaster():GetCastRangeBonus()
	if castrange > 0 then
		castrange = castrange + self:GetCaster():GetCastRangeBonus()
	end
	return castrange
end

function CDOTA_BaseNPC:KillTarget()
	if not ( self:IsInvulnerable() or self:IsOutOfGame() or self:IsUnselectable() ) then
		self:ForceKill(true)
	end
end

function CDOTA_BaseNPC:GetAngleDifference(attacker)
	local lineOfAttack = CalculateDirection( attacker, self )
	local angleUnits = ToDegrees( math.acos( DotProduct( self:GetForwardVector(), lineOfAttack ) ) )
	return angleUnits
end

function CDOTA_BaseNPC:IsAtAngleWithEntity(attacker, flDesiredAngle)
	local angleDiff = self:GetAngleDifference(attacker)
	return angleDiff <= flDesiredAngle / 2
end
	
function CDOTA_BaseNPC:RefreshAllCooldowns(bItems)
    local no_refresh_skill = {["arc_warden_tempest_double"] = true, ["dazzle_good_juju"] = true, ["item_refresher"] = true, ["item_ex_machina"] = true, }
    for i = 0, self:GetAbilityCount() - 1 do
        local ability = self:GetAbilityByIndex( i )
        if ability and not no_refresh_skill[ability:GetAbilityName()] and ( ability.IsRefreshable == nil or ability:IsRefreshable() ) then
			ability:Refresh()
        end
    end
	if bItems then
		for i=DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
			local current_item = self:GetItemInSlot(i)
			if current_item ~= nil and not no_refresh_skill[current_item:GetAbilityName()] and ( current_item.IsRefreshable == nil or current_item:IsRefreshable() ) then
				current_item:Refresh()
			end
		end
		local neutralItem =	self:GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT)  
		if neutralItem and not no_refresh_skill[neutralItem:GetAbilityName()] and ( neutralItem.IsRefreshable == nil or neutralItem:IsRefreshable() ) then
			neutralItem:Refresh()
		end
	end
end

function CDOTABaseAbility:IsRearmable()
	return ( self.IsRefreshable == nil or self:IsRefreshable() )
end

function CDOTA_BaseNPC:ConjureImage( illusionInfo, duration, caster, amount )
	local illuInfo = illusionInfo or {}
	illuInfo.outgoing_damage = illuInfo.outgoing_damage or 0
	illuInfo.incoming_damage = illuInfo.incoming_damage or 0
	
	if self:IsHero() then
		local params = {caster = caster, target = self, duration = duration, ability = illuInfo.ability, modifier_name = "modifier_illusion"}
		local fDur = duration
		if fDur ~= -1 then
			fDur = duration * caster:GetStatusAmplification( params )
		end
		local illusionTable = CreateIllusions( caster or self , self, {outgoing_damage = illuInfo.outgoing_damage, incoming_damage = illuInfo.incoming_damage, duration = fDur}, amount or 1, self:GetHullRadius() + self:GetCollisionPadding(), illuInfo.scramble or false, true )
		if not illusionTable then return end
		for _, illusion in ipairs( illusionTable ) do
			local trueParent = self
			if self.unitOwnerEntity then
				trueParent = self.unitOwnerEntity
			end
			illusion:SetPhysicalArmorBaseValue( self:GetPhysicalArmorBaseValue() )
			for _, modifier in ipairs( self:FindAllModifiers() ) do
				if modifier.AllowIllusionDuplicate and modifier:AllowIllusionDuplicate() then
					illusion:AddNewModifier( modifier:GetCaster(), modifier:GetAbility(), modifier:GetName(), {duration = modifier:GetRemainingTime()} ):SetStackCount( modifier:GetStackCount() )
				end
			end
			for i = 0, 23 do
				local ability = illusion:GetAbilityByIndex( i )
				if ability then
					ability:SetActivated( false )
					local ownerAbility = self:GetAbilityByIndex( i )
					if ownerAbility then
						ability:SetCooldown (  ownerAbility:GetCooldownTimeRemaining() )
						if ownerAbility:GetAutoCastState() then
							ability:ToggleAutoCast()
						end
					end
				end
			end
			illusion:SetHealth( math.min( illusion:GetMaxHealth(), math.max( self:GetHealth(), 1 ) ) )
			illusion:SetOwner(caster or self)
			illusion:SetMaximumGoldBounty( 0 )
			illusion:SetMinimumGoldBounty( 0 )
			if illuInfo.controllable == false then
				illusion:SetControllableByPlayer(-1, true)
			end
			if illuInfo.position then
				FindClearSpaceForUnit( illusion, illuInfo.position, true )
			end
			if illuInfo.illusion_modifier then
				illusion:AddNewModifier( caster or self, illuInfo.ability, illuInfo.illusion_modifier, {} )
			end
			illusion.hasBeenInitialized = true
			Timers:CreateTimer(0.1, function() ResolveNPCPositions( illusion:GetAbsOrigin(), 128 ) end )
		end
		return illusionTable
	else
		local illusionTable = {}
		local owner = caster or self
		for i = 1, (amount or 1) do
			local illusion = CreateUnitByName( self:GetUnitName(), illuInfo.position or self:GetAbsOrigin(), true, owner, owner, owner:GetTeamNumber() )
			if illuInfo.illusion_modifier then
				illusion:AddNewModifier( caster or self, illuInfo.ability, illuInfo.illusion_modifier, {duration = duration} )
			else
				illusion:AddNewModifier( caster or self, illuInfo.ability, "modifier_illusion", {duration = duration} )
			end
			illusion:AddNewModifier( caster or self, illuInfo.ability, "modifier_kill", {duration = duration} )
			illusion:SetOwner(caster or self)
			for i = 0, 23 do
				local ability = illusion:GetAbilityByIndex( i )
				if ability then
					ability:SetActivated( false )
					local ownerAbility = self:GetAbilityByIndex( i )
					if ownerAbility then
						ability:SetCooldown (  ownerAbility:GetCooldownTimeRemaining() )
					end
				end
			end
			for itemSlot=0,5 do
				local item = self:GetItemInSlot(itemSlot)
				if item ~= nil then
					local itemName = item:GetName()
					local newItem = self:GetItemInSlot(itemSlot)
					if not newItem then
						newItem = self:AddItemByName( itemName )
					end
				end
			end	
			illusion:SetBaseDamageMax( self:GetBaseDamageMax() - 10 )
			illusion:SetBaseDamageMin( self:GetBaseDamageMin() - 10 )
			illusion:SetPhysicalArmorBaseValue( self:GetPhysicalArmorBaseValue() )
			illusion:SetBaseAttackTime( self:GetBaseAttackTime() )
			illusion:SetBaseMoveSpeed( self:GetBaseMoveSpeed() )
			illusion:SetMaximumGoldBounty( 0 )
			illusion:SetMinimumGoldBounty( 0 )
			if illuInfo.controllable == false then
				illusion:SetControllableByPlayer(-1, true)
			else
				illusion:SetControllableByPlayer(caster:GetPlayerID(), true)
			end
			Timers:CreateTimer(0.1, function() ResolveNPCPositions( illusion:GetAbsOrigin(), 128 ) end )
			table.insert( illusionTable, illusion )
		end
		return illusionTable
	end
end

function CDOTA_BaseNPC:GetTauntTarget()
	return self._currentlyBeingTauntedBy
end

function CDOTA_BaseNPC:SetTauntTarget( entity )
	self._currentlyBeingTauntedBy = entity
end

function CDOTABaseAbility:IsInnateAbility()
	local truefalse = tonumber( self:GetAbilityKeyValues().InnateAbility ) or 0
	if truefalse == 1 then
		return true
	else
		return false
	end
end

function CDOTA_BaseNPC:IsSlowed()
	return self:GetIdealSpeed() < self:GetIdealSpeedNoSlows()
end

function CDOTA_BaseNPC:IsLeashed()
	for _, modifier in ipairs( self:FindAllModifiers() ) do
		local tState = {}
		modifier:CheckStateToTable(tState)
		if tState[tostring(MODIFIER_STATE_TETHERED)] then
			return true
		end
	end
	return false
end

function CDOTA_BaseNPC:IsDisabled()
	if self:IsSlowed() or self:IsStunned() or self:IsRooted() or self:IsSilenced() or self:IsHexed() or self:IsDisarmed() then 
		return true
	else return false end
end

function CDOTA_BaseNPC:GetPhysicalArmorMultiplier()
	local armorNPC = self:GetPhysicalArmorValue(false)
	local armor_reduction = CalculatePhysicalArmorMultiplier( armorNPC )
	return armor_reduction
end

function CalculatePhysicalArmorMultiplier( armor )
	return 1 - (0.06 * armor) / (1 + 0.06 * math.abs(armor))
end


function CDOTA_BaseNPC:GetPhysicalArmorReduction()
	local armornpc = self:GetPhysicalArmorValue(false)
	local armor_reduction = self:GetPhysicalArmorMultiplier()
	armor_reduction = 100 - (armor_reduction * 100)
	return armor_reduction
end

function CDOTA_BaseNPC:GetRealPhysicalArmorReduction()
	local armornpc = self:GetPhysicalArmorValue()
	local armor_reduction = 1 - (EHP_PER_ARMOR * armornpc) / (1 + (EHP_PER_ARMOR * math.abs(armornpc)))
	armor_reduction = 100 - (armor_reduction * 100)
	return armor_reduction
end

function CDOTA_BaseNPC:FindModifierByAbility(abilityname)
	local modifiers = self:FindAllModifiers()
	local returnTable = {}
	for _,modifier in pairs(modifiers) do
		if modifier:GetAbility():GetName() == abilityname then
			table.insert(returnTable, modifier)
		end
	end
	return returnTable
end

function CDOTA_BaseNPC:FindModifierByNameAndAbility( modifierName, ability )
	local modifiers = self:FindAllModifiersByName( modifierName )
	local returnTable = {}
	for _,modifier in pairs(modifiers) do
		if modifier:GetAbility() == ability then
			return modifier
		end
	end
end

function CDOTA_BaseNPC:IsFakeHero()
	if self:IsIllusion() 
	or (self:HasModifier("modifier_monkey_king_fur_army_soldier") or self:HasModifier("modifier_monkey_king_fur_army_soldier_hidden")) 
	or self:IsTempestDouble() or self:IsClone()
	or self:GetUnitLabel() == "spirit_bear" then
		return true
	else return false end
end

function CDOTABaseAbility:GetTalentSpecialValueFor(value)
	local base = self:GetSpecialValueFor(value)
	local talentName
	local valname = "value"
	local multiply = false
	local kv = self:GetAbilityKeyValues()
	for k,v in pairs(kv) do -- trawl through keyvalues
		if k == "AbilitySpecial" then
			for l,m in pairs(v) do
				if m[value] then
					talentName = m["LinkedSpecialBonus"]
					if m["LinkedSpecialBonusField"] then valname = m["LinkedSpecialBonusField"] end
					if m["LinkedSpecialBonusOperation"] and m["LinkedSpecialBonusOperation"] == "SPECIAL_BONUS_MULTIPLY" then multiply = true end
				end
			end
		end
	end
	if talentName then 
		local talent = self:GetCaster():FindAbilityByName(talentName)
		if talent and talent:GetLevel() > 0 then 
			if multiply then
				base = base * talent:GetSpecialValueFor(valname) 
			else
				base = base + talent:GetSpecialValueFor(valname) 
			end
		end
	end
	return base
end

function CDOTA_Modifier_Lua:GetTalentSpecialValueFor(value)
	return self:GetAbility():GetTalentSpecialValueFor(value)
end

function CDOTA_Buff:HasBeenRefreshed()
	if self:GetCreationTime() + self:GetDuration() < self:GetDieTime() then -- if original destroy time is smaller than new destroy time
		return true
	else
		return false
	end
end

function CDOTABaseAbility:SetCooldown(fCD)
	if fCD then
		self:EndCooldown()
		self:StartCooldown(fCD)
	else
		self:UseResources(false, false, false, true)
	end
end

function CDOTABaseAbility:SpendAbilityCharge()
	local abilityChargeRestoreTime = self:GetAbilityChargeRestoreTime(-1) * (1-self:GetCaster():GetCooldownReduction())
	self:SetCurrentAbilityCharges( self:GetCurrentAbilityCharges() - 1 )
	if self:GetCurrentAbilityCharges() == 0 then
		self:SetCooldown(abilityChargeRestoreTime)
	end
end

function CDOTABaseAbility:ModifyCooldown(amt)
	local currCD = self:GetCooldownTimeRemaining()
	self:EndCooldown()
	self:StartCooldown(currCD + amt)
end

function CScriptHeroList:GetRealHeroes()
	local heroes = self:GetAllHeroes()
	local realHeroes = {}
	for _,hero in pairs(heroes) do
		if not hero:IsFakeHero() then
			table.insert(realHeroes, hero)
		end
	end
	return realHeroes
end

function CScriptHeroList:GetRealHeroCount()
	return #self:GetRealHeroes()
end

function CScriptHeroList:GetActiveHeroes()
	local heroes = self:GetRealHeroes()
	local activeHeroes = {}
	for _, hero in pairs(heroes) do
		if hero:GetPlayerOwner() then
			table.insert(activeHeroes, hero)
		end
	end
	return activeHeroes
end

function CScriptHeroList:GetActiveHeroCount()
	return #self:GetActiveHeroes()
end

function RotateVector2D(vector, theta)
    local xp = vector.x*math.cos(theta)-vector.y*math.sin(theta)
    local yp = vector.x*math.sin(theta)+vector.y*math.cos(theta)
    return Vector(xp,yp,vector.z):Normalized()
end

function ToRadians(degrees)
	return degrees * math.pi / 180
end

function ToDegrees(radians)
	return radians * 180 / math.pi 
end

function CDOTA_BaseNPC:IsSameTeam(unit)
	return (self:GetTeamNumber() == unit:GetTeamNumber())
end

function CDOTA_BaseNPC:HealEvent(amount, sourceAb, healer)
	local healBonus = 1
	local flAmount = amount
	if healer then
		for _,modifier in ipairs( healer:FindAllModifiers() ) do
			if modifier.GetOnHealBonus then
				healBonus = healBonus + ((modifier:GetOnHealBonus() or 0)/100)
			end
		end
	end
	
	flAmount = flAmount * healBonus
	local params = {amount = flAmount, source = sourceAb, unit = healer, target = self}
	-- local units = self:FindAllUnitsInRadius(self:GetAbsOrigin(), -1)
	
	-- for _, unit in ipairs(units) do
		-- if unit.FindAllModifiers then
			-- for _, modifier in ipairs( unit:FindAllModifiers() ) do
				-- if modifier.OnHealed then
					-- modifier:OnHealed(params)
				-- end
				-- if modifier.OnHeal then
					-- modifier:OnHeal(params)
				-- end
				-- if modifier.OnHealRedirect then
					-- local reduction = modifier:OnHealRedirect(params) or 0
					-- flAmount = flAmount + reduction
				-- end
			-- end
		-- end
	-- end
	local preHP = self:GetHealth()
	self:HealWithParams(flAmount, sourceAb, false, true, healer, false)
	local postHP = self:GetHealth()
	SendOverheadEventMessage(self, OVERHEAD_ALERT_HEAL, self, postHP - preHP, healer)
	return postHP - preHP
end

function CDOTA_BaseNPC:SwapAbilityIndexes(index, swapname)
	local ability = self:GetAbilityByIndex(index)
	local swapability = self:FindAbilityByName(swapname)
	self:SwapAbilities(ability:GetName(), swapname, false, true)
	swapability:SetAbilityIndex(index)
end

function FindAllUnits()
	local team = DOTA_TEAM_GOODGUYS
	local data = hData or {}
	local iTeam = data.team or DOTA_UNIT_TARGET_TEAM_BOTH
	local iType = data.type or DOTA_UNIT_TARGET_ALL
	local iFlag = data.flag or DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD + DOTA_UNIT_TARGET_FLAG_DEAD
	local iOrder = data.order or FIND_ANY_ORDER
	return FindUnitsInRadius(team, Vector(0,0), nil, -1, iTeam, iType, iFlag, iOrder, false)
end

function CDOTA_BaseNPC:FindEnemyUnitsInLine(startPos, endPos, width, hData)
	local team = self:GetTeamNumber()
	local data = hData or {}
	local iTeam = data.team or DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = data.type or DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = data.flag or DOTA_UNIT_TARGET_FLAG_NONE
	return FindUnitsInLine(team, startPos, endPos, nil, width, iTeam, iType, iFlag)
end

function CDOTA_BaseNPC:FindFriendlyUnitsInLine(startPos, endPos, width, hData)
	local team = self:GetTeamNumber()
	local data = hData or {}
	local iTeam = data.team or DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = data.type or DOTA_UNIT_TARGET_ALL
	local iFlag = data.flag or DOTA_UNIT_TARGET_FLAG_NONE
	return FindUnitsInLine(team, startPos, endPos, nil, width, iTeam, iType, iFlag)
end

function CDOTA_BaseNPC:FindAllUnitsInLine(startPos, endPos, width, hData)
	local team = self:GetTeamNumber()
	local data = hData or {}
	local iTeam = data.team or DOTA_UNIT_TARGET_TEAM_BOTH
	local iType = data.type or DOTA_UNIT_TARGET_ALL
	local iFlag = data.flag or DOTA_UNIT_TARGET_FLAG_NONE
	return FindUnitsInLine(team, startPos, endPos, nil, width, iTeam, iType, iFlag)
end

function CDOTA_BaseNPC:FindEnemyUnitsInRing(position, maxRadius, minRadius, hData)
	if not self:IsNull() then
		local team = self:GetTeamNumber()
		local data = hData or {}
		local iTeam = data.team or DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = data.type or DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
		local iFlag = data.flag or DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = data.order or FIND_ANY_ORDER
	
		local innerRing = FindUnitsInRadius(team, position, nil, minRadius, iTeam, iType, iFlag, iOrder, false)
		local outerRing = FindUnitsInRadius(team, position, nil, maxRadius, iTeam, iType, iFlag, iOrder, false)
		local resultTable = {}
		for _, unit in ipairs(outerRing) do
			if not unit:IsNull() then
				local addToTable = true
				for _, exclude in ipairs(innerRing) do
					if unit == exclude then
						addToTable = false
						break
					end
				end
				if addToTable then
					table.insert(resultTable, unit)
				end
			end
		end
		return resultTable
		
	else return {} end
end

function CDOTA_BaseNPC:FindEnemyUnitsInRadius(position, radius, hData)
	if not self:IsNull() then
		local team = self:GetTeamNumber()
		local data = hData or {}
		local iTeam = data.team or DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = data.type or DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
		local iFlag = data.flag or DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = data.order or FIND_ANY_ORDER
		return FindUnitsInRadius(team, position, nil, radius, iTeam, iType, iFlag, iOrder, false)
	else return {} end
end

function CDOTA_BaseNPC:FindFriendlyUnitsInRadius(position, radius, hData)
	local team = self:GetTeamNumber()
	local data = hData or {}
	local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	local iType = data.type or DOTA_UNIT_TARGET_ALL
	local iFlag = data.flag or DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = data.order or FIND_ANY_ORDER
	return FindUnitsInRadius(team, position, nil, radius, iTeam, iType, iFlag, iOrder, false)
end

function CDOTA_BaseNPC:FindAllUnitsInRadius(position, radius, hData)
	local team = self:GetTeamNumber()
	local data = hData or {}
	local iTeam = data.team or DOTA_UNIT_TARGET_TEAM_BOTH
	local iType = data.type or DOTA_UNIT_TARGET_ALL
	local iFlag = data.flag or DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = data.order or FIND_ANY_ORDER
	return FindUnitsInRadius(team, position, nil, radius, iTeam, iType, iFlag, iOrder, false)
end

function ParticleManager:FireWarningParticle(position, radius)
	local thinker = ParticleManager:CreateParticle("particles/ui_mouseactions/range_finder_ward_aoe_ring.vpcf", PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControl(thinker, 2, position)
			ParticleManager:SetParticleControl(thinker, 3, Vector(radius,0,0))
	Timers:CreateTimer( 0.5, function() ParticleManager:ClearParticle( thinker ) end )
end

function ParticleManager:FireGenericWarningParticle( position, endPos, radius )
	local thinker = ParticleManager:CreateParticle("particles/ui_mouseactions/range_finder_tower_aoe.vpcf", PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControl(thinker, 0, position)
			ParticleManager:SetParticleControl(thinker, 2, endPos)
			ParticleManager:SetParticleControl(thinker, 3, Vector(radius,0,0))
			ParticleManager:SetParticleControl(thinker, 4, Vector(255,0,0))
			ParticleManager:SetParticleControl(thinker, 6, Vector(radius,0,0))
			ParticleManager:SetParticleControl(thinker, 7, position )
	Timers:CreateTimer( 0.5, function()
		ParticleManager:ClearParticle( thinker ) 
	end )
end

function ParticleManager:FireLinearWarningParticle(vStartPos, vEndPos, vWidth)
	local width = Vector(vWidth, vWidth, vWidth)
	local fx = ParticleManager:FireParticle("particles/ui_mouseactions/range_ability_line.vpcf", PATTACH_WORLDORIGIN, nil, {[0] = vStartPos,
																											[1] = vEndPos,
																											[2] = width} )																						
end

function ParticleManager:FireTargetWarningParticle(target)
	local fx = ParticleManager:CreateParticle("particles/ui_mouseactions/generic_marker.vpcf", PATTACH_OVERHEAD_FOLLOW, target)
end

function ParticleManager:FireParticle(effect, attach, owner, cps)
	local FX = ParticleManager:CreateParticle(effect, attach, owner)
	if cps then
		for cp, value in pairs(cps) do
			if type(value) == "userdata" then
				ParticleManager:SetParticleControl(FX, tonumber(cp), value)
			else
				ParticleManager:SetParticleControlEnt(FX, cp, owner, attach, value, owner:GetAbsOrigin(), true)
			end
		end
	end
	ParticleManager:ReleaseParticleIndex(FX)
end

function ParticleManager:FireRopeParticle(effect, attach, owner, target, tCP)
	local FX = ParticleManager:CreateParticle(effect, attach, owner)

	ParticleManager:SetParticleControlEnt(FX, 0, owner, attach, "attach_hitloc", owner:GetAbsOrigin(), true)
	if target.GetAbsOrigin then -- npc (has getabsorigin function
		ParticleManager:SetParticleControlEnt(FX, 1, target, attach, "attach_hitloc", target:GetAbsOrigin(), true)
	else
		ParticleManager:SetParticleControl(FX, 1, target) -- vector
	end
	
	if tCP then
		for cp, value in pairs(tCP) do
			ParticleManager:SetParticleControl(FX, tonumber(cp), value)
		end
	end
	
	ParticleManager:ReleaseParticleIndex(FX)
end


function ParticleManager:CreateRopeParticle(effect, attach, owner, target, tCP)
	local FX = ParticleManager:CreateParticle(effect, attach, owner)

	ParticleManager:SetParticleControlEnt(FX, 0, owner, attach, "attach_hitloc", owner:GetAbsOrigin(), true)
	if target.GetAbsOrigin then -- npc (has getabsorigin function
		ParticleManager:SetParticleControlEnt(FX, 1, target, attach, "attach_hitloc", target:GetAbsOrigin(), true)
	else
		ParticleManager:SetParticleControl(FX, 1, target) -- vector
	end
	
	if tCP then
		for cp, value in pairs(tCP) do
			ParticleManager:SetParticleControl(FX, tonumber(cp), value)
		end
	end
	
	return FX
end

function ParticleManager:ClearParticle(cFX)
	if cFX then
		self:DestroyParticle(cFX, false)
		self:ReleaseParticleIndex(cFX)
	end
end

function CDOTA_Modifier_Lua:StartMotionController()
	if not self:GetParent():IsNull() and not self:IsNull() and self.DoControlledMotion and self:GetParent():HasMovementCapability() then
		self:GetParent():StopMotionControllers()
		self:GetParent():InterruptMotionControllers(true)
		self.controlledMotionTimer = Timers:CreateTimer(function()
			if pcall( function() self:DoControlledMotion() end ) then
				return 0.03
			elseif not self:IsNull() then
				self:Destroy()
			end
		end)
	else
	end
end

function CDOTA_Modifier_Lua:AddIndependentStack(duration, limit, bDontDestroy, tTimerTable)
	local timerTable = tTimerTable or {}
	self.stackTimers = self.stackTimers or {}
	if limit then
		if  self:GetStackCount() < limit then
			if timerTable.stacks then
				self:SetStackCount( math.min( limit, self:GetStackCount() + timerTable.stacks ) )
			else
				self:IncrementStackCount()
			end
		elseif self.stackTimers[1] and #self.stackTimers >= limit then
			self:SetStackCount( limit )
			Timers:RemoveTimer(self.stackTimers[1].ID)
			table.remove(self.stackTimers, 1)
		end
	else
		if timerTable.stacks then
			self:SetStackCount( self:GetStackCount() + timerTable.stacks )
		else
			self:IncrementStackCount()
		end
	end
	local dontDestroy = bDontDestroy
	if bDontDestroy == nil then dontDestroy = true end
	timerTable.ID = Timers:CreateTimer(duration or self:GetRemainingTime(), function(timer)
		if not self:IsNull() then
			if timerTable.stacks then	
				self:SetStackCount( math.max( 0, self:GetStackCount() - timerTable.stacks ) )
			else
				self:DecrementStackCount()
			end
			for i = #self.stackTimers, 1, -1 do
				if timer.name == self.stackTimers[i].ID then
					table.remove(self.stackTimers, pos)
					break
				end
			end
			if self:GetStackCount() == 0 and self:GetDuration() == -1 and not dontDestroy then self:Destroy() end
		end
	end)
	
	table.insert(self.stackTimers, timerTable or {})
end

function CDOTA_Modifier_Lua:StopMotionController(bForceDestroy)
	FindClearSpaceForUnit(self:GetParent(), self:GetParent():GetAbsOrigin(), true)
	if self.controlledMotionTimer then Timers:RemoveTimer(self.controlledMotionTimer) end
	self:Destroy()
end

function CDOTA_BaseNPC:StopMotionControllers(bForceDestroy)
	if self.InterruptMotionControllers then self:InterruptMotionControllers(true) end
	for _, modifier in ipairs( self:FindAllModifiers() ) do
		if modifier.controlledMotionTimer then 
			modifier:StopMotionController(bForceDestroy)
		end
	end
end

function CDOTA_Modifier_Lua:AddEffect(id)
	self:AddParticle(id, false, false, 0, false, false)
end

function CDOTA_Buff:AddEffect(id)
	self:AddParticle(id, false, false, 0, false, false)
end

function CDOTA_Buff:AddStatusEffect(id, priority)
	self:AddParticle(id, false, true, priority, false, false)
end

function CDOTA_Buff:AddOverHeadEffect(id)
	self:AddParticle(id, false, false, 0, false, true)
end

function CDOTA_Buff:AddHeroEffect(id)
	self:AddParticle(id, false, false, 0, true, false)
end

function CDOTA_BaseNPC:FindRandomEnemyInRadius(position, radius, data)
	for _, unit in ipairs(self:FindEnemyUnitsInRadius(position, radius, data)) do
		return unit
	end
end

function CDOTA_BaseNPC:Blink(position, blinkData)
	if self:IsNull() then return end
	local vPos = position
	local tData = blinkData or {}
	EmitSoundOn("DOTA_Item.BlinkDagger.Activate", self)
	if tData.FX == true or tData.FX == nil then
		ParticleManager:FireParticle("particles/items_fx/blink_dagger_start.vpcf", PATTACH_ABSORIGIN, self, {[0] = self:GetAbsOrigin()})
	end
	local distance = CalculateDistance( self, position )
	
	if tData.distance and distance > tData.distance then
		if tData.clamp then
			vPos = self:GetAbsOrigin() + CalculateDirection( vPos, self ) * tData.clamp
		else
			vPos = self:GetAbsOrigin() + CalculateDirection( vPos, self ) * tData.distance
		end
	else
		EmitSoundOn("DOTA_Item.BlinkDagger.NailedIt", self)
	end
	
	FindClearSpaceForUnit(self, vPos, true)
	ProjectileManager:ProjectileDodge( self )
	if bFX == true or bFX == nil then
		ParticleManager:FireParticle("particles/items_fx/blink_dagger_end.vpcf", PATTACH_ABSORIGIN, self, {[0] = self:GetAbsOrigin()})
	end
end

function CDOTA_BaseNPC:GetStrength()
	return 0
end

function CDOTA_BaseNPC:GetAgility()
	return 0
end

function CDOTA_BaseNPC:GetIntellect()
	return 0
end

function CDOTA_BaseNPC:Dispel(hCaster, bHard)
	local sameTeam = (hCaster:GetTeam() == self:GetTeam())
	local hardDispel = bHard
	if hardDispel == nil then hardDispel = false end
	self:Purge(not sameTeam, sameTeam, false, hardDispel, hardDispel)
end

function CDOTA_BaseNPC:SmoothFindClearSpace(position)
	self:SetAbsOrigin(position)
	ResolveNPCPositions(position, self:GetHullRadius() + self:GetCollisionPadding())
end

function CDOTABaseAbility:Stun(target, duration, effectName, effectData)
	if not target or target:IsNull() then return end
	local stun = target:AddNewModifier(self:GetCaster(), self, "modifier_stunned", {duration = duration})
	if effectName then
		local FX = ParticleManager:CreateParticle(effectName, PATTACH_POINT_FOLLOW, target)
		if effectData then
			for cp, value in pairs(effectData) do
				if type(value) == "userdata" then
					ParticleManager:SetParticleControl(FX, tonumber(cp), value)
				else
					ParticleManager:SetParticleControlEnt(FX, cp, target, attach, value, target:GetAbsOrigin(), true)
				end
			end
		end
		stun:AddEffect( FX )
	end
	return stun
end

function CDOTABaseAbility:Silence(target, duration)
	return target:AddNewModifier(self:GetCaster(), self, "modifier_silence", {duration = duration})
end

function CDOTABaseAbility:FireLinearProjectile(FX, velocity, distance, width, data)
	local internalData = data or {}
	local info = {
		EffectName = FX,
		Ability = self,
		vSpawnOrigin = internalData.origin or self:GetCaster():GetAbsOrigin(), 
		fStartRadius = width,
		fEndRadius = internalData.width_end or width,
		vVelocity = velocity,
		fDistance = distance,
		Source = internalData.source or self:GetCaster(),
		iUnitTargetTeam = internalData.team or DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = internalData.type or DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		ExtraData = internalData.extraData
	}
	return ProjectileManager:CreateLinearProjectile( info )
end

function CDOTAGameRules:GetMaxRound()
	return GameRules.maxRounds
end

function CDOTAGameRules:GetCurrentRound()
	return GameRules._roundnumber
end

function CDOTA_BaseNPC:AddNewModifierStacking( caster, ability, modifierName, modifierData)
	local modifier = self:FindModifierByNameAndAbility( modifierName, ability )
	if modifier then
		modifierData.duration = (modifierData.duration or modifierData.Duration or 0) + modifier:GetRemainingTime()
		modifierData.Duration = nil
		return self:AddNewModifier( caster, ability, modifierName, modifierData )
	else
		return self:AddNewModifier( caster, ability, modifierName, modifierData )
	end
end

function CDOTA_BaseNPC:AttemptKill(sourceAb, attacker)
	ApplyDamage({victim = self, attacker = attacker, ability = sourceAb, damage_type = DAMAGE_TYPE_PURE, damage = self:GetMaxHealth() + 1, damage_flags = DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS})
	return not self:IsAlive()
end

function CDOTA_BaseNPC:ApplyKnockBack(position, stunDuration, knockbackDuration, distance, height, caster, ability)
	local caster = caster or nil
	local ability = ability or nil

	local modifierKnockback = {
		center_x = position.x,
		center_y = position.y,
		center_z = position.z,
		should_stun = TernaryOperator( 1, stunDuration and stunDuration > 0, 0 ),
		duration = math.max( knockbackDuration, stunDuration ),
		knockback_duration = knockbackDuration,
		knockback_distance = distance,
		knockback_height = height,
	}
	return self:AddNewModifier(caster, ability, "modifier_knockback", modifierKnockback )
end

function CDOTA_BaseNPC:IsKnockedBack()
	if self:HasModifier("modifier_knockback") then
		return true
	else
		return false
	end
end

function CDOTABaseAbility:CastSpell(target)
	local caster = self:GetCaster()
	if target then
		if target.GetAbsOrigin then -- npc
			caster:SetCursorCastTarget(target)
			caster:SetCursorPosition(target:GetAbsOrigin())
		else
			caster:SetCursorPosition(target)
		end
	end
	self:OnSpellStart()
	self:UseResources(true, true, true, true)
end

function CDOTA_BaseNPC:InWater()
	if self:HasModifier("modifier_in_water") then
		return true
	else
		return false
	end
end

function CDOTA_BaseNPC:HasShard()
	return self:HasModifier("modifier_item_aghanims_shard")
end

function CDOTABaseAbility:FireTrackingProjectile(FX, target, speed, data, iAttach, bDodge, bVision, vision)
	local internalData = data or {}
	local dodgable = true
	if bDodge ~= nil then dodgable = bDodge end
	local provideVision = false
	if bVision ~= nil then provideVision = bVision end
	local origin = self:GetCaster():GetAbsOrigin()
	if internalData.origin then
		origin = internalData.origin
	elseif internalData.source then
		origin = internalData.source:GetAbsOrigin()
	end
	local projectile = {
		Target = target,
		Source = internalData.source or self:GetCaster(),
		Ability = self,	
		EffectName = FX,
	    iMoveSpeed = speed,
		vSourceLoc= origin or self:GetCaster():GetAbsOrigin(),
		bDrawsOnMinimap = false,
        bDodgeable = dodgable,
        bIsAttack = false,
        bVisibleToEnemies = true,
        bReplaceExisting = false,
        flExpireTime = internalData.duration,
		bProvidesVision = provideVision,
		iVisionRadius = vision or 100,
		iVisionTeamNumber = self:GetCaster():GetTeamNumber(),
		iSourceAttachment = iAttach or DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
		ExtraData = internalData.extraData
	}
	return ProjectileManager:CreateTrackingProjectile(projectile)
end

function GameRules:GetPlayerGoldMultiplier()
	return math.max( 1, 1 + (6 - HeroList:GetActiveHeroCount())/20 )
end

function CDOTA_BaseNPC:AddGold( val, bIgnoreBonus )
	if self:GetPlayerID() >= 0 then
		local hero = PlayerResource:GetSelectedHeroEntity( self:GetPlayerID() )
		if hero then
			local baseGold = val or 0
			local bonusGold = 0
			local gold = baseGold
			
			-- gold handling
			if not bIgnoreBonus then
				-- local midas = hero:FindModifierByName("modifier_hand_of_midas_passive")
			
				-- if midas then
					-- bonusGold = baseGold * (midas.bonus_gold or 0)
				-- end
				if hero:HasAbility("alchemist_goblins_greed") then
					bonusGold = baseGold * hero:FindAbilityByName("alchemist_goblins_greed"):GetSpecialValueFor("bonus_gold")  / 100
				end
				bonusGold = bonusGold + baseGold * (GameRules:GetPlayerGoldMultiplier()-1)
			end
			local newGold = hero:GetGold() + gold + bonusGold
			hero:SetGold(0, false)
			newGold = newGold + (hero.bonusGoldExcessValue or 0)
			hero.bonusGoldExcessValue = newGold % 1
			
			hero:SetGold(math.floor(newGold), true)
			
			-- notification handling
			local showGold = math.floor( gold )
			SendOverheadEventMessage(self:GetPlayerOwner(), OVERHEAD_ALERT_GOLD, self, showGold, self:GetPlayerOwner())
			
			if bonusGold > 0 then
				Timers:CreateTimer( 0.25, function()
					SendOverheadEventMessage(self:GetPlayerOwner(), OVERHEAD_ALERT_GOLD, self, math.floor( bonusGold ), self:GetPlayerOwner())
				end)
			end
			
			return gold
		end
	end
end

function CDOTA_BaseNPC:GetMagicalArmorValue( bUseExperimentalFormula, ability )
	return self:Script_GetMagicalArmorValue( bUseExperimentalFormula, ability )
end

function CDOTA_BaseNPC:ReduceMana( mana, ability )
	return self:Script_ReduceMana( mana, ability )
end

function CDOTA_BaseNPC:IsDeniable()
	return self:Script_IsDeniable()
end

function CDOTA_BaseNPC:GetAttackRange()
	return self:Script_GetAttackRange()
end


MAP_MMR = {
["epic_boss_fight_normal"] = 1200,
["epic_boss_fight_hard"] = 3500,
["epic_boss_fight_challenger"] = 4750,
["epic_boss_fight_nightmare"] = 5260,
}

MMR_WEIGHT = 3000
K_FACTOR = 60

function CalculateExpectedWinrate( map, playerMMR )
	if not MAP_MMR[map] then return end
	local mmrDiff = MAP_MMR[map] - playerMMR
	local mmrWeightedDiff = mmrDiff / MMR_WEIGHT
	return 1 / ( 1 + 10^mmrWeightedDiff )
end

function CalculateMMRChangeForPlayer( map, playerMMR, win )
	local expectedWR = CalculateExpectedWinrate( map, playerMMR )
	if not expectedWR then return end
	
	local score = win and 1 or 0
	local newMMR = playerMMR + K_FACTOR * ( score - expectedWR )
	
	return newMMR
end

function CDOTABaseAbility:UnitFilter( target )
	local caster = self:GetCaster()
	
	if PlayerResource:IsDisableHelpSetForPlayerID( target:GetPlayerOwnerID(), caster:GetPlayerOwnerID() ) then
		DisplayError( caster:GetPlayerOwnerID(), "dota_hud_error_target_has_disable_help")
		return UF_FAIL_DISABLE_HELP
	else
		return UnitFilter( target, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), caster:GetTeam() )
	end
end

function DisplayError(playerID, message)
	local player = PlayerResource:GetPlayer(playerID)
	if player then
		CustomGameEventManager:Send_ServerToPlayer(player, "ebf_error_message", {message=message})
	end
end