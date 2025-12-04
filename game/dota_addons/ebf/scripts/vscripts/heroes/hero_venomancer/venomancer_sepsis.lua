venomancer_sepsis = class({})

function venomancer_sepsis:GetIntrinsicModifierName()
	return "modifier_venomancer_sepsis_handler"
end

LinkLuaModifier( "modifier_venomancer_sepsis_handler", "heroes/hero_venomancer/venomancer_sepsis", LUA_MODIFIER_MOTION_NONE )
modifier_venomancer_sepsis_handler = class({})

function modifier_venomancer_sepsis_handler:OnCreated()
	self:OnRefresh()
end

function modifier_venomancer_sepsis_handler:OnRefresh()
	self.bonus_poison_damage = self:GetSpecialValueFor("bonus_poison_damage")
	self.hits_to_proc_bonus = self:GetSpecialValueFor("hits_to_proc_bonus")
	
	self.proc_lifesteal = self:GetSpecialValueFor("proc_lifesteal") / 100
	self.proc_lifesteal_radius = self:GetSpecialValueFor("proc_lifesteal_radius")
	self.proc_bonus_damage = self:GetSpecialValueFor("proc_bonus_damage")
end

function modifier_venomancer_sepsis_handler:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED}
end

function modifier_venomancer_sepsis_handler:OnAttackLanded(params)
	local caster = self:GetCaster()
	if caster ~= params.attacker then return end
	local ability = self:GetAbility()
	local bonusPoisonDamage = params.target:GetPoison() * self.bonus_poison_damage
	if bonusPoisonDamage <= 0 then return end
	if self.proc_bonus_damage > 0 and self:GetStackCount() >= self.hits_to_proc_bonus then
		 bonusPoisonDamage = params.target:GetPoison() * self.proc_bonus_damage
	end
	local damage = ability:DealDamage( caster, params.target, bonusPoisonDamage, {damage_type = DAMAGE_TYPE_MAGICAL}
	if self.proc_lifesteal > 0 and self:GetStackCount() >= self.hits_to_proc_bonus then
		local heal = damage * self.proc_lifesteal
		for _, ally in ipairs( caster:FindFriendlyUnitsInRadius( params.target:GetAbsOrigin(), self.proc_lifesteal_radius ) ) do
			ally:HealEvent( heal, ability, caster, {heal_type = DOTA_HEAL_TYPE_LIFESTEAL})
		end
	end
	if self:GetStackCount() >= self.hits_to_proc_bonus then
		self:SetStackCount( 0 )
	else
		self:IncrementStackCount()
	end
end

function modifier_venomancer_sepsis_handler:IsHidden()
	return true
end