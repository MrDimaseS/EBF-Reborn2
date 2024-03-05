minion_hellish_servant_infernal_servitude = class({})

function minion_hellish_servant_infernal_servitude:GetIntrinsicModifierName()
	return "modifier_minion_hellish_servant_infernal_servitude_handler"
end

modifier_minion_hellish_servant_infernal_servitude_handler = class({})
LinkLuaModifier("modifier_minion_hellish_servant_infernal_servitude_handler", "bosses/boss_doom/minion_hellish_servant_infernal_servitude", LUA_MODIFIER_MOTION_NONE)

function modifier_minion_hellish_servant_infernal_servitude_handler:OnCreated()
	self.radius = self:GetSpecialValueFor("radius")
end

function modifier_minion_hellish_servant_infernal_servitude_handler:OnRefresh()
	self.radius = self:GetSpecialValueFor("radius")
end

function modifier_minion_hellish_servant_infernal_servitude_handler:IsAura()
	return true
end

--------------------------------------------------------------------------------

function modifier_minion_hellish_servant_infernal_servitude_handler:GetModifierAura()
	return "modifier_minion_hellish_servant_infernal_servitude_checker"
end

--------------------------------------------------------------------------------

function modifier_minion_hellish_servant_infernal_servitude_handler:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

--------------------------------------------------------------------------------

function modifier_minion_hellish_servant_infernal_servitude_handler:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_minion_hellish_servant_infernal_servitude_handler:GetAuraEntityReject(entity)
	return entity:GetUnitName() == self:GetCaster():GetUnitName()
end

--------------------------------------------------------------------------------

function modifier_minion_hellish_servant_infernal_servitude_handler:GetAuraRadius()
	return self.radius
end

function modifier_minion_hellish_servant_infernal_servitude_handler:GetAuraDuration()
	return 0.5
end

--------------------------------------------------------------------------------
function modifier_minion_hellish_servant_infernal_servitude_handler:IsPurgeable()
    return false
end

function modifier_minion_hellish_servant_infernal_servitude_handler:IsHidden()
    return true
end

modifier_minion_hellish_servant_infernal_servitude_checker = class({})
LinkLuaModifier("modifier_minion_hellish_servant_infernal_servitude_checker", "bosses/boss_doom/minion_hellish_servant_infernal_servitude", LUA_MODIFIER_MOTION_NONE)

function modifier_minion_hellish_servant_infernal_servitude_checker:OnCreated()
	self:OnRefresh()
	if IsServer() then
		local FX = ParticleManager:CreateParticle("particles/units/heroes/hero_wisp/wisp_tether.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster())
		ParticleManager:SetParticleControlEnt(FX, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetCaster():GetAbsOrigin(), true)
		
		ParticleManager:SetParticleControlEnt(FX, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
		self:AddEffect(FX)
	end
end

function modifier_minion_hellish_servant_infernal_servitude_checker:OnRefresh()
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
	self.bonus_magic_resist = self:GetSpecialValueFor("bonus_magic_resist")
end

function modifier_minion_hellish_servant_infernal_servitude_checker:DeclareFunctions()
	return {MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS}
end

function modifier_minion_hellish_servant_infernal_servitude_checker:GetModifierDamageOutgoing_Percentage()
	return self.bonus_damage
end

function modifier_minion_hellish_servant_infernal_servitude_checker:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_minion_hellish_servant_infernal_servitude_checker:GetModifierMagicalResistanceBonus()
	return self.bonus_magic_resist
end

function modifier_minion_hellish_servant_infernal_servitude_checker:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end
