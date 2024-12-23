grimstroke_ink_trail = class({})

function grimstroke_ink_trail:GetIntrinsicModifierName()
	return "modifier_grimstroke_ink_trail_innate"
end

modifier_grimstroke_ink_trail_innate = class({})
LinkLuaModifier("modifier_grimstroke_ink_trail_innate", "heroes/hero_grimstroke/grimstroke_ink_trail", LUA_MODIFIER_MOTION_NONE)

function modifier_grimstroke_ink_trail_innate:OnCreated()
	self.debuff_duration = self:GetSpecialValueFor("debuff_duration")
end

function modifier_grimstroke_ink_trail_innate:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED}
end

function modifier_grimstroke_ink_trail_innate:OnAttackLanded( params )
	if params.attacker ~= self:GetCaster() then return end
	params.target:AddNewModifier( params.attacker, self:GetAbility(), "modifier_grimstroke_ink_trail_effect", {duration = self.debuff_duration} )
	params.target:AddNewModifier( params.attacker, self:GetAbility(), "modifier_grimstroke_ink_trail_debuff", {duration = self.debuff_duration} )
end

function modifier_grimstroke_ink_trail_innate:IsHidden()
	return true
end

modifier_grimstroke_ink_trail_effect = class({})
LinkLuaModifier("modifier_grimstroke_ink_trail_effect", "heroes/hero_grimstroke/grimstroke_ink_trail", LUA_MODIFIER_MOTION_NONE)

function modifier_grimstroke_ink_trail_effect:OnCreated()
	self.bonus_spell_damage = self:GetSpecialValueFor("bonus_spell_damage")
end

function modifier_grimstroke_ink_trail_effect:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end

function modifier_grimstroke_ink_trail_effect:GetModifierIncomingDamage_Percentage( params )
	if ( params.inflictor and params.inflictor:GetCaster() == self:GetCaster() ) then
		return self.bonus_spell_damage
	end
end

function modifier_grimstroke_ink_trail_effect:IsHidden()
	return true
end