item_phylactery_2 = class({})

function item_phylactery_2:ShouldUseResources()
	return true
end

function item_phylactery_2:GetIntrinsicModifierName()
	return "modifier_item_phylactery_passive"
end

item_phylactery_3 = class(item_phylactery_2)
item_phylactery_4 = class(item_phylactery_2)
item_phylactery_5 = class(item_phylactery_2)

modifier_item_phylactery_passive = class({})
LinkLuaModifier( "modifier_item_phylactery_passive", "items/item_phylactery.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_phylactery_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_phylactery_passive:OnRefresh()
	self.bonus_mana = self:GetAbility():GetSpecialValueFor("bonus_mana")
	self.bonus_health = self:GetAbility():GetSpecialValueFor("bonus_health")
	self.bonus_all_stats = self:GetAbility():GetSpecialValueFor("bonus_all_stats")
	
	self.bonus_spell_damage = self:GetAbility():GetSpecialValueFor("bonus_spell_damage")
	self.bonus_damage_radius = self:GetAbility():GetSpecialValueFor("bonus_damage_radius")
	self.slow = self:GetAbility():GetSpecialValueFor("slow")
	self.slow_duration = self:GetAbility():GetSpecialValueFor("slow_duration")
end

function modifier_item_phylactery_passive:DeclareFunctions(params)
local funcs = {
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_MANA_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_EVENT_SPELL_APPLIED_SUCCESSFULLY
    }
    return funcs
end

function modifier_item_phylactery_passive:OnSpellAppliedSuccessfully( params )
	if params.ability:GetCaster() ~= self:GetCaster() then return end
	if not self:GetAbility():IsCooldownReady() then return end
	if not params.target then return end
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local target = params.target
	
	for _, unit in ipairs( caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), self.bonus_damage_radius ) ) do
		ability:DealDamage( caster, unit, self.bonus_spell_damage, {damage_type = DAMAGE_TYPE_MAGICAL}, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE )
	end
	
	ParticleManager:FireParticle( "particles/items3_fx/phylactery_burst.vpcf", PATTACH_POINT_FOLLOW, target, {[1] = Vector(self.bonus_damage_radius,self.bonus_damage_radius,self.bonus_damage_radius)} )
	ParticleManager:FireRopeParticle( "particles/items_fx/phylactery.vpcf", PATTACH_POINT_FOLLOW, caster, target )
	EmitSoundOn("Item.Phylactery.Target", target )
	ability:SetCooldown()
end

function modifier_item_phylactery_passive:GetModifierManaBonus()
	return self.bonus_mana
end

function modifier_item_phylactery_passive:GetModifierHealthBonus()
	return self.bonus_health
end

function modifier_item_phylactery_passive:GetModifierBonusStats_Strength()
	return self.bonus_all_stats
end

function modifier_item_phylactery_passive:GetModifierBonusStats_Intellect()
	return self.bonus_all_stats
end

function modifier_item_phylactery_passive:GetModifierBonusStats_Agility()
	return self.bonus_all_stats
end

function modifier_item_phylactery_passive:IsHidden()
	return true
end

function modifier_item_phylactery_passive:IsPurgable()
	return true
end