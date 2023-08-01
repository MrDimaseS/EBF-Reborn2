ogre_magi_dumb_luck = class({})

function ogre_magi_dumb_luck:GetIntrinsicModifierName()
	return "modifier_ogre_magi_dumb_luck_passive"
end

function ogre_magi_dumb_luck:Spawn()
	if IsServer() then
		self:SetLevel(1)
	end
end

function ogre_magi_dumb_luck:OnHeroCalculateStatBonus()
	local caster = self:GetCaster()
	local passive = caster:FindModifierByName( self:GetIntrinsicModifierName() )
	
	local strength = caster:GetStrength()
	if strength == self.lastStrengthCheck then return end
	self.lastStrengthCheck = strength
	caster:AddNewModifier( caster, self, self:GetIntrinsicModifierName(), {} )
end

modifier_ogre_magi_dumb_luck_passive = class({})
LinkLuaModifier("modifier_ogre_magi_dumb_luck_passive", "heroes/hero_ogre_magi/ogre_magi_dumb_luck", LUA_MODIFIER_MOTION_NONE)

function modifier_ogre_magi_dumb_luck_passive:OnCreated()
	self.multicast_chance_bonus_2 = {}
	self.multicast_chance_bonus_3 = {}
	self.multicast_chance_bonus_4 = {}
	self:OnRefresh()
end

function modifier_ogre_magi_dumb_luck_passive:OnRefresh()	
	local caster = self:GetCaster()
	local strength = caster:GetStrength()
	
	self.mana_per_str = self:GetSpecialValueFor("mana_per_str") * strength
	self.mana_regen_per_str = self:GetSpecialValueFor("mana_regen_per_str") * strength
	self.spell_amp_per_str = self:GetSpecialValueFor("spell_amp_per_str") * strength
	self.str_for_benefit = self:GetSpecialValueFor("str_for_benefit")
	self.multicast_per_str = strength * self:GetSpecialValueFor("multicast_per_str") / 100
	
	self.multicast = caster:FindAbilityByName("ogre_magi_multicast")
	if self.multicast and self.multicast:GetLevel() > 0 then
		local multicastScaler = self.multicast_per_str / self.str_for_benefit
		for i = 1, 6 do
			local multicastChance2 = self.multicast:GetLevelSpecialValueNoOverride("multicast_2_times", i-1)
			if multicastChance2 > 0 then
				self.multicast_chance_bonus_2[i-1] = math.floor(( multicastScaler * ((1-multicastChance2/100)/(1 - multicastChance2/100 + multicastScaler) )) * 1000)/10
			end
			
			local multicastChance3 = self.multicast:GetLevelSpecialValueNoOverride("multicast_3_times", i-1)
			if multicastChance3 > 0 then
				self.multicast_chance_bonus_3[i-1] = math.floor(( multicastScaler * ((1-multicastChance3/100)/(1 - multicastChance3/100 + multicastScaler) )) * 1000)/10
			end
			
			local multicastChance4 = self.multicast:GetLevelSpecialValueNoOverride("multicast_4_times", i-1)
			if multicastChance4 > 0 then
				self.multicast_chance_bonus_4[i-1] = math.floor(( multicastScaler * ((1-multicastChance4/100)/(1 - multicastChance4/100 + multicastScaler) )) * 1000)/10
			end
		end
	else
		for i = 1, 6 do
			self.multicast_chance_bonus_2[i-1] = 0
			self.multicast_chance_bonus_3[i-1] = 0
			self.multicast_chance_bonus_4[i-1] = 0
		end
		
	end
	if IsServer() then 
		caster:CalculateGenericBonuses() 
		caster:CalculateStatBonus( true ) 
	end
end

function modifier_ogre_magi_dumb_luck_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_MANA_BONUS,
			MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL, 
			MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS 
			}
end

function modifier_ogre_magi_dumb_luck_passive:GetModifierManaBonus()
	return self.mana_per_str
end

function modifier_ogre_magi_dumb_luck_passive:GetModifierConstantManaRegen()
	return self.mana_regen_per_str
end

function modifier_ogre_magi_dumb_luck_passive:GetModifierSpellAmplify_Percentage()
	return self.spell_amp_per_str
end

function modifier_ogre_magi_dumb_luck_passive:GetModifierBonusStats_Intellect()
	if self._checkingForIntellect then return end
	self._checkingForIntellect = true
	local intellect = self:GetCaster():GetIntellect()
	self._checkingForIntellect = false
	return -intellect
end

function modifier_ogre_magi_dumb_luck_passive:GetModifierOverrideAbilitySpecial(params)
	if params.ability == self.multicast then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if specialValue == "multicast_2_times"
		or specialValue == "multicast_3_times"
		or specialValue == "multicast_4_times" then
			return 1
		end
	end
end

function modifier_ogre_magi_dumb_luck_passive:GetModifierOverrideAbilitySpecialValue(params)
	if params.ability == self.multicast then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if specialValue == "multicast_2_times"then
			local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( specialValue, params.ability_special_level )
			return flBaseValue + (self.multicast_chance_bonus_2[params.ability_special_level] or 0)
		elseif specialValue == "multicast_3_times" then
			local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( specialValue, params.ability_special_level )
			return flBaseValue + (self.multicast_chance_bonus_3[params.ability_special_level] or 0)
		elseif specialValue == "multicast_4_times" then
			local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( specialValue, params.ability_special_level )
			return flBaseValue + (self.multicast_chance_bonus_4[params.ability_special_level] or 0)
		end
	end
end

function modifier_ogre_magi_dumb_luck_passive:IsHidden()
	return true
end

function modifier_ogre_magi_dumb_luck_passive:IsPurgable()
	return false
end