marci_special_delivery = class({})

function marci_special_delivery:GetIntrinsicModifierName()
	return "modifier_marci_special_delivery_innate"
end

modifier_marci_special_delivery_innate = class({})
LinkLuaModifier("modifier_marci_special_delivery_innate", "heroes/hero_marci/marci_special_delivery", LUA_MODIFIER_MOTION_NONE)

function modifier_marci_special_delivery_innate:OnCreated()
	self.bonus_ms = self:GetSpecialValueFor("bonus_ms")
	self.bonus_as = self:GetSpecialValueFor("bonus_as")
	self.bonus_duration = self:GetSpecialValueFor("bonus_duration")
	self:SetStackCount(1)
end

function modifier_marci_special_delivery_innate:OnIntervalThink()
	self:SetStackCount(1)
	self:StartIntervalThink( -1 )
end

function modifier_marci_special_delivery_innate:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ABILITY_EXECUTED, 
			 MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
			 MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		}
end

function modifier_marci_special_delivery_innate:OnAbilityExecuted( params )
	if not (params.unit == self:GetCaster()) then return end
	if not ( params.target or params.target:IsSameTeam( self:GetCaster() )) then return end
	self:SetStackCount(0)
	self:StartIntervalThink( self.bonus_duration )
	self:SetDuration( self.bonus_duration, true )
end

function modifier_marci_special_delivery_innate:GetModifierAttackSpeedBonus_Constant()
	if self:GetStackCount() == 0 then
		return self.bonus_as
	end
end

function modifier_marci_special_delivery_innate:GetModifierMoveSpeedBonus_Constant()
	if self:GetStackCount() == 0 then
		return self.bonus_ms
	end
end

function modifier_marci_special_delivery_innate:IsHidden()
	return self:GetStackCount() == 1
end

function modifier_marci_special_delivery_innate:IsPurgable()
	return false
end

function modifier_marci_special_delivery_innate:DestroyOnExpire()
	return false
end
