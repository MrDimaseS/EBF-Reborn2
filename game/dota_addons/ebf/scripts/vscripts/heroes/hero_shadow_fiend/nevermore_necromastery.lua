nevermore_necromastery_ebf = class({})

function  nevermore_necromastery_ebf:ShouldUseResources()
	return true
end
function nevermore_necromastery_ebf:OnOwnerDied()
	local modifier = self:GetCaster():FindModifierByName( self:GetIntrinsicModifierName() )
	if modifier then
		modifier:SetStackCount( math.max( 0, modifier:GetStackCount() * (1 - self:GetSpecialValueFor("percent_souls_lost_on_death") / 100) ) )
	end
end
function nevermore_necromastery_ebf:GetIntrinsicModifierName()
	return "modifier_nevermore_necromastery_passive"
end

modifier_nevermore_necromastery_passive = class({})
LinkLuaModifier( "modifier_nevermore_necromastery_passive","heroes/hero_shadow_fiend/nevermore_necromastery.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_nevermore_necromastery_passive:OnCreated()
	self:OnRefresh()
end
function modifier_nevermore_necromastery_passive:OnRefresh()
	self.damage_per_soul = self:GetSpecialValueFor("damage_per_soul")
	
	self.armor_per_soul = self:GetSpecialValueFor("armor_per_soul")
	self.hp_regen_per_soul = self:GetSpecialValueFor("health_regen_per_soul")

	self.spell_amp_per_soul = self:GetSpecialValueFor("spell_amplification_per_soul")

	self.base_max_souls = self:GetSpecialValueFor("base_max_souls")
	self.kills_per_max_soul = self:GetSpecialValueFor("kills_per_max_soul")
	self.hero_kill_multiplier = self:GetSpecialValueFor("hero_kill_multiplier")
	self.souls_per_kill = self:GetSpecialValueFor("souls_per_kill")
	self.hero_soul_multiplier = self:GetSpecialValueFor("hero_soul_multiplier")
	self.percent_souls_lost_on_death = self:GetSpecialValueFor("percent_souls_lost_on_death")

	self.bonus_max_souls = 0
	self.max_souls = self.bonus_max_souls + self.base_max_souls
end
function modifier_nevermore_necromastery_passive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE, 
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
	}
end
function modifier_nevermore_necromastery_passive:GetModifierPreAttack_BonusDamage()
	if self:GetCaster():PassivesDisabled() then return end
	return self:GetStackCount() * self.damage_per_soul
end
function modifier_nevermore_necromastery_passive:GetModifierPhysicalArmorBonus()
	if self:GetCaster():PassivesDisabled() then return end
	return self:GetStackCount() * self.armor_per_soul
end
function modifier_nevermore_necromastery_passive:GetModifierConstantHealthRegen()
	if self:GetCaster():PassivesDisabled() then return end
	return self:GetStackCount() * self.hp_regen_per_soul
end
function modifier_nevermore_necromastery_passive:GetModifierSpellAmplify_Percentage()
	if self:GetCaster():PassivesDisabled() then return end
	return self:GetStackCount() * self.spell_amp_per_soul
end
function modifier_nevermore_necromastery_passive:OnTakeDamage( params )
	if self:GetCaster():PassivesDisabled() or IsClient() then return end
	local stacksToAdd = 0
	if params.attacker == self:GetCaster() then
		if params.inflictor and ( params.inflictor:GetAbilityName() == "nevermore_shadowraze1_ebf" 
								or params.inflictor:GetAbilityName() == "nevermore_shadowraze2_ebf" 
								or params.inflictor:GetAbilityName() == "nevermore_shadowraze3_ebf" ) then
			stacksToAdd = stacksToAdd + 1
		end
		if params.unit:GetHealth() <= 0 then
			stacksToAdd = stacksToAdd + 1
		end
	end

	if params.unit:HasModifier("modifier_nevermore_dark_lord_passive_aura") and params.unit:GetHealth() <= 0 then
		stacksToAdd = stacksToAdd + 1
	end

	if stacksToAdd > 0 then
		if params.unit:IsConsideredHero() then
			stacksToAdd = stacksToAdd * self.hero_soul_multiplier
		end
		self:SetStackCount( math.min( self.max_souls, self:GetStackCount() + stacksToAdd ) )
	end
end
function modifier_nevermore_necromastery_passive:IsPurgable()
	return false
end
function modifier_nevermore_necromastery_passive:IsPermanent()
	return true
end