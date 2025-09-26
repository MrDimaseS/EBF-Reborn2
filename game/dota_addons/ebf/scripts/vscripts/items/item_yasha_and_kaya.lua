item_yasha_and_kaya = class({})

function item_yasha_and_kaya:GetIntrinsicModifierName()
	return "modifier_item_yasha_and_kaya_passive"
end

modifier_item_yasha_and_kaya_passive = class({})
LinkLuaModifier( "modifier_item_yasha_and_kaya_passive", "items/item_yasha_and_kaya.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_yasha_and_kaya_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_yasha_and_kaya_passive:OnRefresh()
	self.bonus_agility = self:GetSpecialValueFor("bonus_agility")
	self.bonus_intellect = self:GetSpecialValueFor("bonus_intellect")
	self.bonus_attack_speed = self:GetSpecialValueFor("bonus_attack_speed")
	self.spell_amp = self:GetSpecialValueFor("spell_amp")
	
	self.spellblade_duration = self:GetSpecialValueFor("spellblade_duration")
end

function modifier_item_yasha_and_kaya_passive:OnDestroy()
	if IsServer() then
		self:GetParent():RemoveModifierByName("modifier_item_yasha_and_kaya_spellblade_attack")
	end
end


function modifier_item_yasha_and_kaya_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_EVENT_ON_ATTACK_LANDED,
			MODIFIER_EVENT_ON_ABILITY_FULLY_CAST }
end

function modifier_item_yasha_and_kaya_passive:GetModifierBonusStats_Intellect()
	return self.bonus_intellect
end

function modifier_item_yasha_and_kaya_passive:GetModifierBonusStats_Agility()
	return self.bonus_agility
end

function modifier_item_yasha_and_kaya_passive:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end

function modifier_item_yasha_and_kaya_passive:GetModifierSpellAmplify_Percentage()
	return self.spell_amp
end

function modifier_item_yasha_and_kaya_passive:OnAttackLanded( params )
	if params.attacker ~= self:GetParent() then return end
	if params.attacker:IsSameTeam( params.target ) then return end
	params.attacker:AddNewModifier( params.attacker, self:GetAbility(), "modifier_item_yasha_and_kaya_spellblade_attack", {} )
end

function modifier_item_yasha_and_kaya_passive:OnAbilityFullyCast( params )
	if params.unit ~= self:GetParent() then return end
	params.unit:AddNewModifier( params.unit, self:GetAbility(), "modifier_item_yasha_and_kaya_spellblade_cast", {duration = self.spellblade_duration} )
	params.unit:RemoveModifierByName("modifier_item_yasha_and_kaya_spellblade_attack")
	return self.spell_amp
end

function modifier_item_yasha_and_kaya_passive:IsHidden()
	return true
end

function modifier_item_yasha_and_kaya_passive:IsPurgable()
	return false
end

function modifier_item_yasha_and_kaya_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

modifier_item_yasha_and_kaya_spellblade_cast = class({})
LinkLuaModifier( "modifier_item_yasha_and_kaya_spellblade_cast", "items/item_yasha_and_kaya.lua" ,LUA_MODIFIER_MOTION_NONE )


function modifier_item_yasha_and_kaya_spellblade_cast:OnCreated()
	self:OnRefresh()
end

function modifier_item_yasha_and_kaya_spellblade_cast:OnRefresh()
	self.spellblade_movespeed = self:GetSpecialValueFor("spellblade_movespeed")
	self.spellblade_evasion = self:GetSpecialValueFor("spellblade_evasion")
end

function modifier_item_yasha_and_kaya_spellblade_cast:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_EVASION_CONSTANT }
end

function modifier_item_yasha_and_kaya_spellblade_cast:GetModifierMoveSpeedBonus_Percentage()
	return self.spellblade_movespeed
end

function modifier_item_yasha_and_kaya_spellblade_cast:GetModifierEvasion_Constant()
	return self.spellblade_evasion
end

modifier_item_yasha_and_kaya_spellblade_attack = class({})
LinkLuaModifier( "modifier_item_yasha_and_kaya_spellblade_attack", "items/item_yasha_and_kaya.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_yasha_and_kaya_spellblade_attack:OnCreated()
	self:OnRefresh()
end

function modifier_item_yasha_and_kaya_spellblade_attack:OnRefresh()
	self.spellblade_cast_speed = self:GetSpecialValueFor("spellblade_cast_speed")
	self.spellblade_max_cast_speed = self:GetSpecialValueFor("spellblade_max_cast_speed")
	
	self.max_stacks = math.ceil( self.spellblade_max_cast_speed / self.spellblade_cast_speed )
	
	self:GetParent().cooldownModifiers = self:GetParent().cooldownModifiers or {}
	self:GetParent().cooldownModifiers[self] = true
	
	if IsServer() then
		if self:GetStackCount() < self.max_stacks then
			self:IncrementStackCount()
		end
	end
end

function modifier_item_yasha_and_kaya_spellblade_attack:DeclareFunctions()
	return { MODIFIER_PROPERTY_TOOLTIP }
end

function modifier_item_yasha_and_kaya_spellblade_attack:OnTooltip()
	return self.spellblade_cast_speed * self:GetStackCount()
end

function modifier_item_yasha_and_kaya_spellblade_attack:GetModifierCastSpeed( params )
	return self.spellblade_cast_speed * self:GetStackCount()
end
