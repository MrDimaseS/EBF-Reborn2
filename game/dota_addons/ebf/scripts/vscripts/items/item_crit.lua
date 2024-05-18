item_greater_crit = class({})

function item_greater_crit:GetIntrinsicModifierName()
	return "modifier_item_crit_passive"
end

function item_greater_crit:RefreshCritModifiers()
	if not IsServer() then return end
	if self:GetCaster()._currentlyRefreshingAllModifiers then return end
	self:GetCaster()._currentlyRefreshingAllModifiers = true
	
	local hero = self:GetCaster()
	for i=DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
		local item = hero:GetItemInSlot(i)
		if item then
			item:OnUnequip()
			item:OnEquip()
			item:RefreshIntrinsicModifier()
		end
	end
	local neutralItem =	hero:GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT)  
	if neutralItem then
		neutralItem:OnUnequip()
		neutralItem:OnEquip()
		neutralItem:RefreshIntrinsicModifier()
	end
	for i = 0, hero:GetAbilityCount() - 1 do
		local ability = hero:GetAbilityByIndex( i )
		if ability then
			if ability:IsAttributeBonus() then
				local passive = hero:FindModifierByName( ability:GetIntrinsicModifierName() )
				if passive then
					passive:Destroy()
				end
			end
			ability:RefreshIntrinsicModifier()
		end
	end
	Timers:CreateTimer( function() self:GetCaster()._currentlyRefreshingAllModifiers = false end )
end

item_greater_crit_2 = class(item_greater_crit)
item_greater_crit_3 = class(item_greater_crit)
item_greater_crit_4 = class(item_greater_crit)
item_greater_crit_5 = class(item_greater_crit)

modifier_item_crit_passive = class({})
LinkLuaModifier( "modifier_item_crit_passive", "items/item_crit.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_crit_passive:OnCreated()
	self:OnRefresh()
	
	self:GetCaster()._critModifiersList = self:GetCaster()._critModifiersList or {}
	self:GetCaster()._critModifiersList[self] = true
	
	if IsServer() then Timers:CreateTimer( function() 
		self:GetAbility():RefreshCritModifiers() end )
	end
end

function modifier_item_crit_passive:OnRefresh()
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.crit_chance = self:GetSpecialValueFor("crit_chance")
	self.crit_multiplier = self:GetSpecialValueFor("crit_multiplier")
	
	self.bonus_crit = self:GetSpecialValueFor("bonus_crit")
end

function modifier_item_crit_passive:OnRemoved()
	self:GetCaster()._critModifiersList[self] = nil
	
	self:GetAbility():RefreshCritModifiers()
end

function modifier_item_crit_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE}
end

function modifier_item_crit_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_crit_passive:GetModifierPreAttack_CriticalStrike()
	if self:RollPRNG( self.crit_chance ) then
		return self:GetSpecialValueFor("crit_multiplier")
	end
end

function modifier_item_crit_passive:GetCritDamage()
	return self.crit_multiplier / 100
end

function modifier_item_crit_passive:GetModifierCriticalStrike_BonusDamage()
	return self.bonus_crit
end

function modifier_item_crit_passive:IsHidden()
	return true
end

function modifier_item_crit_passive:IsPurgable()
	return false
end

function modifier_item_crit_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end