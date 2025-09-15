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
	self._nextTriggerTime = 0
	
	self:GetCaster()._buffModifiersList = self:GetCaster()._buffModifiersList or {}
	self:GetCaster()._buffModifiersList[self] = true
	self:GetCaster()._debuffModifiersList = self:GetCaster()._debuffModifiersList or {}
	self:GetCaster()._debuffModifiersList[self] = true
	
	if IsServer() then
		self:SetStackCount( self:GetCaster()._permanentBloodForgedAxeStacks or 0 )
	end
end

function modifier_axe_bloodforged_axe_handler:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
	}
	return funcs
end

function modifier_axe_bloodforged_axe_handler:OnTakeDamage( params )
	if IsServer() then
		if self:GetParent() ~= self:GetCaster() then return end
		if params.damage <= 0 then return end
		if GameRules:GetGameTime() < self._nextTriggerTime then return end
		if ( params.attacker == self:GetCaster() and ( not params.inflictor or ( params.inflictor and params.attacker:HasAbility( params.inflictor:GetAbilityName() ) ) ) )
		or params.unit == self:GetCaster() then
			self:AddIndependentStack({duration = self.stack_duration})
			self:SetDuration( self.stack_duration, true )
			self._nextTriggerTime = GameRules:GetGameTime() + TernaryOperator( 0, self.no_cd_berserkers_call and self:GetCaster():HasModifier("modifier_axe_berserkers_call_aura"), self.internal_cooldown )
		end
	end
end

function modifier_axe_bloodforged_axe_handler:GetBerserkersCallBonus(  )
	local increase = 1
	if IsModifierSafe( self:GetCaster()._berserkersCall ) then
		increase = increase + self:GetCaster()._berserkersCall.bonus_axe_bonus / 100
	end
	return increase
end

function modifier_axe_bloodforged_axe_handler:GetModifierTotalDamageOutgoing_Percentage( params )
	return ( self.damage_increase_stack * self:GetBerserkersCallBonus() ) * self:GetStackCount()
end

function modifier_axe_bloodforged_axe_handler:GetModifierIncomingDamage_Percentage( params )
	if self.stacks_reduce_damage_taken then
		local increase = self.damage_increase_stack * self:GetBerserkersCallBonus()
		return (1-1/(1+(increase/100) * self:GetStackCount())) * 100
	end
end

function modifier_axe_bloodforged_axe_handler:GetModifierAttackSpeedBonus_Constant( params )
	return ( self.attack_speed_stack * self:GetBerserkersCallBonus() ) * self:GetStackCount()
end

function modifier_axe_bloodforged_axe_handler:GetModifierHealAmplify_PercentageTarget( params )
	return ( self.heal_increase_stack * self:GetBerserkersCallBonus() ) * self:GetStackCount()
end

function modifier_axe_bloodforged_axe_handler:GetModifierBuffDurationBonusPercentage( params )
	return ( self.duration_bonus_stack * self:GetBerserkersCallBonus() ) * self:GetStackCount()
end

function modifier_axe_bloodforged_axe_handler:GetModifierDebuffDurationBonusPercentage( params )
	return ( self.duration_bonus_stack * self:GetBerserkersCallBonus() ) * self:GetStackCount()
end


function modifier_axe_bloodforged_axe_handler:IsHidden()
	return self:GetStackCount() > 0
end

function modifier_axe_bloodforged_axe_handler:IsPurgable()
	return false
end

function modifier_axe_bloodforged_axe_handler:IsPermanent()
	return true
end

function modifier_axe_bloodforged_axe_handler:DestroyOnExpire()
	return self:GetParent() ~= self:GetCaster()
end