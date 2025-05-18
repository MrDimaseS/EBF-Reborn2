item_grove_bow = class({})

function item_grove_bow:GetIntrinsicModifierName()
	return "modifier_item_grove_bow_passive"
end

modifier_item_grove_bow_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_grove_bow_passive", "items/item_grove_bow.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_grove_bow_passive:OnCreated()
	self.distance_damage = self:GetAbility():GetSpecialValueFor("distance_damage")
	self.debuff_duration = self:GetAbility():GetSpecialValueFor("debuff_duration")
	
	self.attack_speed_bonus = self:GetAbility():GetSpecialValueFor("attack_speed_bonus")
	self.attack_range_bonus = self:GetAbility():GetSpecialValueFor("attack_range_bonus")
end

function modifier_item_grove_bow_passive:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, 
			 MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
			 MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL,
			 MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end

function modifier_item_grove_bow_passive:GetModifierAttackSpeedBonus_Constant(params)
	return self.attack_speed_bonus
end

function modifier_item_grove_bow_passive:GetModifierProcAttack_BonusDamage_Magical(params)
	local damage = CalculateDistance( params.target, params.attacker ) * self.distance_damage
	return damage
end

function modifier_item_grove_bow_passive:OnAttackLanded(params)
	if params.attacker ~= self:GetParent() then return end
	Timers:CreateTimer( 0.1, function() params.target:AddNewModifier( params.attacker, self:GetAbility(), "modifier_item_grove_bow_debuff", {duration = self.debuff_duration} ) end )
end

function modifier_item_grove_bow_passive:GetModifierAttackRangeBonus(params)
	return self.attack_range_bonus * TernaryOperator( 1, self:GetParent():IsRangedAttacker(), 0 )
end

function modifier_item_grove_bow_passive:IsHidden()
	return true
end

function modifier_item_grove_bow_passive:IsPurgable()
	return false
end

function modifier_item_grove_bow_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end