pudge_flesh_heap = class({})

function pudge_flesh_heap:GetIntrinsicModifierName()
	return "modifier_pudge_flesh_heap_kills"
end

function pudge_flesh_heap:Spawn()
	if not IsServer() then return end
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_pudge_flesh_heap_kills", {} )
end

function pudge_flesh_heap:OnSpellStart()
	local caster = self:GetCaster()
	
	caster:AddNewModifier( caster, self, "modifier_pudge_flesh_heap_buff", {duration = self:GetSpecialValueFor("duration")} )
end

LinkLuaModifier("modifier_pudge_flesh_heap_kills", "heroes/hero_pudge/pudge_flesh_heap.lua", LUA_MODIFIER_MOTION_NONE)
modifier_pudge_flesh_heap_kills = class({})

function modifier_pudge_flesh_heap_kills:OnCreated()
	self:OnRefresh()
end

function modifier_pudge_flesh_heap_kills:OnRefresh()
	self.strength_per_stack = self:GetSpecialValueFor("flesh_heap_strength_buff_amount")
	self.creep_stacks = self:GetAbility():GetLevelSpecialValueFor("creep_stacks", 1)
	self.hero_stacks = self:GetAbility():GetLevelSpecialValueFor("hero_stacks", 1)
	self.flesh_heap_range = self:GetAbility():GetLevelSpecialValueFor("flesh_heap_range", 1)
	self.temporary_duration = self:GetAbility():GetLevelSpecialValueFor("temporary_duration", 1)
end

function modifier_pudge_flesh_heap_kills:OnIntervalThink()
	self:SetDuration( -1, true )
	self:StartIntervalThink( -1 )
end

function modifier_pudge_flesh_heap_kills:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			 MODIFIER_EVENT_ON_DEATH }
end

function modifier_pudge_flesh_heap_kills:OnDeath(params)
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

function modifier_pudge_flesh_heap_kills:GetModifierBonusStats_Strength()
	return self:GetStackCount() * self.strength_per_stack
end

function modifier_pudge_flesh_heap_kills:RemoveOnDeath()
	return false
end

function modifier_pudge_flesh_heap_kills:IsPermanent()
	return true
end

function modifier_pudge_flesh_heap_kills:IsPurgable()
	return false
end

function modifier_pudge_flesh_heap_kills:DestroyOnExpire()
	return false
end

LinkLuaModifier("modifier_pudge_flesh_heap_buff", "heroes/hero_pudge/pudge_flesh_heap.lua", LUA_MODIFIER_MOTION_NONE)
modifier_pudge_flesh_heap_buff = class({})

function modifier_pudge_flesh_heap_buff:OnCreated()
	self:OnRefresh()
end

function modifier_pudge_flesh_heap_buff:OnRefresh()
	self.block = self:GetSpecialValueFor("damage_block")
end

function modifier_pudge_flesh_heap_buff:DeclareFunctions()
	return { MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK }
end

function modifier_pudge_flesh_heap_buff:GetModifierTotal_ConstantBlock()
	return self.block
end