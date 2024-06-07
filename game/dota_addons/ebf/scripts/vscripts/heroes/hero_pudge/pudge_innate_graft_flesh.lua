pudge_innate_graft_flesh = class({})

function pudge_innate_graft_flesh:GetIntrinsicModifierName()
	return "modifier_pudge_innate_graft_flesh_kills"
end

LinkLuaModifier("modifier_pudge_innate_graft_flesh_kills", "heroes/hero_pudge/pudge_innate_graft_flesh.lua", LUA_MODIFIER_MOTION_NONE)
modifier_pudge_innate_graft_flesh_kills = class({})

function modifier_pudge_innate_graft_flesh_kills:OnCreated()
	self:OnRefresh()
end

function modifier_pudge_innate_graft_flesh_kills:OnRefresh()
	self.strength_per_stack = self:GetSpecialValueFor("flesh_heap_strength_buff_amount")
	self.creep_stacks = self:GetAbility():GetSpecialValueFor("creep_stacks")
	self.hero_stacks = self:GetAbility():GetSpecialValueFor("hero_stacks")
	self.flesh_heap_range = self:GetAbility():GetSpecialValueFor("flesh_heap_range")
	self.temporary_duration = self:GetAbility():GetSpecialValueFor("temporary_duration")
end

function modifier_pudge_innate_graft_flesh_kills:OnIntervalThink()
	self:SetDuration( -1, true )
	self:StartIntervalThink( -1 )
end

function modifier_pudge_innate_graft_flesh_kills:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			 MODIFIER_EVENT_ON_DEATH }
end

function modifier_pudge_innate_graft_flesh_kills:OnDeath(params)
	local caster = self:GetCaster()
	if not caster:IsSameTeam( params.unit ) and ( params.attacker == caster or CalculateDistance( caster, params.unit ) <= self.flesh_heap_range ) then
		local stacks = TernaryOperator( self.hero_stacks, params.unit:IsConsideredHero(), self.creep_stacks )
		if params.unit:IsNeutralUnitType() or params.unit.Holdout_IsCore then
			self:SetStackCount( self:GetStackCount() + stacks )
		else
			for i = 1, stacks do
				self:AddIndependentStack( self.temporary_duration )
			end
			self:SetDuration( self.temporary_duration, true )
			self:StartIntervalThink( self.temporary_duration )
		end
	end
end

function modifier_pudge_innate_graft_flesh_kills:GetModifierBonusStats_Strength()
	return self:GetStackCount() * self.strength_per_stack
end

function modifier_pudge_innate_graft_flesh_kills:RemoveOnDeath()
	return false
end

function modifier_pudge_innate_graft_flesh_kills:IsPermanent()
	return true
end

function modifier_pudge_innate_graft_flesh_kills:IsPurgable()
	return false
end

function modifier_pudge_innate_graft_flesh_kills:DestroyOnExpire()
	return false
end