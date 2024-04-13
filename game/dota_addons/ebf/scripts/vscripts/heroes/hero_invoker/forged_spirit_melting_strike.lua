forged_spirit_melting_strike = class({})

function forged_spirit_melting_strike:GetIntrinsicModifierName()
	return "modifier_forged_spirit_melting_strike_handler"
end

modifier_forged_spirit_melting_strike_handler = class({})
LinkLuaModifier( "modifier_forged_spirit_melting_strike_handler", "heroes/hero_invoker/forged_spirit_melting_strike", LUA_MODIFIER_MOTION_NONE )

function modifier_forged_spirit_melting_strike_handler:OnCreated()
	self:OnRefresh()
end

function modifier_forged_spirit_melting_strike_handler:OnRefresh()
	self.max_armor_removed = self:GetSpecialValueFor("max_armor_removed")
	self.duration = self:GetSpecialValueFor("duration")
end

function modifier_forged_spirit_melting_strike_handler:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED}
end

function modifier_forged_spirit_melting_strike_handler:OnAttackLanded(params)
	if params.attacker == self:GetParent() then
		local armor_debuff = params.target:AddNewModifier( params.attacker, self:GetAbility(), "modifier_forged_spirit_melting_strike_debuff", {duration = self.duration} )
	end
end