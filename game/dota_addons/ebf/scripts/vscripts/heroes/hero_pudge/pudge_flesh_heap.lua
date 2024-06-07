pudge_flesh_heap = class({})

function pudge_flesh_heap:OnSpellStart()
	local caster = self:GetCaster()
	
	caster:AddNewModifier( caster, self, "modifier_pudge_flesh_heap_buff", {duration = self:GetSpecialValueFor("duration")} )
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