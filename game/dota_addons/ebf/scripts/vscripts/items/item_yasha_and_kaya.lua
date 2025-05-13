item_yasha_and_kaya = class({})

function item_yasha_and_kaya:GetIntrinsicModifierName()
	return "modifier_item_yasha_and_kaya_passive"
end

modifier_item_yasha_and_kaya_passive = class({})
LinkLuaModifier( "modifier_item_yasha_and_kaya_passive", "items/item_yasha_and_kaya.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_yasha_and_kaya_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_yasha_and_kaya_passive:OnRefresh()
	self.bonus_agility = self:GetSpecialValueFor("bonus_agility")
	self.bonus_intellect = self:GetSpecialValueFor("bonus_intellect")
	
	self.movement_speed_percent_bonus = self:GetSpecialValueFor("movement_speed_percent_bonus")
	self.bonus_attack_speed = self:GetSpecialValueFor("bonus_attack_speed")
	self.spell_amp = self:GetSpecialValueFor("spell_amp")
	self.spell_lifesteal_amp = self:GetSpecialValueFor("spell_lifesteal_amp")
	self.mana_regen_multiplier = self:GetSpecialValueFor("mana_regen_multiplier")
	
	self.bonus_cooldown = self:GetSpecialValueFor("cast_speed")
	
	self:GetParent().cooldownModifiers = self:GetParent().cooldownModifiers or {}
	self:GetParent().cooldownModifiers[self] = true
end

function modifier_item_yasha_and_kaya_passive:OnDestroy()
	self:GetParent().cooldownModifiers[self] = nil
end


function modifier_item_yasha_and_kaya_passive:DeclareFunctions()
	return {
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE_UNIQUE,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
	}
end

function modifier_item_yasha_and_kaya_passive:GetModifierBonusStats_Intellect()
	return self.bonus_intellect
end

function modifier_item_yasha_and_kaya_passive:GetModifierBonusStats_Agility()
	return self.bonus_agility
end

function modifier_item_yasha_and_kaya_passive:GetModifierMoveSpeedBonus_Percentage_Unique()
	return self.movement_speed_percent_bonus
end

function modifier_item_yasha_and_kaya_passive:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end

function modifier_item_yasha_and_kaya_passive:GetModifierSpellAmplify_Percentage()
	return self.spell_amp
end

function modifier_item_yasha_and_kaya_passive:GetModifierSpellLifestealRegenAmplify_Percentage()
	return self.spell_lifesteal_amp
end

function modifier_item_yasha_and_kaya_passive:GetModifierCastSpeed( params )
	return self.bonus_cooldown
end

function modifier_item_yasha_and_kaya_passive:GetModifierMPRegenAmplify_Percentage()
	return self.mana_regen_multiplier
end


function modifier_item_yasha_and_kaya_passive:IsHidden()
	return true
end

function modifier_item_yasha_and_kaya_passive:IsPurgable()
	return false
end

function modifier_item_yasha_and_kaya_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end