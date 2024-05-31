slark_barracuda = class({})

function slark_barracuda:GetIntrinsicModifierName()
	return "modifier_slark_barracuda_handler"
end

modifier_slark_barracuda_handler = class({})
LinkLuaModifier("modifier_slark_barracuda_handler", "heroes/hero_slark/slark_barracuda", LUA_MODIFIER_MOTION_NONE)

function modifier_slark_barracuda_handler:OnCreated()
	self.regen = self:GetSpecialValueFor("bonus_regen")
	self.ms = self:GetSpecialValueFor("bonus_movement_speed")
	
	self.neutral_disable = self:GetSpecialValueFor("neutral_disable")
	if IsServer() then
		self:StartIntervalThink(0.1)
	end
end

function modifier_slark_barracuda_handler:OnRefresh()
	self.regen = self:GetSpecialValueFor("bonus_regen")
	self.ms = self:GetSpecialValueFor("bonus_movement_speed")
	self.radius = self:GetSpecialValueFor("search_radius")
	self.linger_duration = self:GetSpecialValueFor("linger_duration")
	if IsServer() then
		self:StartIntervalThink(0.1)
	end
end


function modifier_slark_barracuda_handler:OnIntervalThink()
	local caster = self:GetCaster()
	if self:GetParent():HasModifier("modifier_slark_shadow_dance_activated") or self:GetParent():HasModifier("modifier_slark_depth_shroud") then
		self:SetStackCount(0)
		return
	end
	if self:GetParent():PassivesDisabled() then
		self:SetStackCount(self.neutral_disable * 10)
		return
	end
	if self:GetStackCount() > 0 then
		self:DecrementStackCount()
		return
	end
end

function modifier_slark_barracuda_handler:IsHidden()
	return self:GetStackCount() ~= 0
end

function modifier_slark_barracuda_handler:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_slark_barracuda_handler:OnTakeDamage(params)
	if params.unit == self:GetParent() and not params.attacker:IsSameTeam( params.unit ) and not HasBit( params.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS ) then
		if self.linger_duration > 0 and not self:IsHidden() then
			self:GetParent():AddNewModifier( self:GetParent(), self:GetAbility(), "modifier_slark_barracuda_lingering", {duration = self.linger_duration} )
		end
		self:SetStackCount(self.neutral_disable * 10)
	end
end

function modifier_slark_barracuda_handler:GetModifierConstantHealthRegen()
	if not self:IsHidden() or self:GetCaster():HasModifier("modifier_slark_barracuda_lingering") then return self.regen end
end

function modifier_slark_barracuda_handler:GetModifierMoveSpeedBonus_Percentage()
	if not self:IsHidden() or self:GetCaster():HasModifier("modifier_slark_barracuda_lingering") then return self.ms end
end
modifier_slark_barracuda_lingering = class({})
LinkLuaModifier("modifier_slark_barracuda_lingering", "heroes/hero_slark/slark_barracuda", LUA_MODIFIER_MOTION_NONE)