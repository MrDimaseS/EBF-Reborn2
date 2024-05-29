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
	
	self.str_for_benefit = self:GetSpecialValueFor("str_for_benefit")
	self.mp_restore_per_str = self:GetSpecialValueFor("mp_restore_per_str") * (strength / self.str_for_benefit)
	self.spell_amp_per_str = self:GetSpecialValueFor("spell_amp_per_str") * (strength / self.str_for_benefit)
	
	self.multicast = caster:FindAbilityByName("ogre_magi_multicast")
	
	if IsServer() then 
		caster:CalculateGenericBonuses() 
		caster:CalculateStatBonus( true ) 
	end
end

function modifier_ogre_magi_dumb_luck_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS 
			}
end

function modifier_ogre_magi_dumb_luck_passive:GetModifierMPRegenAmplify_Percentage()
	return self.mp_restore_per_str
end

function modifier_ogre_magi_dumb_luck_passive:GetModifierSpellAmplify_Percentage()
	return self.spell_amp_per_str
end

function modifier_ogre_magi_dumb_luck_passive:GetModifierBonusStats_Intellect()
	if self._checkingForIntellect then return end
	self._checkingForIntellect = true
	local intellect = self:GetCaster():GetIntellect(true)
	self._checkingForIntellect = false
	return -intellect
end

function modifier_ogre_magi_dumb_luck_passive:IsHidden()
	return true
end

function modifier_ogre_magi_dumb_luck_passive:IsPurgable()
	return false
end