item_lucky_femur = class({})

function item_lucky_femur:GetIntrinsicModifierName()
	return "modifier_item_lucky_femur_passive"
end

modifier_item_lucky_femur_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_lucky_femur_passive", "items/item_lucky_femur.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_lucky_femur_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_lucky_femur_passive:OnRefresh()
	self.bonus_mana = self:GetSpecialValueFor("bonus_mana")
	self.bonus_int = self:GetSpecialValueFor("bonus_int")
	
	self.instant_refresh_chance = self:GetSpecialValueFor("instant_refresh_chance")
	self.mana_cost_penalty = self:GetSpecialValueFor("mana_cost_penalty")
end

function modifier_item_lucky_femur_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,				
			MODIFIER_PROPERTY_MANA_BONUS,
			MODIFIER_EVENT_ON_ABILITY_FULLY_CAST }
end

function modifier_item_lucky_femur_passive:GetModifierBonusStats_Intellect()
	return self.bonus_int
end

function modifier_item_lucky_femur_passive:GetModifierManaBonus()
	return self.bonus_mana
end

function modifier_item_lucky_femur_passive:OnAbilityFullyCast( params )
	local parent = self:GetParent()
	if params.unit ~= parent then return end
	if self:RollPRNG( self.instant_refresh_chance ) then
		parent:AddNewModifier( parent, params.ability, "modifier_item_lucky_femur_debuff", {duration = params.ability:GetCooldownTimeRemaining()} ):SetStackCount(self.mana_cost_penalty * params.ability:GetCooldownTimeRemaining())
		params.ability:EndCooldown()
	end
end

modifier_item_lucky_femur_debuff = class({})
LinkLuaModifier( "modifier_item_lucky_femur_debuff", "items/item_lucky_femur.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_lucky_femur_debuff:OnCreated()
	self.tick = 0.1
	if IsServer() then
		self:StartIntervalThink(self.tick)
	end
end

function modifier_item_lucky_femur_debuff:OnIntervalThink()
	local reduction = self:GetStackCount() / self:GetRemainingTime() * self.tick
	self:SetStackCount( self:GetStackCount() - reduction )
end

function modifier_item_lucky_femur_debuff:DeclareFunctions()
	return {MODIFIER_PROPERTY_MANACOST_PERCENTAGE_STACKING}
end

function modifier_item_lucky_femur_debuff:GetModifierPercentageManacostStacking( params )
	if params.ability == self:GetAbility() then
		return -self:GetStackCount()
	end
end

function modifier_item_lucky_femur_debuff:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_lucky_femur_debuff:IsDebuff()
	return true
end

function modifier_item_lucky_femur_debuff:IsPurgable()
	return false
end