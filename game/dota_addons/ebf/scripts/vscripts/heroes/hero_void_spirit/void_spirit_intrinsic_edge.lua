void_spirit_intrinsic_edge = class({})

function void_spirit_intrinsic_edge:GetIntrinsicModifierName()
	return "modifier_void_spirit_intrinsic_edge_handler"
end

modifier_void_spirit_intrinsic_edge_handler = class(persistentModifier)
LinkLuaModifier( "modifier_void_spirit_intrinsic_edge_handler", "heroes/hero_void_spirit/void_spirit_intrinsic_edge", LUA_MODIFIER_MOTION_NONE )

function modifier_void_spirit_intrinsic_edge_handler:OnCreated()
	self:OnRefresh()
end

function modifier_void_spirit_intrinsic_edge_handler:OnRefresh()
	self.secondary_stat_bonus_pct = self:GetSpecialValueFor("secondary_stat_bonus_pct") / 100
	self.str_stat_bonus_pct = self:GetSpecialValueFor("str_stat_bonus_pct") / 100
	self.agi_stat_bonus_pct = self:GetSpecialValueFor("agi_stat_bonus_pct") / 100
	self.int_stat_bonus_pct = self:GetSpecialValueFor("int_stat_bonus_pct") / 100
end

function modifier_void_spirit_intrinsic_edge_handler:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS}
end

function modifier_void_spirit_intrinsic_edge_handler:GetModifierBonusStats_Strength( params )
	if self._strengthLock then return end
	self._strengthLock = true
	local strength = self:GetParent():GetStrength()
	self._strengthLock = false
	return strength * (self.secondary_stat_bonus_pct + self.str_stat_bonus_pct)
end

function modifier_void_spirit_intrinsic_edge_handler:GetModifierBonusStats_Agility( params )
	if self._agilityLock then return end
	self._agilityLock = true
	local agility = self:GetParent():GetAgility()
	self._agilityLock = false
	return agility * (self.secondary_stat_bonus_pct + self.agi_stat_bonus_pct)
end

function modifier_void_spirit_intrinsic_edge_handler:GetModifierBonusStats_Intellect( params )
	if self._intellectLock then return end
	self._intellectLock = true
	local intellect = self:GetParent():GetIntellect(true)
	self._intellectLock = false
	return intellect * (self.secondary_stat_bonus_pct + self.int_stat_bonus_pct)
end