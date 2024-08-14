morphling_equalize = class({})

function morphling_equalize:GetIntrinsicModifierName()
	return "modifier_morphling_equalize"
end

modifier_morphling_equalize = class(persistentModifier)
LinkLuaModifier( "modifier_morphling_equalize", "heroes/hero_morphling/morphling_equalize.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_morphling_equalize:OnCreated()
	self:OnRefresh()
end

function modifier_morphling_equalize:OnRefresh()
	self.bonus_strength = self:GetSpecialValueFor("bonus_strength")
	self.bonus_agility = self:GetSpecialValueFor("bonus_agility")
	self.bonus_intellect = self:GetSpecialValueFor("bonus_intellect")
end

function modifier_morphling_equalize:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		}
end

function modifier_morphling_equalize:GetModifierBonusStats_Strength()
	return self.bonus_strength
end

function modifier_morphling_equalize:GetModifierBonusStats_Agility()
	return self.bonus_agility
end

function modifier_morphling_equalize:GetModifierBonusStats_Intellect()
	return self.bonus_intellect
end

function modifier_morphling_equalize:IsHidden()
	return true
end