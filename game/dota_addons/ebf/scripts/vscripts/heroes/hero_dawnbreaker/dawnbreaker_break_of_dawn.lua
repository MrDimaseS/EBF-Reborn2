dawnbreaker_break_of_dawn = class({})

function dawnbreaker_break_of_dawn:IsStealable()
	return true
end

function dawnbreaker_break_of_dawn:IsHiddenWhenStolen()
	return false
end

function dawnbreaker_break_of_dawn:GetIntrinsicModifierName()
	return "modifier_dawnbreaker_break_of_dawn_handler"
end

modifier_dawnbreaker_break_of_dawn_handler = class({})
LinkLuaModifier( "modifier_dawnbreaker_break_of_dawn_handler", "heroes/hero_dawnbreaker/dawnbreaker_break_of_dawn.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_dawnbreaker_break_of_dawn_handler:OnCreated()
	self:OnRefresh()
	self:SetStackCount(1)
	if IsServer() then
		self:StartIntervalThink(0.2)
	end
end

function modifier_dawnbreaker_break_of_dawn_handler:OnRefresh()
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.damage_duration = self:GetSpecialValueFor("damage_duration")
end

function modifier_dawnbreaker_break_of_dawn_handler:OnIntervalThink()
	if self:GetStackCount() == 0 then
		self:SetStackCount( 1 )
		self:StartIntervalThink(0.2)
	end -- ignore while activated
	if GameRules:IsDaytime() and self:GetCaster().daytimeTriggered then return end
	if GameRules:IsDaytime() then
		if self:GetCaster().daytimeTriggered then
			return
		else
			self:StartIntervalThink( self.damage_duration )
			self:SetDuration( self.damage_duration, true )
			self:SetStackCount(0) -- activate ability
			self:GetCaster().daytimeTriggered = true
		end
	else
		self:GetCaster().daytimeTriggered = false
	end
end

function modifier_dawnbreaker_break_of_dawn_handler:DeclareFunctions()
    local funcs = {
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
    }
    return funcs
end

function modifier_dawnbreaker_break_of_dawn_handler:GetModifierTotalDamageOutgoing_Percentage(params)
    if not self:IsHidden() then
		return self.bonus_damage
	end
end

function modifier_dawnbreaker_break_of_dawn_handler:IsHidden()
	return self:GetStackCount() == 1
end

function modifier_dawnbreaker_break_of_dawn_handler:IsPermanent()
	return true
end

function modifier_dawnbreaker_break_of_dawn_handler:DestroyOnExpire()
	return false
end