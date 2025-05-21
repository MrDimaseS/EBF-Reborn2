item_revenants_brooch = class({})

function item_revenants_brooch:GetIntrinsicModifierName()
	return "modifier_item_revenants_brooch_passive_effect"
end

item_revenants_brooch_2 = class(item_revenants_brooch)
item_revenants_brooch_3 = class(item_revenants_brooch)
item_revenants_brooch_4 = class(item_revenants_brooch)
item_revenants_brooch_5 = class(item_revenants_brooch)

modifier_item_revenants_brooch_passive_effect = class({})
LinkLuaModifier( "modifier_item_revenants_brooch_passive_effect", "items/item_revenants_brooch.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_revenants_brooch_passive_effect:OnCreated()
	self:OnRefresh()
end

function modifier_item_revenants_brooch_passive_effect:OnRefresh()
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.spell_lifesteal = self:GetSpecialValueFor("spell_lifesteal")
	self.crit_chance = self:GetSpecialValueFor("crit_chance")
	self.crit_multiplier = self:GetSpecialValueFor("crit_multiplier")
	self.crits = {}
	
	self:GetCaster()._spellLifestealModifiersList = self:GetCaster()._spellLifestealModifiersList or {}
	self:GetCaster()._spellLifestealModifiersList[self] = true
end

function modifier_item_revenants_brooch_passive_effect:DeclareFunctions(params)
	local funcs = {
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE 
    }
    return funcs
end

function modifier_item_revenants_brooch_passive_effect:GetModifierPreAttack_BonusDamage( params )
	return self.bonus_damage
end

function modifier_item_revenants_brooch_passive_effect:GetModifierProperty_MagicalLifesteal(params)
	return self.spell_lifesteal
end

function modifier_item_revenants_brooch_passive_effect:GetModifierPreAttack_CriticalStrike( params )
	if self:RollPRNG( self.crit_chance ) then
		self.crits[params.record] = true
		return 101
	end
end

function modifier_item_revenants_brooch_passive_effect:GetModifierTotalDamageOutgoing_Percentage( params )
	if self.crits[params.record] then
		self.crits[params.record] = nil
		self:GetAbility():DealDamage( params.attacker, params.target, params.original_damage * self.crit_multiplier / 100, {damage_type = DAMAGE_TYPE_MAGICAL, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_MAGIC_AUTO_ATTACK}, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE )
		return damage_reduction
	end
end

function modifier_item_revenants_brooch_passive_effect:GetCritDamage()
	return 1+self.crit_multiplier / 100
end

function modifier_item_revenants_brooch_passive_effect:IsHidden()
	return true
end

function modifier_item_revenants_brooch_passive_effect:IsPurgable()
	return false
end

function modifier_item_revenants_brooch_passive_effect:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE 
end