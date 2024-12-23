templar_assassin_third_eye = class({})

function templar_assassin_third_eye:GetIntrinsicModifierName()
	return "modifier_templar_assassin_third_eye_innate"
end

modifier_templar_assassin_third_eye_innate = class({})
LinkLuaModifier("modifier_templar_assassin_third_eye_innate", "heroes/hero_templar_assassin/templar_assassin_third_eye", LUA_MODIFIER_MOTION_NONE)

function modifier_templar_assassin_third_eye_innate:OnCreated()
	self.radius = self:GetSpecialValueFor("radius")
end

function modifier_templar_assassin_third_eye_innate:CheckState()
	return { [MODIFIER_STATE_CANNOT_MISS] = true }
end

function modifier_templar_assassin_third_eye_innate:IsAura()
	return true
end

function modifier_templar_assassin_third_eye_innate:GetModifierAura()
	return "modifier_truesight"
end

function modifier_templar_assassin_third_eye_innate:GetAuraRadius()
	return self.radius
end

function modifier_templar_assassin_third_eye_innate:GetAuraDuration()
	return 0.5
end

function modifier_templar_assassin_third_eye_innate:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_templar_assassin_third_eye_innate:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_templar_assassin_third_eye_innate:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_templar_assassin_third_eye_innate:IsHidden()
	return true
end

function modifier_templar_assassin_third_eye_innate:IsPurgable()
	return false
end