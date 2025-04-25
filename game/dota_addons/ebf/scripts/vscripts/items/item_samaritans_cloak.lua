item_samaritans_cloak = class({})

function item_samaritans_cloak:GetIntrinsicModifierName()
	return "modifier_item_samaritans_cloak_passive"
end

modifier_item_samaritans_cloak_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_samaritans_cloak_passive", "items/item_samaritans_cloak.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_samaritans_cloak_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_samaritans_cloak_passive:OnRefresh()
	self.bonus_strength = self:GetSpecialValueFor("bonus_strength")
	self.bonus_intellect = self:GetSpecialValueFor("bonus_intellect")
	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
	
	self.share_radius = self:GetSpecialValueFor("share_radius")
	self.share_percent = self:GetSpecialValueFor("share_percent") / 100
end

function modifier_item_samaritans_cloak_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,				
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,				
			MODIFIER_EVENT_ON_MODIFIER_ADDED }
end

function modifier_item_samaritans_cloak_passive:GetModifierBonusStats_Strength()
	return self.bonus_strength
end

function modifier_item_samaritans_cloak_passive:GetModifierBonusStats_Intellect()
	return self.bonus_intellect
end

function modifier_item_samaritans_cloak_passive:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

DONT_COPY_THESE_MODIFIERS = {
	["modifier_kill"] = true
}

function modifier_item_samaritans_cloak_passive:OnModifierAdded( params )
	if self:GetParent()._cannotReceiveSamaritanBuffs then return end
	if params.unit ~= self:GetParent() then return end
	if params.unit:IsFakeHero() then return end
	if not params.attacker:IsSameTeam( params.unit ) then return end
	if params.added_buff:IsDebuff() then return end
	if params.added_buff:IsHidden() then return end
	if params.added_buff:GetDuration() <= 0 then return end
	if DONT_COPY_THESE_MODIFIERS[params.added_buff:GetName()] then return end
	for _, ally in ipairs( params.attacker:FindFriendlyUnitsInRadius( params.unit:GetAbsOrigin(), self.share_radius ) ) do
		if ally ~= params.unit and not ally:IsFakeHero() then
			ally._cannotReceiveSamaritanBuffs = true
			ally:AddNewModifier( params.attacker, params.added_buff:GetAbility(), params.added_buff:GetName(), {duration = params.added_buff:GetDuration() * self.share_percent} )
			ally._cannotReceiveSamaritanBuffs = false
			return
		end
	end
end