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
end

function modifier_bounty_hunter_big_game_hunter_handler:DeclareFunctions()
    local funcs = {
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
    }
    return funcs
end

function modifier_bounty_hunter_big_game_hunter_handler:GetModifierTotalDamageOutgoing_Percentage(params)
    if params.target:IsConsideredHero() then
		return self.bonus_hero_damage
	end
end
