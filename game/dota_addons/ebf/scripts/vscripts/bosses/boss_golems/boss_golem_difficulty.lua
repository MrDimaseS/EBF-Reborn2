boss_golem_difficulty = class({})

function boss_golem_difficulty:GetIntrinsicModifierName()
	return "modifier_boss_golem_difficulty"
end

modifier_boss_golem_difficulty = class({})
LinkLuaModifier( "modifier_boss_golem_difficulty", "bosses/boss_golems/boss_golem_difficulty", LUA_MODIFIER_MOTION_NONE)

function modifier_boss_golem_difficulty:OnCreated()
	self:OnRefresh()
end

function modifier_boss_golem_difficulty:OnRefresh()
	self.cdr = self:GetSpecialValueFor("cdr")
end

function modifier_boss_golem_difficulty:DeclareFunctions()
	return {MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE_STACKING}
end

function modifier_boss_golem_difficulty:GetModifierPercentageCooldownStacking( params )
	return self.cdr
end

function modifier_boss_golem_difficulty:IsHidden()
	return true
end

function modifier_boss_golem_difficulty:IsPurgable()
	return false
end