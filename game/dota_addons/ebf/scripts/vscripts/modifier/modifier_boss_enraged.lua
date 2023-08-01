modifier_boss_enraged = class({})

function modifier_boss_enraged:OnCreated()
	self.attackSpeed = self:GetParent():GetAttackSpeed() * 100
	self:OnRefresh()
end

function modifier_boss_enraged:OnRefresh()
	if IsServer() then
		self:IncrementStackCount()
	end
end

function modifier_boss_enraged:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, 
			MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE, 
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, 
			MODIFIER_PROPERTY_TOOLTIP }
end

function modifier_boss_enraged:GetModifierAttackSpeedBonus_Constant()
	return (self.attackSpeed or 100) * 0.30 * self:GetStackCount()
end

function modifier_boss_enraged:GetModifierMoveSpeedBonus_Percentage()
	return 30 * self:GetStackCount()
end

function modifier_boss_enraged:GetModifierTotalDamageOutgoing_Percentage()
	return 30 * self:GetStackCount()
end

function modifier_boss_enraged:OnTooltip()
	return 30 * self:GetStackCount()
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
