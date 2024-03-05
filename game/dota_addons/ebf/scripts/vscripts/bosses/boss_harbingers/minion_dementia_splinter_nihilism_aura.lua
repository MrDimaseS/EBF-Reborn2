minion_dementia_splinter_nihilism_aura = class({})

function minion_dementia_splinter_nihilism_aura:GetIntrinsicModifierName()
	return "modifier_minion_dementia_splinter_nihilism_aura"
end

modifier_minion_dementia_splinter_nihilism_aura = class({})
LinkLuaModifier( "modifier_minion_dementia_splinter_nihilism_aura", "bosses/boss_harbingers/minion_dementia_splinter_nihilism_aura", LUA_MODIFIER_MOTION_NONE )

function modifier_minion_dementia_splinter_nihilism_aura:OnCreated()
	self:OnRefresh()
end

function modifier_minion_dementia_splinter_nihilism_aura:OnRefresh()
	self.radius = self:GetSpecialValueFor("radius")
	self.debuff_duration = self:GetSpecialValueFor("debuff_duration")
end

function modifier_minion_dementia_splinter_nihilism_aura:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_minion_dementia_splinter_nihilism_aura:OnAttackLanded( params )
	if self:GetParent():PassivesDisabled() then return end
	if params.attacker == self:GetParent() then
		params.target:AddNewModifier( params.attacker, self:GetAbility(), "modifier_minion_dementia_splinter_nihilism_aura_atk_debuff", {duration = self.debuff_duration} )
	end
end

function modifier_minion_dementia_splinter_nihilism_aura:IsAura()
	return not self:GetParent():PassivesDisabled()
end

function modifier_minion_dementia_splinter_nihilism_aura:GetModifierAura()
	return "modifier_minion_dementia_splinter_nihilism_aura_aura_debuff"
end

function modifier_minion_dementia_splinter_nihilism_aura:GetAuraRadius()
	return self.radius
end

function modifier_minion_dementia_splinter_nihilism_aura:GetAuraDuration()
	return 0.5
end

function modifier_minion_dementia_splinter_nihilism_aura:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_minion_dementia_splinter_nihilism_aura:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_minion_dementia_splinter_nihilism_aura:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_minion_dementia_splinter_nihilism_aura:IsHidden()
	return self:GetStackCount() <= 0
end

function modifier_minion_dementia_splinter_nihilism_aura:IsPurgable()
	return false
end

modifier_minion_dementia_splinter_nihilism_aura_aura_debuff = class({})
LinkLuaModifier( "modifier_minion_dementia_splinter_nihilism_aura_aura_debuff", "bosses/boss_harbingers/minion_dementia_splinter_nihilism_aura", LUA_MODIFIER_MOTION_NONE )

function modifier_minion_dementia_splinter_nihilism_aura_aura_debuff:OnCreated()
	self:OnRefresh()
end

function modifier_minion_dementia_splinter_nihilism_aura_aura_debuff:OnRefresh()
	self.heal_reduction_aura = -self:GetSpecialValueFor("heal_reduction_aura")
end

function modifier_minion_dementia_splinter_nihilism_aura_aura_debuff:DeclareFunctions()
	return { MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
			 MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
			 MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
			 MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET }
end

function modifier_minion_dementia_splinter_nihilism_aura_aura_debuff:GetModifierLifestealRegenAmplify_Percentage()
	return self.heal_reduction_aura
end

function modifier_minion_dementia_splinter_nihilism_aura_aura_debuff:GetModifierSpellLifestealRegenAmplify_Percentage()
	return self.heal_reduction_aura
end

function modifier_minion_dementia_splinter_nihilism_aura_aura_debuff:GetModifierHPRegenAmplify_Percentage()
	return self.heal_reduction_aura
end

function modifier_minion_dementia_splinter_nihilism_aura_aura_debuff:GetModifierHealAmplify_PercentageTarget()
	return self.heal_reduction_aura
end

modifier_minion_dementia_splinter_nihilism_aura_atk_debuff = class({})
LinkLuaModifier( "modifier_minion_dementia_splinter_nihilism_aura_atk_debuff", "bosses/boss_harbingers/minion_dementia_splinter_nihilism_aura", LUA_MODIFIER_MOTION_NONE )

function modifier_minion_dementia_splinter_nihilism_aura_atk_debuff:OnCreated()
	self:OnRefresh()
end

function modifier_minion_dementia_splinter_nihilism_aura_atk_debuff:OnRefresh()
	self.heal_reduction_atk = -self:GetSpecialValueFor("heal_reduction_atk")
end

function modifier_minion_dementia_splinter_nihilism_aura_atk_debuff:DeclareFunctions()
	return { MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
			 MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
			 MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
			 MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET }
end

function modifier_minion_dementia_splinter_nihilism_aura_atk_debuff:GetModifierLifestealRegenAmplify_Percentage()
	return self.heal_reduction_atk
end

function modifier_minion_dementia_splinter_nihilism_aura_atk_debuff:GetModifierSpellLifestealRegenAmplify_Percentage()
	return self.heal_reduction_atk
end

function modifier_minion_dementia_splinter_nihilism_aura_atk_debuff:GetModifierHPRegenAmplify_Percentage()
	return self.heal_reduction_atk
end

function modifier_minion_dementia_splinter_nihilism_aura_atk_debuff:GetModifierHealAmplify_PercentageTarget()
	return self.heal_reduction_atk
end