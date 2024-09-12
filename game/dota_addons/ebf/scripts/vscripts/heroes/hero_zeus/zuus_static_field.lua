zuus_static_field = class({})

function zuus_static_field:GetIntrinsicModifierName()
	return "modifier_zuus_static_field_passive"
end

function zuus_static_field:ShouldUseResources()
	return true
end

LinkLuaModifier("modifier_zuus_static_field_passive", "heroes/hero_zeus/zuus_static_field", LUA_MODIFIER_MOTION_NONE)
modifier_zuus_static_field_passive = class({})

function modifier_zuus_static_field_passive:OnCreated()
	self._processingStaticField = {}
	if IsServer() then self:SetHasCustomTransmitterData(true) end
	self:OnRefresh()
end

function modifier_zuus_static_field_passive:OnRefresh()
	self.bonus_damage_spell = self:GetSpecialValueFor("bonus_damage_spell")
	self.bonus_damage_attack = self:GetSpecialValueFor("bonus_damage_attack")
	self.creep_multiplier = self:GetSpecialValueFor("creep_multiplier")
	self.damage_to_barrier = self:GetSpecialValueFor("damage_to_barrier") / 100
	self.barrier_maximum = self:GetSpecialValueFor("barrier_maximum") / 100
	self.barrier_creep_penalty = self:GetSpecialValueFor("barrier_creep_penalty") / 100

	if IsServer() then
		self.barrier = 0
		self:SendBuffRefreshToClients()
	end
end

function modifier_zuus_static_field_passive:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE, MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT}
end

function modifier_zuus_static_field_passive:OnTakeDamage(params)
	if params.attacker ~= self:GetParent() then return end
	if params.inflictor == self:GetAbility() then return end
	if params.inflictor and not self:GetParent():HasAbility( params.inflictor:GetAbilityName() ) then return end
	if self._processingStaticField[params.unit] then return end
	self._processingStaticField[params.unit] = true

	local ability = self:GetAbility()
	local damage = self.bonus_damage_attack
	
	if params.inflictor then
		damage = self.bonus_damage_spell
		EmitSoundOn( "Hero_Zuus.StaticField", params.unit )
	end
	if not params.unit:IsConsideredHero() then
		damage = damage * self.creep_multiplier
	end
	
	ParticleManager:FireParticle("particles/units/heroes/hero_zuus/zuus_static_field.vpcf", PATTACH_POINT_FOLLOW, params.unit )
	local damageDealt = ability:DealDamage( params.attacker, params.unit, damage )
	
	if self.damage_to_barrier > 0 then
		local addedBarrier = damageDealt * self.damage_to_barrier
		if not params.unit:IsConsideredHero() then
			addedBarrier = addedBarrier * self.barrier_creep_penalty
		end
		self.barrier = math.min( self.barrier + addedBarrier, params.attacker:GetMaxHealth() * self.barrier_maximum )
		
		self:SendBuffRefreshToClients()
	end
	Timers:CreateTimer( function() self._processingStaticField[params.unit] = nil end )
end

function modifier_zuus_static_field_passive:GetModifierIncomingDamageConstant( params )
	if self.barrier <= 0 then return end
	if IsServer() then
		local barrier = math.min( self.barrier, math.max( self.barrier, params.damage ) )
		self.barrier = math.max( 0, self.barrier - params.damage )
		
		self:SendBuffRefreshToClients()
		return -barrier
	else
		return self.barrier
	end
end

function modifier_zuus_static_field_passive:AddCustomTransmitterData()
	return {barrier = self.barrier}
end

function modifier_zuus_static_field_passive:HandleCustomTransmitterData(data)
	self.barrier = data.barrier
end

function modifier_zuus_static_field_passive:IsHidden()
	return true
end

function modifier_zuus_static_field_passive:IsPurgable()
	return false
end