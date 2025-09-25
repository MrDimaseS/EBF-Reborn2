item_breath_of_the_anemoi = class({})

function item_breath_of_the_anemoi:GetIntrinsicModifierName()
	return "modifier_item_breath_of_the_anemoi_passive"
end

modifier_item_breath_of_the_anemoi_passive = class({})
LinkLuaModifier( "modifier_item_breath_of_the_anemoi_passive", "items/item_breath_of_the_anemoi.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_breath_of_the_anemoi_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_breath_of_the_anemoi_passive:OnRefresh()
	self.bonus_movespeed = self:GetSpecialValueFor("bonus_movespeed")
	self.bonus_max_speed = self:GetSpecialValueFor("bonus_max_speed")
	self.bonus_spell_amp = self:GetSpecialValueFor("bonus_spell_amp")
	
	self.health_regen_per_ms = self:GetSpecialValueFor("health_regen_per_ms")
	self.health_per_ms = self:GetSpecialValueFor("health_per_ms")
end

function modifier_item_breath_of_the_anemoi_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_MOVESPEED_MAX_BONUS_CONSTANT,
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
			MODIFIER_PROPERTY_HEALTH_BONUS  }
end

function modifier_item_breath_of_the_anemoi_passive:GetModifierMoveSpeedBonus_Constant()
	return self.bonus_movespeed
end

function modifier_item_breath_of_the_anemoi_passive:GetModifierMoveSpeedMax_BonusConstant()
	return self.bonus_max_speed
end

function modifier_item_breath_of_the_anemoi_passive:GetModifierSpellAmplify_Percentage()
	return self.bonus_spell_amp
end

function modifier_item_breath_of_the_anemoi_passive:GetModifierConstantHealthRegen()
	return self.health_regen_per_ms * self:GetParent():GetIdealSpeed()
end

function modifier_item_breath_of_the_anemoi_passive:GetModifierHealthBonus()
	return self.health_per_ms * self:GetParent():GetIdealSpeed()
end

function modifier_item_breath_of_the_anemoi_passive:IsHidden()
	return true
end

function modifier_item_breath_of_the_anemoi_passive:IsPurgable()
	return false
end

function modifier_item_breath_of_the_anemoi_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end