centaur_centaur_heart = class({})

function centaur_centaur_heart:GetIntrinsicModifierName()
	return "modifier_centaur_centaur_heart_passive"
end

modifier_centaur_centaur_heart_passive = class({})
LinkLuaModifier("modifier_centaur_centaur_heart_passive", "heroes/hero_centaur/centaur_centaur_heart", LUA_MODIFIER_MOTION_NONE)

function modifier_centaur_centaur_heart_passive:OnCreated()
	self.hp_per_str = self:GetSpecialValueFor("hp_per_str")
end

function modifier_centaur_centaur_heart_passive:DeclareFunctions()
	return { MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS }
end

function modifier_centaur_centaur_heart_passive:GetModifierExtraHealthBonus()
	return self.hp_per_str * self:GetParent():GetStrength()
end

function modifier_centaur_centaur_heart_passive:IsHidden()
	return true
end

function modifier_centaur_centaur_heart_passive:IsPurgable()
	return false
end