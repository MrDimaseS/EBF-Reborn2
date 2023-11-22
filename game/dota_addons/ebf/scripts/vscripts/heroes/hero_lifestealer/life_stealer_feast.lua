life_stealer_feast = class({})

function life_stealer_feast:GetIntrinsicModifierName()
	return "modifier_life_stealer_feast_ebf"
end

modifier_life_stealer_feast_ebf = class({})
LinkLuaModifier("modifier_life_stealer_feast_ebf", "heroes/hero_lifestealer/life_stealer_feast", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------
-- Classifications
function modifier_life_stealer_feast_ebf:IsHidden()
	return true
end

function modifier_life_stealer_feast_ebf:IsDebuff()
	return false
end

function modifier_life_stealer_feast_ebf:IsPurgable()
	return false
end

-- Optional Classifications
function modifier_life_stealer_feast_ebf:RemoveOnDeath()
	return false
end

function modifier_life_stealer_feast_ebf:DestroyOnExpire()
	return false
end

function modifier_life_stealer_feast_ebf:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}

	return funcs
end

function modifier_life_stealer_feast_ebf:OnAttackLanded( params )
	local parent = self:GetParent()
	if params.attacker ~= parent then return end
	if parent:PassivesDisabled() then return end
	local ability = self:GetAbility()
	
	local preHP = parent:GetHealth()
	parent:HealWithParams( self:GetSpecialValueFor("leech"), ability, true, true, healer, false)
	local healing = parent:GetHealth() - preHP
	if healing > 0 then
		SendOverheadEventMessage(parent, OVERHEAD_ALERT_HEAL, parent, healing, parent)
	end
end

function modifier_life_stealer_feast_ebf:GetModifierPreAttack_BonusDamage()
	if self:GetParent():PassivesDisabled() then return end
	return self:GetSpecialValueFor("damage")
end

modifier_life_stealer_open_wounds_feast = class(modifier_life_stealer_feast_ebf)

function modifier_life_stealer_open_wounds_feast:IsHidden()
	return false
end

function modifier_life_stealer_open_wounds_feast:IsDebuff()
	return false
end

function modifier_life_stealer_open_wounds_feast:IsPurgable()
	return false
end

-- Optional Classifications
function modifier_life_stealer_open_wounds_feast:RemoveOnDeath()
	return true
end

function modifier_life_stealer_open_wounds_feast:DestroyOnExpire()
	return true
end

function modifier_life_stealer_open_wounds_feast:GetModifierPreAttack_BonusDamage()
	return self:GetSpecialValueFor("damage")
end