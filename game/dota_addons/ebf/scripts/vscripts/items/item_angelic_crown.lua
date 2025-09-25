item_angelic_crown = class({})

function item_angelic_crown:GetIntrinsicModifierName()
	return "modifier_item_angelic_crown_passive"
end

modifier_item_angelic_crown_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_angelic_crown_passive", "items/item_angelic_crown.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_angelic_crown_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_angelic_crown_passive:OnRefresh()
	self.spell_amp = self:GetSpecialValueFor("spell_amp")
	self.heal_amp = self:GetSpecialValueFor("heal_amp")
	
	self.bonus_buff_durations = self:GetSpecialValueFor("bonus_buff_durations") / 100
	
	self:GetCaster()._buffModifiersList = self:GetCaster()._buffModifiersList or {}
	self:GetCaster()._buffModifiersList[self] = true
end

function modifier_item_angelic_crown_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET }
end

function modifier_item_angelic_crown_passive:GetModifierSpellAmplify_Percentage()
	return self.spell_amp
end

function modifier_item_angelic_crown_passive:GetModifierHealAmplify_PercentageTarget()
	return self.heal_amp
end

function modifier_item_angelic_crown_passive:GetModifierBuffDurationBonusPercentage( params )
	return self.bonus_buff_durations
end