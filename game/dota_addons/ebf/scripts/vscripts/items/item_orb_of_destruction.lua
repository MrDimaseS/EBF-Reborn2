item_orb_of_destruction = class({})

function item_orb_of_destruction:GetIntrinsicModifierName()
	return "modifier_item_orb_of_destruction_passive"
end

modifier_item_orb_of_destruction_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_orb_of_destruction_passive", "items/item_orb_of_destruction.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_orb_of_destruction_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_orb_of_destruction_passive:OnRefresh()
	self.bonus_all = self:GetSpecialValueFor("bonus_all")
	
	self.duration = self:GetSpecialValueFor("duration")
end

function modifier_item_orb_of_destruction_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_EVENT_ON_ATTACK }
end


function modifier_item_orb_of_destruction_passive:GetModifierBonusStats_Strength()
	return self.bonus_all
end

function modifier_item_orb_of_destruction_passive:GetModifierBonusStats_Agility()
	return self.bonus_all
end

function modifier_item_orb_of_destruction_passive:GetModifierBonusStats_Intellect()
	return self.bonus_all
end

function modifier_item_orb_of_destruction_passive:OnAttack( params )
	local parent = self:GetParent()
	if params.attacker ~= parent then return end
	params.target:AddNewModifier( params.attacker, self:GetAbility(), "modifier_orb_of_destruction_debuff", {duration = self.duration} )
end