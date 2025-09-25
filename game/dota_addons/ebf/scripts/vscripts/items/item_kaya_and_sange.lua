LinkLuaModifier( "modifier_item_aeon_disk_effect", "items/item_aeon_disk.lua" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_aeon_disk_cooldown", "items/item_aeon_disk.lua" ,LUA_MODIFIER_MOTION_NONE )
item_kaya_and_sange = class({})

function item_kaya_and_sange:GetIntrinsicModifierName()
	return "modifier_item_kaya_and_sange_passive"
end

modifier_item_kaya_and_sange_passive = class({})
LinkLuaModifier( "modifier_item_kaya_and_sange_passive", "items/item_kaya_and_sange.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_kaya_and_sange_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_kaya_and_sange_passive:OnRefresh()
	self.bonus_strength = self:GetSpecialValueFor("bonus_strength")
	self.bonus_intellect = self:GetSpecialValueFor("bonus_intellect")
	self.spell_amp = self:GetSpecialValueFor("spell_amp")
	
	self.catalyst_duration = self:GetSpecialValueFor("catalyst_duration")
	self.catalyst_heal = self:GetSpecialValueFor("catalyst_heal")
end

function modifier_item_kaya_and_sange_passive:DeclareFunctions()
	return {
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_EVENT_ON_ABILITY_FULLY_CAST
	}
end

function modifier_item_kaya_and_sange_passive:OnAbilityFullyCast(params)
	local parent = self:GetParent()
	if params.unit == parent and params.ability:GetCooldown(-1) > 0 then
		local abilityKV = params.ability:GetAbilityKeyValues().AbilityValues
		local abilityDamageType = params.ability:GetAbilityDamageType()
		local physicalDamage = (abilityDamageType == DAMAGE_TYPE_PHYSICAL)
		local magicalDamage = (abilityDamageType == DAMAGE_TYPE_MAGICAL)
		local pureDamage = (abilityDamageType == DAMAGE_TYPE_PURE)
		for key, valueTable in ipairs( abilityKV ) do
			if type(valueTable) == "table" and valueTable.CalculateSpellDamageTooltip == "1" and valueTable.DamageTypeTooltip then
				physicalDamage = physicalDamage or DamageTypeTooltip == "DAMAGE_TYPE_PHYSICAL"
				magicalDamage = magicalDamage or DamageTypeTooltip == "DAMAGE_TYPE_MAGICAL"
				pureDamage = pureDamage or DamageTypeTooltip == "DAMAGE_TYPE_PURE"
			end
		end
		if physicalDamage then
			self:GetParent():AddNewModifier( self:GetParent(), self:GetAbility(), "modifier_item_kaya_and_sange_physical", {duration = self.catalyst_duration} )
		end
		if magicalDamage then
			self:GetParent():AddNewModifier( self:GetParent(), self:GetAbility(), "modifier_item_kaya_and_sange_magical", {duration = self.catalyst_duration} )
		end
		if pureDamage then
			parent:HealEvent( self.catalyst_heal, self:GetAbility(), parent )
		end
		if not (physicalDamage or magicalDamage or pureDamage ) then
			parent:Dispel( parent )
		end
	end
end

function modifier_item_kaya_and_sange_passive:GetModifierBonusStats_Strength()
	return self.bonus_strength
end

function modifier_item_kaya_and_sange_passive:GetModifierBonusStats_Intellect()
	return self.bonus_intellect
end

function modifier_item_kaya_and_sange_passive:GetModifierSpellAmplify_Percentage()
	return self.spell_amp
end

function modifier_item_kaya_and_sange_passive:IsHidden()
	return true
end

function modifier_item_kaya_and_sange_passive:IsPurgable()
	return false
end

function modifier_item_kaya_and_sange_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

modifier_item_kaya_and_sange_physical = class({})
LinkLuaModifier( "modifier_item_kaya_and_sange_physical", "items/item_kaya_and_sange.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_kaya_and_sange_physical:OnCreated()
	self:OnRefresh()
end

function modifier_item_kaya_and_sange_physical:OnRefresh()
	self.catalyst_armor = self:GetSpecialValueFor("catalyst_armor")
end

function modifier_item_kaya_and_sange_physical:DeclareFunctions()
	return {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS}
end

function modifier_item_kaya_and_sange_physical:GetModifierPhysicalArmorBonus()
	return self.catalyst_armor
end

modifier_item_kaya_and_sange_magical = class({})
LinkLuaModifier( "modifier_item_kaya_and_sange_magical", "items/item_kaya_and_sange.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_kaya_and_sange_magical:OnCreated()
	self:OnRefresh()
end

function modifier_item_kaya_and_sange_magical:OnRefresh()
	self.catalyst_magic_resist = self:GetSpecialValueFor("catalyst_magic_resist")
end

function modifier_item_kaya_and_sange_magical:DeclareFunctions()
	return {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS}
end

function modifier_item_kaya_and_sange_magical:GetModifierMagicalResistanceBonus()
	return self.catalyst_magic_resist
end