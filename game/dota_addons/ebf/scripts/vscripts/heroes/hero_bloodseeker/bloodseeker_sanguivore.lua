bloodseeker_sanguivore = class({})

function bloodseeker_sanguivore:GetIntrinsicModifierName()
	return "modifier_bloodseeker_sanguivore_buff"
end

modifier_bloodseeker_sanguivore_buff = class({})
LinkLuaModifier( "modifier_bloodseeker_sanguivore_buff", "heroes/hero_bloodseeker/bloodseeker_sanguivore", LUA_MODIFIER_MOTION_NONE )

function modifier_bloodseeker_sanguivore_buff:OnCreated()
	self:OnRefresh()
end

function modifier_bloodseeker_sanguivore_buff:OnRefresh()
	self.hero_stacks = 100 / self:GetSpecialValueFor("creep_pct")
	self.kill_stacks = self:GetSpecialValueFor("kill_pct") / 100
	self.heal_duration = self:GetSpecialValueFor("heal_duration")
end

function modifier_bloodseeker_sanguivore_buff:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_bloodseeker_sanguivore_buff:OnTakeDamage( params )
	local caster = self:GetCaster()
	if params.attacker ~= caster or params.attacker == params.unit then return end
	if ( params.inflictor and caster:HasAbility( params.inflictor:GetAbilityName() ) ) or not params.unit:IsAlive() then
		local stacks = 1
		if params.unit:IsConsideredHero() then
			stacks = stacks * self.hero_stacks
		end
		if not params.unit:IsAlive() then
			stacks = stacks * self.kill_stacks
		end
		
		local regeneration = caster:AddNewModifier( caster, self:GetAbility(), "modifier_bloodseeker_sanguivore_regeneration", {duration = self.heal_duration} )
		regeneration:AddIndependentStack( self.heal_duration, nil, nil, {stacks = math.floor( stacks )} )
	end
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
	
	local healPerSec = (self.max_hp_percent_heal_tooltip * self.creep_pct) * self:GetStackCount() * TernaryOperator( self.heal_factor, self:GetCaster():HasModifier("modifier_bloodseeker_blood_mist_toggle"), 1 ) / self.heal_duration
	
	local realHPS = parent:GetMaxHealth() * healPerSec * 0.33 + (self.healOverFlow or 0)
	self.healOverFlow = realHPS % 1
	
	parent:HealEvent( math.floor( realHPS ), ability, caster )
end

function modifier_bloodseeker_sanguivore_regeneration:DeclareFunctions()
	return { MODIFIER_PROPERTY_TOOLTIP }
end

function modifier_bloodseeker_sanguivore_regeneration:OnTooltip()
	return 100 * (self.max_hp_percent_heal_tooltip * self.creep_pct) * self:GetStackCount() * TernaryOperator( self.heal_factor, self:GetCaster():HasModifier("modifier_bloodseeker_blood_mist_toggle"), 1 ) / self.heal_duration
end