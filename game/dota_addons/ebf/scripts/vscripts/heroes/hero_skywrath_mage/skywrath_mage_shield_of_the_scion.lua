skywrath_mage_shield_of_the_scion = class({})

function skywrath_mage_shield_of_the_scion:GetIntrinsicModifierName()
	return "modifier_skywrath_mage_shield_of_the_scion_handler"
end

modifier_skywrath_mage_shield_of_the_scion_handler = class({})
LinkLuaModifier( "modifier_skywrath_mage_shield_of_the_scion_handler","heroes/hero_skywrath_mage/skywrath_mage_shield_of_the_scion.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_skywrath_mage_shield_of_the_scion_handler:OnCreated()
	self.damage_barrier_base = self:GetSpecialValueFor("damage_barrier_base")
	self.damage_barrier_per_level = self:GetSpecialValueFor("damage_barrier_per_level")
	
	self.barrier_duration = self:GetSpecialValueFor("barrier_duration")
	self.creep_pct = self:GetSpecialValueFor("creep_pct") / 100
	self.barrier = 0
	if IsServer() then self:SetHasCustomTransmitterData(true) end
end

function modifier_skywrath_mage_shield_of_the_scion_handler:OnStackCountChanged( prevStacks )
	if self:GetStackCount() < prevStacks then -- stacks lost, clamp
		local newMax = self:GetStackCount() * ( self.damage_barrier_base + self.damage_barrier_per_level * self:GetParent():GetLevel() )
		
		self.barrier = math.min( self.barrier, newMax )
	end
end

function modifier_skywrath_mage_shield_of_the_scion_handler:AddCustomTransmitterData()
	return {barrier = self.barrier}
end

function modifier_skywrath_mage_shield_of_the_scion_handler:HandleCustomTransmitterData(data)
	self.barrier = data.barrier
end

function modifier_skywrath_mage_shield_of_the_scion_handler:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT,
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}
end

function modifier_skywrath_mage_shield_of_the_scion_handler:GetModifierIncomingSpellDamageConstant( params )
	if IsServer() and self.barrier > 0 then
		local barrier = math.min( self.barrier, math.max( self.barrier, params.damage ) )
		self.barrier = math.max( 0, self.barrier - params.damage )
		if self.barrier > 0 then
			self:SendBuffRefreshToClients()
		else
			self:Destroy()
		end
		EmitSoundOn( "Hero_Antimage.Counterspell.Absorb", self:GetParent() )
		return -barrier
	else
		return self.barrier
	end
end

function modifier_skywrath_mage_shield_of_the_scion_handler:OnTakeDamage( params )
	if params.attacker == self:GetParent() and params.inflictor then
		if params.attacker:HasAbility( params.inflictor:GetAbilityName() ) then
			self:AddIndependentStack( self.barrier_duration )
			self:SetDuration( self.barrier_duration, true )
			
			local addedBarrier = ( self.damage_barrier_base + self.damage_barrier_per_level * params.attacker:GetLevel() ) * TernaryOperator( 1, params.unit:IsConsideredHero(), self.creep_pct )
			self.barrier = self.barrier + addedBarrier
			self:SendBuffRefreshToClients()
		end
	end
end

function modifier_skywrath_mage_shield_of_the_scion_handler:IsHidden()
	return self:GetStackCount() <= 0
end

function modifier_skywrath_mage_shield_of_the_scion_handler:DestroyOnExpire()
	return false
end

function modifier_skywrath_mage_shield_of_the_scion_handler:IsPurgable()
	return false
end

function modifier_skywrath_mage_shield_of_the_scion_handler:IsPermanent()
	return true
end