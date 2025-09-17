antimage_persectur = class ({})

function antimage_persectur:GetIntrinsicModifierName()
	return "modifier_antimage_persectur_passive"
end

modifier_antimage_persectur_passive = class({})
LinkLuaModifier( "modifier_antimage_persectur_passive", "heroes/hero_antimage/antimage_persectur", LUA_MODIFIER_MOTION_NONE )

function modifier_antimage_persectur_passive:OnCreated()
	if IsServer() then self:SetHasCustomTransmitterData(true) end
	self:OnRefresh()
end

function modifier_antimage_persectur_passive:OnRefresh()
	self.mana_to_damage = self:GetSpecialValueFor("mana_to_damage")
	self.mana_threshold = self:GetSpecialValueFor("mana_threshold") / 100
	self.search_radius = self:GetSpecialValueFor("search_radius")
	self.loss_delay = self:GetSpecialValueFor("loss_delay")
	self.loss_amount = self:GetSpecialValueFor("loss_amount") / 100
	self.tick = 0.25
	
	self.mana_to_barrier = self:GetSpecialValueFor("mana_to_barrier")
	self.barrier_max = self:GetSpecialValueFor("barrier_max") / 100
	self.barrier_max_rate = 1/(self:GetSpecialValueFor("barrier_max_time") / self.tick)
	
	self.base_damage = self:GetSpecialValueFor("base_damage")
	if IsServer() then
		self._safeAmount = 0
		self.barrier = 0
		self:SendBuffRefreshToClients()
		
		self:StartIntervalThink( self.tick )
	end
end

function modifier_antimage_persectur_passive:OnIntervalThink()
	local stacksToAdjust = self:GetStackCount() - self._safeAmount
	self:SetStackCount( stacksToAdjust * (1 - self.loss_amount * self.tick ) + self._safeAmount )
	
	if self.mana_to_barrier > 0 and self.barrier < math.min( self:GetParent():GetMaxHealth() * self.barrier_max, stacksToAdjust * self.mana_to_barrier ) then
		self.barrier = math.min( self:GetParent():GetMaxHealth() * self.barrier_max, (self.barrier or 0) + ( stacksToAdjust * self.mana_to_barrier * self.barrier_max_rate ) )
		self:SendBuffRefreshToClients()
	end
end

function modifier_antimage_persectur_passive:DeclareFunctions()
	return {MODIFIER_EVENT_ON_SPENT_MANA,
			MODIFIER_EVENT_ON_TAKEDAMAGE,
			MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT 
			}
end

function modifier_antimage_persectur_passive:OnTakeDamage(params)
	if params.attacker ~= self:GetParent() then return end
	local ability = self:GetAbility()
	if params.inflictor == ability then return end
	if params.inflictor and params.inflictor:IsItem() then return end
	if self:GetStackCount() == 0 and self.base_damage == 0 then return end
	ability:DealDamage( params.attacker, params.unit, self.base_damage + self:GetStackCount() * self.mana_to_damage, {damage_type = TernaryOperator( DAMAGE_TYPE_PURE, params.unit:GetManaPercent() <= self.mana_threshold, DAMAGE_TYPE_MAGICAL) }, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE  )
end

function modifier_antimage_persectur_passive:OnSpentMana(params)
	if CalculateDistance( params.unit, self:GetParent() ) > self.search_radius then return end
	self:SetStackCount( self:GetStackCount() + params.cost )
	self._safeAmount = self._safeAmount + params.cost
	Timers:CreateTimer( self.loss_delay, function()
		self._safeAmount = math.max( 0, self._safeAmount - params.cost )
	end )
end

function modifier_antimage_persectur_passive:GetModifierIncomingDamageConstant( params )
	if not self.barrier or self.barrier <= 0 then return end
	if IsServer() then
		local barrier = math.min( self.barrier, math.max( self.barrier, params.damage ) )
		self.barrier = math.max( 0, self.barrier - params.damage )
		if self.barrier > 0 then
			self:SendBuffRefreshToClients()
		end
		return -barrier
	else
		return self.barrier
	end
end

function modifier_antimage_persectur_passive:AddCustomTransmitterData()
	return {barrier = self.barrier}
end

function modifier_antimage_persectur_passive:HandleCustomTransmitterData(data)
	self.barrier = data.barrier
end

function modifier_antimage_persectur_passive:IsHidden()
	return self:GetStackCount() <= 0
end