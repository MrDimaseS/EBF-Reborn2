item_enhancement_mystical = class({})

function item_enhancement_mystical:GetIntrinsicModifierName()
	return "modifier_item_enhancement_mystical_passive"
end

modifier_item_enhancement_mystical_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_enhancement_mystical_passive", "items/item_enhancement_mystical.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_enhancement_mystical_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_enhancement_mystical_passive:OnRefresh()
	self.mana_regen = self:GetSpecialValueFor("mana_regen")
	self.magic_res = self:GetSpecialValueFor("magic_res")
end

function modifier_item_enhancement_mystical_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_MANACOST_PERCENTAGE_STACKING,
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE 
			}
end

function modifier_item_enhancement_mystical_passive:GetModifierPercentageManacostStacking()
	return self.mana_regen
end

function modifier_item_enhancement_mystical_passive:GetModifierSpellAmplify_Percentage()
	return self.magic_res
end
