vengefulspirit_retribution = class({})

function vengefulspirit_retribution:IsStealable()
	return true
end

function vengefulspirit_retribution:IsHiddenWhenStolen()
	return false
end

function vengefulspirit_retribution:GetIntrinsicModifierName()
	return "modifier_vengefulspirit_retribution_handler"
end

modifier_vengefulspirit_retribution_handler = class({})
LinkLuaModifier( "modifier_vengefulspirit_retribution_handler", "heroes/hero_vengefulspirit/vengefulspirit_retribution.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_vengefulspirit_retribution_handler:OnCreated()
	self:OnRefresh()
end

function modifier_vengefulspirit_retribution_handler:OnRefresh()
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.bonus_duration = self:GetSpecialValueFor("bonus_duration")
end

function modifier_vengefulspirit_retribution_handler:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
    }
    return funcs
end

function modifier_vengefulspirit_retribution_handler:GetModifierIncomingDamage_Percentage(params)
    params.attacker:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_vengefulspirit_retribution_tracker", {duration = self.bonus_duration} )
end

function modifier_vengefulspirit_retribution_handler:GetModifierTotalDamageOutgoing_Percentage(params)
    if params.target:HasModifier("modifier_vengefulspirit_retribution_tracker") then
		return self.bonus_damage
	end
end
