item_enhancement_tough = class({})

function item_enhancement_tough:GetIntrinsicModifierName()
	return "modifier_item_enhancement_tough_passive"
end

modifier_item_enhancement_tough_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_enhancement_tough_passive", "items/item_enhancement_tough.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_enhancement_tough_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_enhancement_tough_passive:OnRefresh()
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.armor = self:GetSpecialValueFor("armor")
end

function modifier_item_enhancement_tough_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS 
			}
end

function modifier_item_enhancement_tough_passive:GetModifierMagicalResistanceBonus()
	return self.bonus_damage
end

function modifier_item_enhancement_tough_passive:GetModifierPhysicalArmorBonus()
	return self.armor
end
