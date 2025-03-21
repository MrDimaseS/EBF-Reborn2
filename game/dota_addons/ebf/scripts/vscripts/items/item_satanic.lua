item_lifesteal = class({})

function item_lifesteal:GetIntrinsicModifierName()
	return "modifier_item_satanic_passive_effect"
end

item_satanic = class(item_lifesteal)

function item_satanic:OnSpellStart()
	local caster = self:GetCaster()
	caster:Dispel( caster )
	caster:AddNewModifier( caster, self, "modifier_item_satanic_active", {duration = self:GetSpecialValueFor("unholy_duration")} )
	
	EmitSoundOn( "DOTA_Item.Satanic.Activate", caster )
end

item_satanic_2 = class(item_satanic)
item_satanic_3 = class(item_satanic)
item_satanic_4 = class(item_satanic)
item_satanic_5 = class(item_satanic)

modifier_item_satanic_active = class({})
LinkLuaModifier( "modifier_item_satanic_active", "items/item_satanic.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_satanic_active:OnCreated()
	self.unholy_lifesteal_total_tooltip = self:GetAbility():GetSpecialValueFor("unholy_lifesteal_total_tooltip")
	self.unholy_status_resistance = self:GetAbility():GetSpecialValueFor("unholy_status_resistance")
end

function modifier_item_satanic_active:CheckState()
	return {[MODIFIER_STATE_ROOTED] = false,
			[MODIFIER_STATE_UNSLOWABLE] = true}
end

function modifier_item_satanic_active:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING, MODIFIER_PROPERTY_TOOLTIP }
end

function modifier_item_satanic_active:GetModifierStatusResistanceStacking( params )
	return self.unholy_status_resistance
end

function modifier_item_satanic_active:OnTooltip( params )
	return self.unholy_lifesteal_total_tooltip
end

function modifier_item_satanic_active:GetEffectName()
	return "particles/items2_fx/satanic_buff.vpcf"
end

modifier_item_satanic_passive_effect = class({})
LinkLuaModifier( "modifier_item_satanic_passive_effect", "items/item_satanic.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_satanic_passive_effect:OnCreated()
	self:OnRefresh()
end

function modifier_item_satanic_passive_effect:OnRefresh()
	self.bonus_strength = self:GetSpecialValueFor("bonus_strength")
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.lifesteal_percent = self:GetSpecialValueFor("lifesteal_percent")
	self.unholy_lifesteal_total_tooltip = self:GetSpecialValueFor("unholy_lifesteal_total_tooltip")
	
	self:GetCaster()._attackLifestealModifiersList = self:GetCaster()._attackLifestealModifiersList or {}
	self:GetCaster()._attackLifestealModifiersList[self] = true
end

function modifier_item_satanic_passive_effect:DeclareFunctions(params)
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    }
    return funcs
end

function modifier_item_satanic_passive_effect:GetModifierBonusStats_Strength( params )
	return self.bonus_strength
end

function modifier_item_satanic_passive_effect:GetModifierPreAttack_BonusDamage( params )
	return self.bonus_damage
end

function modifier_item_satanic_passive_effect:GetModifierProperty_PhysicalLifesteal(params)
	return TernaryOperator( self.unholy_lifesteal_total_tooltip, params.attacker:HasModifier("modifier_item_satanic_active"), self.lifesteal_percent )
end

function modifier_item_satanic_passive_effect:IsHidden()
	return true
end

function modifier_item_satanic_passive_effect:IsPurgable()
	return false
end

function modifier_item_satanic_passive_effect:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE 
end