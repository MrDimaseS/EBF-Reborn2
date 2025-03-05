pudge_flesh_heap = class({})

function pudge_flesh_heap:OnSpellStart()
	local caster = self:GetCaster()
	
	local duration = self:GetSpecialValueFor("duration")
	local heal = self:GetSpecialValueFor("heal")
	local dispel = self:GetSpecialValueFor("basic_dispel") == 1
	caster:AddNewModifier( caster, self, "modifier_pudge_flesh_heap_buff", {duration = duration} )
	if heal > 0 then
		caster:HealEvent( heal, self, caster )
	end
	if dispel then
		caster:Dispel( caster, false )
	end
end

LinkLuaModifier("modifier_pudge_flesh_heap_buff", "heroes/hero_pudge/pudge_flesh_heap.lua", LUA_MODIFIER_MOTION_NONE)
modifier_pudge_flesh_heap_buff = class({})

function modifier_pudge_flesh_heap_buff:OnCreated()
	self:OnRefresh()
end

function modifier_pudge_flesh_heap_buff:OnRefresh()
	self.block = self:GetSpecialValueFor("damage_block")
	self.bonus_ms = self:GetSpecialValueFor("bonus_ms")
	self.phased_movement = self:GetSpecialValueFor("phased_movement") == 1
end

function modifier_pudge_flesh_heap_buff:CheckState()
	if self.phased_movement then
		return {[MODIFIER_STATE_NO_UNIT_COLLISION] = true}
	end
end

function modifier_pudge_flesh_heap_buff:DeclareFunctions()
	return { MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE  }
end

function modifier_pudge_flesh_heap_buff:GetModifierTotal_ConstantBlock()
	return self.block
end

function modifier_pudge_flesh_heap_buff:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_ms
end

function modifier_pudge_flesh_heap_buff:GetEffectName()
	return "particles/units/heroes/hero_pudge/pudge_fleshheap_block_activation.vpcf"
end