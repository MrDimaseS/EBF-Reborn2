item_lifesteal2 = class({})

function item_lifesteal2:GetIntrinsicModifierName()
	return "modifier_item_lifesteal_ebf"
end

item_vladmir = class(item_lifesteal2)
item_lifesteal3 = class(item_lifesteal2)
item_lifesteal4 = class(item_lifesteal2)
item_lifesteal5 = class(item_lifesteal2)
item_lifestealtank = class(item_lifesteal2)

function item_lifestealtank:GetIntrinsicModifierName()
	return "modifier_item_lifestealtank_ebf"
end

item_booster_3 = class(item_lifestealtank)

function item_booster_3:GetIntrinsicModifierName()
	return "modifier_item_lifestealbooster_ebf"
end

item_booster_1 = class(item_booster_3)
item_booster_2 = class(item_booster_3)
item_booster_4 = class(item_booster_3)

modifier_item_lifesteal_ebf = class({})
LinkLuaModifier( "modifier_item_lifesteal_ebf", "items/item_lifesteal.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_lifesteal_ebf:OnCreated()
	self:OnRefresh()
end

function modifier_item_lifesteal_ebf:OnRefresh()
	self.bonus_armor = self:GetAbility():GetSpecialValueFor("bonus_armor")
	self.bonus_all = self:GetAbility():GetSpecialValueFor("bonus_all")
	self.bonus_damage = self:GetAbility():GetSpecialValueFor("bonus_damage")
	self.aura_radius = self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_lifesteal_ebf:DeclareFunctions(params)
	local funcs = {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    }
    return funcs
end

function modifier_item_lifesteal_ebf:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_lifesteal_ebf:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_item_lifesteal_ebf:GetModifierBonusStats_Strength()
	return self.bonus_all
end

function modifier_item_lifesteal_ebf:GetModifierBonusStats_Intellect()
	return self.bonus_all
end

function modifier_item_lifesteal_ebf:GetModifierBonusStats_Agility()
	return self.bonus_all
end

function modifier_item_lifesteal_ebf:IsAura()
	return self.aura_radius > 0
end

function modifier_item_lifesteal_ebf:GetModifierAura()
	return "modifier_item_lifesteal_ebf_aura"
end

function modifier_item_lifesteal_ebf:GetAuraRadius()
	return self.aura_radius
end

function modifier_item_lifesteal_ebf:GetAuraDuration()
	return 0.5
end

function modifier_item_lifesteal_ebf:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_lifesteal_ebf:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_CREEP + DOTA_UNIT_TARGET_HERO
end

function modifier_item_lifesteal_ebf:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_item_lifesteal_ebf:IsHidden()
	return true
end

function modifier_item_lifesteal_ebf:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE 
end


LinkLuaModifier( "modifier_item_lifesteal_ebf_aura", "items/item_lifesteal.lua" ,LUA_MODIFIER_MOTION_NONE )
modifier_item_lifesteal_ebf_aura = class({})

function modifier_item_lifesteal_ebf_aura:OnCreated()
	self:OnRefresh( )
end

function modifier_item_lifesteal_ebf_aura:OnRefresh()
	self.armor_aura = self:GetAbility():GetSpecialValueFor("armor_aura")
	self.mana_regen_aura = self:GetAbility():GetSpecialValueFor("mana_regen_aura")
	self.hp_regen_aura = self:GetAbility():GetSpecialValueFor("hp_regen_aura")
	self.lifesteal_aura = self:GetAbility():GetSpecialValueFor("lifesteal_aura")
	self.damage_aura = self:GetAbility():GetSpecialValueFor("damage_aura")
end

function modifier_item_lifesteal_ebf_aura:DeclareFunctions(params)
	local funcs = {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_EVENT_ON_TOOLTIP,
    }
    return funcs
end

function modifier_item_lifesteal_ebf_aura:GetModifierBaseDamageOutgoing_Percentage()
	return self.damage_aura
end

function modifier_item_lifesteal_ebf_aura:GetModifierConstantManaRegen()
	return self.mana_regen_aura
end

function modifier_item_lifesteal_ebf_aura:GetModifierConstantHealthRegen()
	return self.hp_regen_aura
end

function modifier_item_lifesteal_ebf_aura:GetModifierPhysicalArmorBonus()
	return self.armor_aura
end

function modifier_item_lifesteal_ebf_aura:OnTooltip()
	return self.lifesteal_aura
end

function modifier_item_lifesteal_ebf_aura:OnTakeDamage(params)
	if params.attacker == self:GetParent() and params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
		local EHPMult = self:GetParent().EHP_MULT or 1
		local lifesteal = params.damage * self.lifesteal_aura / 100 * math.max( 1, EHPMult )
		
		local preHP = params.attacker:GetHealth()
		params.attacker:HealWithParams( lifesteal, self:GetAbility(), true, true, self:GetCaster(), false )
		local postHP = params.attacker:GetHealth()
		
		if (postHP - preHP) > 0 then
			SendOverheadEventMessage( params.attacker:GetPlayerOwner(), OVERHEAD_ALERT_HEAL, params.attacker, postHP - preHP, params.attacker:GetPlayerOwner() )
		end
	end
end

modifier_item_lifestealtank_ebf = class(modifier_item_lifesteal_ebf)
LinkLuaModifier( "modifier_item_lifestealtank_ebf", "items/item_lifesteal.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_lifestealtank_ebf:GetModifierAura()
	return "modifier_item_lifestealtank_ebf_aura"
end

modifier_item_lifestealbooster_ebf = class(modifier_item_lifestealtank_ebf)
LinkLuaModifier( "modifier_item_lifestealbooster_ebf", "items/item_lifesteal.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_lifestealbooster_ebf:OnCreated()
	self.bonus_health = self:GetAbility():GetSpecialValueFor("bonus_health")
	self.health_per_str = self:GetAbility():GetSpecialValueFor("health_per_str")
	self.bonus_mana = self:GetAbility():GetSpecialValueFor("bonus_mana")
	self.bonus_armor = self:GetAbility():GetSpecialValueFor("bonus_armor")
	self.bonus_all = self:GetAbility():GetSpecialValueFor("bonus_all")
	self.bonus_damage = self:GetAbility():GetSpecialValueFor("bonus_damage")
	
	self.aura_radius = self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_lifestealbooster_ebf:DeclareFunctions(params)
	local funcs = {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MANA_BONUS,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    }
    return funcs
end

function modifier_item_lifestealbooster_ebf:GetModifierHealthBonus()
	return self.bonus_health + self.health_per_str * self:GetParent():GetStrength()
end

function modifier_item_lifestealbooster_ebf:GetModifierManaBonus()
	return self.bonus_mana
end

function modifier_item_lifestealbooster_ebf:IsHidden()
	return true
end

LinkLuaModifier( "modifier_item_lifestealtank_ebf_aura", "items/item_lifesteal.lua" ,LUA_MODIFIER_MOTION_NONE )
modifier_item_lifestealtank_ebf_aura = class(modifier_item_lifesteal_ebf_aura)

function modifier_item_lifestealtank_ebf_aura:OnCreated()
	self:OnRefresh()
	if IsServer() and self:GetCaster() ~= self:GetParent() then
		local originModifier = self:GetAbility():GetIntrinsicModifierName()
		self.modifier = self:GetCaster():FindModifierByName(originModifier)
		if self.modifier then
			self.modifier:IncrementStackCount()
		end
	end
end

function modifier_item_lifestealtank_ebf_aura:OnRefresh()
	self.armor_aura = self:GetAbility():GetSpecialValueFor("armor_aura")
	self.mana_regen_aura = self:GetAbility():GetSpecialValueFor("mana_regen_aura")
	self.hp_regen_aura = self:GetAbility():GetSpecialValueFor("hp_regen_aura")
	self.lifesteal_aura = self:GetAbility():GetSpecialValueFor("lifesteal_aura") / 100
	self.lifesteal_shared = self:GetAbility():GetSpecialValueFor("lifesteal_shared") / 100
	self.damage_aura = self:GetAbility():GetSpecialValueFor("damage_aura")
end

function modifier_item_lifestealtank_ebf_aura:OnDestroy()
	if IsServer() and self:GetCaster() ~= self:GetParent() then
		if self.modifier and not self.modifier:IsNull() then
			self.modifier:DecrementStackCount()
		end
	end
end

function modifier_item_lifestealtank_ebf_aura:OnTakeDamage(params)
	if params.attacker == self:GetParent() and params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
		local EHPMult = self:GetParent().EHP_MULT or 1
		
		local preHP = params.attacker:GetHealth()
		params.attacker:HealWithParams( params.damage * self.lifesteal_aura * EHPMult, self:GetAbility(), true, true, self:GetCaster(), false )
		local healing = params.attacker:GetHealth() - preHP
		if healing > 0 then
			SendOverheadEventMessage( params.attacker:GetPlayerOwner(), OVERHEAD_ALERT_HEAL, params.attacker, healing, params.attacker:GetPlayerOwner() )
		end
		
		if not self.modifier then
			self:Destroy()
			return
		end
		local stacks = self.modifier:GetStackCount()
		
		if params.attacker ~= self:GetCaster() then
			local preHPCaster = self:GetCaster():GetHealth()
			self:GetCaster():HealWithParams( params.damage * self.lifesteal_aura * EHPMult / stacks, self:GetAbility(), true, true, params.attacker, false )
			local healingCaster = self:GetCaster():GetHealth() - preHPCaster
			
			if healingCaster > 0 then
				SendOverheadEventMessage( self:GetCaster():GetPlayerOwner(), OVERHEAD_ALERT_HEAL, self:GetCaster(), healingCaster, self:GetCaster():GetPlayerOwner() )
			end
		end
	end
end