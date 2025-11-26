huskar_blood_magic = class({})

function huskar_blood_magic:GetIntrinsicModifierName()
	return "modifier_huskar_blood_magic_passive"
end

modifier_huskar_blood_magic_passive = class({})
LinkLuaModifier("modifier_huskar_blood_magic_passive", "heroes/hero_huskar/huskar_blood_magic", LUA_MODIFIER_MOTION_NONE)

function modifier_huskar_blood_magic_passive:OnCreated()
	self:OnRefresh()
end

function modifier_huskar_blood_magic_passive:OnRefresh()
	self.rage_to_burn = self:GetSpecialValueFor("rage_to_burn")
	self.burn_spell_amp = self:GetSpecialValueFor("burn_spell_amp")
	self.burn_restore_amp = self:GetSpecialValueFor("burn_restore_amp")
end

function modifier_huskar_blood_magic_passive:DeclareFunctions()
	return {
	
			}
end

function modifier_huskar_blood_magic_passive:IsHidden()
	return true
end

function modifier_huskar_blood_magic_passive:IsPurgable()
	return false
end