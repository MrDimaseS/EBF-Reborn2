item_mysterious_hat = class({})

function item_mysterious_hat:GetIntrinsicModifierName()
	return "modifier_item_mysterious_hat_passive"
end

modifier_item_mysterious_hat_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_mysterious_hat_passive", "items/item_mysterious_hat.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_mysterious_hat_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_mysterious_hat_passive:OnRefresh()
	self.spell_amp = self:GetAbility():GetSpecialValueFor("spell_amp")
	self.bonus_health = self:GetAbility():GetSpecialValueFor("bonus_health")
	self.manacost_reduction = self:GetAbility():GetSpecialValueFor("manacost_reduction")
	
	self.escalating_duration = self:GetAbility():GetSpecialValueFor("escalating_duration")
	self.min_cd = self:GetAbility():GetSpecialValueFor("min_cd")
end

function modifier_item_mysterious_hat_passive:DeclareFunctions()
	return { MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, 
			 MODIFIER_PROPERTY_HEALTH_BONUS,
			 MODIFIER_PROPERTY_MANACOST_PERCENTAGE_STACKING,
			 MODIFIER_EVENT_ON_ABILITY_EXECUTED
	}
end

function modifier_item_mysterious_hat_passive:GetModifierSpellAmplify_Percentage(params)
	return self.spell_amp
end

function modifier_item_mysterious_hat_passive:GetModifierHealthBonus(params)
	return self.bonus_health
end

function modifier_item_mysterious_hat_passive:GetModifierPercentageManacostStacking(params)
	return self.manacost_reduction
end

function modifier_item_mysterious_hat_passive:OnAbilityExecuted(params)
	if params.unit ~= self:GetParent() then return end
	if params.ability:GetCooldown(-1) < self.min_cd then return end
	params.unit:AddNewModifier( params.unit, self:GetAbility(), "modifier_item_mysterious_hat_fae_escalation", {duration = self.escalating_duration} )
end

function modifier_item_mysterious_hat_passive:GetModifierAttackRangeBonus(params)
	return self.attack_range_bonus * TernaryOperator( 1, self:GetParent():IsRangedAttacker(), 0 )
end

function modifier_item_mysterious_hat_passive:IsHidden()
	return true
end

function modifier_item_mysterious_hat_passive:IsPurgable()
	return false
end

function modifier_item_mysterious_hat_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

modifier_item_mysterious_hat_fae_escalation = class({})
LinkLuaModifier( "modifier_item_mysterious_hat_fae_escalation", "items/item_mysterious_hat.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_mysterious_hat_fae_escalation:OnCreated()
	self:OnRefresh()
end

function modifier_item_mysterious_hat_fae_escalation:OnRefresh()
	self.spell_amp = self:GetAbility():GetSpecialValueFor("spell_amp")
	self.bonus_health = self:GetAbility():GetSpecialValueFor("bonus_health")
	self.manacost_reduction = self:GetAbility():GetSpecialValueFor("manacost_reduction")
	
	self.escalating_duration = self:GetAbility():GetSpecialValueFor("escalating_duration")
	if IsServer() then
		self:AddIndependentStack()
	end
end

function modifier_item_mysterious_hat_fae_escalation:DeclareFunctions()
	return { MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
	}
end

function modifier_item_mysterious_hat_fae_escalation:GetModifierSpellAmplify_Percentage(params)
	return self.spell_amp * self:GetStackCount()
end