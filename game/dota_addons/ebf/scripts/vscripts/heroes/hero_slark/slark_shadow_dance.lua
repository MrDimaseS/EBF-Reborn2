slark_shadow_dance = class({})

function slark_shadow_dance:GetIntrinsicModifierName()
	return "modifier_slark_shadow_dance_handler"
end

function slark_shadow_dance:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_slark_shadow_dance_activated", {duration = self:GetTalentSpecialValueFor("duration")})
	EmitSoundOn("Hero_Slark.ShadowDance", caster)
end

modifier_slark_shadow_dance_handler = class({})
LinkLuaModifier("modifier_slark_shadow_dance_handler", "heroes/hero_slark/slark_shadow_dance", LUA_MODIFIER_MOTION_NONE)

function modifier_slark_shadow_dance_handler:OnCreated()
	self.regen = self:GetTalentSpecialValueFor("bonus_regen")
	self.ms = self:GetTalentSpecialValueFor("bonus_movement_speed")
	
	self.neutral_disable = self:GetTalentSpecialValueFor("neutral_disable")
	if IsServer() then
		self:StartIntervalThink(0.1)
	end
end

function modifier_slark_shadow_dance_handler:OnRefresh()
	self.regen = self:GetTalentSpecialValueFor("bonus_regen")
	self.ms = self:GetTalentSpecialValueFor("bonus_movement_speed")
	self.radius = self:GetTalentSpecialValueFor("search_radius")
	if IsServer() then
		self:StartIntervalThink(0.1)
	end
end


function modifier_slark_shadow_dance_handler:OnIntervalThink()
	local caster = self:GetCaster()
	if self:GetParent():HasModifier("modifier_slark_shadow_dance_activated") or self:GetParent():HasModifier("modifier_slark_depth_shroud") then
		self:SetStackCount(0)
		return
	end
	if self:GetParent():PassivesDisabled() then
		self:SetStackCount(self.neutral_disable * 10)
		return
	end
	if self:GetStackCount() > 0 then
		self:DecrementStackCount()
		return
	end
end

function modifier_slark_shadow_dance_handler:IsHidden()
	return self:GetStackCount() ~= 0
end

function modifier_slark_shadow_dance_handler:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_slark_shadow_dance_handler:OnTakeDamage(params)
	if params.unit == self:GetParent() and not params.attacker:IsSameTeam( params.unit ) and not HasBit( params.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS ) then
		self:SetStackCount(self.neutral_disable * 10)
	end
end

function modifier_slark_shadow_dance_handler:GetModifierConstantHealthRegen()
	if not self:IsHidden() then return self.regen end
end

function modifier_slark_shadow_dance_handler:GetModifierMoveSpeedBonus_Percentage()
	if not self:IsHidden() then return self.ms end
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
