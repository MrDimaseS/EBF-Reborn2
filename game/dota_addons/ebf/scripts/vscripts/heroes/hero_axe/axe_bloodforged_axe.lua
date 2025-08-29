axe_bloodforged_axe = class({})

function axe_bloodforged_axe:ShouldUseResources()
	return true
end

function axe_bloodforged_axe:GetIntrinsicModifierName()
	return "modifier_axe_bloodforged_axe_handler"
end

modifier_axe_bloodforged_axe_handler = class({})
LinkLuaModifier( "modifier_axe_bloodforged_axe_handler", "heroes/hero_axe/axe_bloodforged_axe", LUA_MODIFIER_MOTION_NONE )

function modifier_axe_bloodforged_axe_handler:OnCreated()
	self:OnRefresh()
end

function modifier_axe_bloodforged_axe_handler:OnRefresh()
	self.damage_increase_stack = self:GetSpecialValueFor("damage_increase_stack")
	self.stack_duration = self:GetSpecialValueFor("stack_duration")
	self.internal_cooldown = self:GetSpecialValueFor("internal_cooldown")
	
	self.stacks_reduce_damage_taken = self:GetSpecialValueFor("stacks_reduce_damage_taken") == 1
	self.attack_speed_stack = self:GetSpecialValueFor("attack_speed_stack")
	self.duration_bonus_stack = self:GetSpecialValueFor("duration_bonus_stack")
	self.heal_increase_stack = self:GetSpecialValueFor("heal_increase_stack")
	
	self.no_cd_berserkers_call = self:GetSpecialValueFor("no_cd_berserkers_call") == 1
	self._lastTriggerTime = 0
	
	self:GetCaster()._buffModifiersList[self] = true
	self:GetCaster()._debuffModifiersList[self] = true
end

function modifier_axe_bloodforged_axe_handler:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
	}
	return funcs
end

function modifier_axe_bloodforged_axe_handler:OnDeath( params )
	if IsServer() then
		if params.unit:HasModifier("modifier_axe_culling_blade_grace_period") then
			if params.unit:IsConsideredHero() then
				self:IncrementStackCount()
			end
		end
	end
end

function modifier_axe_bloodforged_axe_handler:OnTakeDamage( params )
	if IsServer() then
		if params.damage <= 0 then return end
		if GameRules:GetGameTime() < self._nextTriggerTime then return end
		if ( params.attacker == self:GetCaster() and ( not params.inflictor or ( params.inflictor and params.attacker:HasAbility( params.inflictor:GetAbilityName() ) ) ) )
		or params.unit == self:GetCaster() then
			self:AddIndependentStack({duration = self.stack_duration})
			self._nextTriggerTime = GameRules:GetGameTime() + TernaryOperator( 0, self.no_cd_berserkers_call and self:GetCaster():HasModifier("modifier_axe_berserkers_call_aura"), self.internal_cooldown )
		end
	end
end

function modifier_axe_bloodforged_axe_handler:GetModifierTotalDamageOutgoing_Percentage( params )
	return self.damage_increase_stack * self:GetStackCount()
end

function modifier_axe_bloodforged_axe_handler:GetModifierIncomingDamage_Percentage( params )
	if self.stacks_reduce_damage_taken then
		return (1-1/(1+(self.damage_increase_stack/100) * self:GetStackCount())) * 100
	end
end

function modifier_axe_bloodforged_axe_handler:GetModifierAttackSpeedBonus_Constant( params )
	return self.attack_speed_stack * self:GetStackCount()
end

function modifier_axe_bloodforged_axe_handler:GetModifierHealAmplify_PercentageTarget( params )
	return self.heal_increase_stack * self:GetStackCount()
end

function modifier_axe_bloodforged_axe_handler:GetModifierBuffDurationBonusPercentage( params )
	return self.duration_bonus_stack * self:GetStackCount()
end

function modifier_axe_bloodforged_axe_handler:GetModifierDebuffDurationBonusPercentage( params )
	return self.duration_bonus_stack * self:GetStackCount()
end


function modifier_axe_bloodforged_axe_handler:IsHidden()
	return self:GetStackCount() <= 0
end

function modifier_axe_bloodforged_axe_handler:IsPurgable()
	return false
end

function modifier_axe_bloodforged_axe_handler:IsPermanent()
	return true
end

function modifier_axe_bloodforged_axe_handler:DestroyOnExpire()
	return false
end

modifier_axe_bloodforged_axe_buff = class({})
LinkLuaModifier( "modifier_axe_bloodforged_axe_buff", "heroes/hero_axe/axe_bloodforged_axe", LUA_MODIFIER_MOTION_NONE )

function modifier_axe_bloodforged_axe_buff:OnCreated(kv)
	if IsServer() then 
		self.heroStacks = {}
		self.heroStackCount = self.heroStackCount or 0
		self.creepStacks = {}
		self.creepStackCount = self.heroStackCount or 0
		self:StartIntervalThink(0.1)
		self:SetHasCustomTransmitterData(true)
	end
	
	self:OnRefresh(kv)
end

function modifier_axe_bloodforged_axe_buff:OnRefresh(kv)
	self.armor_per_hero = self:GetSpecialValueFor("armor_per_hero")
	self.atk_bonus_per_hero = self:GetSpecialValueFor("atk_bonus_per_hero")
	self.spell_amp_per_hero = self:GetSpecialValueFor("spell_amp_per_hero")
	self.armor_per_creep = self:GetSpecialValueFor("armor_per_creep")
	self.atk_bonus_per_creep = self:GetSpecialValueFor("atk_bonus_per_creep")
	self.spell_amp_per_creep = self:GetSpecialValueFor("spell_amp_per_creep")
	self.duration = self:GetSpecialValueFor("duration")
	self.multiplier_during_berserkers_call = self:GetSpecialValueFor("multiplier_during_berserkers_call")
	
	if not IsServer() then return end
	if kv then
		if tonumber(kv.hero) == 1 then
			for i = 1, kv.stacks or 1 do
				table.insert( self.heroStacks, GameRules:GetGameTime() + self:GetRemainingTime() )
			end
		else
			for i = 1, kv.stacks or 1 do
				table.insert( self.creepStacks, GameRules:GetGameTime() + self:GetRemainingTime() )
			end
		end
	end
	self.heroStackCount = #self.heroStacks
	self.creepStackCount = #self.creepStacks
	self:SetStackCount( self.heroStackCount + self.creepStackCount )
end

function modifier_axe_bloodforged_axe_buff:OnIntervalThink( )
	while self.heroStacks[1] and self.heroStacks[1] <= GameRules:GetGameTime() do
		table.remove( self.heroStacks, 1 )
		self.heroStackCount = #self.heroStacks
		stackRemoved = true
	end
	while self.creepStacks[1] and  self.creepStacks[1] <= GameRules:GetGameTime() do
		table.remove( self.creepStacks, 1 )
		self.creepStackCount = #self.creepStacks
		stackRemoved = true
	end
	if stackRemoved then
		self:SetStackCount( self.heroStackCount + self.creepStackCount )
	end
	if self:GetDuration() <= 0 then
		self:SetDuration( -1, true )
	end
end

function modifier_axe_bloodforged_axe_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
	}
	return funcs
end

function modifier_axe_bloodforged_axe_buff:AddCustomTransmitterData()
	return {heroStackCount = tonumber(self.heroStackCount),
			creepStackCount = tonumber(self.creepStackCount)}
end

function modifier_axe_bloodforged_axe_buff:HandleCustomTransmitterData(data)
	self.heroStackCount = tonumber(data.heroStackCount)
	self.creepStackCount = tonumber(data.creepStackCount)
end


function modifier_axe_bloodforged_axe_buff:GetModifierPhysicalArmorBonus( params )
	return ( self.armor_per_hero * self.heroStackCount + self.armor_per_creep * self.creepStackCount ) * TernaryOperator( self.multiplier_during_berserkers_call, self:GetParent():HasModifier("modifier_axe_berserkers_call_aura"), 1 )
end

function modifier_axe_bloodforged_axe_buff:GetModifierDamageOutgoing_Percentage( params )
	return ( self.atk_bonus_per_hero * self.heroStackCount + self.atk_bonus_per_creep * self.creepStackCount ) * TernaryOperator( self.multiplier_during_berserkers_call, self:GetParent():HasModifier("modifier_axe_berserkers_call_aura"), 1 )
end

function modifier_axe_bloodforged_axe_buff:GetModifierSpellAmplify_Percentage( params )
	return ( self.spell_amp_per_hero * self.heroStackCount + self.spell_amp_per_creep * self.creepStackCount ) * TernaryOperator( self.multiplier_during_berserkers_call, self:GetParent():HasModifier("modifier_axe_berserkers_call_aura"), 1 )
end

function modifier_axe_bloodforged_axe_buff:IsPurgable()
	return true
end