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
    self.no_casting_loss = self:GetSpecialValueFor("no_casting_loss") == 1
    self.stifling_multiplier = self:GetSpecialValueFor("stifling_multiplier")
    self.kills_refresh = self:GetSpecialValueFor("kills_refresh") == 1
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
	if self:GetParent():PassivesDisabled() then 
		self:StartIntervalThink( 0 )
		self:SetStackCount( 0 )
		return
	end
	self:StartIntervalThink( self.tick_rate )
	if GameRules:GetGameTime() - self._lastTimePenalized > self.loss_delay then
		if self._currentMode == IMMATERIAL_STATE_REDUCE then
			self._currentMode = IMMATERIAL_STATE_INCREASE
		end
	end
	if self._currentMode == IMMATERIAL_STATE_INCREASE then
		if not self._blurFX then
			self._blurFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_phantom_assassin/phantom_assassin_blur.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
		end
		if self:GetStackCount() < self.max_stacks then
			self:IncrementStackCount()
		end
	elseif self._currentMode == IMMATERIAL_STATE_REDUCE then
		if self._blurFX then
			ParticleManager:ClearParticle( self._blurFX )
			self._blurFX = nil
		end
		if self:GetStackCount() > 0 then
			self:DecrementStackCount()
		end
	end
end

function modifier_phantom_assassin_immaterial_handler:OnDestroy()
	if self._blurFX then
		ParticleManager:ClearParticle( self._blurFX )
		self._blurFX = nil
	end
end

function modifier_phantom_assassin_immaterial_handler:CheckState()
	if self.invisibility_threshold and self.invisibility_threshold > 0 and (self:GetParent():GetEvasion()*100 >= self.invisibility_threshold) then
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
	if not ( params.attacker == self:GetParent() or params.target == self:GetParent() ) then return end
	if self.no_casting_loss and params.attacker == self:GetParent() and params.attacker:GetAttackData( params.record ).ability and params.attacker:GetAttackData( params.record ).ability:GetAbilityName() == "phantom_assassin_stifling_dagger" then
		return
	end
	if self._currentMode ~= IMMATERIAL_STATE_REDUCE then
		self:StartIntervalThink( self.loss_delay )
		self._currentMode = IMMATERIAL_STATE_REDUCE
	end
	self._lastTimePenalized = GameRules:GetGameTime()
end

function modifier_phantom_assassin_immaterial_handler:OnAbilityFullyCast(params)
	if self.no_casting_loss then return end
	if params.unit ~= self:GetParent() then return end
	if self._currentMode ~= IMMATERIAL_STATE_REDUCE then
		self:StartIntervalThink( self.loss_delay )
		self._currentMode = IMMATERIAL_STATE_REDUCE
	end
	self._lastTimePenalized = GameRules:GetGameTime()
end

function modifier_phantom_assassin_immaterial_handler:GetModifierEvasion_Constant(params)
	local evasion = self.evasion_base + self.evasion_per_second * self:GetStackCount()
	if IsClient() or not params.attacker then return evasion end
	if self.stifling_multiplier > 0 and params.attacker:HasModifier("modifier_phantom_assassin_stifling_dagger_debuff") then
		evasion = evasion * self.stifling_multiplier
	end
	return evasion
end

function modifier_phantom_assassin_immaterial_handler:OnTakeDamage(params)
	if params.attacker:PassivesDisabled() then return end
	if params.attacker ~= self:GetParent() then return end
	if self.kills_refresh and params.damage >= params.unit:GetHealth() then
		Timers:CreateTimer( function()
			if not ( IsEntitySafe( params.unit ) and params.unit:NotDead() ) then
				params.attacker:RefreshAllCooldowns( false )
			end
		end)
	end
	if params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
		local lifesteal = params.damage * params.attacker:GetEvasion() * self.evasion_to_lifesteal
		
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