modifier_boss_enraged = class({})

function modifier_boss_enraged:OnCreated()
	self:OnRefresh()
end

function modifier_boss_enraged:OnRefresh()
	if IsServer() then
		self:IncrementStackCount()
	end
end

function modifier_boss_enraged:CheckState()
	if self:GetStackCount() >= 3 then
		return {[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true}
	end
end

function modifier_boss_enraged:DeclareFunctions()
	return {MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE, 
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
			MODIFIER_PROPERTY_TOOLTIP }
end

function modifier_boss_enraged:GetModifierMoveSpeedBonus_Percentage()
	return 50 * self:GetStackCount()
end

function modifier_boss_enraged:GetModifierTotalDamageOutgoing_Percentage()
	return 50 * self:GetStackCount()
end

function modifier_boss_enraged:GetModifierMagicalResistanceBonus()
	return -10 * self:GetStackCount()
end

function modifier_boss_enraged:GetModifierPhysicalArmorBonus(event)
	return -3 * self:GetStackCount()
end

function modifier_boss_enraged:GetModifierHPRegenAmplify_Percentage()
	return -25 * self:GetStackCount()
end

function modifier_boss_enraged:GetModifierLifestealRegenAmplify_Percentage()
	return -25 * self:GetStackCount()
end

function modifier_boss_enraged:GetModifierSpellLifestealRegenAmplify_Percentage()
	return -25 * self:GetStackCount()
end

function modifier_boss_enraged:GetModifierHealAmplify_PercentageSource()
	return -25 * self:GetStackCount()
end

function modifier_boss_enraged:OnTooltip()
	return 50 * self:GetStackCount()
end

function modifier_boss_enraged:GetEffectName()
	return "particles/units/heroes/hero_lone_druid/lone_druid_battle_cry_overhead.vpcf"
end

function modifier_boss_enraged:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_boss_enraged:GetTexture()
	return "axe_berserkers_call"
end

function modifier_boss_enraged:IsHidden()
	return false
end

function modifier_boss_enraged:IsPurgable()
	return false
end
