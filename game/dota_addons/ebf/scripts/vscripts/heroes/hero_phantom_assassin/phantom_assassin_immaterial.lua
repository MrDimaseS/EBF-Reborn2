phantom_assassin_immaterial = class({})

function phantom_assassin_immaterial:GetIntrinsicModifierName()
    return "modifier_phantom_assassin_immaterial_handler"
end

modifier_phantom_assassin_immaterial_handler = class({})
LinkLuaModifier( "modifier_phantom_assassin_immaterial_handler", "heroes/hero_phantom_assassin/phantom_assassin_immaterial", LUA_MODIFIER_MOTION_NONE )

function modifier_phantom_assassin_immaterial_handler:OnCreated()
    self:OnRefresh()
end

IMMATERIAL_STATE_REDUCE = 1
IMMATERIAL_STATE_INCREASE = 0
IMMATERIAL_STATE_BUFFERING = 2

function modifier_phantom_assassin_immaterial_handler:OnRefresh()
	self.tick_rate = 0.5
    self.evasion_base = self:GetSpecialValueFor("evasion_base")
    self.evasion_per_second = self:GetSpecialValueFor("evasion_per_second") * self.tick_rate
    self.max_stacks = (100 - self.evasion_base) / self.evasion_per_second
    self.loss_delay = self:GetSpecialValueFor("loss_delay")
    self.stifling_multiplier = self:GetSpecialValueFor("stifling_multiplier")
    self.invisibility_threshold = self:GetSpecialValueFor("invisibility_threshold")
    self.evasion_to_lifesteal = self:GetSpecialValueFor("evasion_to_lifesteal") / 100
	
	if IsServer() then
		self._currentMode = IMMATERIAL_STATE_INCREASE
		self._lastTimePenalized = GameRules:GetGameTime()
		self:StartIntervalThink( self.tick_rate )
	end
end

function modifier_phantom_assassin_immaterial_handler:OnIntervalThink()
	if self._currentMode == IMMATERIAL_STATE_BUFFERING then return end
	if GameRules:GetGameTime() - self._lastTimePenalized > self.loss_delay then
		if self._currentMode == IMMATERIAL_STATE_REDUCE then
			self._currentMode = IMMATERIAL_STATE_INCREASE
		end
	end
	if self._currentMode == IMMATERIAL_STATE_INCREASE and self:GetStackCount() < self.max_stacks then
		self:IncrementStackCount()
	elseif self._currentMode == IMMATERIAL_STATE_REDUCE and self:GetStackCount() > 0 then
		self:DecrementStackCount()
	end
	self:StartIntervalThink( self.tick_rate )
end

function modifier_phantom_assassin_immaterial_handler:CheckState()
	if self.invisibility_threshold and self.invisibility_threshold > 0 and (self:GetParent():GetEvasion() >= self.invisibility_threshold) then
		return {[MODIFIER_STATE_INVISIBLE] = true}
	end
end

function modifier_phantom_assassin_immaterial_handler:DeclareFunctions()
    return {MODIFIER_EVENT_ON_ATTACK,
			MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
			MODIFIER_PROPERTY_EVASION_CONSTANT,
			MODIFIER_EVENT_ON_TAKEDAMAGE,
			MODIFIER_PROPERTY_INVISIBILITY_LEVEL }
end

function modifier_phantom_assassin_immaterial_handler:OnAttack(params)
	if self:GetParent():PassivesDisabled() then return end
	if not ( params.attacker == self:GetParent() or params.target == self:GetParent() ) then return end
	if self._currentMode ~= IMMATERIAL_STATE_REDUCE then
		self:StartIntervalThink( self.loss_delay )
		self._currentMode = IMMATERIAL_STATE_REDUCE
		self._lastTimePenalized = GameRules:GetGameTime()
	end
end

function modifier_phantom_assassin_immaterial_handler:OnAbilityFullyCast(params)
	if self:GetParent():PassivesDisabled() then return end
	if not ( params.attacker == self:GetParent() or params.target == self:GetParent() ) then return end
	if self._currentMode ~= IMMATERIAL_STATE_REDUCE then
		self:StartIntervalThink( self.loss_delay )
		self._currentMode = IMMATERIAL_STATE_REDUCE
		self._lastTimePenalized = GameRules:GetGameTime()
	end
end

function modifier_phantom_assassin_immaterial_handler:GetModifierEvasion_Constant(params)
	local evasion = self.evasion_base + self.evasion_per_second * self:GetStackCount()
	if IsClient() then return evasion end
	if self.stifling_multiplier > 0 and params.attacker:HasModifier("modifier_phantom_assassin_stifling_dagger_debuff") then
		evasion = evasion * self.stifling_multiplier
	end
	return evasion
end

function modifier_phantom_assassin_immaterial_handler:OnTakeDamage(params)
	if params.attacker ~= self:GetParent() then return end
	if params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
		local lifesteal = params.damage * params.target:GetEvasion() * self.evasion_to_lifesteal
		
		self.lifeToGive = (self.lifeToGive or 0) + lifesteal
		if self.lifeToGive > 1 then
			local lifeGained = self.lifeToGive
			local preHP = params.attacker:GetHealth()
			params.attacker:HealWithParams( lifeGained, self:GetAbility(), false, true, self, true )
			self.lifeToGive = self.lifeToGive - math.floor(self.lifeToGive)
			local postHP = params.attacker:GetHealth()
			
			
			local actualLifeGained = postHP - preHP
			if actualLifeGained > 0 then
				ParticleManager:FireParticle( "particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_POINT_FOLLOW, params.attacker )
			end
		end
	end
end

function modifier_phantom_assassin_immaterial_handler:GetModifierInvisibilityLevel()
	return #self:GetParent():IsInvisible()
end

function modifier_phantom_assassin_immaterial_handler:IsHidden()
	return self:GetStackCount() == 0
end