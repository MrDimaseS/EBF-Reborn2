item_void_reach = class({})

function item_void_reach:GetIntrinsicModifierName()
	return "modifier_void_reach_passive"
end

item_void_reach_2 = class(item_void_reach)
item_void_reach_3 = class(item_void_reach)
item_void_reach_4 = class(item_void_reach)
item_void_reach_5 = class(item_void_reach)

modifier_void_reach_passive = class({})
LinkLuaModifier( "modifier_void_reach_passive", "items/item_void_reach.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_void_reach_passive:OnCreated()
	self.bonus_all = self:GetAbility():GetSpecialValueFor("bonus_all")
	self.bonus_mana = self:GetAbility():GetSpecialValueFor("bonus_mana")
	self.bonus_mana_regen = self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
	
	self.cast_range_bonus = self:GetAbility():GetSpecialValueFor("cast_range_bonus")
	self.base_attack_range = self:GetAbility():GetSpecialValueFor("base_attack_range")
	self.melee_pct = self:GetAbility():GetSpecialValueFor("melee_pct") / 100
end

function modifier_void_reach_passive:DeclareFunctions(params)
	local funcs = {
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
    }
    return funcs
end

function modifier_void_reach_passive:GetModifierBonusStats_Strength()
	return self.bonus_all
end

function modifier_void_reach_passive:GetModifierBonusStats_Intellect()
	return self.bonus_all
end

function modifier_void_reach_passive:GetModifierBonusStats_Agility()
	return self.bonus_all
end

function modifier_void_reach_passive:GetModifierManaBonus()
	return self.bonus_mana
end

function modifier_void_reach_passive:GetModifierConstantManaRegen()
	return self.bonus_mana_regen
end

function modifier_void_reach_passive:GetModifierCastRangeBonusStacking()
	return self.cast_range_bonus
end

function modifier_void_reach_passive:GetModifierAttackRangeBonus(params)
	if self:GetParent():IsRangedAttacker() then 
		return self.base_attack_range 
	else
		return self.base_attack_range * self.melee_pct
	end
end

function modifier_void_reach_passive:IsHidden()
	return true
end

function modifier_void_reach_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end