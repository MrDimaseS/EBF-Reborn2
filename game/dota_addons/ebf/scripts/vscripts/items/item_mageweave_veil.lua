item_mageweave_veil = class({})

function item_mageweave_veil:GetIntrinsicModifierName()
	return "modifier_item_mageweave_veil_passive"
end

modifier_item_mageweave_veil_passive = class({})
LinkLuaModifier( "modifier_item_mageweave_veil_passive", "items/item_mageweave_veil.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_mageweave_veil_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_mageweave_veil_passive:OnRefresh()
	self.bonus_health = self:GetSpecialValueFor("bonus_health")
	self.bonus_spell_amp = self:GetSpecialValueFor("bonus_spell_amp")
	
	self.mana_to_health = self:GetSpecialValueFor("mana_to_health")
	self.health_cost = self:GetSpecialValueFor("health_cost") / 100
	if IsServer() then
		self._previousManaValue = self:GetParent():GetMana()
		self:StartIntervalThink( 0.1 )
	end
end

function modifier_item_mageweave_veil_passive:OnIntervalThink()
	local parent = self:GetParent()
	
	local currentManaValue
	if parent.GetRage then
		currentManaValue = parent:GetRage()
	elseif parent.GetStamina then
		currentManaValue = parent:GetStamina()
	else
		currentManaValue = parent:GetMana()
	end
	if self._previousManaValue < currentManaValue then
		local manaGain = currentManaValue - self._previousManaValue
		if manaGain >= 1 then
			parent:HealEvent( manaGain * self.mana_to_health, nil, parent, {heal_type = DOTA_HEAL_TYPE_REGENERATION} )
		end
	end
	self._previousManaValue = currentManaValue
end

function modifier_item_mageweave_veil_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEALTH_BONUS,
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_EVENT_ON_MANA_GAINED,
			MODIFIER_EVENT_ON_ABILITY_FULLY_CAST }
end

function modifier_item_mageweave_veil_passive:GetModifierHealthBonus()
	return self.bonus_health
end

function modifier_item_mageweave_veil_passive:GetModifierSpellAmplify_Percentage()
	return self.bonus_spell_amp
end

function modifier_item_mageweave_veil_passive:OnAbilityFullyCast( params )
	local parent = self:GetParent()
	if params.unit ~= parent then return end
	self:GetAbility():DealDamage( parent, parent, parent:GetHealth() * self.health_cost, {damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_NON_LETHAL } )
end

function modifier_item_mageweave_veil_passive:IsHidden()
	return true
end

function modifier_item_mageweave_veil_passive:IsPurgable()
	return false
end

function modifier_item_mageweave_veil_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end