clockwerk_tech_barrier = class({})

function clockwerk_tech_barrier:GetIntrinsicModifierName()
	return "modifier_clockwerk_tech_barrier_passive"
end

modifier_clockwerk_tech_barrier_barrier = class({})
LinkLuaModifier( "modifier_clockwerk_tech_barrier_barrier", "heroes/hero_clockwerk/clockwerk_tech_barrier", LUA_MODIFIER_MOTION_NONE )

function modifier_clockwerk_tech_barrier_barrier:OnCreated()
	self:OnRefresh()
	if IsServer() then 
		EmitSoundOn( "Hero_Rattletrap.Power_Cogs", self:GetCaster() )
		self:SetHasCustomTransmitterData(true)
	end
end

function modifier_clockwerk_tech_barrier_barrier:OnRefresh()
	if IsServer() then
		self.barrier = self:GetSpecialValueFor("barrier")
		self.mana_burn = self:GetSpecialValueFor("mana_burn") / 100
		self.damage = self:GetSpecialValueFor("damage")
		self.push_length = self:GetSpecialValueFor("push_length")
		self.push_duration = self:GetSpecialValueFor("push_duration")
		if self:GetParent():HasModifier("modifier_rattletrap_overclocking") then
			self.barrier = self.barrier * self:GetParent():FindModifierByName("modifier_rattletrap_overclocking"):GetAbility():GetSpecialValueFor("bonus_barrier") / 100
		end
		self.debuff_immunity_duration = self:GetSpecialValueFor("debuff_immunity_duration")
		if self.debuff_immunity_duration > 0 then
			self:GetParent():AddNewModifier( self:GetParent(), self:GetAbility(), "modifier_black_king_bar_immune", {duration = self.debuff_immunity_duration} )
		end
		self:SendBuffRefreshToClients()
	end
end

function modifier_clockwerk_tech_barrier_barrier:OnDestroy()
	if IsServer() then
		EmitSoundOn( "Hero_Rattletrap.Power_Cog.Destroy", self:GetCaster() )
		StopSoundOn( "Hero_Rattletrap.Power_Cogs", self:GetCaster() )
	end
end


function modifier_clockwerk_tech_barrier_barrier:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT }
end

function modifier_clockwerk_tech_barrier_barrier:GetModifierIncomingDamageConstant( params )
	if IsServer() then
		local barrier = math.min( self.barrier, math.max( self.barrier, params.damage ) )
		self.barrier = self.barrier - params.damage
		if self.barrier > 0 then
			self:SendBuffRefreshToClients()
		else
			self:GetAbility():DealDamage( self:GetCaster(), params.attacker, self.damage, {damage_type = DAMAGE_TYPE_MAGICAL} )
			params.attacker:ApplyKnockBack( self:GetCaster():GetAbsOrigin(), self.push_duration, self.push_duration, self.push_length, 0, self:GetCaster(), self:GetAbility() )
			params.attacker:ReduceMana( params.attacker:GetMana() * self.mana_burn, self:GetAbility() )
			
			EmitSoundOn("Hero_Rattletrap.Power_Cogs_Impact", params.attacker )
			ParticleManager:FireRopeParticle( "particles/units/heroes/hero_rattletrap/rattletrap_cog_attack.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster(), params.attacker )
			self:Destroy()
		end
		return -barrier
	else
		return self.barrier
	end
end

function modifier_clockwerk_tech_barrier_barrier:AddCustomTransmitterData()
	return {barrier = self.barrier}
end

function modifier_clockwerk_tech_barrier_barrier:HandleCustomTransmitterData(data)
	self.barrier = data.barrier
end

function modifier_clockwerk_tech_barrier_barrier:GetEffectName()
	return "particles/units/heroes/hero_rattletrap/clockwerk_tech_barrier.vpcf"
end

function modifier_clockwerk_tech_barrier_barrier:IsHidden()
	return false
end

modifier_clockwerk_tech_barrier_passive = class({})
LinkLuaModifier( "modifier_clockwerk_tech_barrier_passive", "heroes/hero_clockwerk/clockwerk_tech_barrier", LUA_MODIFIER_MOTION_NONE )

function modifier_clockwerk_tech_barrier_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, MODIFIER_EVENT_ON_ABILITY_FULLY_CAST }
end

function modifier_clockwerk_tech_barrier_passive:GetModifierMagicalResistanceBonus(params)
	return self:GetSpecialValueFor("magic_resistance")
end

function modifier_clockwerk_tech_barrier_passive:OnAbilityFullyCast(params)
	if self:GetParent():PassivesDisabled() then return end
	if params.unit == self:GetParent() and params.unit:HasAbility( params.ability:GetName() ) then
		params.unit:AddNewModifier( params.unit, self:GetAbility(), "modifier_clockwerk_tech_barrier_barrier", {duration = self:GetSpecialValueFor("duration")} )
	end
end

function modifier_clockwerk_tech_barrier_passive:IsHidden()
	return true
end