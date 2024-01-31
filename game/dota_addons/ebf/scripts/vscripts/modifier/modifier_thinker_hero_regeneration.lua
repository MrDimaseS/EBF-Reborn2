modifier_thinker_hero_regeneration = class({})

function modifier_thinker_hero_regeneration:OnCreated()
	self.delay = 5
	self.delayTimer = 5
	self.baseRegen = 3
	self.regenIncrease = 0.1
	self.currentRegen = self.baseRegen
	self:StartIntervalThink(0.1)
	if IsServer() then
		self:SetStackCount(1)
	end
end

function modifier_thinker_hero_regeneration:OnIntervalThink()
	if self:GetStackCount() == 1 then
		self.currentRegen = self.baseRegen
		if IsServer() then
			self.delayTimer = self.delayTimer - 0.1
			if self.delayTimer <= 0 then
				self:SetStackCount( 0 )
			end
		end
	elseif self:GetStackCount() == 0 then
		self.currentRegen = math.min( 10, self.currentRegen + self.regenIncrease )
	end
end

function modifier_thinker_hero_regeneration:ResetRestoration()
	self:SetStackCount(1)
	self:StartIntervalThink(0.1)
	self.delayTimer = 5
end
	

function modifier_thinker_hero_regeneration:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ABILITY_EXECUTED, MODIFIER_EVENT_ON_TAKEDAMAGE, MODIFIER_EVENT_ON_SPENT_MANA, MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE, MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE }
end

function modifier_thinker_hero_regeneration:OnAbilityExecuted( params )
	if params.attacker == self:GetParent() or params.unit == self:GetParent() then
		self:ResetRestoration()
	end
end

function modifier_thinker_hero_regeneration:OnTakeDamage( params )
	if params.attacker == self:GetParent() or params.unit == self:GetParent() then
		self:ResetRestoration()
	end
end

function modifier_thinker_hero_regeneration:OnSpentMana( params )
	if params.unit == self:GetParent() then
		self:ResetRestoration()
	end
end

function modifier_thinker_hero_regeneration:GetModifierHealthRegenPercentage()
	if not self:IsHidden() then 
		return self.currentRegen
	end
end

function modifier_thinker_hero_regeneration:GetModifierTotalPercentageManaRegen()
	if not self:IsHidden() then return self.currentRegen end
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