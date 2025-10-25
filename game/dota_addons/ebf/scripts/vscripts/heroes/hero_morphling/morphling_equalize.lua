morphling_equalize = class({})

function morphling_equalize:GetIntrinsicModifierName()
	return "modifier_morphling_equalize"
end

modifier_morphling_equalize = class({})
LinkLuaModifier( "modifier_morphling_equalize", "heroes/hero_morphling/morphling_equalize.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_morphling_equalize:IsHidden()
	return true
end

function modifier_morphling_equalize:OnCreated()
	self:OnRefresh()
end

function modifier_morphling_equalize:OnRefresh()
	self.bonus_strength = self:GetSpecialValueFor("bonus_strength")
	self.bonus_agility = self:GetSpecialValueFor("bonus_agility")
	self.bonus_intellect = self:GetSpecialValueFor("bonus_intellect")

	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
	self.bonus_mres = self:GetSpecialValueFor("bonus_mres")

	self.bonus_mspd = self:GetSpecialValueFor("bonus_mspd")
	self.bonus_attack_range = self:GetSpecialValueFor("bonus_attack_range")

	self.bonus_spell_amp = self:GetSpecialValueFor("bonus_spell_amp")
	self.bonus_cast_range = self:GetSpecialValueFor("bonus_cast_range")
	self:StartIntervalThink(0.1)
end

function modifier_morphling_equalize:OnIntervalThink()
	self:OnRefresh()
end

function modifier_morphling_equalize:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
		}
end

function modifier_morphling_equalize:GetModifierBonusStats_Strength()
	return self.bonus_strength
end

function modifier_morphling_equalize:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_morphling_equalize:GetModifierMagicalResistanceBonus()
	if self.bonus_mres ~= 0 then
		return self.bonus_mres
	end
end
----------------------------------------------------------------------------------------------------------------------------------------
function modifier_morphling_equalize:GetModifierBonusStats_Agility()
	return self.bonus_agility
end

function modifier_morphling_equalize:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_mspd
end

function modifier_morphling_equalize:GetModifierAttackRangeBonus()
	if self.bonus_attack_range ~= 0 then
		return self.bonus_attack_range
	end
end

----------------------------------------------------------------------------------------------------------------------------------------
function modifier_morphling_equalize:GetModifierBonusStats_Intellect()
	return self.bonus_intellect
end

function modifier_morphling_equalize:GetModifierSpellAmplify_Percentage()
	return self.bonus_spell_amp
end

function modifier_morphling_equalize:GetModifierCastRangeBonusStacking()
	if self.bonus_cast_range ~= 0 then
		return self.bonus_cast_range
	end
end