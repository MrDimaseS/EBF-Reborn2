item_unrelenting_eye = class({})

function item_unrelenting_eye:GetIntrinsicModifierName()
	return "modifier_item_unrelenting_eye_passive"
end

modifier_item_unrelenting_eye_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_unrelenting_eye_passive", "items/item_unrelenting_eye.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_unrelenting_eye_passive:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink( 0.25 )
	end
end

function modifier_item_unrelenting_eye_passive:OnRefresh()
	self.bonus_all_stats = self:GetSpecialValueFor("bonus_all_stats")
	self.max_slow_res = self:GetSpecialValueFor("max_slow_res")
	
	self.hero_reduction = self:GetSpecialValueFor("hero_reduction")
	self.creep_reduction = self:GetSpecialValueFor("creep_reduction")
	self.status_res_pct_increase_per_hero = self:GetSpecialValueFor("status_res_pct_increase_per_hero")
	self.hero_check_radius = self:GetSpecialValueFor("hero_check_radius")
	
	self.stacks_per_hero = TernaryOperator( self.hero_reduction / self.creep_reduction, self.creep_reduction > 0, 1 )
	self.reduction_per_stack = self.max_slow_res / self.stacks_per_hero
end

function modifier_item_unrelenting_eye_passive:OnDestroy()
	if not IsServer() then return end
	local parent = self:GetParent()
	parent:RemoveModifierByName("modifier_item_unrelenting_eye_status_resist")
end

function modifier_item_unrelenting_eye_passive:OnIntervalThink()
	local parent = self:GetParent()
	local stacks = 0
	local statusResistStacks = 0
	for _, enemy in ipairs( parent:FindEnemyUnitsInRadius( parent:GetAbsOrigin(), self.hero_check_radius ) ) do
		if enemy:IsConsideredHero() or self.creep_reduction > 0 then
			if enemy:IsConsideredHero() then
				stacks = stacks + self.stacks_per_hero
				statusResistStacks = statusResistStacks + 1
			else
				stacks = stacks + 1
				
			end
		end
	end
	if statusResistStacks > 0 then
		local modifier = parent:FindModifierByName("modifier_item_unrelenting_eye_status_resist")
		if not modifier then
			modifier = parent:AddNewModifier( parent, self:GetAbility(), "modifier_item_unrelenting_eye_status_resist", {})
		end
		modifier:SetStackCount( statusResistStacks )
	else
		parent:RemoveModifierByName("modifier_item_unrelenting_eye_status_resist")
	end
end

function modifier_item_unrelenting_eye_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_SLOW_RESISTANCE_STACKING }
end

function modifier_item_unrelenting_eye_passive:GetModifierSlowResistance_Stacking()
	return self.max_slow_res - self.reduction_per_stack * self:GetStackCount()
end

function modifier_item_unrelenting_eye_passive:GetModifierBonusStats_Strength()
	return self.bonus_all_stats
end

function modifier_item_unrelenting_eye_passive:GetModifierBonusStats_Intellect()
	return self.bonus_all_stats
end

function modifier_item_unrelenting_eye_passive:GetModifierBonusStats_Agility()
	return self.bonus_all_stats
end

modifier_item_unrelenting_eye_status_resist = class(persistentModifier)
LinkLuaModifier( "modifier_item_unrelenting_eye_status_resist", "items/item_unrelenting_eye.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_unrelenting_eye_status_resist:OnCreated()
	self:OnRefresh()
end

function modifier_item_unrelenting_eye_status_resist:OnRefresh()
	self.status_res_pct_increase_per_hero = self:GetSpecialValueFor("status_res_pct_increase_per_hero")
end

function modifier_item_unrelenting_eye_status_resist:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING}
end

function modifier_item_unrelenting_eye_status_resist:GetModifierStatusResistanceStacking()
	return self.status_res_pct_increase_per_hero * self:GetStackCount()
end

function modifier_item_unrelenting_eye_status_resist:IsHidden()
	return false
end