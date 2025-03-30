life_stealer_feast = class({})

function life_stealer_feast:GetIntrinsicModifierName()
	return "modifier_life_stealer_feast_ebf"
end

modifier_life_stealer_feast_ebf = class({})
LinkLuaModifier("modifier_life_stealer_feast_ebf", "heroes/hero_lifestealer/life_stealer_feast", LUA_MODIFIER_MOTION_NONE)

function modifier_life_stealer_feast_ebf:OnCreated()
	self:OnRefresh()
end

function modifier_life_stealer_feast_ebf:OnRefresh()
	self.leech = self:GetSpecialValueFor("leech")
	self.damage = self:GetSpecialValueFor("damage")
	self.bonus_hp_per_creep = self:GetSpecialValueFor("bonus_hp_per_creep")
end

function modifier_life_stealer_feast_ebf:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL, 
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE
	}

	return funcs
end

function modifier_life_stealer_feast_ebf:OnAttackLanded( params )
	local parent = self:GetParent()
	if params.attacker ~= parent then return end
	if parent:PassivesDisabled() then return end
	local ability = self:GetAbility()
	
	local preHP = parent:GetHealth()
	parent:HealWithParams( self.leech, ability, true, true, self:GetCaster(), false)
	local healing = parent:GetHealth() - preHP
	if healing > 0 then
		SendOverheadEventMessage(parent, OVERHEAD_ALERT_HEAL, parent, healing, parent)
	end
end

function modifier_life_stealer_feast_ebf:OnDeath( params )
	local parent = self:GetParent()
	if params.attacker ~= parent then return end
	if parent:PassivesDisabled() then return end
	self:IncrementStackCount()
	parent:CalculateStatBonus( true )
end

function modifier_life_stealer_feast_ebf:GetModifierPreAttack_BonusDamage()
	if self:GetParent():PassivesDisabled() then return end
	return self.damage
end

function modifier_life_stealer_feast_ebf:GetModifierExtraHealthBonus()
	return self.bonus_hp_per_creep * self:GetStackCount()
end

function modifier_life_stealer_feast_ebf:GetModifierOverrideAbilitySpecial(params)
	if params.ability == self:GetAbility() then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if specialValue == "bonus_hp_total" then
			return 1
		end
	end
end

function modifier_life_stealer_feast_ebf:GetModifierOverrideAbilitySpecialValue(params)
	if params.ability == self:GetAbility() then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if specialValue == "bonus_hp_total" then
			return self.bonus_hp_per_creep * self:GetStackCount()
		end
	end
end

function modifier_life_stealer_feast_ebf:IsHidden()
	return true
end

function modifier_life_stealer_feast_ebf:IsDebuff()
	return false
end

function modifier_life_stealer_feast_ebf:IsPurgable()
	return false
end

function modifier_life_stealer_feast_ebf:RemoveOnDeath()
	return false
end

function modifier_life_stealer_feast_ebf:DestroyOnExpire()
	return false
end

modifier_life_stealer_open_wounds_feast = class(modifier_life_stealer_feast_ebf)

function modifier_life_stealer_open_wounds_feast:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED,
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE}
end

function modifier_life_stealer_open_wounds_feast:GetModifierPreAttack_BonusDamage()
	return self.damage
end

function modifier_life_stealer_open_wounds_feast:IsHidden()
	return false
end

function modifier_life_stealer_open_wounds_feast:RemoveOnDeath()
	return true
end

function modifier_life_stealer_open_wounds_feast:DestroyOnExpire()
	return true
end

