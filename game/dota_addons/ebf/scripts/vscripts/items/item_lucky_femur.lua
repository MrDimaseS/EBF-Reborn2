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
	self.bonus_str = self:GetSpecialValueFor("bonus_str")
	
	self.instant_refresh_chance = self:GetSpecialValueFor("instant_refresh_chance")
	self.mana_cost_penalty_base = self:GetSpecialValueFor("mana_cost_penalty_base")
	self.mana_cost_penalty_cdr = self:GetSpecialValueFor("mana_cost_penalty_cdr")
end

function modifier_item_lucky_femur_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,				
			MODIFIER_PROPERTY_MANA_BONUS,
			MODIFIER_EVENT_ON_ABILITY_FULLY_CAST }
end

function modifier_item_lucky_femur_passive:GetModifierBonusStats_Strength()
	return self.bonus_str
end

function modifier_item_lucky_femur_passive:GetModifierManaBonus()
	return self.bonus_mana
end

function modifier_item_lucky_femur_passive:OnAbilityFullyCast( params )
	local parent = self:GetParent()
	if params.unit ~= parent then return end
	if params.ability:GetCooldown( -1 ) == 0 then return end
	if params.ability:GetCooldownTimeRemaining() <= 0 then return end
	if self:RollPRNG( self.instant_refresh_chance ) and not params.ability._rolledForRefresh then
		params.ability._rolledForRefresh = true
		params.ability:SetFrozenCooldown( true )
		Timers:CreateTimer( 0.25,
		function()
			params.ability._rolledForRefresh = false
			params.ability:SetFrozenCooldown( false )
			parent:AddNewModifier( parent, params.ability, "modifier_item_lucky_femur_debuff", {duration = params.ability:GetCooldownTimeRemaining()} ):SetStackCount(self.mana_cost_penalty_base + self.mana_cost_penalty_cdr * params.ability:GetCooldownTimeRemaining())
			params.ability:EndCooldown() 
		end )
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
	if params.ability == self:GetAbility() or IsClient() then
		return -self:GetStackCount()
	end
end

function modifier_item_lucky_femur_debuff:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_lucky_femur_debuff:IsDebuff()
	return false
end

function modifier_item_lucky_femur_debuff:IsPurgable()
	return false
end