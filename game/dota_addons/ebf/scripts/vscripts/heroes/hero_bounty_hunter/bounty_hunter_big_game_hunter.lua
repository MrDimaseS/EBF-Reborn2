bounty_hunter_big_game_hunter = class({})

function bounty_hunter_big_game_hunter:IsStealable()
	return true
end

function bounty_hunter_big_game_hunter:IsHiddenWhenStolen()
	return false
end

function bounty_hunter_big_game_hunter:GetIntrinsicModifierName()
	return "modifier_bounty_hunter_big_game_hunter_handler"
end

modifier_bounty_hunter_big_game_hunter_handler = class({})
LinkLuaModifier( "modifier_bounty_hunter_big_game_hunter_handler", "heroes/hero_bounty_hunter/bounty_hunter_big_game_hunter.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_bounty_hunter_big_game_hunter_handler:OnCreated()
	self:OnRefresh()
end

function modifier_bounty_hunter_big_game_hunter_handler:OnRefresh()
	self.bonus_hero_damage = self:GetSpecialValueFor("bonus_hero_damage")
	
	self.headhunter_crit_chance = self:GetSpecialValueFor("headhunter_crit_chance")
	self.headhunter_base_crit_damage = self:GetSpecialValueFor("headhunter_base_crit_damage")
	self.headhunter_stack_crit_damage = self:GetSpecialValueFor("headhunter_stack_crit_damage")
end

function modifier_bounty_hunter_big_game_hunter_handler:DeclareFunctions()
    local funcs = {
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE
    }
    return funcs
end

function modifier_bounty_hunter_big_game_hunter_handler:GetModifierTotalDamageOutgoing_Percentage(params)
    if params.target:IsConsideredHero() then
		return self.bonus_hero_damage
	end
end

function modifier_item_crit_passive:GetModifierPreAttack_CriticalStrike()
	if self:RollPRNG( self.headhunter_crit_chance ) then
		return self.headhunter_base_crit_damage + self.headhunter_stack_crit_damage * self:GetStackCount()
	end
end

function modifier_item_crit_passive:GetCritDamage()
	return (self.headhunter_base_crit_damage + self.headhunter_stack_crit_damage * self:GetStackCount()) / 100
end
