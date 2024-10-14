slark_shadow_dance = class({})

function slark_shadow_dance:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_slark_shadow_dance_activated", {duration = self:GetSpecialValueFor("duration")})
	EmitSoundOn("Hero_Slark.ShadowDance", caster)
end

modifier_slark_shadow_dance_activated = class({})
LinkLuaModifier("modifier_slark_shadow_dance_activated", "heroes/hero_slark/slark_shadow_dance", LUA_MODIFIER_MOTION_NONE)

function modifier_slark_shadow_dance_activated:OnCreated()
	self.attackspeed = self:GetSpecialValueFor("bonus_attackspeed")
	if not IsServer() then return end
	local parent = self:GetParent()
	local sFX = ParticleManager:CreateParticle("particles/units/heroes/hero_slark/slark_shadow_dance.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControlEnt(sFX, 1, parent, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(sFX, 3, parent, PATTACH_POINT_FOLLOW, "attach_eyeR", parent:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(sFX, 4, parent, PATTACH_POINT_FOLLOW, "attach_eyeL", parent:GetAbsOrigin(), true)
	self:AddEffect(sFX)
end

function modifier_slark_shadow_dance_activated:GetStatusEffectName()
	return "particles/status_fx/status_effect_slark_shadow_dance.vpcf"
end

function modifier_slark_shadow_dance_activated:StatusEffectPriority()
	return 50
end

function modifier_slark_shadow_dance_activated:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end

function modifier_slark_shadow_dance_activated:GetModifierAttackSpeedBonus_Constant()
	return self.attackspeed
end

function modifier_slark_shadow_dance_activated:CheckState()
	return {[MODIFIER_STATE_INVISIBLE] = true,
			[MODIFIER_STATE_UNTARGETABLE] = true,
			[MODIFIER_STATE_ATTACK_IMMUNE] = true}
end
