function GetClientSync(key)
	local value = CustomNetTables:GetTableValue( "syncing_purposes", key).value
	return value
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

AbilityKV = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
MergeTables(AbilityKV, LoadKeyValues("scripts/npc/npc_items_custom.txt"))
MergeTables(AbilityKV, LoadKeyValues("scripts/npc/items.txt"))
UnitKV = LoadKeyValues("scripts/npc/npc_heroes.txt")
MergeTables(UnitKV, LoadKeyValues("scripts/npc/npc_heroes_custom.txt"))

function C_DOTA_BaseNPC:IsSameTeam(unit)
	return (self:GetTeamNumber() == unit:GetTeamNumber())
end

function C_DOTA_BaseNPC:HasTalent(talentName)
	local unit = self
	if unit:GetParentUnit() then
		unit = unit:GetParentUnit()
	end
	local data = CustomNetTables:GetTableValue("talents", tostring(unit:entindex())) or {}
	if data and data[talentName] then
		return true 
	end
	return false
end

function C_DOTA_BaseNPC:FindTalentValue(talentName, valname)
	local value = valname or "value"
	local unit = self
	if unit:GetParentUnit() then
		unit = unit:GetParentUnit()
	end
	if unit:HasTalent(talentName) and AbilityKV[talentName] then  
		local specialVal = AbilityKV[talentName]["AbilitySpecial"]
		for l,m in pairs(specialVal) do
			if m[value] then
				return m[value]
			end
		end
	end    
	return 0
end


function C_DOTA_BaseNPC:HasShard()
	return self:HasModifier("modifier_item_aghanims_shard")
end


function C_DOTABaseAbility:GetAbilityTextureName()
	if AbilityKV[self:GetName()] and AbilityKV[self:GetName()]["AbilityTextureName"] then
		return AbilityKV[self:GetName()]["AbilityTextureName"]
	end
	return nil
end

function C_DOTABaseAbility:GetTalentSpecialValueFor(value)
	return self:GetTalentLevelSpecialValueFor( value, -1)
end

function C_DOTABaseAbility:GetTalentLevelSpecialValueFor(value, level)
	local base = self:GetLevelSpecialValueFor(value, level)
	local talentName
	local kv = AbilityKV[self:GetName()]["AbilitySpecial"]
	local kVal = AbilityKV[self:GetName()]["AbilityValues"]
	local valname = "value"
	local multiply = false
	local subtract = false
	local zadd = false
	if kv then
		for k,v in pairs(kv) do -- trawl through keyvalues
			if v[value] then
				talentName = v["LinkedSpecialBonus"]
				if v["LinkedSpecialBonusField"] then valname = v["LinkedSpecialBonusField"] end
				if v["LinkedSpecialBonusOperation"] and v["LinkedSpecialBonusOperation"] == "SPECIAL_BONUS_MULTIPLY" then multiply = true end
				if v["LinkedSpecialBonusOperation"] and v["LinkedSpecialBonusOperation"] == "SPECIAL_BONUS_SUBTRACT" then subtract = true end
				if v["LinkedSpecialBonusOperation"] and v["LinkedSpecialBonusOperation"] == "SPECIAL_BONUS_PERCENTAGE_ADD" then zadd = true end
				break
			end
		end
	end
	if kVal then
		local valueData = kVal[value]
		if type(valueData) == table then
			talentName = valueData["LinkedSpecialBonus"]
			if valueData["LinkedSpecialBonusOperation"] and valueData["LinkedSpecialBonusOperation"] == "SPECIAL_BONUS_MULTIPLY" then multiply = true end
			if valueData["LinkedSpecialBonusOperation"] and valueData["LinkedSpecialBonusOperation"] == "SPECIAL_BONUS_SUBTRACT" then subtract = true end
			if valueData["LinkedSpecialBonusOperation"] and valueData["LinkedSpecialBonusOperation"] == "SPECIAL_BONUS_PERCENTAGE_ADD" then zadd = true end
		end
	end
	local unit = self:GetCaster()
	if unit:GetParentUnit() then
		unit = unit:GetParentUnit()
	end
	if talentName and unit:HasTalent(talentName) then 
		if multiply then
			base = base * unit:FindTalentValue(talentName, valname) 
		elseif subtract then
			base = base - unit:FindTalentValue(talentName, valname) 
		elseif zadd then
			base = base + math.floor(base * unit:FindTalentValue(talentName, valname) /100)
		else
			base = base + unit:FindTalentValue(talentName, valname)
		end
	end
	return base
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

function CDOTA_Modifier_Lua:GetTalentSpecialValueFor(specVal)
	return self:GetAbility():GetTalentSpecialValueFor(specVal)
end

function CDOTA_Modifier_Lua:GetTalentLevelSpecialValueFor(specVal, level)
	return self:GetAbility():GetTalentLevelSpecialValueFor(specVal, level)
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
		return unit:GetIntellect()
	else
		return 0
	end
end

function C_DOTA_BaseNPC:GetPrimaryAttribute()
	local unit = self
	if self:GetParentUnit() then
		unit = self:GetParentUnit()
	end
	if UnitKV[unit:GetUnitName()] then
		attribute = UnitKV[unit:GetUnitName()]["AttributePrimary"]
		if attribute then
			if attribute == "DOTA_ATTRIBUTE_STRENGTH" then
				return DOTA_ATTRIBUTE_STRENGTH
			elseif attribute == "DOTA_ATTRIBUTE_INTELLECT" then
				return DOTA_ATTRIBUTE_INTELLECT
			elseif attribute == "DOTA_ATTRIBUTE_AGILITY" then
				return DOTA_ATTRIBUTE_AGILITY
			end
		end
	end
	return -1
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
		return unit:GetIntellect()
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