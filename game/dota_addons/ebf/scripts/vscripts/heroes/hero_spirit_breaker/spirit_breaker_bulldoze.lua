spirit_breaker_bulldoze = class({})

function spirit_breaker_bulldoze:IsStealable()
	return true
end

function spirit_breaker_bulldoze:OnSpellStart()
	local caster = self:GetCaster()
	
	local duration = self:GetSpecialValueFor("duration")
	caster:AddNewModifier(caster, self, "modifier_spirit_breaker_bulldoze_active", {Duration = duration})
	EmitSoundOn("Hero_Spirit_Breaker.Bulldoze.Cast", caster)
end

modifier_spirit_breaker_bulldoze_active = class({})
LinkLuaModifier( "modifier_spirit_breaker_bulldoze_active", "heroes/hero_spirit_breaker/spirit_breaker_bulldoze.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_spirit_breaker_bulldoze_active:OnCreated()
	self:OnRefresh()
end

function modifier_spirit_breaker_bulldoze_active:OnRefresh()
	self.movement_speed = self:GetSpecialValueFor("movement_speed")
	self.status_resistance = self:GetSpecialValueFor("status_resistance")
	self.barrier = self:GetSpecialValueFor("damage_barrier")
	
	if IsServer() then self:SetHasCustomTransmitterData(true) end
end

function modifier_spirit_breaker_bulldoze_active:OnRefresh(kv)
	self.movement_speed = self:GetSpecialValueFor("movement_speed")
	self.status_resistance = self:GetSpecialValueFor("status_resistance")
	self.barrier = self:GetSpecialValueFor("damage_barrier")
	if IsServer() then
		self:SendBuffRefreshToClients()
	end
end

function modifier_spirit_breaker_bulldoze_active:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
	}
	return funcs
end

function modifier_spirit_breaker_bulldoze_active:GetModifierMoveSpeedBonus_Percentage(params)
	return self.movement_speed
end
function modifier_spirit_breaker_bulldoze_active:GetModifierStatusResistanceStacking(params)
	return self.status_resistance
end

function modifier_spirit_breaker_bulldoze_active:GetModifierIncomingDamageConstant( params )
	if IsServer() then
		local barrier = math.min( self.barrier, math.max( self.barrier, params.damage ) )
		self.barrier = self.barrier - params.damage
		self:SendBuffRefreshToClients()
		return -barrier
	else
		return self.barrier
	end
end

function modifier_spirit_breaker_bulldoze_active:AddCustomTransmitterData()
	return {barrier = self.barrier}
end

function modifier_spirit_breaker_bulldoze_active:HandleCustomTransmitterData(data)
	self.barrier = data.barrier
end

function modifier_spirit_breaker_bulldoze_active:GetEffectName()
	return "particles/units/heroes/hero_spirit_breaker/spirit_breaker_haste_owner.vpcf"
end