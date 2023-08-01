item_force_boots = class({})

function item_force_boots:GetIntrinsicModifierName()
	return "modifier_ebfr_force_boots_passive"
end

function item_force_boots:OnSpellStart()
	local caster = self:GetCaster()
	
	caster:ApplyKnockBack( caster:GetAbsOrigin() - caster:GetForwardVector(), 0.5, 0.5, self:GetSpecialValueFor("push_length"), 0, caster, self )
	caster:AddNewModifier( caster, self, "modifier_item_phase_boots_active", {duration = self:GetSpecialValueFor("phase_duration") + 0.5} )
	
	EmitSoundOn( "DOTA_Item.Force_Boots.Cast", caster )
	EmitSoundOn( "DOTA_Item.PhaseBoots.Activate", caster )
end

item_force_boots_2 = class(item_force_boots)
item_force_boots_3 = class(item_force_boots)
item_force_boots_4 = class(item_force_boots)
item_force_boots_5 = class(item_force_boots)

modifier_ebfr_force_boots_passive = class({})
LinkLuaModifier( "modifier_ebfr_force_boots_passive", "items/item_force_boots.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_ebfr_force_boots_passive:OnCreated()
	self.bonus_movement_speed = self:GetAbility():GetSpecialValueFor("bonus_movement_speed")
	self.bonus_intellect = self:GetAbility():GetSpecialValueFor("bonus_intellect")
	self.bonus_health = self:GetAbility():GetSpecialValueFor("bonus_health")
	self.bonus_damage_melee = self:GetAbility():GetSpecialValueFor("bonus_damage_melee")
	self.bonus_damage_range = self:GetAbility():GetSpecialValueFor("bonus_damage_range")
	self.bonus_armor = self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_ebfr_force_boots_passive:DeclareFunctions(params)
local funcs = {
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    }
    return funcs
end

function modifier_ebfr_force_boots_passive:GetModifierMoveSpeedBonus_Special_Boots()
	return self.bonus_movement_speed
end

function modifier_ebfr_force_boots_passive:GetModifierBonusStats_Intellect()
	return self.bonus_intellect
end

function modifier_ebfr_force_boots_passive:GetModifierHealthBonus()
	return self.bonus_health
end

function modifier_ebfr_force_boots_passive:GetModifierPreAttack_BonusDamage()
	local result = TernaryOperator( self.bonus_damage_range, self:GetParent():IsRangedAttacker(), self.bonus_damage_melee )
	return result
end

function modifier_ebfr_force_boots_passive:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_ebfr_force_boots_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ebfr_force_boots_passive:IsHidden()
	return true
end