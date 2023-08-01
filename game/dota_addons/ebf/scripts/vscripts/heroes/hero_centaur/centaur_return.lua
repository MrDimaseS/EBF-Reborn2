centaur_return = class({})

function centaur_return:GetIntrinsicModifierName()
	return "modifier_centaur_return_passive"
end

function centaur_return:ProcReturn(target, damage)
	local caster = self:GetCaster()
	local fDmg = damage or self:GetSpecialValueFor("return_damage")
	ParticleManager:FireRopeParticle("particles/units/heroes/hero_centaur/centaur_return.vpcf", PATTACH_POINT_FOLLOW, caster, target)
	return self:DealDamage( caster, target, fDmg )
end

modifier_centaur_return_passive = class({})
LinkLuaModifier("modifier_centaur_return_passive", "heroes/hero_centaur/centaur_return", LUA_MODIFIER_MOTION_NONE)

function modifier_centaur_return_passive:IsHidden()
	return true
end

function modifier_centaur_return_passive:IsAura()
	return true
end

function modifier_centaur_return_passive:GetModifierAura()
	return "modifier_centaur_return_return"
end

function modifier_centaur_return_passive:GetAuraRadius()
	return self:GetSpecialValueFor("aura_radius")
end

function modifier_centaur_return_passive:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_centaur_return_passive:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_centaur_return_passive:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

modifier_centaur_return_return = class({})
LinkLuaModifier("modifier_centaur_return_return", "heroes/hero_centaur/centaur_return", LUA_MODIFIER_MOTION_NONE)

function modifier_centaur_return_return:OnCreated()
	self:OnRefresh()
end

function modifier_centaur_return_return:OnRefresh()
	self.bonus_armor_str = self:GetSpecialValueFor("bonus_armor_str") / 100
end

function modifier_centaur_return_return:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK, MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS  }
end

function modifier_centaur_return_return:OnAttack(params)
	if params.target == self:GetParent() then
		if self:GetParent():PassivesDisabled() then return end
		self:GetAbility():ProcReturn( params.attacker )
	end
end

function modifier_centaur_return_return:GetModifierPhysicalArmorBonus(params)
	return self:GetCaster():GetStrength() * self.bonus_armor_str
end