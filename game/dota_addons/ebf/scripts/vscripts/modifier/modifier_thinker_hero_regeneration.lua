modifier_thinker_hero_regeneration = class({})

function modifier_thinker_hero_regeneration:OnCreated()
	self.delay = 5
	self.regen = 5
	if IsServer() then
		self:SetStackCount(1)
	end
end

function modifier_thinker_hero_regeneration:OnIntervalThink()
	self:StartIntervalThink(-1)
	self:SetStackCount(0)
end

function modifier_thinker_hero_regeneration:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ABILITY_EXECUTED, MODIFIER_EVENT_ON_TAKEDAMAGE, MODIFIER_EVENT_ON_SPENT_MANA, MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE }
end

function modifier_thinker_hero_regeneration:OnAbilityExecuted( params )
	if params.attacker == self:GetParent() or params.unit == self:GetParent() then
		self:SetStackCount(1)
		self:StartIntervalThink(self.delay)
	end
end

function modifier_thinker_hero_regeneration:OnTakeDamage( params )
	if params.attacker == self:GetParent() or params.unit == self:GetParent() then
		self:SetStackCount(1)
		self:StartIntervalThink(self.delay)
	end
end

function modifier_thinker_hero_regeneration:OnSpentMana( params )
	if params.unit == self:GetParent() then
		self:SetStackCount(1)
		self:StartIntervalThink(self.delay)
	end
end

function modifier_thinker_hero_regeneration:GetModifierHealthRegenPercentage()
	if not self:IsHidden() then return self.regen end
end

function modifier_thinker_hero_regeneration:GetModifierTotalPercentageManaRegen()
	if not self:IsHidden() then return self.regen end
end

function modifier_thinker_hero_regeneration:IsHidden()
	return self:GetStackCount() == 1
end

function modifier_thinker_hero_regeneration:IsPurgable()
	return false
end

function modifier_thinker_hero_regeneration:DestroyOnExpire()
	return false
end

function modifier_thinker_hero_regeneration:RemoveOnDeath()
	return false
end

function modifier_thinker_hero_regeneration:IsPermanent()
	return true
end

function modifier_thinker_hero_regeneration:GetPriority()
	return MODIFIER_PRIORITY_HIGH
end

function modifier_thinker_hero_regeneration:GetTexture()
	return "rune_regen"
end