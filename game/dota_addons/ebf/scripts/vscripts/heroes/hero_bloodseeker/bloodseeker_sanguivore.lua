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
	self.hero_stacks = 100 / self:GetSpecialValueFor("creep_pct")
	self.kill_stacks = self:GetSpecialValueFor("kill_pct") / 100
	self.heal_duration = self:GetSpecialValueFor("heal_duration")
	self.pure_damage_lifesteal_pct = self:GetSpecialValueFor("pure_damage_lifesteal_pct")
	
	self.max_shield_pct = self:GetSpecialValueFor("max_shield_pct")
	self.barrier_decay_pct = self:GetSpecialValueFor("barrier_decay_pct")
	self.barrier_block = 0
	if IsServer() then self:SendBuffRefreshToClients() end
end

function modifier_bloodseeker_sanguivore_buff:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE, MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT, MODIFIER_EVENT_ON_HEAL_RECEIVED }
end

function modifier_bloodseeker_sanguivore_buff:OnTakeDamage( params )
	local caster = self:GetCaster()
	if params.attacker ~= caster or params.attacker == params.unit then return end
	local ability = self:GetAbility()
	if params.damage_type == DAMAGE_TYPE_PURE then
		local lifesteal = params.damage * self.pure_damage_lifesteal_pct / 100
		parent:HealEvent( lifesteal, ability, caster )
	end
	if ( params.inflictor and caster:HasAbility( params.inflictor:GetAbilityName() ) ) or not params.unit:IsAlive() then
		local stacks = 1
		if params.unit:IsConsideredHero() then
			stacks = stacks * self.hero_stacks
		end
		if not params.unit:IsAlive() then
			stacks = stacks * self.kill_stacks
		end
		
		local regeneration = caster:AddNewModifier( caster, ability, "modifier_bloodseeker_sanguivore_regeneration", {duration = self.heal_duration} )
		regeneration:AddIndependentStack( { duration = self.heal_duration, stacks = math.floor( stacks ) } )
	end
end

function modifier_item_blood_gem_passive:GetModifierIncomingDamageConstant( params )
	if (self.barrier_block or 0) <= 0 then return end
	if IsServer() then
		local barrier_block = math.min( self.barrier_block, params.damage )
		self.barrier_block = math.max( 0, self.barrier_block - barrier_block )
		self:SendBuffRefreshToClients()
		return -barrier_block
	else
		return self.barrier_block
	end
end

function modifier_bloodseeker_sanguivore_buff:OnHealReceived( params )
	PrintAll( params )
end

function modifier_bloodseeker_sanguivore_buff:AddCustomTransmitterData()
	return {barrier_block = self.barrier_block}
end

function modifier_bloodseeker_sanguivore_buff:HandleCustomTransmitterData(data)
	self.barrier_block = data.barrier_block
end


function modifier_bloodseeker_sanguivore_buff:IsHidden()
	return true
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
	self.creep_pct = self:GetSpecialValueFor("creep_pct") / 100
	
	self.heal_factor = 1
	self.heal_duration = self:GetSpecialValueFor("heal_duration")
	
	self.mist = self:GetCaster():FindAbilityByName("bloodseeker_blood_mist")
	if self.mist then
		self.heal_factor = self.heal_factor + self.mist:GetSpecialValueFor("thirst_bonus_pct") / 100
	end
end

function modifier_bloodseeker_sanguivore_regeneration:OnIntervalThink()
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	
	local healPerSec = (self.max_hp_percent_heal_tooltip * self.creep_pct) * self:GetStackCount() / self.heal_duration
	
	local realHPS = parent:GetMaxHealth() * healPerSec * 0.33 + (self.healOverFlow or 0)
	self.healOverFlow = realHPS % 1
	
	parent:HealEvent( math.floor( realHPS ), ability, caster )
end

function modifier_bloodseeker_sanguivore_regeneration:DeclareFunctions()
	return { MODIFIER_PROPERTY_TOOLTIP }
end

function modifier_bloodseeker_sanguivore_regeneration:OnTooltip()
	return 100 * (self.max_hp_percent_heal_tooltip * self.creep_pct) * self:GetStackCount() / self.heal_duration
end