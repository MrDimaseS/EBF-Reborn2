doom_bringer_lvl_pain = class({})

function doom_bringer_lvl_pain:IsStealable()
	return true
end
function doom_bringer_lvl_pain:IsHiddenWhenStolen()
	return false
end
function doom_bringer_lvl_pain:GetIntrinsicModifierName()
	return "modifier_doom_bringer_lvl_pain_handler"
end

modifier_doom_bringer_lvl_pain_handler = class({})
LinkLuaModifier( "modifier_doom_bringer_lvl_pain_handler", "heroes/hero_doom/doom_bringer_lvl_pain", LUA_MODIFIER_MOTION_NONE )

function modifier_doom_bringer_lvl_pain_handler:IsHidden()
	return true
end
function modifier_doom_bringer_lvl_pain_handler:OnCreated()
	self:OnRefresh()
end
function modifier_doom_bringer_lvl_pain_handler:OnRefresh()
	self.bonus_creep_damage = self:GetSpecialValueFor("bonus_creep_damage")
	self.creep_death_radius = self:GetSpecialValueFor("creep_death_radius")
	self.creep_death_heal = self:GetSpecialValueFor("creep_death_heal") / 100
	self.creep_death_damage_duration = self:GetSpecialValueFor("creep_death_damage_duration")
	self.creep_death_cooldown_reduction = self:GetSpecialValueFor("creep_death_cooldown_reduction") / 100
end
function modifier_doom_bringer_lvl_pain_handler:DeclareFunctions()
    local funcs = {
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_EVENT_SPELL_APPLIED_SUCCESSFULLY
    }
    return funcs
end
function modifier_doom_bringer_lvl_pain_handler:GetModifierTotalDamageOutgoing_Percentage(params)
    if not params.target:IsConsideredHero() then
		return self.bonus_creep_damage
	end
end
function modifier_doom_bringer_lvl_pain_handler:OnSpellAppliedSuccessfully(params)
	local caster = self:GetCaster()
	if params.ability:GetCaster() ~= caster then return end
	if not params.target then return end
	local ability = self:GetAbility()
	local target = params.target
	
	if target:IsConsideredHero() then return end
	target:AttemptKill( ability, caster )
end
function modifier_doom_bringer_lvl_pain_handler:OnTakeDamage(event)
	if self:GetCaster():PassivesDisabled() or IsClient() then return end
	if event.unit:GetHealth() > 0 then return end

	local parent = self:GetParent()
	if not event.unit:IsConsideredHero() then
		local distance = CalculateDistance(parent, event.unit)
		if self.creep_death_heal ~= 0 and distance <= self.creep_death_radius then
			parent:Heal(parent:GetMaxHealth() * self.creep_death_heal, self:GetAbility())
		end
		if self.creep_death_damage_duration ~= 0 and distance <= self.creep_death_radius then
			parent:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_doom_bringer_lvl_pain_wrath_and_greed", { duration = self.creep_death_damage_duration })
		end
		if self.creep_death_cooldown_reduction ~= 0 and event.attacker == parent then
			for i = 0, parent:GetAbilityCount() - 1 do
				local ability = parent:GetAbilityByIndex(i)
				if ability and ability:GetCooldownTimeRemaining() > 0 then
					ability:ModifyCooldown(-(ability:GetCooldownTimeRemaining() * self.creep_death_cooldown_reduction))
				end
			end
		end
	end
end

modifier_doom_bringer_lvl_pain_wrath_and_greed = class({})
LinkLuaModifier( "modifier_doom_bringer_lvl_pain_wrath_and_greed", "heroes/hero_doom/doom_bringer_lvl_pain", LUA_MODIFIER_MOTION_NONE )

function modifier_doom_bringer_lvl_pain_wrath_and_greed:IsHidden()
	return false
end
function modifier_doom_bringer_lvl_pain_wrath_and_greed:IsDebuff()
	return false
end
function modifier_doom_bringer_lvl_pain_wrath_and_greed:IsPurgable()
	return true
end
function modifier_doom_bringer_lvl_pain_wrath_and_greed:OnCreated()
	self:OnRefresh()
end
function modifier_doom_bringer_lvl_pain_wrath_and_greed:OnRefresh()
	self.damage = self:GetSpecialValueFor("creep_death_damage")
	self.damage_creeps = self:GetSpecialValueFor("creep_death_damage_creeps")
end
function modifier_doom_bringer_lvl_pain_wrath_and_greed:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
	}
end
function modifier_doom_bringer_lvl_pain_wrath_and_greed:GetModifierTotalDamageOutgoing_Percentage(event)
	if event.attacker == self:GetParent() then
		if event.target:IsConsideredHero() then
			return self.damage
		else
			return self.damage_creeps
		end
	end
end