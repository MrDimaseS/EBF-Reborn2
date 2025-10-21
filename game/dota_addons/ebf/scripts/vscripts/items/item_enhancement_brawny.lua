item_enhancement_brawny = class({})

function item_enhancement_brawny:GetIntrinsicModifierName()
	return "modifier_item_enhancement_brawny_passive"
end

modifier_item_enhancement_brawny_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_enhancement_brawny_passive", "items/item_enhancement_brawny.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_enhancement_brawny_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_enhancement_brawny_passive:OnRefresh()
	self.health_bonus = self:GetSpecialValueFor("health_bonus")
	self.health_regen = self:GetSpecialValueFor("health_regen")
end

function modifier_item_enhancement_brawny_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE,
			MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
			}
end

function modifier_item_enhancement_brawny_passive:GetModifierExtraHealthPercentage()
	return self.health_bonus
end

function modifier_item_enhancement_brawny_passive:GetModifierHPRegenAmplify_Percentage()
	return self.health_regen
end

function modifier_item_enhancement_brawny_passive:GetModifierLifestealRegenAmplify_Percentage()
	return self.health_regen
end

function modifier_item_enhancement_brawny_passive:GetModifierSpellLifestealRegenAmplify_Percentage()
	return self.health_regen
end

function modifier_item_enhancement_brawny_passive:GetModifierHealAmplify_PercentageSource()
	return self.health_regen
end

function modifier_item_enhancement_brawny_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_MULTIPLE
end
