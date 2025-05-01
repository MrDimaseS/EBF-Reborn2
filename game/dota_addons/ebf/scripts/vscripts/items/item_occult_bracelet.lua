item_occult_bracelet = class({})

function item_occult_bracelet:GetIntrinsicModifierName()
	return "modifier_item_occult_bracelet_passive"
end

modifier_item_occult_bracelet_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_occult_bracelet_passive", "items/item_occult_bracelet.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_occult_bracelet_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_occult_bracelet_passive:OnRefresh()
	self.bonus_all_stats = self:GetSpecialValueFor("bonus_all_stats")
	self.magic_resistance = self:GetSpecialValueFor("magic_resistance")
	
	self.mana_regen = self:GetSpecialValueFor("mana_regen")
	self.damage_amp = self:GetSpecialValueFor("damage_amp")
	self.stack_limit = self:GetSpecialValueFor("stack_limit")
	self.stack_duration = self:GetSpecialValueFor("stack_duration")
end

function modifier_item_occult_bracelet_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
			MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			MODIFIER_EVENT_ON_ATTACK }
end

function modifier_item_occult_bracelet_passive:GetModifierBonusStats_Strength()
	return self.bonus_all_stats
end

function modifier_item_occult_bracelet_passive:GetModifierBonusStats_Agility()
	return self.bonus_all_stats
end

function modifier_item_occult_bracelet_passive:GetModifierBonusStats_Intellect()
	return self.bonus_all_stats
end

function modifier_item_occult_bracelet_passive:GetModifierMagicalResistanceBonus()
	return self.magic_resistance
end

function modifier_item_occult_bracelet_passive:GetModifierConstantManaRegen()
	return self.mana_regen * self:GetStackCount()
end

function modifier_item_occult_bracelet_passive:GetModifierTotalDamageOutgoing_Percentage()
	return self.damage_amp * self:GetStackCount()
end

function modifier_item_occult_bracelet_passive:OnAttack( params )
	if params.target ~= self:GetParent() then return end
	self:AddIndependentStack({duration = self.stack_duration, limit = self.stack_limit})
end

function modifier_item_occult_bracelet_passive:IsHidden()
	return self:GetStackCount() <= 0
end

function modifier_item_occult_bracelet_passive:DestroyOnExpire()
	return false
end