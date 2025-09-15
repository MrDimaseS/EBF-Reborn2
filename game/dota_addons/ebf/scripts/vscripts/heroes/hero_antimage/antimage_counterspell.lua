antimage_counterspell = class ({})

function antimage_counterspell:OnSpellStart(target)
	local hTarget = target or self:GetCaster()
	
	hTarget:AddNewModifier( self:GetCaster(), self, "modifier_antimage_counterspell_barrier", {duration = self:GetSpecialValueFor("duration")} )
	ParticleManager:FireParticle("particles/units/heroes/hero_antimage/antimage_spellshield.vpcf", PATTACH_POINT_FOLLOW, hTarget, {[0] = "attach_hitloc"})
	EmitSoundOn( "Hero_Antimage.Counterspell.Cast", hTarget )
end

modifier_antimage_counterspell_barrier = class({})
LinkLuaModifier( "modifier_antimage_counterspell_barrier", "heroes/hero_antimage/antimage_counterspell", LUA_MODIFIER_MOTION_NONE )

function modifier_antimage_counterspell_barrier:OnCreated()
	self:OnRefresh()
	if IsServer() then self:SetHasCustomTransmitterData(true) end
end

function modifier_antimage_counterspell_barrier:OnRefresh()
	self.duration = self:GetSpecialValueFor("duration")
	self.total_barrier = self:GetSpecialValueFor("barrier")
	
	self.attack_speed_duration = self:GetSpecialValueFor("attack_speed_duration")
	self.barrier_to_innate = self:GetSpecialValueFor("barrier_to_innate") / 100
	
	self.damage_taken_returned = self:GetSpecialValueFor("damage_taken_returned")
	self.damage_radius = self:GetSpecialValueFor("damage_radius")
	if IsServer() then
		self.barrier = self.total_barrier
		self:SendBuffRefreshToClients()
	end
end

function modifier_antimage_counterspell_barrier:OnDestroy()
	if IsClient() then return end
	if self.attack_speed_duration > 0 then
		self:GetParent():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_antimage_counterspell_pragmatic", {duration = self.attack_speed_duration} )
	end
	if self.barrier_to_innate > 0 then
		local innate = self:GetCaster():FindModifierByName("modifier_antimage_persectur_passive")
		if innate then
			innate:SetStackCount( innate:GetStackCount() + self.total_barrier * self.barrier_to_innate )
		end
	end
end

function modifier_antimage_counterspell_barrier:CheckState()
	return {[MODIFIER_STATE_DEBUFF_IMMUNE] = true}
end

function modifier_antimage_counterspell_barrier:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT, MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_antimage_counterspell_barrier:OnTakeDamage( params )
	if self.damage_radius > 0 then
		local caster = self:GetCaster()
		if params.unit ~= caster then return end
		local ability = self:GetAbility()
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( self:GetParent(), self.damage_radius ) ) do
			ability:DealDamage( caster, enemy, barrier, {damage_type = params.damage_type, damage_flags = DOTA_DAMAGE_FLAG_REFLECTION + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION} )
		end
	end
end

function modifier_antimage_counterspell_barrier:GetModifierIncomingSpellDamageConstant( params )
	if IsServer() then
		local barrier = math.min( self.barrier, math.max( self.barrier, params.damage ) )
		self.barrier = math.max( 0, self.barrier - params.damage )
		
		if self.damage_radius > 0 then
			local caster = self:GetCaster()
			local ability = self:GetAbility()
			for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( self:GetParent(), self.damage_radius ) ) do
				ability:DealDamage( caster, enemy, barrier, {damage_type = params.damage_type, damage_flags = DOTA_DAMAGE_FLAG_REFLECTION + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION} )
			end
		end
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

modifier_antimage_counterspell_pragmatic = class({})
LinkLuaModifier( "modifier_antimage_counterspell_pragmatic", "heroes/hero_antimage/antimage_counterspell", LUA_MODIFIER_MOTION_NONE )

function modifier_antimage_counterspell_pragmatic:OnCreated()
	self:OnRefresh()
end

function modifier_antimage_counterspell_pragmatic:OnRefresh()
	self.attack_speed_bonus = self:GetSpecialValueFor("attack_speed_bonus")
end

function modifier_antimage_counterspell_pragmatic:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end
function modifier_antimage_counterspell_pragmatic:GetModifierAttackSpeedBonus_Constant( )
	return self.attack_speed_bonus
end