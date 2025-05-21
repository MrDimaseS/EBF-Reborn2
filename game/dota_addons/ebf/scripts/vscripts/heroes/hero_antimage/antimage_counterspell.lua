antimage_counterspell = class ({})

function antimage_counterspell:OnSpellStart(target)
	local hTarget = target or self:GetCaster()
	
	hTarget:AddNewModifier( self:GetCaster(), self, "modifier_antimage_counterspell_barrier", {duration = self:GetSpecialValueFor("max_duration")} )
	ParticleManager:FireParticle("particles/units/heroes/hero_antimage/antimage_spellshield.vpcf", PATTACH_POINT_FOLLOW, hTarget, {[0] = "attach_hitloc"})
	EmitSoundOn( "Hero_Antimage.Counterspell.Cast", hTarget )
end

modifier_antimage_counterspell_barrier = class({})
LinkLuaModifier( "modifier_antimage_counterspell_barrier", "heroes/hero_antimage/antimage_counterspell", LUA_MODIFIER_MOTION_NONE )

function modifier_antimage_counterspell_barrier:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink( self.duration )
	end
	if IsServer() then self:SetHasCustomTransmitterData(true) end
end

function modifier_antimage_counterspell_barrier:OnRefresh()
	self.barrier = self:GetSpecialValueFor("barrier")
	self.max_duration = self:GetSpecialValueFor("max_duration")
	self.duration = self:GetSpecialValueFor("duration")
	if IsServer() thenµ
		self:SendBuffRefreshToClients()
	end
end

function modifier_antimage_counterspell_barrier:CheckState()
	return {[MODIFIER_STATE_DEBUFF_IMMUNE] = true}
end

function modifier_antimage_counterspell_barrier:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT}
end
function modifier_antimage_counterspell_barrier:GetModifierIncomingSpellDamageConstant( params )
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