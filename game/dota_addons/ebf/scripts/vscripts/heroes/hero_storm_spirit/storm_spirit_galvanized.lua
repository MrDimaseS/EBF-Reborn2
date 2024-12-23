storm_spirit_galvanized = class({})

function storm_spirit_galvanized:GetIntrinsicModifierName()
	return "modifier_storm_spirit_galvanized_innate"
end

modifier_storm_spirit_galvanized_innate = class({})
LinkLuaModifier("modifier_storm_spirit_galvanized_innate", "heroes/hero_storm_spirit/storm_spirit_galvanized", LUA_MODIFIER_MOTION_NONE)

function modifier_storm_spirit_galvanized_innate:OnCreated()
	self.mana_cost = self:GetSpecialValueFor("mana_cost")
	self.spell_amp = self:GetSpecialValueFor("spell_amp")
	self.duration = self:GetSpecialValueFor("duration")
end

function modifier_storm_spirit_galvanized_innate:DeclareFunctions()
	return { MODIFIER_EVENT_ON_TAKEDAMAGE, MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, MODIFIER_PROPERTY_MANACOST_PERCENTAGE_STACKING }
end

function modifier_storm_spirit_galvanized_innate:OnTakeDamage( params )
	if params.attacker ~= self:GetCaster() then return end
	if not params.inflictor then return end
	if params.inflictor:IsItem() then return end
	self:AddIndependentStack({duration = self.duration})
	self:SetDuration( self.duration, true )
end

function modifier_storm_spirit_galvanized_innate:GetModifierSpellAmplify_Percentage()
	return self.spell_amp * self:GetStackCount()
end

function modifier_storm_spirit_galvanized_innate:GetModifierPercentageManacostStacking()
	return self.mana_cost * self:GetStackCount()
end

function modifier_storm_spirit_galvanized_innate:IsHidden()
	return self:GetStackCount() <= 0
end

function modifier_storm_spirit_galvanized_innate:IsPurgable()
	return false
end

function modifier_storm_spirit_galvanized_innate:DestroyOnExpire()
	return false
end
