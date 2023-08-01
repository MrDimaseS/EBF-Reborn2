bristleback_bristleback = class({})

function bristleback_bristleback:GetIntrinsicModifierName()
	return "modifier_bristleback_bristleback_passive"
end

modifier_bristleback_bristleback_passive = class({})
LinkLuaModifier( "modifier_bristleback_bristleback_passive", "heroes/hero_bristleback/bristleback_bristleback", LUA_MODIFIER_MOTION_NONE )

function modifier_bristleback_bristleback_passive:OnCreated()
	if IsServer() then
		self.quills = self:GetCaster():FindAbilityByName("bristleback_quill_spray")
	end
end

function modifier_bristleback_bristleback_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE}
end

function modifier_bristleback_bristleback_passive:GetModifierIncomingDamage_Percentage( params )
	if self:GetParent():PassivesDisabled() then return end
	local max_reduction = self:GetSpecialValueFor("max_damage_reduction")
	local min_reduction = self:GetSpecialValueFor("min_damage_reduction")
	local red_scale = max_reduction - min_reduction
	
	local dotPr = DotProduct( params.target:GetForwardVector(), params.attacker:GetForwardVector() )
	local scaling = (dotPr + 1) / 2
	
	local total_reduction = min_reduction + red_scale * scaling
	
	self.damageTaken = (self.damageTaken or 0) + params.damage * total_reduction/100
	local hpThreshold = self:GetCaster():GetHealth() * self:GetSpecialValueFor("quill_release_threshold") / 100
	if self.damageTaken >= hpThreshold then
		if self.quills then self.quills:OnSpellStart() end
		self.damageTaken = 0
	end
	
	return -total_reduction
end