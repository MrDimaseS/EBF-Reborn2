item_searing_signet = class({})

function item_searing_signet:GetIntrinsicModifierName()
	return "modifier_item_searing_signet_passive"
end

modifier_item_searing_signet_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_searing_signet_passive", "items/item_searing_signet.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_searing_signet_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_searing_signet_passive:OnRefresh()
	self.spell_amp = self:GetSpecialValueFor("spell_amp")
	self.bonus_all = self:GetSpecialValueFor("bonus_all")
	
	self.burn_duration = self:GetSpecialValueFor("burn_duration")
	self.damage_threshold = self:GetSpecialValueFor("damage_threshold") / 100
end

function modifier_item_searing_signet_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_item_searing_signet_passive:GetModifierSpellAmplify_Percentage()
	return self.spell_amp
end

function modifier_item_searing_signet_passive:GetModifierBonusStats_Strength()
	return self.bonus_all
end

function modifier_item_searing_signet_passive:GetModifierBonusStats_Intellect()
	return self.bonus_all
end

function modifier_item_searing_signet_passive:GetModifierBonusStats_Agility()
	return self.bonus_all
end

function modifier_item_searing_signet_passive:OnTakeDamage( params )
	if params.attacker ~= self:GetParent() then return end
	if params.damage_category ~= DOTA_DAMAGE_CATEGORY_SPELL then return end
	if HasBit( params.damage_flags, DOTA_DAMAGE_FLAG_ATTACK_MODIFIER ) then return end
	if params.damage < params.unit:GetMaxHealth() * self.damage_threshold * params.unit:GetMaxHealthDamageResistance() then return end
	local ability = self:GetAbility()
	if params.inflictor == ability then return end
	params.unit:AddNewModifier( params.attacker, ability, "modifier_searing_signet_burn", {duration = self.burn_duration} )
end