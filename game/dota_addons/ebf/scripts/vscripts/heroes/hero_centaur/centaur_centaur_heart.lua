centaur_centaur_heart = class({})

function centaur_centaur_heart:GetIntrinsicModifierName()
	return "modifier_centaur_centaur_heart_passive"
end

modifier_centaur_centaur_heart_passive = class({})
LinkLuaModifier( "modifier_centaur_centaur_heart_passive", "heroes/hero_centaur/centaur_centaur_heart", LUA_MODIFIER_MOTION_NONE )

function modifier_centaur_centaur_heart_passive:IsHidden()
	return true
end
function modifier_centaur_centaur_heart_passive:IsPurgable()
	return false
end
function modifier_centaur_centaur_heart_passive:OnCreated()
	self.hp_per_str = self:GetSpecialValueFor("hp_per_str")
	self.base_damage_per_str = self:GetSpecialValueFor("base_damage_per_str")
	self.movement_speed_per_str = self:GetSpecialValueFor("movement_speed_per_str")
	self.unslowable = self:GetSpecialValueFor("is_unslowable") ~= 0
	self.no_movespeed_cap = self:GetSpecialValueFor("no_movespeed_cap") ~= 0
end
function modifier_centaur_centaur_heart_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_SLOW_RESISTANCE_STACKING,
		MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT
	}
end
function modifier_centaur_centaur_heart_passive:GetModifierExtraHealthBonus()
	return self.hp_per_str * self:GetParent():GetStrength()
end
function modifier_centaur_centaur_heart_passive:GetModifierBaseAttack_BonusDamage()
	return self.base_damage_per_str * self:GetParent():GetStrength()
end
function modifier_centaur_centaur_heart_passive:GetModifierMoveSpeedBonus_Constant()
	return self.movement_speed_per_str * self:GetParent():GetStrength()
end
function modifier_centaur_centaur_heart_passive:GetModifierSlowResistance_Stacking()
    return TernaryOperator(100, self.unslowable, 0)
end
function modifier_centaur_centaur_heart_passive:GetModifierIgnoreMovespeedLimit()
	return self.no_movespeed_cap
end