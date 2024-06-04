item_lucky_dice = class({})

function item_lucky_dice:GetIntrinsicModifierName()
	return "modifier_item_lucky_dice_passive"
end

function item_lucky_dice:RefreshChanceModifiers()
	if not IsServer() then return end
	if self:GetCaster()._currentlyRefreshingAllModifiers then return end
	self:GetCaster()._currentlyRefreshingAllModifiers = true
	
	self:GetCaster():RefreshAllIntrinsicModifiers()
	Timers:CreateTimer( function() self:GetCaster()._currentlyRefreshingAllModifiers = false end )
end

item_lucky_dice_2 = class(item_lucky_dice)
item_lucky_dice_3 = class(item_lucky_dice)
item_lucky_dice_4 = class(item_lucky_dice)
item_lucky_dice_5 = class(item_lucky_dice)

modifier_item_lucky_dice_passive = class({})
LinkLuaModifier( "modifier_item_lucky_dice_passive", "items/item_lucky_dice.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_lucky_dice_passive:OnCreated()
	self:OnRefresh()
	
	self:GetCaster()._chanceModifiersList = self:GetCaster()._chanceModifiersList or {}
	self:GetCaster()._chanceModifiersList[self] = true
	
	if IsServer() then Timers:CreateTimer( function() 
		self:GetAbility():RefreshChanceModifiers() end )
	end
end

function modifier_item_lucky_dice_passive:OnRefresh()
	self.bonus_health = self:GetSpecialValueFor("bonus_health")
	self.bonus_health_regen = self:GetSpecialValueFor("bonus_health_regen")
	self.bonus_mana_regen = self:GetSpecialValueFor("bonus_mana_regen")
	
	self.bonus_chance = self:GetSpecialValueFor("bonus_chance")
end

function modifier_item_lucky_dice_passive:OnRemoved()
	self:GetCaster()._chanceModifiersList[self] = nil
	
	if IsServer() then
		Timers:CreateTimer( function()
			if IsModifierSafe( self ) and IsEntitySafe( self:GetAbility() ) then
				self:GetAbility():RefreshChanceModifiers()
			end
		end )
	end
end

function modifier_item_lucky_dice_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEALTH_BONUS,
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
			MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
			MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE}
end

function modifier_item_lucky_dice_passive:GetModifierHealthBonus()
	return self.bonus_health
end

function modifier_item_lucky_dice_passive:GetModifierConstantHealthRegen()
	return self.bonus_health_regen
end

function modifier_item_lucky_dice_passive:GetModifierConstantManaRegen()
	return self.bonus_mana_regen
end

function modifier_item_lucky_dice_passive:GetModifierChanceBonusConstant()
	return self.bonus_chance
end

function modifier_item_lucky_dice_passive:IsHidden()
	return true
end

function modifier_item_lucky_dice_passive:IsPurgable()
	return false
end

function modifier_item_lucky_dice_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end