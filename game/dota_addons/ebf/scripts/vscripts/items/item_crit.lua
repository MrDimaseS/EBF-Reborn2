item_greater_crit = class({})

function item_greater_crit:GetIntrinsicModifierName()
	return "modifier_item_crit_passive"
end

function item_greater_crit:RefreshCritModifiers()
	if not IsServer() then return end
	if self:GetCaster()._currentlyRefreshingAllModifiers then return end
	self:GetCaster()._currentlyRefreshingAllModifiers = true
	
	self:GetCaster():RefreshAllIntrinsicModifiers()
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
	
	if IsServer() then
		Timers:CreateTimer( function()
			if IsModifierSafe( self ) and IsEntitySafe( self:GetAbility() ) then
				self:GetAbility():RefreshCritModifiers()
			end
		end )
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
	
	if IsServer() then
		Timers:CreateTimer( function()
			if IsModifierSafe( self ) and IsEntitySafe( self:GetAbility() ) then
				self:GetAbility():RefreshCritModifiers()
			end
		end )
	end
end

function modifier_item_crit_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE}
end

function modifier_item_crit_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_crit_passive:GetModifierPreAttack_CriticalStrike()
	print( self.crit_chance )
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