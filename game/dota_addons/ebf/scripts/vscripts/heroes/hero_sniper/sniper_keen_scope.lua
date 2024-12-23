sniper_keen_scope = class({})

function sniper_keen_scope:GetIntrinsicModifierName()
	return "modifier_sniper_keen_scope_handler"
end

modifier_sniper_keen_scope_handler = class({})
LinkLuaModifier( "modifier_sniper_keen_scope_handler","heroes/hero_sniper/sniper_keen_scope.lua",LUA_MODIFIER_MOTION_NONE )
function modifier_sniper_keen_scope_handler:OnCreated()
	self:OnRefresh()
end

function modifier_sniper_keen_scope_handler:OnRefresh()
	self.bonus_range = self:GetSpecialValueFor("bonus_range")
	self.bonus_attack_time = self:GetSpecialValueFor("bonus_attack_time")
end

function modifier_sniper_keen_scope_handler:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS
	}
	return funcs
end

function modifier_sniper_keen_scope_handler:GetModifierBaseAttackTimeConstant( params )
	return self.bonus_attack_time
end

function modifier_sniper_keen_scope_handler:GetModifierAttackRangeBonus( params )
	return self.bonus_range
end

function modifier_sniper_keen_scope_handler:IsPurgeException()
	return false
end

function modifier_sniper_keen_scope_handler:IsPurgable()
	return false
end

function modifier_sniper_keen_scope_handler:IsHidden()
	return true
end