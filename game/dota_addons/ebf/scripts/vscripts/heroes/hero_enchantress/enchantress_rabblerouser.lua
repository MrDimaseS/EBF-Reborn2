enchantress_rabblerouser = class({})

function enchantress_rabblerouser:GetIntrinsicModifierName()
	return "modifier_enchantress_rabblerouser_innate"
end

modifier_enchantress_rabblerouser_innate = class({})
LinkLuaModifier("modifier_enchantress_rabblerouser_innate", "heroes/hero_enchantress/enchantress_rabblerouser", LUA_MODIFIER_MOTION_NONE)

function modifier_enchantress_rabblerouser_innate:OnCreated()
	self.radius = self:GetSpecialValueFor("aura_radius")
end

function modifier_enchantress_rabblerouser_innate:IsAura()
	return true
end

function modifier_enchantress_rabblerouser_innate:GetModifierAura()
	return "modifier_enchantress_rabblerouser_buff"
end

function modifier_enchantress_rabblerouser_innate:GetAuraRadius()
	return self.radius
end

function modifier_enchantress_rabblerouser_innate:GetAuraDuration()
	return 0.5
end

function modifier_enchantress_rabblerouser_innate:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_enchantress_rabblerouser_innate:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_enchantress_rabblerouser_innate:IsHidden()
	return true
end

modifier_enchantress_rabblerouser_buff = class({})
LinkLuaModifier("modifier_enchantress_rabblerouser_buff", "heroes/hero_enchantress/enchantress_rabblerouser", LUA_MODIFIER_MOTION_NONE)

function modifier_enchantress_rabblerouser_buff:OnCreated()
	self.base_damage_amp = self:GetSpecialValueFor("base_damage_amp")
end

function modifier_enchantress_rabblerouser_buff:DeclareFunctions()
	return { MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE }
end

function modifier_enchantress_rabblerouser_buff:GetModifierBaseDamageOutgoing_Percentage( params )
	return self.base_damage_amp
end

function modifier_enchantress_rabblerouser_buff:IsHidden()
	return false
end