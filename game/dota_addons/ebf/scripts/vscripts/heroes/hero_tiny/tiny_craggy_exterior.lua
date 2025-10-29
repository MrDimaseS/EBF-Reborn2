tiny_craggy_exterior = class({})

function tiny_craggy_exterior:GetIntrinsicModifierName()
	return "modifier_tiny_craggy_exterior_handler"
end

modifier_tiny_craggy_exterior_handler = class({})
LinkLuaModifier("modifier_tiny_craggy_exterior_handler", "heroes/hero_tiny/tiny_craggy_exterior", LUA_MODIFIER_MOTION_NONE)
function modifier_tiny_craggy_exterior_handler:OnCreated()
	self:OnRefresh()
end

function modifier_tiny_craggy_exterior_handler:OnRefresh()
	self.slow_resistance = self:GetSpecialValueFor("slow_resistance")
	self.status_resistance = self:GetSpecialValueFor("status_resistance")
	
	self.debuff_duration = self:GetSpecialValueFor("debuff_duration")
end

function modifier_tiny_craggy_exterior_handler:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED,
			MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
			MODIFIER_PROPERTY_SLOW_RESISTANCE_STACKING,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
			}
end

function modifier_tiny_craggy_exterior_handler:OnAttackLanded(params)
	if params.target ~= self:GetParent() then return end
	if params.target:IsSameTeam( params.attacker ) then return end
	params.attacker:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_tiny_craggy_exterior_effect", {duration = self.debuff_duration} )
end

function modifier_tiny_craggy_exterior_handler:GetModifierStatusResistanceStacking()
	return self.status_resistance
end

function modifier_tiny_craggy_exterior_handler:GetModifierSlowResistance_Stacking()
	return self.slow_resistance
end

function modifier_tiny_craggy_exterior_handler:GetModifierMoveSpeedBonus_Percentage()
	if self.slow_resistance <= 0 then return end
	if self._locked then return end
	self._locked = true
	local totalSlow = (1 - (self:GetParent():GetIdealSpeed() / self:GetParent():GetIdealSpeedNoSlows())) * 100
	self._locked = false
	if totalSlow <= 0 then 
		return 
	end
	return totalSlow * self.slow_resistance / 100
end

function modifier_tiny_craggy_exterior_handler:IsHidden()
	return true
end

modifier_tiny_craggy_exterior_effect = class({})
LinkLuaModifier("modifier_tiny_craggy_exterior_effect", "heroes/hero_tiny/tiny_craggy_exterior", LUA_MODIFIER_MOTION_NONE)
function modifier_tiny_craggy_exterior_effect:OnCreated()
	self:OnRefresh()
end

function modifier_tiny_craggy_exterior_effect:OnRefresh()
	self.damage_reduction_per_stack = -self:GetSpecialValueFor("damage_reduction_per_stack")
	
	self.max_stacks = self:GetSpecialValueFor("max_stacks")
	self.stun_chance_per_stack = self:GetSpecialValueFor("stun_chance_per_stack")
	self.stun_duration = self:GetSpecialValueFor("stun_duration")
	if IsServer() then
		if self:GetStackCount() < self.max_stacks then
			self:IncrementStackCount()
		end
		if self.stun_chance_per_stack > 0 then
			local chance = self:GetStackCount() * self.stun_chance_per_stack
			if self:RollPRNG( chance ) then
				local parent = self:GetParent()
				self:GetAbility():Stun( parent, self.stun_duration )
			end
		end
	end
end

function modifier_tiny_craggy_exterior_effect:DeclareFunctions()
	return {MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE}
end

function modifier_tiny_craggy_exterior_effect:GetModifierDamageOutgoing_Percentage()
	return self.damage_reduction_per_stack * self:GetStackCount()
end
