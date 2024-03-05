boss_rift_guardian_obliterate = class({})

function boss_rift_guardian_obliterate:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	target:AddNewModifier( caster, self, "modifier_boss_rift_guardian_obliterate", {duration = self:GetSpecialValueFor("duration")})
	EmitSoundOn( "Hero_EmberSpirit.SearingChains.Cast", caster )
	EmitSoundOn( "Hero_EmberSpirit.SearingChains.Target", target )
end

modifier_boss_rift_guardian_obliterate = class({})
LinkLuaModifier( "modifier_boss_rift_guardian_obliterate", "bosses/boss_asura/boss_rift_guardian_obliterate", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_rift_guardian_obliterate:OnCreated()
	self.slow = self:GetSpecialValueFor("slow")
	self.damage_amp = self:GetSpecialValueFor("damage_amp")
end

function modifier_boss_rift_guardian_obliterate:CheckState()
	return {[MODIFIER_STATE_DISARMED] = true}
end

function modifier_boss_rift_guardian_obliterate:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end

function modifier_boss_rift_guardian_obliterate:GetModifierMoveSpeedBonus_Percentage()
	return -self.slow
end

function modifier_boss_rift_guardian_obliterate:GetModifierIncomingDamage_Percentage()
	return self.damage_amp
end

function modifier_boss_rift_guardian_obliterate:GetEffectName()
	return "particles/units/heroes/hero_rubick/rubick_doom.vpcf"
end

function modifier_boss_rift_guardian_obliterate:GetStatusEffectName()
	return "particles/status_fx/status_effect_burn.vpcf"
end

function modifier_boss_rift_guardian_obliterate:StatusEffectPriority()
	return 10
end