item_skadi = class({})

function item_skadi:GetIntrinsicModifierName()
	return "modifier_item_skadi_passive"
end

item_skadi2 = class(item_skadi)
item_skadi3 = class(item_skadi)
item_skadi4 = class(item_skadi)
item_skadi5 = class(item_skadi)

modifier_item_skadi_passive = class({})
LinkLuaModifier( "modifier_item_skadi_passive", "items/item_skadi.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_skadi_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_skadi_passive:OnRefresh()
	self.bonus_mana = self:GetAbility():GetSpecialValueFor("bonus_mana")
	self.bonus_health = self:GetAbility():GetSpecialValueFor("bonus_health")
	self.bonus_all_stats = self:GetAbility():GetSpecialValueFor("bonus_all_stats")
	
	self.cold_duration = self:GetSpecialValueFor("cold_duration")
end

function modifier_item_skadi_passive:DeclareFunctions(params)
local funcs = {
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_MANA_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_PROJECTILE_NAME 
    }
    return funcs
end

function modifier_item_skadi_passive:GetModifierManaBonus()
	return self.bonus_mana
end

function modifier_item_skadi_passive:GetModifierHealthBonus()
	return self.bonus_health
end

function modifier_item_skadi_passive:GetModifierBonusStats_Strength()
	return self.bonus_all_stats
end

function modifier_item_skadi_passive:GetModifierBonusStats_Intellect()
	return self.bonus_all_stats
end

function modifier_item_skadi_passive:GetModifierBonusStats_Agility()
	return self.bonus_all_stats
end

function modifier_item_skadi_passive:GetModifierProjectileName()
	return "particles/items2_fx/skadi_projectile.vpcf"
end

function modifier_item_skadi_passive:OnAttackLanded(params)
	if params.attacker == self:GetParent() then
		params.target:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_item_skadi_debuff", {duration = self.cold_duration} )
	end
end

function modifier_item_skadi_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_skadi_passive:IsHidden()
	return true
end

modifier_item_skadi_debuff = class({})
LinkLuaModifier( "modifier_item_skadi_debuff", "items/item_skadi.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_skadi_debuff:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink( 1 )
	end
end

function modifier_item_skadi_debuff:OnRefresh()
	self.cold_damage_per_second = self:GetSpecialValueFor("cold_damage_per_second")
	self.cold_slow_melee = self:GetSpecialValueFor("cold_slow_melee")
	self.cold_slow_ranged = self:GetSpecialValueFor("cold_slow_ranged")
	self.cold_attack_slow_melee = self:GetSpecialValueFor("cold_attack_slow_melee")
	self.cold_attack_slow_ranged = self:GetSpecialValueFor("cold_attack_slow_ranged")
	self.heal_reduction = -self:GetSpecialValueFor("heal_reduction")
end

function modifier_item_skadi_debuff:OnIntervalThink()
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	if not ability or not caster or not parent
	or ability:IsNull() or caster:IsNull() or parent:IsNull() then
		return
	end
	ability:DealDamage( caster, parent, self.cold_damage_per_second, {damage_type = DAMAGE_TYPE_MAGICAL} )
end

function modifier_item_skadi_debuff:DeclareFunctions(params)
local funcs = {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
    }
    return funcs
end

function modifier_item_skadi_debuff:GetModifierAttackSpeedBonus_Constant()
	return TernaryOperator( self.cold_slow_ranged, self:GetParent():IsRangedAttacker(), self.cold_slow_melee )
end

function modifier_item_skadi_debuff:GetModifierMoveSpeedBonus_Percentage()
	return TernaryOperator( self.cold_attack_slow_ranged, self:GetParent():IsRangedAttacker(), self.cold_attack_slow_melee )
end

function modifier_item_skadi_debuff:GetModifierHealAmplify_PercentageSource()
	return self.heal_reduction
end

function modifier_item_skadi_debuff:GetModifierHPRegenAmplify_Percentage()
	return self.heal_reduction
end

function modifier_item_skadi_debuff:GetModifierLifestealRegenAmplify_Percentage()
	return self.heal_reduction
end

function modifier_item_skadi_debuff:GetModifierSpellLifestealRegenAmplify_Percentage()
	return self.heal_reduction
end

function modifier_item_skadi_debuff:GetEffectName()
	return "particles/generic_gameplay/generic_slowed_cold.vpcf"
end