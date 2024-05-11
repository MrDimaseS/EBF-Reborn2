antimage_counterspell = class ({})

function antimage_counterspell:GetIntrinsicModifierName()
	return "modifier_antimage_counterspell_passive"
end

function antimage_counterspell:OnSpellStart(target)
	local hTarget = target or self:GetCaster()
	
	hTarget:AddNewModifier( self:GetCaster(), self, "modifier_antimage_counterspell_barrier", {duration = self:GetSpecialValueFor("max_duration")} )
	ParticleManager:FireParticle("particles/units/heroes/hero_antimage/antimage_spellshield.vpcf", PATTACH_POINT_FOLLOW, hTarget, {[0] = "attach_hitloc"})
	EmitSoundOn( "Hero_Antimage.Counterspell.Cast", hTarget )
end

modifier_antimage_counterspell_barrier = class({})
LinkLuaModifier( "modifier_antimage_counterspell_barrier", "heroes/hero_antimage/antimage_counterspell", LUA_MODIFIER_MOTION_NONE )

function modifier_antimage_counterspell_barrier:OnCreated()
	if IsServer() then
		self.barrier = self:GetSpecialValueFor("barrier")
		self.max_duration = self:GetSpecialValueFor("max_duration")
		self.duration = self:GetSpecialValueFor("duration")
		self.degen_duration = self.max_duration - self.duration
		
		self.degen_acceleration = (self.barrier / self.degen_duration) * FrameTime()
		self.barrier_degen = 0
		
		self:StartIntervalThink( self.duration )
	end
	if IsServer() then self:SetHasCustomTransmitterData(true) end
end

function modifier_antimage_counterspell_barrier:OnRefresh()
	if IsServer() then
		self.barrier = self.barrier + self:GetSpecialValueFor("barrier")
		self:SendBuffRefreshToClients()
	end
end

function modifier_antimage_counterspell_barrier:OnIntervalThink()
	if self.barrier_degen == 0 then
		self:StartIntervalThink( 0 )
	end
	self.barrier = self.barrier - self.degen_acceleration * (((GameRules:GetGameTime() - self:GetCreationTime()) - self.duration)/4) ^ 2.2
	
	if self.barrier <= 0 then
		self:Destroy()
	end
	self:SendBuffRefreshToClients()
end

function modifier_antimage_counterspell_barrier:CheckState()
	return {[MODIFIER_STATE_DEBUFF_IMMUNE] = true}
end

function modifier_antimage_counterspell_barrier:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT, 
			 MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT }
end

function modifier_antimage_counterspell_barrier:GetModifierIncomingDamageConstant( params )
	if not self:GetCaster():HasShard() then return end
	if IsServer() then
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

function modifier_antimage_counterspell_barrier:GetModifierIncomingSpellDamageConstant( params )
	if self:GetCaster():HasShard() then return end
	if IsServer() then
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

function modifier_antimage_counterspell_barrier:AddCustomTransmitterData()
	return {barrier = self.barrier}
end

function modifier_antimage_counterspell_barrier:HandleCustomTransmitterData(data)
	self.barrier = data.barrier
end

function modifier_antimage_counterspell_barrier:GetEffectName()
	return "particles/units/heroes/hero_antimage/antimage_counterspell_shield.vpcf"
end

function modifier_antimage_counterspell_barrier:IsHidden()
	return false
end

modifier_antimage_counterspell_passive = class({})
LinkLuaModifier( "modifier_antimage_counterspell_passive", "heroes/hero_antimage/antimage_counterspell", LUA_MODIFIER_MOTION_NONE )

function modifier_antimage_counterspell_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, MODIFIER_EVENT_ON_ABILITY_FULLY_CAST }
end

function modifier_antimage_counterspell_passive:GetModifierMagicalResistanceBonus(params)
	return self:GetSpecialValueFor("magic_resistance")
end

function modifier_antimage_counterspell_passive:OnAbilityFullyCast(params)
	if params.ability:GetName() == "antimage_mana_overload" then
		local caster = self:GetCaster()
		for _, target in ipairs( caster:FindFriendlyUnitsInRadius( params.ability:GetCursorPosition(), 150 ) ) do
			if target:IsIllusion() and target:GetUnitName() == caster:GetUnitName() then
				self:GetAbility():OnSpellStart( target )
				return
			end
		end
	end
end

function modifier_antimage_counterspell_passive:IsHidden()
	return true
end