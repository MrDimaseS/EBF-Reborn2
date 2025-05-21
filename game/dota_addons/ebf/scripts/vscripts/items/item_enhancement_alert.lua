item_enhancement_alert = class({})

function item_enhancement_alert:GetIntrinsicModifierName()
	return "modifier_item_enhancement_alert_passive"
end

modifier_item_enhancement_alert_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_enhancement_alert_passive", "items/item_enhancement_alert.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_enhancement_alert_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_enhancement_alert_passive:OnRefresh()
	self.bonus_attack_speed = self:GetSpecialValueFor("bonus_attack_speed")
	self.bonus_night_vision = self:GetSpecialValueFor("bonus_night_vision")
end

function modifier_item_enhancement_alert_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT ,
			MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
			}
end

function modifier_item_enhancement_alert_passive:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end

function modifier_item_enhancement_alert_passive:GetModifierBaseDamageOutgoing_Percentage()
	return self.bonus_night_vision
end