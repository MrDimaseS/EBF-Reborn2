pudge_flesh_heap = class({})

function pudge_flesh_heap:OnSpellStart()
	local caster = self:GetCaster()
	
	local duration = self:GetSpecialValueFor("duration")
	local heal = self:GetSpecialValueFor("heal")
	local dispel = self:GetSpecialValueFor("basic_dispel") == 1
	local invulnerability = self:GetSpecialValueFor("invulnerability")
	caster:AddNewModifier( caster, self, "modifier_pudge_flesh_heap_buff", {duration = duration} )
	if heal > 0 then
		caster:HealEvent( heal, self, caster )
	end
	if dispel then
		caster:Dispel( caster, false )
	end
	if invulnerability > 0 then
		caster:AddNewModifier( caster, self, "modifier_invulnerable", {duration = invulnerability} )
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
	self.status_resistance = self:GetSpecialValueFor("status_resistance")
	self.strength_pct = self:GetParent():GetStrength() * self:GetSpecialValueFor("strength_pct") / 100
	self.size_pct = self:GetSpecialValueFor("strength_pct")
end

function modifier_pudge_flesh_heap_buff:CheckState()
	if self.phased_movement then
		return {[MODIFIER_STATE_NO_UNIT_COLLISION] = true}
	end
end

function modifier_pudge_flesh_heap_buff:DeclareFunctions()
	return { MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, 
			 MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING, 
			 MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, MODIFIER_PROPERTY_MODEL_SCALE }
end

function modifier_pudge_flesh_heap_buff:GetModifierTotal_ConstantBlock()
	return self.block
end

function modifier_pudge_flesh_heap_buff:GetModifierStatusResistanceStacking()
	return self.status_resistance
end

function modifier_pudge_flesh_heap_buff:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_ms
end

function modifier_pudge_flesh_heap_buff:GetModifierBonusStats_Strength()
	return self.strength_pct
end

function modifier_pudge_flesh_heap_buff:GetModifierModelScale()
	return self.size_pct
end

function modifier_pudge_flesh_heap_buff:GetEffectName()
	return "particles/units/heroes/hero_pudge/pudge_fleshheap_block_activation.vpcf"
end