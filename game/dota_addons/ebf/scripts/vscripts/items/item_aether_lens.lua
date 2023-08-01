item_orichalcum_lens = class({})

function item_orichalcum_lens:GetIntrinsicModifierName()
	return "modifier_item_aether_lens_ebf"
end

item_redium_lens = class(item_orichalcum_lens)
item_sunium_lens = class(item_orichalcum_lens)
item_omni_lens = class(item_orichalcum_lens)
item_asura_lens = class(item_orichalcum_lens)

modifier_item_aether_lens_ebf = class({})
LinkLuaModifier( "modifier_item_aether_lens_ebf", "items/item_aether_lens.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_aether_lens_ebf:OnCreated()
	self.bonus_mana_regen = self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
	self.bonus_mana = self:GetAbility():GetSpecialValueFor("bonus_mana")
	self.bonus_int = self:GetAbility():GetSpecialValueFor("bonus_intelligence")
	self.cast_range_bonus = self:GetAbility():GetSpecialValueFor("cast_range_bonus")
	self.spell_amp = self:GetAbility():GetSpecialValueFor("spell_amp")
	self.spell_amp_pr = self:GetAbility():GetSpecialValueFor("spell_amp_pr")
	self.mana_regen_multiplier = self:GetAbility():GetSpecialValueFor("mana_regen_multiplier")
	self.spell_lifesteal_amp = self:GetAbility():GetSpecialValueFor("spell_lifesteal_amp")
	
	if self.spell_amp_pr > 0 and IsServer() then
		self:StartIntervalThink(0.25)
	end
end

function modifier_item_aether_lens_ebf:OnIntervalThink()
	local stack = GameRules._roundnumber
	if stack ~= self:GetStackCount() then
		self:SetStackCount( stack )
	end
end

function modifier_item_aether_lens_ebf:DeclareFunctions(params)
local funcs = {
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
    MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
    }
    return funcs
end

function modifier_item_aether_lens_ebf:GetModifierConstantManaRegen()
	return self.bonus_mana_regen
end

function modifier_item_aether_lens_ebf:GetModifierManaBonus()
	return self.bonus_mana
end

function modifier_item_aether_lens_ebf:GetModifierBonusStats_Intellect()
	return self.bonus_int
end

function modifier_item_aether_lens_ebf:GetModifierCastRangeBonusStacking()
	return self.cast_range_bonus
end

function modifier_item_aether_lens_ebf:GetModifierSpellAmplify_Percentage()
	return self.spell_amp + self.spell_amp_pr * self:GetStackCount()
end

function modifier_item_aether_lens_ebf:GetModifierSpellLifestealRegenAmplify_Percentage()
	return self.spell_lifesteal_amp
end

function modifier_item_aether_lens_ebf:GetModifierMPRegenAmplify_Percentage()
	return self.mana_regen_multiplier
end

function modifier_item_aether_lens_ebf:IsHidden()
	return true
end

function modifier_item_aether_lens_ebf:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end