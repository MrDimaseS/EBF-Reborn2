invoker_mastermind = class({})

function invoker_mastermind:GetIntrinsicModifierName()
	return "modifier_invoker_mastermind_innate"
end

modifier_invoker_mastermind_innate = class({})
LinkLuaModifier("modifier_invoker_mastermind_innate", "heroes/hero_invoker/invoker_mastermind", LUA_MODIFIER_MOTION_NONE)

function modifier_invoker_mastermind_innate:OnCreated()
	self.spell_amp_bonus = self:GetSpecialValueFor("spell_amp_bonus")
	self.bonus_duration = self:GetSpecialValueFor("bonus_duration")
end

function modifier_invoker_mastermind_innate:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ABILITY_FULLY_CAST, MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE }
end

function modifier_invoker_mastermind_innate:OnAbilityFullyCast( params )
	if params.unit ~= self:GetCaster() then return end
	if params.ability:IsItem() then return end
	if params.ability:GetName() == "invoker_invoke" then return end
	if params.ability:GetName() == "invoker_quas" then return end
	if params.ability:GetName() == "invoker_wex" then return end
	if params.ability:GetName() == "invoker_exort" then return end
	self:AddIndependentStack({duration = self.bonus_duration})
end

function modifier_invoker_mastermind_innate:GetModifierSpellAmplify_Percentage()
	return self.spell_amp_bonus * self:GetStackCount()
end

function modifier_invoker_mastermind_innate:IsHidden()
	return self:GetStackCount() <= 0
end

function modifier_invoker_mastermind_innate:IsPurgable()
	return false
end

function modifier_invoker_mastermind_innate:DestroyOnExpire()
	return false
end
