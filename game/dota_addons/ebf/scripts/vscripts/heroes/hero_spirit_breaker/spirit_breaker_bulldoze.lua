spirit_breaker_bulldoze = class({})

function spirit_breaker_bulldoze:IsStealable()
	return true
end

function spirit_breaker_bulldoze:GetIntrinsicModifierName()
	return "modifier_spirit_breaker_bulldoze_armor"
end

function spirit_breaker_bulldoze:OnSpellStart()
	local caster = self:GetCaster()
	
	local duration = self:GetSpecialValueFor("duration")
	caster:AddNewModifier(caster, self, "modifier_spirit_breaker_bulldoze_active", {Duration = duration})
	EmitSoundOn("Hero_Spirit_Breaker.Bulldoze.Cast", caster)
end

modifier_spirit_breaker_bulldoze_armor = class({})
LinkLuaModifier( "modifier_spirit_breaker_bulldoze_armor", "heroes/hero_spirit_breaker/spirit_breaker_bulldoze.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_spirit_breaker_bulldoze_armor:OnCreated()
	self:OnRefresh()
end

function modifier_spirit_breaker_bulldoze_armor:OnRefresh()
	self.ms_armor = self:GetSpecialValueFor("ms_armor") / 100
end

function modifier_spirit_breaker_bulldoze_armor:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
	}
	return funcs
end

function modifier_spirit_breaker_bulldoze_armor:GetModifierPhysicalArmorBonus()
	return self.ms_armor * self:GetParent():GetIdealSpeed()
end

function modifier_spirit_breaker_bulldoze_armor:IsHidden()
	return true
end

function modifier_spirit_breaker_bulldoze_armor:IsPurgable()
	return false
end

function modifier_spirit_breaker_bulldoze_armor:IsPurgeException()
	return false
end

modifier_spirit_breaker_bulldoze_active = class({})
LinkLuaModifier( "modifier_spirit_breaker_bulldoze_active", "heroes/hero_spirit_breaker/spirit_breaker_bulldoze.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_spirit_breaker_bulldoze_active:OnCreated()
	self:OnRefresh()
end

function modifier_spirit_breaker_bulldoze_active:OnRefresh()
	self.movement_speed = self:GetSpecialValueFor("movement_speed")
	self.status_resistance = self:GetSpecialValueFor("status_resistance")
	self.magic_resistance = self:GetSpecialValueFor("magic_resistance")
	
	self.unitsHit = {}
end

function modifier_spirit_breaker_bulldoze_active:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
	return funcs
end

function modifier_spirit_breaker_bulldoze_active:GetModifierMoveSpeedBonus_Percentage(params)
	return self.movement_speed
end
function modifier_spirit_breaker_bulldoze_active:GetModifierStatusResistanceStacking(params)
	return self.status_resistance
end
function modifier_spirit_breaker_bulldoze_active:GetModifierMagicalResistanceBonus(params)
	return self.magic_resistance
end

function modifier_spirit_breaker_bulldoze_active:GetEffectName()
	return "particles/units/heroes/hero_spirit_breaker/spirit_breaker_haste_owner.vpcf"
end