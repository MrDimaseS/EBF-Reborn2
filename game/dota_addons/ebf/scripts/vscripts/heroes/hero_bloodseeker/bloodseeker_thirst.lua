bloodseeker_thirst = class({})

function bloodseeker_thirst:GetIntrinsicModifierName()
	return "modifier_bloodseeker_thirst_buff"
end

modifier_bloodseeker_thirst_buff = class({})
LinkLuaModifier( "modifier_bloodseeker_thirst_buff", "heroes/hero_bloodseeker/bloodseeker_thirst", LUA_MODIFIER_MOTION_NONE )

function modifier_bloodseeker_thirst_buff:OnCreated()
	self:OnRefresh()
end

function modifier_bloodseeker_thirst_buff:OnRefresh()
	self.min_bonus_pct = self:GetSpecialValueFor("min_bonus_pct")
	self.max_bonus_pct = self:GetSpecialValueFor("max_bonus_pct")
	self.bonus_movement_speed = self:GetSpecialValueFor("bonus_movement_speed")
	
	self.hero_stacks = 100 / self:GetSpecialValueFor("creep_pct")
	self.kill_stacks = self:GetSpecialValueFor("kill_pct") / 100
	self.heal_duration = self:GetSpecialValueFor("heal_duration")
end

function modifier_bloodseeker_thirst_buff:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT, 
			MODIFIER_PROPERTY_MOVESPEED_LIMIT, 
			MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_bloodseeker_thirst_buff:GetModifierMoveSpeedBonus_Percentage()
	if self:GetCaster():GetHealthPercent() < self.min_bonus_pct then
		if not self.NFX and IsServer() then
			self.NFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_bloodseeker/bloodseeker_thirst_owner.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster() )
		end
		return self.bonus_movement_speed * ( math.max( self.max_bonus_pct, self:GetCaster():GetHealthPercent() ) - self.min_bonus_pct) / (self.max_bonus_pct - self.min_bonus_pct)
	elseif self.NFX and IsServer() then
		ParticleManager:ClearParticle( self.NFX )
		self.NFX = nil
	end
end

function modifier_bloodseeker_thirst_buff:GetModifierIgnoreMovespeedLimit()
	return 1
end

function modifier_bloodseeker_thirst_buff:GetModifierMoveSpeed_Limit()
	return 3500
end

function modifier_bloodseeker_thirst_buff:OnTakeDamage( params )
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
		
		local regeneration = caster:AddNewModifier( caster, self:GetAbility(), "modifier_bloodseeker_thirst_regeneration", {duration = self.heal_duration} )
		regeneration:AddIndependentStack( self.heal_duration, nil, nil, {stacks = math.floor( stacks )} )
	end
end

function modifier_bloodseeker_thirst_buff:IsHidden()
	return self:GetCaster():GetHealthPercent() >= self.min_bonus_pct
end

modifier_bloodseeker_thirst_regeneration = class({})
LinkLuaModifier( "modifier_bloodseeker_thirst_regeneration", "heroes/hero_bloodseeker/bloodseeker_thirst", LUA_MODIFIER_MOTION_NONE )

function modifier_bloodseeker_thirst_regeneration:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink( 0.33 )
	end
end

function modifier_bloodseeker_thirst_regeneration:OnRefresh()
	self.hero_kill_heal = self:GetSpecialValueFor("hero_kill_heal") / 100
	self.creep_pct = self:GetSpecialValueFor("creep_pct") / 100
	
	self.heal_factor = 1
	self.heal_duration = self:GetSpecialValueFor("heal_duration")
	
	self.mist = self:GetCaster():FindAbilityByName("bloodseeker_blood_mist")
	if self.mist then
		self.heal_factor = self.heal_factor + self.mist:GetSpecialValueFor("thirst_bonus_pct") / 100
	end
end

function modifier_bloodseeker_thirst_regeneration:OnIntervalThink()
	local healPerSec = (self.hero_kill_heal * self.creep_pct) * self:GetStackCount() * TernaryOperator( self.heal_factor, self:GetCaster():HasModifier("modifier_bloodseeker_blood_mist_toggle"), 1 ) / self.heal_duration
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	
	parent:HealEvent( parent:GetMaxHealth() * healPerSec * 0.33, ability, caster )
end

function modifier_bloodseeker_thirst_regeneration:DeclareFunctions()
	return { MODIFIER_PROPERTY_TOOLTIP }
end

function modifier_bloodseeker_thirst_regeneration:OnTooltip()
	print( 100 * (self.hero_kill_heal * self.creep_pct) * self:GetStackCount() * TernaryOperator( self.heal_factor, self:GetCaster():HasModifier("modifier_bloodseeker_blood_mist_toggle"), 1 ) / self.heal_duration )
	return 100 * (self.hero_kill_heal * self.creep_pct) * self:GetStackCount() * TernaryOperator( self.heal_factor, self:GetCaster():HasModifier("modifier_bloodseeker_blood_mist_toggle"), 1 ) / self.heal_duration
end