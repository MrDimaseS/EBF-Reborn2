minion_mania_splinter_manic_aura = class({})

function minion_mania_splinter_manic_aura:GetIntrinsicModifierName()
	return "modifier_minion_mania_splinter_manic_aura"
end

modifier_minion_mania_splinter_manic_aura = class({})
LinkLuaModifier( "modifier_minion_mania_splinter_manic_aura", "bosses/boss_harbingers/minion_mania_splinter_manic_aura", LUA_MODIFIER_MOTION_NONE )

function modifier_minion_mania_splinter_manic_aura:OnCreated()
	self:OnRefresh()
end

function modifier_minion_mania_splinter_manic_aura:OnRefresh()
	self.radius = self:GetSpecialValueFor("radius")
end

function modifier_minion_mania_splinter_manic_aura:IsAura()
	return not self:GetParent():PassivesDisabled()
end

function modifier_minion_mania_splinter_manic_aura:GetModifierAura()
	return "modifier_minion_mania_splinter_manic_aura_aura_buff"
end

function modifier_minion_mania_splinter_manic_aura:GetAuraRadius()
	return self.radius
end

function modifier_minion_mania_splinter_manic_aura:GetAuraDuration()
	return 0.5
end

function modifier_minion_mania_splinter_manic_aura:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_minion_mania_splinter_manic_aura:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_minion_mania_splinter_manic_aura:IsHidden()
	return true
end

function modifier_minion_mania_splinter_manic_aura:IsPurgable()
	return false
end

modifier_minion_mania_splinter_manic_aura_aura_buff = class({})
LinkLuaModifier( "modifier_minion_mania_splinter_manic_aura_aura_buff", "bosses/boss_harbingers/minion_mania_splinter_manic_aura", LUA_MODIFIER_MOTION_NONE )

function modifier_minion_mania_splinter_manic_aura_aura_buff:OnCreated()
	self:OnRefresh()
end

function modifier_minion_mania_splinter_manic_aura_aura_buff:OnRefresh()
	self.critical_damage = self:GetSpecialValueFor("critical_damage")
	self.critical_chance = self:GetSpecialValueFor("critical_chance")
	self.bonus_attackspeed = self:GetSpecialValueFor("bonus_attackspeed")
end

function modifier_minion_mania_splinter_manic_aura_aura_buff:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
			 MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end

function modifier_minion_mania_splinter_manic_aura_aura_buff:GetCritDamage()
	return self.critical_damage / 100
end

function modifier_minion_mania_splinter_manic_aura_aura_buff:GetModifierPreAttack_CriticalStrike()
	if RollPseudoRandomPercentage( self.critical_chance, self:GetAbility():entindex(), self:GetParent() ) then
		return self.critical_damage
	end
end

function modifier_minion_mania_splinter_manic_aura_aura_buff:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attackspeed
end