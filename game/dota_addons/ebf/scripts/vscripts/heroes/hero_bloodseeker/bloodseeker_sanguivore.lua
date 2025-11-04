bloodseeker_sanguivore = class({})

function bloodseeker_sanguivore:GetIntrinsicModifierName()
	return "modifier_bloodseeker_sanguivore_buff"
end

modifier_bloodseeker_sanguivore_buff = class({})
LinkLuaModifier( "modifier_bloodseeker_sanguivore_buff", "heroes/hero_bloodseeker/bloodseeker_sanguivore", LUA_MODIFIER_MOTION_NONE )

function modifier_bloodseeker_sanguivore_buff:OnCreated()
	self:OnRefresh()
	if IsServer() then self:SetHasCustomTransmitterData(true) end
end

function modifier_bloodseeker_sanguivore_buff:OnRefresh()
	self.kill_stacks = self:GetSpecialValueFor("kill_pct") / 100
	self.heal_duration = self:GetSpecialValueFor("heal_duration")
	self.internal_cooldown = self:GetSpecialValueFor("internal_cooldown")
	self.internal_cd_refresh = self:GetSpecialValueFor("internal_cd_refresh")
	self.pure_damage_lifesteal_pct = self:GetSpecialValueFor("pure_damage_lifesteal_pct")
	
	self:GetParent()._pureLifestealModifiersList = self:GetParent()._pureLifestealModifiersList or {}
	self:GetParent()._pureLifestealModifiersList[self] = true
	
	self.blood_mist_aoe = self:GetSpecialValueFor("blood_mist_aoe")
	self.blood_mist_missing_hp_dmg = self:GetSpecialValueFor("blood_mist_missing_hp_dmg") / 100
	
	if IsServer() and self.blood_mist_aoe > 0 then 
		self:StartIntervalThink(1.0)
	end
end

function modifier_bloodseeker_sanguivore_buff:OnIntervalThink()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local missingHPDmg = self:GetCaster():GetHealthDeficit() * self.blood_mist_missing_hp_dmg
	if missingHPDmg > 1 then
		if not self.nFX then
			self.nFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_bloodseeker/bloodseeker_scepter_blood_mist_aoe.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster() )
			ParticleManager:SetParticleControl(self.nFX, 1, Vector( self.blood_mist_aoe, 1, 1 ) )
		end
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self.blood_mist_aoe ) ) do
			ability:DealDamage( caster, enemy, missingHPDmg, { damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION } )
		end
	else
		if self.nFX then
			ParticleManager:ClearParticle( self.nFX )
			self.nFX = nil
		end
	end
end

function modifier_bloodseeker_sanguivore_buff:OnDestroy()
	if self.nFX then
		ParticleManager:ClearParticle( self.nFX )
		self.nFX = nil
	end
end

function modifier_bloodseeker_sanguivore_buff:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_bloodseeker_sanguivore_buff:GetModifierProperty_PureLifesteal(data)
	return self.pure_damage_lifesteal_pct
end

function modifier_bloodseeker_sanguivore_buff:OnTakeDamage( params )
	local caster = self:GetCaster()
	if params.attacker ~= caster or params.attacker == params.unit then return end
	local ability = self:GetAbility()
	if IsModifierSafe( self._internalCD ) then
		local newDuration = self._internalCD:GetRemainingTime() - self.internal_cd_refresh
		if newDuration > 0 then
			self._internalCD:SetDuration( newDuration, true )
		else
			self._internalCD:Destroy()
		end
	else
		local stacks = 1
		if not params.unit:IsAlive() then
			stacks = stacks * self.kill_stacks
		end
		
		local regeneration = caster:AddNewModifier( caster, ability, "modifier_bloodseeker_sanguivore_regeneration", {duration = self.heal_duration} )
		regeneration:AddIndependentStack( { duration = self.heal_duration, stacks = math.floor( stacks ) } )
		
		self._internalCD = caster:AddNewModifier( caster, ability, "modifier_bloodseeker_sanguivore_cd", {duration = self.internal_cooldown, ignoreStatusResist = true} )
	end
end

function modifier_bloodseeker_sanguivore_buff:IsHidden()
	return true
end

modifier_bloodseeker_sanguivore_cd = class({})
LinkLuaModifier( "modifier_bloodseeker_sanguivore_cd", "heroes/hero_bloodseeker/bloodseeker_sanguivore", LUA_MODIFIER_MOTION_NONE )

function modifier_bloodseeker_sanguivore_cd:IsDebuff()
	return true
end

function modifier_bloodseeker_sanguivore_cd:IsPurgable()
	return false
end

modifier_bloodseeker_sanguivore_regeneration = class({})
LinkLuaModifier( "modifier_bloodseeker_sanguivore_regeneration", "heroes/hero_bloodseeker/bloodseeker_sanguivore", LUA_MODIFIER_MOTION_NONE )

function modifier_bloodseeker_sanguivore_regeneration:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink( 0.33 )
	end
end

function modifier_bloodseeker_sanguivore_regeneration:OnRefresh()
	self.max_hp_percent_heal_tooltip = self:GetSpecialValueFor("max_hp_percent_heal_tooltip") / 100
	
	self.heal_factor = 1
	self.heal_duration = self:GetSpecialValueFor("heal_duration")
end

function modifier_bloodseeker_sanguivore_regeneration:DeclareFunctions()
	return { MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE }
end

function modifier_bloodseeker_sanguivore_regeneration:GetModifierHealthRegenPercentage()
	return 100 * self.max_hp_percent_heal_tooltip * self:GetStackCount() / self.heal_duration
end