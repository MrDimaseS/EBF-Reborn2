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
	self.bonus_mana = self:GetSpecialValueFor("bonus_mana")
	self.bonus_health = self:GetSpecialValueFor("bonus_health")
	self.bonus_all_stats = self:GetSpecialValueFor("bonus_all_stats")
	
	self.bonus_spell_damage = self:GetSpecialValueFor("bonus_spell_damage")
	self.bonus_damage_radius = self:GetSpecialValueFor("bonus_damage_radius")
	
	self.slow_duration = self:GetSpecialValueFor("slow_duration")
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
	
	params.target:AddNewModifier( caster, ability, "modifier_item_phylactery_debuff", {duration = self.slow_duration})
	
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

modifier_item_phylactery_debuff = class({})
LinkLuaModifier( "modifier_item_phylactery_debuff", "items/item_phylactery.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_phylactery_debuff:OnCreated()
	self:OnRefresh()
end

function modifier_item_phylactery_debuff:OnRefresh()
	self.slow = self:GetSpecialValueFor("slow")
	
	self.breaks = self:GetSpecialValueFor("break")
	self.disarms = self:GetSpecialValueFor("disarm")
	self.silences = self:GetSpecialValueFor("silence")
	self.stuns = self:GetSpecialValueFor("stun")
	
	self.weighting = 0
	
	if self.breaks < 0 then
		self.breakWeight = self.breaks * 100
		self.weighting = self.weighting + self.breaks * 100
		self.breaks = false
	else
		self.breaks = true
	end
	if self.disarms < 0 then
		self.disarmWeight = self.weighting + self.disarms * 100
		self.weighting = self.weighting + self.disarms * 100
		self.disarms = false
	else
		self.disarms = true
	end
	if self.silences < 0 then
		self.silenceWeight = self.weighting + self.disarms * 100
		self.weighting = self.weighting + self.disarms * 100
		self.silences = false
	else
		self.silences = true
	end
	if self.stuns < 0 then
		self.stunWeight = self.weighting + self.stuns * 100
		self.weighting = self.weighting + self.stuns * 100
		self.stuns = false
	else
		self.stuns = true
	end
	
	local randomFloat = RandomInt( 1, self.weighting )
	if self.breakWeight and randomFloat <= self.breakWeight then
		self.breaks = true
	elseif self.disarmWeight and randomFloat <= self.disarmWeight then
		self.disarms = true
	elseif self.silenceWeight and randomFloat <= self.silenceWeight then
		self.silences = true
	elseif self.stunWeight and randomFloat <= self.stunWeight then
		self.stuns = true
	end
end
function modifier_item_phylactery_debuff:CheckState(params)
	local state = {}
	if self.breaks then
		state[MODIFIER_STATE_PASSIVES_DISABLED] = true
	end
	if self.disarms then
		state[MODIFIER_STATE_DISARMED] = true
	end
	if self.silences then
		state[MODIFIER_STATE_SILENCED] = true
	end
	if self.stuns then
		state[MODIFIER_STATE_STUNNED] = true
	end
    return state
end

function modifier_item_phylactery_debuff:DeclareFunctions(params)
    return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_item_phylactery_debuff:GetModifierMoveSpeedBonus_Percentage()
	return -self.slow
end

function modifier_item_phylactery_debuff:IsPurgable()
	return true
end

function modifier_item_phylactery_debuff:GetEffectName()
	return "particles/units/heroes/hero_templar_assassin/templar_assassin_trap_slow.vpcf"
end