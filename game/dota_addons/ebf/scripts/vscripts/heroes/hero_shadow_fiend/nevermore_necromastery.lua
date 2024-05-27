nevermore_necromastery = class({})

function  nevermore_necromastery:ShouldUseResources()
	return true
end

function nevermore_necromastery:OnInventoryContentsChanged()
	self:RefreshIntrinsicModifier()
end

function nevermore_necromastery:OnOwnerDied()
	local modifier = self:GetCaster():FindModifierByName( self:GetIntrinsicModifierName() )
	if modifier then
		modifier:SetStackCount( math.max( 0, modifier:GetStackCount() * (1-self:GetSpecialValueFor("necromastery_soul_release") / 100) ) )
	end
end

function nevermore_necromastery:GetIntrinsicModifierName()
	return "modifier_nevermore_necromastery_passive"
end

modifier_nevermore_necromastery_passive = class({})
LinkLuaModifier( "modifier_nevermore_necromastery_passive","heroes/hero_shadow_fiend/nevermore_necromastery.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_nevermore_necromastery_passive:OnCreated()
	self.crit_attack = {}
	self:OnRefresh()
end

function modifier_nevermore_necromastery_passive:OnRefresh()
	self.necromastery_damage_per_soul = self:GetSpecialValueFor("necromastery_damage_per_soul")
	self.necromastery_max_souls = self:GetSpecialValueFor("necromastery_max_souls")
	self.hero_stack_multiplier = self:GetSpecialValueFor("hero_stack_multiplier")
	self.necromastery_soul_release = self:GetSpecialValueFor("necromastery_soul_release")
	self.shard_crit_pct = self:GetSpecialValueFor("shard_crit_pct") / 100
	self.shard_fear_duration = self:GetSpecialValueFor("shard_fear_duration")
	if IsServer() then
		self:SetStackCount( math.min( self.necromastery_max_souls, self:GetStackCount() ) )
	end
end

function modifier_nevermore_necromastery_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_REINCARNATION, MODIFIER_EVENT_ON_TAKEDAMAGE, MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE }
end

function modifier_nevermore_necromastery_passive:ReincarnateTime()
	if self:GetCaster():PassivesDisabled() then return end
	if self:GetSpecialValueFor("immortality")  == 1 and self:GetStackCount() == self.necromastery_max_souls then
		return 0.1
	end
end

function modifier_nevermore_necromastery_passive:GetModifierPreAttack_BonusDamage()
	if self:GetCaster():PassivesDisabled() then return end
	return self:GetStackCount() * self.necromastery_damage_per_soul
end

function modifier_nevermore_necromastery_passive:OnTakeDamage( params )
	if self:GetCaster():PassivesDisabled() then return end
	local stacksToAdd = 0
	if params.attacker == self:GetCaster() then
		if params.inflictor and ( params.inflictor:GetAbilityName() == "nevermore_shadowraze1" 
								or params.inflictor:GetAbilityName() == "nevermore_shadowraze2" 
								or params.inflictor:GetAbilityName() == "nevermore_shadowraze3" ) then
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
			stacksToAdd = stacksToAdd * self.hero_stack_multiplier
		end
		self:SetStackCount( math.min( self.necromastery_max_souls, self:GetStackCount() + stacksToAdd ) )
	end
	if self.crit_attack[params.record] then
		params.unit:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_nevermore_necromastery_fear", {duration = self.shard_fear_duration} )
		self.crit_attack[params.record] = nil
	end
end

-- function modifier_nevermore_necromastery_passive:GetModifierPreAttack_CriticalStrike( params )
	-- if self:GetCaster():PassivesDisabled() then return end
	-- if self:GetAbility():IsCooldownReady() and self:GetCaster():HasShard() then
		-- self.crit_attack[params.record] = true
		-- local critDamage = self:GetCritDamage() * 100
		-- self:GetAbility():SetCooldown()
		-- return critDamage
	-- end
-- end

-- function modifier_nevermore_necromastery_passive:GetCritDamage()
	-- if self:GetCaster():PassivesDisabled() then return end
	-- if self:GetAbility():IsCooldownReady() and self:GetCaster():HasShard() then
		-- return 1 + self:GetStackCount() * self.shard_crit_pct
	-- end
-- end

function modifier_nevermore_necromastery_passive:IsPurgable()
	return false
end

function modifier_nevermore_necromastery_passive:IsPermanent()
	return true
end