item_seacursed_trident = class({})

function item_seacursed_trident:GetIntrinsicModifierName()
	return "modifier_item_seacursed_trident_passive"
end

modifier_item_seacursed_trident_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_seacursed_trident_passive", "items/item_seacursed_trident.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_seacursed_trident_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_seacursed_trident_passive:OnRefresh()
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.bonus_agility = self:GetSpecialValueFor("bonus_agility")
	self.spell_amp = self:GetSpecialValueFor("spell_amp")
	
	self.cdr_chance = self:GetSpecialValueFor("cdr_chance")
	self.debuff_damage_amp = self:GetSpecialValueFor("debuff_damage_amp")
end

function modifier_item_seacursed_trident_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,				
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE }
end

function modifier_item_seacursed_trident_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_seacursed_trident_passive:GetModifierBonusStats_Agility()
	return self.bonus_agility
end

function modifier_item_seacursed_trident_passive:GetModifierSpellAmplify_Percentage()
	return self.spell_amp
end

function modifier_item_seacursed_trident_passive:GetModifierTotalDamageOutgoing_Percentage( params )
	local parent = self:GetParent()
	if params.target:IsSameTeam( parent ) then return end
	for _, modifier in ipairs( params.target:FindAllModifiers() ) do
		if modifier:GetCaster() == parent and not (modifier:IsDebuff() == false) then
			return self.debuff_damage_amp
		end
	end
end