elder_titan_tip_the_scales = class({})

function elder_titan_tip_the_scales:GetIntrinsicModifierName()
	return "modifier_elder_titan_tip_the_scales_innate"
end

modifier_elder_titan_tip_the_scales_innate = class({})
LinkLuaModifier("modifier_elder_titan_tip_the_scales_innate", "heroes/hero_elder_titan/elder_titan_tip_the_scales", LUA_MODIFIER_MOTION_NONE)

function modifier_elder_titan_tip_the_scales_innate:IsAura()
	return true
end

function modifier_elder_titan_tip_the_scales_innate:GetModifierAura()
	return "modifier_elder_titan_tip_the_scales_handler"
end

function modifier_elder_titan_tip_the_scales_innate:GetAuraRadius()
	return 6000
end

function modifier_elder_titan_tip_the_scales_innate:GetAuraDuration()
	return 0.5
end

function modifier_elder_titan_tip_the_scales_innate:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_elder_titan_tip_the_scales_innate:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_HERO
end

function modifier_elder_titan_tip_the_scales_innate:IsAuraActiveOnDeath()
	return true
end

function modifier_elder_titan_tip_the_scales_innate:IsHidden()
	return true
end

modifier_elder_titan_tip_the_scales_handler = class({})
LinkLuaModifier("modifier_elder_titan_tip_the_scales_handler", "heroes/hero_elder_titan/elder_titan_tip_the_scales", LUA_MODIFIER_MOTION_NONE)

function modifier_elder_titan_tip_the_scales_handler:OnCreated()
	self.damage_bonus = self:GetSpecialValueFor("damage_bonus")
	self.amp_bonus = self:GetSpecialValueFor("amp_bonus")
end

function modifier_elder_titan_tip_the_scales_handler:DeclareFunctions()
	return { MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE, MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end

function modifier_elder_titan_tip_the_scales_handler:GetModifierTotalDamageOutgoing_Percentage( params )
	if self:GetParent():HasModifier("modifier_fountain_glyph") then
		return self.damage_bonus
	end
end
function modifier_elder_titan_tip_the_scales_handler:GetModifierIncomingDamage_Percentage( params )
	if self:GetParent():HasModifier("modifier_radar_debuff") then
		return self.amp_bonus
	end
end

function modifier_elder_titan_tip_the_scales_handler:IsHidden()
	return true
end