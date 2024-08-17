special_bonus_attributes = class({})

ABILITY_POWER_SCALING = 0.3

function special_bonus_attributes:OnHeroLevelUp()
	local hero = self:GetCaster()
	if hero:IsIllusion() then return end
	
	local realStrDiff = hero._internalStrGain - hero:GetStrengthGain()
	local realAgiDiff = hero._internalAgiGain - hero:GetAgilityGain()
	local realIntDiff = hero._internalIntGain - hero:GetIntellectGain()
	if realStrDiff > 0 then
		hero:ModifyStrength( realStrDiff ) 
	end
	if realIntDiff > 0 then
		hero:ModifyAgility( realAgiDiff ) 
	end
	if realIntDiff > 0 then
		hero:ModifyIntellect( realIntDiff )
	end
	
	local attribute_multiplier = 1+self:GetSpecialValueFor("value") / 100
	-- calculate current level attributes
	local currentIntendedStr = (self.originalBaseStr + hero:GetStrengthGain() * (hero:GetLevel()-1) ) * ( 1 + ABILITY_POWER_SCALING * (hero:GetLevel() - 1) ) * attribute_multiplier
	local currentIntendedAgi = (self.originalBaseAgi + hero:GetAgilityGain() * (hero:GetLevel()-1) ) * ( 1 + ABILITY_POWER_SCALING * (hero:GetLevel() - 1) ) * attribute_multiplier
	local currentIntendedInt = (self.originalBaseInt + hero:GetIntellectGain() * (hero:GetLevel()-1) ) * ( 1 + ABILITY_POWER_SCALING * (hero:GetLevel() - 1) ) * attribute_multiplier
	-- calculate next level attributes
	local nextIntendedStr = (self.originalBaseStr + hero:GetStrengthGain() * hero:GetLevel() ) * ( 1 + ABILITY_POWER_SCALING * hero:GetLevel() ) * attribute_multiplier
	local nextIntendedAgi = (self.originalBaseAgi + hero:GetAgilityGain() * hero:GetLevel() ) * ( 1 + ABILITY_POWER_SCALING * hero:GetLevel() ) * attribute_multiplier
	local nextIntendedInt = (self.originalBaseInt + hero:GetIntellectGain() * hero:GetLevel() ) * ( 1 + ABILITY_POWER_SCALING * hero:GetLevel() ) * attribute_multiplier
	
	hero._internalStrGain = nextIntendedStr - currentIntendedStr
	hero._internalAgiGain = nextIntendedAgi - currentIntendedAgi
	hero._internalIntGain = nextIntendedInt - currentIntendedInt
	
	self:SendUpdatedInventoryContents( info )
	CustomGameEventManager:Send_ServerToAllClients( "hero_leveled_up", {unit = self:GetCaster():entindex()} )
end

function special_bonus_attributes:OnUpgrade()
	local hero = self:GetCaster()
	if hero:IsIllusion() then return end
	
	local totalStrValue = (self.originalBaseStr + hero:GetStrengthGain() * (hero:GetLevel()-1) )  * ( 1 + ABILITY_POWER_SCALING * hero:GetLevel() )
	local totalAgiValue = (self.originalBaseAgi + hero:GetAgilityGain() * (hero:GetLevel()-1) )  * ( 1 + ABILITY_POWER_SCALING * hero:GetLevel() )
	local totalIntValue = (self.originalBaseInt + hero:GetIntellectGain() * (hero:GetLevel()-1) )  * ( 1 + ABILITY_POWER_SCALING * hero:GetLevel() )
	
	local attribute_multiplier = (self:GetSpecialValueFor( "value" ) - self:GetLevelSpecialValueFor( "value", self:GetLevel()-2 ) ) / 100
	if self:GetLevel() == 1 then -- no way to get 0 out of specialvalue and getlevel
		attribute_multiplier = self:GetSpecialValueFor( "value" ) / 100
	end
	
	hero:ModifyStrength( totalStrValue * attribute_multiplier ) 
	hero:ModifyAgility( totalAgiValue * attribute_multiplier ) 
	hero:ModifyIntellect( totalIntValue * attribute_multiplier )
	
	CustomGameEventManager:Send_ServerToAllClients( "update_talent_pips", {unit = self:GetCaster():entindex()} )
end

function special_bonus_attributes:Spawn()
	if not IsServer() then return end
	local hero = self:GetCaster()
	
	local heroName = hero:GetUnitName()
	local originalHero
	for _, ogHero in ipairs( HeroList:GetRealHeroes() ) do
		if heroName == ogHero:GetUnitName() then
			originalHero = ogHero
		end
	end
	
	-- security check
	self.originalBaseStr = hero:GetBaseStrength()
	self.originalBaseAgi = hero:GetBaseAgility()
	self.originalBaseInt = hero:GetBaseIntellect()
	
	hero._internalStrGain = (self.originalBaseStr + hero:GetStrengthGain()) * (1 + ABILITY_POWER_SCALING)
	hero._internalAgiGain = (self.originalBaseAgi + hero:GetAgilityGain()) * (1 + ABILITY_POWER_SCALING)
	hero._internalIntGain = (self.originalBaseInt + hero:GetIntellectGain()) * (1 + ABILITY_POWER_SCALING)
	
	hero._originalPrimaryValue = hero:GetPrimaryAttribute()
	
	Timers:CreateTimer(function()
		-- delay for KV overrides
		self.originalBaseStr = hero:GetBaseStrength()
		self.originalBaseAgi = hero:GetBaseAgility()
		self.originalBaseInt = hero:GetBaseIntellect()
		
		hero._internalStrGain = (self.originalBaseStr + hero:GetStrengthGain()) * (1 + ABILITY_POWER_SCALING) - self.originalBaseStr
		hero._internalAgiGain = (self.originalBaseAgi + hero:GetAgilityGain()) * (1 + ABILITY_POWER_SCALING) - self.originalBaseAgi
		hero._internalIntGain = (self.originalBaseInt + hero:GetIntellectGain()) * (1 + ABILITY_POWER_SCALING) - self.originalBaseInt
		
		hero._originalPrimaryValue = hero:GetPrimaryAttribute()
	end)
	
	hero._attributesAbility = self

	Timers:CreateTimer( 0.1, function()
		hero:AddNewModifier( originalHero or hero, self, "modifier_special_bonus_attributes_stat_rescaling", {} )
		if originalHero then
			hero:ModifyStrength( originalHero:GetBaseStrength() - hero:GetBaseStrength() )
			hero:ModifyAgility( originalHero:GetBaseAgility() - hero:GetBaseAgility() )
			hero:ModifyIntellect( originalHero:GetBaseIntellect() - hero:GetBaseIntellect() )
		end
	end )
end

function special_bonus_attributes:OnHeroCalculateStatBonus()
	if not IsEntitySafe( self ) then return end
	local hero = self:GetCaster() 
	local modifier = self:GetCaster():FindModifierByName("modifier_special_bonus_attributes_stat_rescaling")
	
	if modifier then 
		modifier:SetStackCount( self:GetCaster():GetPrimaryAttribute() )
		modifier:ForceRefresh()
	end
end

function special_bonus_attributes:OnInventoryContentsChanged()
	if not IsEntitySafe( self ) then return end
	if not IsEntitySafe( self:GetCaster() ) then return end
	if self:GetCaster():IsFakeHero( ) then return end
	Timers:CreateTimer( function() self:SendUpdatedInventoryContents({unit = self:GetCaster():entindex()}) end )
end

function special_bonus_attributes:SendUpdatedInventoryContents( info )
	if IsEntitySafe( self ) and not self.stopUnnecessaryUpdates and IsEntitySafe( self:GetCaster() ) then
		self.stopUnnecessaryUpdates = true
		local inventory = {}
		for i = 0, 8 do
			if self:GetCaster():GetItemInSlot(i) then
				inventory[i] = self:GetCaster():GetItemInSlot(i):GetAbilityKeyValues()
			else
				inventory[i] = -1
			end
		end
		if self:GetCaster():GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT) then
			inventory[9] = self:GetCaster():GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT):GetAbilityKeyValues()
		else
			inventory[9] = -1
		end
		CustomGameEventManager:Send_ServerToAllClients( "client_update_ability_kvs", {unit = self:GetCaster():entindex(), inventory = inventory} )
		CustomGameEventManager:Send_ServerToAllClients( "hero_leveled_up", {unit = self:GetCaster():entindex()} )
		Timers:CreateTimer( function() self.stopUnnecessaryUpdates = false end )
	end
end

modifier_special_bonus_attributes_stat_rescaling = class({})
LinkLuaModifier( "modifier_special_bonus_attributes_stat_rescaling", "heroes/special_bonus_attributes", LUA_MODIFIER_MOTION_NONE )

function modifier_special_bonus_attributes_stat_rescaling:GetAttributes()
  return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE --+ MODIFIER_ATTRIBUTE_MULTIPLE
end

HP_AMP_PER_STR = 0.8
MP_AMP_PER_INT = 0.8

function modifier_special_bonus_attributes_stat_rescaling:OnCreated()
	self:GetParent()._heroManaType = (CustomNetTables:GetTableValue("hero_attributes", tostring(self:GetParent():entindex())) or {}).mana_type or "Mana"
	
	self.baseManaRegen = 10
	if self:GetParent()._heroManaType ~= "Mana" then
		self.baseMana = 0
		self.baseManaRegen = 0
	end

	self.bonusSpellAmp = 0.02
	self.bonusDamage = 1.5
	self.baseMR = 15
	
	self.internal_ability_scaling = ABILITY_POWER_SCALING
	
	self:GetParent().cooldownModifiers = {}
	self:GetParent()._aoeModifiersList = {}
	self:GetParent()._critModifiersList = {}
	self:GetParent()._chanceModifiersList = {}
	self.baseArmor = self:GetParent():GetPhysicalArmorBaseValue() + ( self:GetParent():GetAgility() / 6 - 0.065 * self:GetParent():GetAgility() )
	self:GetParent()._baseArmorForIllusions = self.baseArmor
	if self:GetParent():IsIllusion() then
		self.baseArmor = self:GetCaster()._baseArmorForIllusions or (self:GetParent():GetPhysicalArmorBaseValue() + math.min( 0.065 * self:GetParent():GetAgility(), 0.9*self:GetParent():GetAgility()^(math.log(2)/math.log(5)) ))
	end
	self:GetParent()._primaryAttribute = self:GetParent():GetPrimaryAttribute()
	self:OnRefresh()
	if IsServer() then
		self:SetStackCount( self:GetParent():GetPrimaryAttribute() )
		
		if self:GetParent()._heroManaType == "Rage" then
			Timers:CreateTimer( 0.1, function() self:GetParent():AddNewModifier( self:GetParent(), self:GetAbility(), "modifier_hero_rage_system", {} ) end )
		elseif self:GetParent()._heroManaType == "Stamina" then
			Timers:CreateTimer( 0.1, function() self:GetParent():AddNewModifier( self:GetParent(), self:GetAbility(), "modifier_hero_stamina_system", {} ) end )
		end
		if not self:GetParent():IsFakeHero() then
			self:StartIntervalThink( 0.3 )
		end
	end
end

function modifier_special_bonus_attributes_stat_rescaling:OnRefresh()
	self.attackspeed = math.floor( math.min( 0.25 * self:GetParent():GetAgility(), 3.44*self:GetParent():GetAgility()^(math.log(2)/math.log(5)) ) )
	if IsServer() then
		if self.baseArmor then
			local agilityArmor = math.min( 0.065 * self:GetParent():GetAgility(), 0.9*self:GetParent():GetAgility()^(math.log(2)/math.log(5)) )
			self:GetParent():SetPhysicalArmorBaseValue( self.baseArmor + agilityArmor )
			Timers:CreateTimer( function() -- illusion fix, idk why the fuck it needs a frame delay for them
				if not IsEntitySafe( self:GetParent() ) then return end
				self:GetParent():SetPhysicalArmorBaseValue( self.baseArmor + agilityArmor )
			end)
		end
		if self.baseMR then
			local intArmor =  math.min( 0.04 * self:GetParent():GetIntellect(false), 0.55*self:GetParent():GetIntellect(false)^(math.log(2)/math.log(5)) )
			local totalVal = -self:GetParent():GetIntellect(false) * 0.1 + self.baseMR + intArmor
			self:GetParent():SetBaseMagicalResistanceValue( totalVal )
			Timers:CreateTimer( function() -- illusion fix, idk why the fuck it needs a frame delay for them
				if not IsEntitySafe( self:GetParent() ) then return end
				self:GetParent():SetBaseMagicalResistanceValue( totalVal )
			end)
		end
	end
end	

function modifier_special_bonus_attributes_stat_rescaling:OnIntervalThink()
	CustomNetTables:SetTableValue("hero_attributes", tostring( self:GetCaster():entindex() ), {mana_type = self:GetCaster()._heroManaType, strength = self:GetCaster():GetStrength(), agility = self:GetCaster():GetAgility(), intellect = self:GetCaster():GetIntellect(false), str_gain = self:GetCaster()._internalStrGain, agi_gain = self:GetCaster()._internalAgiGain, int_gain = self:GetCaster()._internalIntGain, spell_amp = self:GetCaster():GetSpellAmplification( false ), innate = self:GetCaster()._innateAbilityName, facetID = self:GetCaster():GetHeroFacetID(), primaryStat = self:GetCaster()._originalPrimaryValue})
end

function modifier_special_bonus_attributes_stat_rescaling:CheckState()
	return {[MODIFIER_STATE_ALLOW_PATHING_THROUGH_TREES] = true}
end

function modifier_special_bonus_attributes_stat_rescaling:DeclareFunctions()
  local funcs = {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_BONUS,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
		MODIFIER_PROPERTY_CASTTIME_PERCENTAGE,
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
		MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
		MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_EVASION_CONSTANT,
		MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE
  }
  return funcs
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierEvasion_Constant()
	if self:GetParent():IsStunned() or self:GetParent():IsHexed() or self:GetParent():IsRooted() then
		return -999
	end
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierAttackSpeedBonus_Constant()
  return self.attackspeed
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierHealAmplify_PercentageSource()
	return HP_AMP_PER_STR * (self:GetParent():GetStrength() / 100)
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierHPRegenAmplify_Percentage()
	return HP_AMP_PER_STR * (self:GetParent():GetStrength() / 100)
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierLifestealRegenAmplify_Percentage()
	return HP_AMP_PER_STR * (self:GetParent():GetStrength() / 100)
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierSpellLifestealRegenAmplify_Percentage()
	return HP_AMP_PER_STR * (self:GetParent():GetStrength() / 100)
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierMPRegenAmplify_Percentage()
	return MP_AMP_PER_INT * (self:GetParent():GetIntellect(false) / 100)
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierOverrideAbilitySpecial(params)
	if self._lockForProcessing then return end
	if params.ability._processValuesForScaling == nil then
		params.ability._processValuesForScaling = {}
	end
	local special_value = params.ability_special_value:gsub("%#", "")
	local abilityValues = GetAbilityKeyValuesByName(params.ability:GetAbilityName()).AbilityValues
	if params.ability._processValuesForScaling[special_value] == nil and abilityValues then
		params.ability._processValuesForScaling[special_value] = {}
		params.ability._processValuesForScaling[special_value].affected_by_aoe_increase = false
		params.ability._processValuesForScaling[special_value].affected_by_crit_increase = false
		params.ability._processValuesForScaling[special_value].affected_by_chance_increase = false
		params.ability._processValuesForScaling[special_value].affected_by_lvl_increase = false
		if type(GetAbilityKeyValuesByName(params.ability:GetAbilityName()).AbilityValues[special_value]) == "table" then -- check for adjustments
			if toboolean(GetAbilityKeyValuesByName(params.ability:GetAbilityName()).AbilityValues[special_value].affected_by_aoe_increase) then
				params.ability._processValuesForScaling[special_value].affected_by_aoe_increase = true
			end
			if toboolean(GetAbilityKeyValuesByName(params.ability:GetAbilityName()).AbilityValues[special_value].affected_by_chance_increase) then
				params.ability._processValuesForScaling[special_value].affected_by_chance_increase = true
			end
			if toboolean(GetAbilityKeyValuesByName(params.ability:GetAbilityName()).AbilityValues[special_value].affected_by_crit_increase) then
				params.ability._processValuesForScaling[special_value].affected_by_crit_increase = true
			end
			if toboolean(GetAbilityKeyValuesByName(params.ability:GetAbilityName()).AbilityValues[special_value].CalculateSpellDamageTooltip)
			or toboolean(GetAbilityKeyValuesByName(params.ability:GetAbilityName()).AbilityValues[special_value].CalculateSpellHealTooltip)
			or toboolean(GetAbilityKeyValuesByName(params.ability:GetAbilityName()).AbilityValues[special_value].CalculateAttackDamageTooltip)
			or toboolean(GetAbilityKeyValuesByName(params.ability:GetAbilityName()).AbilityValues[special_value].CalculateAttributeTooltip) then
				params.ability._processValuesForScaling[special_value].affected_by_lvl_increase = true
			end
			if GetAbilityKeyValuesByName(params.ability:GetAbilityName()).AbilityValues[special_value].ForceCalculateLevelBonus then
				params.ability._processValuesForScaling[special_value].affected_by_lvl_increase = toboolean(GetAbilityKeyValuesByName(params.ability:GetAbilityName()).AbilityValues[special_value].ForceCalculateLevelBonus)
			end
		elseif special_value == "AbilityDamage" then
			params.ability._processValuesForScaling[special_value].affected_by_lvl_increase = true
		end
	end
	if params.ability._processValuesForScaling[special_value]
	and (params.ability._processValuesForScaling[special_value].affected_by_aoe_increase
	or params.ability._processValuesForScaling[special_value].affected_by_crit_increase
	or params.ability._processValuesForScaling[special_value].affected_by_chance_increase
	or params.ability._processValuesForScaling[special_value].affected_by_lvl_increase) then
		return 1
	end
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierOverrideAbilitySpecialValue(params)
	self._lockForProcessing = true
	local special_value = params.ability_special_value:gsub("%#", "")
	local flBaseValue = params.ability:GetLevelSpecialValueFor( special_value, params.ability_special_level )
	self._lockForProcessing = false
	if flBaseValue <= 0 then
		return
	end
	if params.ability._processValuesForScaling[special_value].affected_by_aoe_increase  then
		local aoe_bonus_positive = 0
		local aoe_bonus_positive_pct = 0
		local aoe_bonus_negative = 0
		local aoe_bonus_negative_pct = 0
		for modifier, active in pairs( self:GetCaster()._aoeModifiersList ) do
			if IsModifierSafe( modifier ) then
				if modifier.GetModifierAoEBonusConstant and modifier:GetModifierAoEBonusConstant() then
					if modifier:GetModifierAoEBonusConstant() > 0 then
						aoe_bonus_positive = math.max( aoe_bonus_positive, modifier:GetModifierAoEBonusConstant() )
					else
						aoe_bonus_negative = math.min( aoe_bonus_negative, modifier:GetModifierAoEBonusConstant() )
					end
				end
				if modifier.GetModifierAoEBonusConstantStacking and modifier:GetModifierAoEBonusConstantStacking() then
					if modifier:GetModifierAoEBonusConstantStacking() > 0 then
						aoe_bonus_positive = aoe_bonus_positive + modifier:GetModifierAoEBonusConstantStacking()
					else
						aoe_bonus_negative = aoe_bonus_negative - modifier:GetModifierAoEBonusConstantStacking()
					end
				end
				if modifier.GetModifierAoEBonusPercentage and modifier:GetModifierAoEBonusPercentage() then
					if modifier:GetModifierAoEBonusPercentage() > 0 then
						aoe_bonus_positive_pct = math.max( aoe_bonus_positive_pct, modifier:GetModifierAoEBonusPercentage() )
					else
						aoe_bonus_negative_pct = math.min( aoe_bonus_negative_pct, modifier:GetModifierAoEBonusPercentage() )
					end
				end
			else
				self:GetCaster()._aoeModifiersList[modifier] = nil
			end
		end
		local flNewValue = flBaseValue * (1+(aoe_bonus_positive_pct/100 + aoe_bonus_negative_pct/100)) + aoe_bonus_positive + aoe_bonus_negative
		return flNewValue
	end
	if params.ability._processValuesForScaling[special_value].affected_by_crit_increase then
		local aoe_bonus_positive = 0
		local aoe_bonus_negative = 0
		for modifier, active in pairs( self:GetCaster()._critModifiersList ) do
			if IsModifierSafe( modifier ) then
				if modifier.GetModifierCriticalStrike_BonusDamage and modifier:GetModifierCriticalStrike_BonusDamage() then
					if modifier:GetModifierCriticalStrike_BonusDamage() > 0 then
						aoe_bonus_positive = math.max( aoe_bonus_positive, modifier:GetModifierCriticalStrike_BonusDamage() )
					else
						aoe_bonus_negative = math.min( aoe_bonus_negative, modifier:GetModifierCriticalStrike_BonusDamage() )
					end
				end
			else
				self:GetCaster()._critModifiersList[modifier] = nil
			end
		end
		local flNewValue = flBaseValue + aoe_bonus_positive + aoe_bonus_negative
		return flNewValue
	end
	if params.ability._processValuesForScaling[special_value].affected_by_chance_increase then
		local aoe_bonus_positive = 0
		local aoe_bonus_negative = 0
		for modifier, active in pairs( self:GetCaster()._chanceModifiersList ) do
			if IsModifierSafe( modifier ) then
				if modifier.GetModifierChanceBonusConstant and modifier:GetModifierChanceBonusConstant() then
					if modifier:GetModifierChanceBonusConstant() > 0 then
						aoe_bonus_positive = math.max( aoe_bonus_positive, 1+modifier:GetModifierChanceBonusConstant()/100 )
					else
						aoe_bonus_negative = math.max( math.min( aoe_bonus_negative, 1+modifier:GetModifierChanceBonusConstant()/100 ), -0.99 )
					end
				end
			else
				self:GetCaster()._chanceModifiersList[modifier] = nil
			end
		end
		local trueProbability = ((flBaseValue % 100)/100)
		
		local bonus_end_result = 0
		if aoe_bonus_positive > 0 then
			bonus_end_result = (((trueProbability * aoe_bonus_positive) / (1 + (aoe_bonus_positive-1) * trueProbability)) - trueProbability)*100
		end
		local minus_end_result = 0
		if aoe_bonus_negative < 0 then
			minus_end_result = (((trueProbability * aoe_bonus_negative) / (1 + (aoe_bonus_negative-1) * trueProbability)) - trueProbability)*100
		end
		local flNewValue = flBaseValue + bonus_end_result + minus_end_result
		return flNewValue
	end
	if params.ability._processValuesForScaling[special_value].affected_by_lvl_increase then
		local flNewValue = flBaseValue * ( 1 + (self:GetCaster():GetLevel() - 1) * self.internal_ability_scaling )
		return flNewValue
	end
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierPercentageCooldown( params )
  local castSpeed = 0
  for modifier,_ in pairs( self:GetParent().cooldownModifiers or {} ) do
	if IsModifierSafe( modifier ) and modifier.GetModifierCastSpeed then
		castSpeed = castSpeed + (modifier:GetModifierCastSpeed( params ) or 0)
	else
		self:GetParent().cooldownModifiers[modifier] = nil
	end
  end
  local cdr = (1 - ( 1 / (( 100 + castSpeed ) / 100 ) ))*100
  return cdr
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierPercentageCasttime( params )
  return self:GetModifierPercentageCooldown( params ) * 2
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierPhysicalArmorBonus()
	if not self:GetParent():IsRangedAttacker() then
		return 4
	end
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierStatusResistanceStacking()
	if not self:GetParent():IsRangedAttacker() then
		return 25
	end
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierExtraHealthPercentage()
	if not self:GetParent():IsRangedAttacker() then
		return 1.25
	end
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierHealthBonus()
	local BASE_HP_PRIMARY = 11
	local BASE_HP_UNIVERSAL = 4
	local bonusBaseHP = 0
	if self:GetStackCount() == DOTA_ATTRIBUTE_STRENGTH then
		bonusBaseHP = self:GetParent():GetStrength() * BASE_HP_PRIMARY
	elseif self:GetStackCount() == DOTA_ATTRIBUTE_AGILITY then
		bonusBaseHP = self:GetParent():GetAgility() * BASE_HP_PRIMARY
	elseif self:GetStackCount() == DOTA_ATTRIBUTE_INTELLECT then
		bonusBaseHP = self:GetParent():GetIntellect(false) * BASE_HP_PRIMARY
	else -- universal hero
		bonusBaseHP = ( self:GetParent():GetStrength() + self:GetParent():GetAgility() + self:GetParent():GetIntellect(false) ) * BASE_HP_UNIVERSAL
	end
	return bonusBaseHP
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierManaBonus()
	-- local mana = self.baseMana
	-- if self:GetParent()._heroManaType ~= "Mana" then
		-- mana = mana - self:GetParent():GetIntellect(false) * 2
	-- end
  -- return mana
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierConstantManaRegen()
	if self:GetParent()._heroManaType ~= "Mana" then
		return -self:GetParent():GetIntellect(false) * 0.05
	else
		return self.baseManaRegen - self:GetParent():GetIntellect(false) * 0.05
	end
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierBaseAttack_BonusDamage()
	local BASE_DAMAGE_PRIMARY = 0.5
	local BASE_DAMAGE_UNIVERSAL = 0.3
	local bonusBaseDamage = 0
	if self:GetStackCount() == DOTA_ATTRIBUTE_STRENGTH then
		bonusBaseDamage = self:GetParent():GetStrength() * BASE_DAMAGE_PRIMARY
	elseif self:GetStackCount() == DOTA_ATTRIBUTE_AGILITY then
		bonusBaseDamage = self:GetParent():GetAgility() * BASE_DAMAGE_PRIMARY
	elseif self:GetStackCount() == DOTA_ATTRIBUTE_INTELLECT then
		bonusBaseDamage = self:GetParent():GetIntellect(false) * BASE_DAMAGE_PRIMARY
	else -- universal hero
		bonusBaseDamage = ( self:GetParent():GetStrength() + self:GetParent():GetAgility() + self:GetParent():GetIntellect(false) ) * BASE_DAMAGE_UNIVERSAL
	end
	return self:GetParent():GetAgility() * self.bonusDamage + 30 + bonusBaseDamage
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierSpellAmplify_Percentage()
	local SPELL_AMP_PRIMARY = 0.02
	local SPELL_AMP_UNIVERSAL = 0.015
	local bonusSpellAmp = 0
	if self:GetStackCount() == DOTA_ATTRIBUTE_STRENGTH then
		bonusSpellAmp =  self:GetParent():GetStrength() * SPELL_AMP_PRIMARY
	elseif self:GetStackCount() == DOTA_ATTRIBUTE_AGILITY then
		bonusSpellAmp =  self:GetParent():GetAgility() * SPELL_AMP_PRIMARY
	elseif self:GetStackCount() == DOTA_ATTRIBUTE_INTELLECT then
		bonusSpellAmp =  self:GetParent():GetIntellect(false) * SPELL_AMP_PRIMARY
	else -- universal hero
		bonusSpellAmp =  ( self:GetParent():GetStrength() + self:GetParent():GetAgility() + self:GetParent():GetIntellect(false) ) * SPELL_AMP_UNIVERSAL
	end
	return self:GetParent():GetIntellect(false) * self.bonusSpellAmp + bonusSpellAmp
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierMagicalResistanceBonus()
	if not self:GetParent():IsRangedAttacker() then 
		return 12
	end
end

function modifier_special_bonus_attributes_stat_rescaling:GetModifierMoveSpeedBonus_Percentage()
	if not self:GetParent():IsRangedAttacker() then 
		return 12
	end
end

function modifier_special_bonus_attributes_stat_rescaling:IsHidden()
  return true
end

function modifier_special_bonus_attributes_stat_rescaling:IsDebuff()
  return false
end

function modifier_special_bonus_attributes_stat_rescaling:IsPurgable()
  return false
end

function modifier_special_bonus_attributes_stat_rescaling:AllowIllusionDuplicate()
  return true
end
