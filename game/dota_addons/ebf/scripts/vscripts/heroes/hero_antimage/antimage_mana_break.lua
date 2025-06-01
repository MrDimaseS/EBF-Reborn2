antimage_mana_break = class ({})

function antimage_mana_break:GetIntrinsicModifierName()
	return "modifier_antimage_mana_break_passive"
end

modifier_antimage_mana_break_passive = class({})
LinkLuaModifier( "modifier_antimage_mana_break_passive", "heroes/hero_antimage/antimage_mana_break", LUA_MODIFIER_MOTION_NONE )

function modifier_antimage_mana_break_passive:OnCreated()
	self:OnRefresh()
end

function modifier_antimage_mana_break_passive:OnRefresh()
	self.duration = self:GetSpecialValueFor("duration")
end

function modifier_antimage_mana_break_passive:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED}
end

function modifier_antimage_mana_break_passive:OnAttackLanded(params)
	local caster = self:GetCaster()
	if params.attacker ~= caster or caster:PassivesDisabled() then return end
	local ability = self:GetAbility()
	params.target:AddNewModifier( params.attacker, ability, "modifier_antimage_mana_break_debuff", {duration = self.duration} )
end

function modifier_antimage_mana_break_passive:IsHidden()
	return true
end

modifier_antimage_mana_break_debuff = class({})
LinkLuaModifier( "modifier_antimage_mana_break_debuff", "heroes/hero_antimage/antimage_mana_break", LUA_MODIFIER_MOTION_NONE )

function modifier_antimage_mana_break_debuff:OnCreated()
	self:OnRefresh()
end

function modifier_antimage_mana_break_debuff:OnRefresh()
	self.slow_duration = self:GetSpecialValueFor("slow_duration")
	self.percent_damage_per_burn = self:GetSpecialValueFor("percent_damage_per_burn") / 100
	self.mana_per_hit = self:GetSpecialValueFor("mana_per_hit")
	self.mana_per_hit_pct = self:GetSpecialValueFor("mana_per_hit_pct") / 100
	
	self.spell_damage_dealt = self:GetSpecialValueFor("spell_damage_dealt")
	self.spell_damage_taken = self:GetSpecialValueFor("spell_damage_taken")
end

function modifier_antimage_mana_break_debuff:DeclareFunctions()
	return {MODIFIER_EVENT_ON_SPENT_MANA,
			MODIFIER_PROPERTY_TOOLTIP,
			MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
			MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
			}
end

function modifier_antimage_mana_break_debuff:OnTooltip()
	return self.mana_per_hit + self:GetCaster():GetMaxMana() * self.mana_per_hit_pct
end

function modifier_antimage_mana_break_debuff:GetModifierTotalDamageOutgoing_Percentage( params )
	if params.damage_category ~= DOTA_DAMAGE_CATEGORY_SPELL then return end
	return -self.spell_damage_dealt
end

function modifier_antimage_mana_break_debuff:GetModifierIncomingDamage_Percentage( params )
	if params.damage_category ~= DOTA_DAMAGE_CATEGORY_SPELL then return end
	return self.spell_damage_taken
end

function modifier_antimage_mana_break_debuff:OnSpentMana(params)
	local parent = self:GetParent()
	if params.unit ~= parent then return end
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	local burn = params.cost + self:OnTooltip()
	parent:ReduceMana( self:OnTooltip() )
	ability:DealDamage( caster, parent, burn * self.percent_damage_per_burn )
	SendOverheadEventMessage(caster:GetPlayerOwner(), OVERHEAD_ALERT_MANA_LOSS , parent, math.floor( self:OnTooltip() ), caster:GetPlayerOwner())
	parent:AddNewModifier( caster, ability, "modifier_antimage_mana_break_slow", {duration = self.slow_duration} )
end

modifier_antimage_mana_break_slow = class({})
LinkLuaModifier( "modifier_antimage_mana_break_slow", "heroes/hero_antimage/antimage_mana_break", LUA_MODIFIER_MOTION_NONE )

function modifier_antimage_mana_break_slow:OnCreated()
	self:OnRefresh()
end

function modifier_antimage_mana_break_slow:OnRefresh()
	self.slow = self:GetSpecialValueFor("slow")
end

function modifier_antimage_mana_break_slow:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_antimage_mana_break_slow:GetModifierMoveSpeedBonus_Percentage()
	return self.slow * self:GetCaster():GetMana() / self:GetCaster():GetMaxMana()
end