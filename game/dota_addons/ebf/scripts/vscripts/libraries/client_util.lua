function MergeTables( t1, t2 )
    for name,info in pairs(t2) do
		if type(info) == "table"  and type(t1[name]) == "table" then
			MergeTables(t1[name], info)
		else
			t1[name] = info
		end
	end
end

function table.copy(t1)
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

function CalculateDistance(ent1, ent2)
	local pos1 = ent1
	local pos2 = ent2
	if ent1.GetAbsOrigin then pos1 = ent1:GetAbsOrigin() end
	if ent2.GetAbsOrigin then pos2 = ent2:GetAbsOrigin() end
	local distance = (pos1 - pos2):Length2D()
	return distance
end

function HasBit(checker, value)
	return bit.band(checker, value) == value
end

function AddTableToTable( t1, t2)
	for k,v in pairs(t2) do
		table.insert(t1, v)
	end
end

function ToRadians(degrees)
	return degrees * math.pi / 180
end

function ToDegrees(radians)
	return radians * 180 / math.pi 
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
	else -- tables and bools
		return thing
	end
end

function string.split( inputStr, delimiter )
	local d = delimiter or '%s' 
	local t={} 
	for field,s in string.gmatch(inputStr, "([^"..delimiter.."]*)("..delimiter.."?)") do 
		table.insert(t,field) 
		if s=="" then 
			return t 
		end 
	end
end

function C_DOTA_BaseNPC:GetAttackRange()
	return self:Script_GetAttackRange()
end

function C_DOTA_BaseNPC:HookInModifier( modifierType, modifier, priority )
	local statsHandler = self.statsSystemHandlerModifier
	if statsHandler and not statsHandler:IsNull() then
		statsHandler.modifierFunctions[modifierType] = statsHandler.modifierFunctions[modifierType] or {}
		statsHandler.modifierFunctions[modifierType][modifier] = priority or modifier:GetPriority() or 1
		statsHandler:ForceRefresh()
	end
end

function C_DOTA_BaseNPC:HookOutModifier( modifierType, modifier )
	local statsHandler = self.statsSystemHandlerModifier
	if statsHandler and not statsHandler:IsNull() then
		statsHandler.modifierFunctions[modifierType] = statsHandler.modifierFunctions[modifierType] or {}
		statsHandler.modifierFunctions[modifierType][modifier] = nil
		statsHandler:ForceRefresh()
	end
end

function TernaryOperator(value, bCheck, default)
	if bCheck then 
		return value 
	else 
		return default
	end
end

function GetTableLength(rndTable)
	local counter = 0
	for k,v in pairs(rndTable) do
		counter = counter + 1
	end
	return counter
end

function PrintAll(t)
	if type(t) == "table" then
		for k,v in pairs(t) do
			print(k,v)
			if type(v) == "table" then
				for m,n in pairs(v) do
					print('--', m,n)
					if type(n) == "table" then
						for h,j in pairs(n) do
							print('----', h,j)
						end
					end
				end
			end
		end
	else
		print( t )
	end
end

function C_DOTA_BaseNPC:IsSameTeam(unit)
	return (self:GetTeamNumber() == unit:GetTeamNumber())
end

function C_DOTA_BaseNPC:HasShard()
	return self:HasModifier("modifier_item_aghanims_shard")
end

function C_DOTABaseAbility:GetAbilityTextureName()
	local KV = GetAbilityKeyValuesByName( self:GetAbilityName() )
	if KV and KV["AbilityTextureName"] then
		return KV["AbilityTextureName"]
	end
	return nil
end

function C_DOTA_BaseNPC:HealDisabled()
	if self:HasModifier("Disabled_silence") or 
		 self:HasModifier("primal_avatar_miss_aura") or 
		 self:HasModifier("modifier_reflection_invulnerability") or 
		 self:HasModifier("modifier_elite_burning_health_regen_block") or 
		 self:HasModifier("modifier_elite_entangling_health_regen_block") or 
		 self:HasModifier("modifier_plague_damage") or 
		 self:HasModifier("modifier_rupture_datadriven") or 
		 self:HasModifier("fire_aura_debuff") or 
		 self:HasModifier("item_sange_and_yasha_4_debuff") or 
		 self:HasModifier("cursed_effect") then
	return true
	else return false end
end

function CDOTA_Modifier_Lua:GetSpecialValueFor(specVal)
	if self:GetAbility() then
		return self:GetAbility():GetSpecialValueFor(specVal)
	end
	return 0
end

function CDOTA_Modifier_Lua:AddIndependentStack()
	if self:GetStackCount() == 0 then self:GetStackCount(1)
	else self:IncrementStackCount() end
end

function C_DOTA_BaseNPC:GetAgility()
	local unit = self
	if self:GetParentUnit() then
		unit = self:GetParentUnit()
	end
	if unit:IsRealHero() then
		return unit:GetAgility()
	else
		return 0
	end
end

function C_DOTA_BaseNPC:GetStrength()
	local unit = self
	if self:GetParentUnit() then
		unit = self:GetParentUnit()
	end
	if unit:IsRealHero() then
		return unit:GetStrength()
	else
		return 0
	end
end

function C_DOTA_BaseNPC:GetIntellect()
	local unit = self
	if self:GetParentUnit() then
		unit = self:GetParentUnit()
	end
	if unit:IsRealHero() then
		return unit:GetIntellect(false)
	else
		return 0
	end
end

function C_DOTA_BaseNPC:GetPrimaryAttribute()
	local unit = self
	if self:GetParentUnit() then
		unit = self:GetParentUnit()
	end
	if not self._getPrimaryAttribute then
		local KV = GetUnitKeyValuesByName(self:GetUnitName())
		if KV.AttributePrimary == "DOTA_ATTRIBUTE_STRENGTH" then
			self._getPrimaryAttribute = DOTA_ATTRIBUTE_STRENGTH
		elseif KV.AttributePrimary == "DOTA_ATTRIBUTE_INTELLECT" then
			self._getPrimaryAttribute = DOTA_ATTRIBUTE_INTELLECT
		elseif KV.AttributePrimary == "DOTA_ATTRIBUTE_AGILITY" then
			self._getPrimaryAttribute = DOTA_ATTRIBUTE_AGILITY
		elseif KV.AttributePrimary == "DOTA_ATTRIBUTE_ALL" then
			self._getPrimaryAttribute = DOTA_ATTRIBUTE_ALL
		else
			self._getPrimaryAttribute = -1
		end
	end
	return self._getPrimaryAttribute
end

function C_DOTA_BaseNPC:GetPrimaryStatValue()
	local unit = self
	if self:GetParentUnit() then
		unit = self:GetParentUnit()
	end
	local nPrim = unit:GetPrimaryAttribute()
	if nPrim == DOTA_ATTRIBUTE_STRENGTH then
		return unit:GetStrength()
	elseif nPrim == DOTA_ATTRIBUTE_AGILITY then
		return unit:GetAgility()
	elseif nPrim == DOTA_ATTRIBUTE_INTELLECT then
		return unit:GetIntellect(false)
	end
	return 0
end

function C_BaseEntity:RollPRNG( percentage )
	local internalInt = (100/percentage)
	local startingRoll = internalInt^2
	self.internalPRNGCounter = self.internalPRNGCounter or (1/internalInt)^2
	if RollPercentage(self.internalPRNGCounter * 100) then
		self.internalPRNGCounter = (1/internalInt)^2
		return true
	else
		local internalCount = 1/self.internalPRNGCounter
		self.internalPRNGCounter = 1/( math.max(internalCount - internalInt, 1) )
		return false
	end
end

function C_DOTA_Ability_Lua:RollPRNG( percentage )
	local internalInt = (100/percentage)
	local startingRoll = internalInt^2
	self.internalPRNGCounter = self.internalPRNGCounter or (1/internalInt)^2
	if RollPercentage(self.internalPRNGCounter * 100) then
		self.internalPRNGCounter = (1/internalInt)^2
		return true
	else
		local internalCount = 1/self.internalPRNGCounter
		self.internalPRNGCounter = 1/( math.max(internalCount - internalInt, 1) )
		return false
	end
end

function RollPercentage( percentage )
	return RandomInt(1, 100) <= percentage
end

function CDOTA_Modifier_Lua:RollPRNG( percentage )
	local internalInt = (100/percentage)
	local startingRoll = internalInt^2
	self.internalPRNGCounter = self.internalPRNGCounter or (1/internalInt)^2
	if RollPercentage(self.internalPRNGCounter * 100) then
		self.internalPRNGCounter = (1/internalInt)^2
		return true
	else
		local internalCount = 1/self.internalPRNGCounter
		self.internalPRNGCounter = 1/( math.max(internalCount - internalInt, 1) )
		return false
	end
end

function C_DOTA_BaseNPC:GetParentUnit()
	return self.unitOwnerEntity
end

DOTA_UNIT_TARGET_FLAGS = {["DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES"] = DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES,
						  ["DOTA_UNIT_TARGET_FLAG_CHECK_DISABLE_HELP"] = DOTA_UNIT_TARGET_FLAG_CHECK_DISABLE_HELP,
						  ["DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES"] = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES}
DOTA_UNIT_TARGET_TYPE = {["DOTA_UNIT_TARGET_BASIC"] = DOTA_UNIT_TARGET_BASIC,
						 ["DOTA_UNIT_TARGET_HERO"] = DOTA_UNIT_TARGET_HERO,}
DOTA_UNIT_TARGET_TEAM = {["DOTA_UNIT_TARGET_TEAM_ENEMY"] = DOTA_UNIT_TARGET_TEAM_ENEMY,
						 ["DOTA_UNIT_TARGET_TEAM_FRIENDLY"] = DOTA_UNIT_TARGET_TEAM_FRIENDLY}

function string.trim(s)
   return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end

function C_DOTABaseAbility:GetAbilityTargetTeam()
	local KV = GetAbilityKeyValuesByName( self:GetAbilityName() )
	local targetTeam = 0
	for i in string.gmatch(KV.AbilityUnitTargetTeam, '([^|]+)') do
		targetTeam = targetTeam + (DOTA_UNIT_TARGET_TEAM[string.trim(i)] or 0)
	end
	return targetTeam
end

function C_DOTABaseAbility:GetAbilityTargetType()
	local KV = GetAbilityKeyValuesByName( self:GetAbilityName() )
	local targetType = 0
	for i in string.gmatch(KV.AbilityUnitTargetType, '([^|]+)') do
		targetType = targetType + (DOTA_UNIT_TARGET_TYPE[string.trim(i)] or 0)
	end
	return targetType
end

function C_DOTABaseAbility:GetAbilityTargetFlags()
	local KV = GetAbilityKeyValuesByName( self:GetAbilityName() )
	local targetFlags = 0
	for i in string.gmatch(KV.AbilityUnitTargetFlags, '([^|]+)') do
		targetFlags = targetFlags + (DOTA_UNIT_TARGET_FLAGS[string.trim(i)] or 0)
	end
	return targetFlags
end

function C_DOTABaseAbility:UnitFilter( target )
	local caster = self:GetCaster()
	local casterPlayerID = self:GetCaster():GetPlayerOwnerID()
	local targetPlayerID = target:GetPlayerOwnerID()
	
	local disableHelp = CustomNetTables:GetTableValue("disable_help", tostring(targetPlayerID) ) or {}
	if disableHelp[casterPlayerID] then
		return UF_FAIL_DISABLE_HELP
	else
		return UnitFilter( target, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), caster:GetTeamNumber() )
	end
end


function IsEntitySafe( entity )
	return entity and IsValidEntity( entity ) and not entity:IsNull() 
end

function IsModifierSafe( entity )
	return entity and not entity:IsNull() 
end

function C_DOTA_BaseNPC:GetManaType()
	return hero._heroManaType or "Mana"
end

function C_DOTA_BaseNPC:GetBaseAttackSpeed()
	if not self._internalBaseAttackSpeed then
		local KV = GetUnitKeyValuesByName(self:GetUnitName())
		self._internalBaseAttackSpeed = KV.BaseAttackSpeed or 100
	end
	self._internalBaseAttackSpeedBonus = self._internalBaseAttackSpeedBonus or 0
	return self._internalBaseAttackSpeedBonus + self._internalBaseAttackSpeed
end

function C_DOTABaseAbility:GetAltCastState()
	return self._getAltCastState or false
end