necrolyte_sadist = class({})

function necrolyte_sadist:GetIntrinsicModifierName()
	return "modifier_necrophos_sadist_passive"
end

modifier_necrophos_sadist_passive = class({})
LinkLuaModifier( "modifier_necrophos_sadist_passive", "heroes/hero_necrophos/necrolyte_sadist", LUA_MODIFIER_MOTION_NONE )

function modifier_necrophos_sadist_passive:OnCreated()
	self:OnRefresh()
end

function modifier_necrophos_sadist_passive:OnRefresh()
	self.duration = self:GetSpecialValueFor("regen_duration")
	self.hero_multiplier = self:GetSpecialValueFor("hero_multiplier")
	self.kill_multiplier = self:GetSpecialValueFor("kill_multiplier")
end

function modifier_necrophos_sadist_passive:DeclareFunctions()
	return {MODIFIER_EVENT_ON_DEATH}
end

function modifier_necrophos_sadist_passive:OnDeath(params)
	if params.unit:HasModifier("modifier_necrophos_heart_stopper_passive_degen") or params.attacker == self:GetParent() then
		local stacks = 1
		if params.unit:IsConsideredHero() then
			stacks = stacks * self.hero_multiplier
		end
		if params.attacker == self:GetParent() or params.unit:HasModifier("modifier_necrolyte_reapers_scythe_upgrader_mark") then
			stacks = stacks * self.kill_multiplier
		end
		ParticleManager:FireRopeParticle("particles/units/heroes/hero_necrolyte/necrolyte_sadist.vpcf", PATTACH_POINT_FOLLOW, params.unit, self:GetParent())
		for i = 1, stacks do
			self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_necrolyte_sadist_buff", {duration = self.duration})
		end
	end
end

function modifier_necrophos_sadist_passive:IsHidden()
	return true
end

modifier_necrolyte_sadist_buff = class({})
LinkLuaModifier("modifier_necrolyte_sadist_buff", "heroes/hero_necrophos/necrolyte_sadist", LUA_MODIFIER_MOTION_NONE)

function modifier_necrolyte_sadist_buff:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:SetStackCount(1)
	end
end

function modifier_necrolyte_sadist_buff:OnRefresh()
	self.hp_regen = self:GetSpecialValueFor("health_regen")
	self.mp_regen = self:GetSpecialValueFor("mana_regen")
	self.bonus_aoe = self:GetSpecialValueFor("bonus_aoe")
	if self.bonus_aoe > 0 then
		self:GetCaster()._aoeModifiersList[self] = true
	end
	if IsServer() then
		self:AddIndependentStack()
	end
end

function modifier_necrolyte_sadist_buff:OnDestroy()
	self:GetCaster()._aoeModifiersList[self] = nil
end

function modifier_necrolyte_sadist_buff:DeclareFunctions()
	return {MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT}
end

function modifier_necrolyte_sadist_buff:GetModifierConstantHealthRegen()
	return self.hp_regen * self:GetStackCount()
end

function modifier_necrolyte_sadist_buff:GetModifierConstantManaRegen()
	return self.mp_regen * self:GetStackCount()
end

function modifier_necrolyte_sadist_buff:GetModifierAoEBonusConstantStacking()
	return self.bonus_aoe * self:GetStackCount()
end
