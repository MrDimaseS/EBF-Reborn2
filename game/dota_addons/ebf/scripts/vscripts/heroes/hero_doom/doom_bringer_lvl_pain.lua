doom_bringer_lvl_pain = class({})

function doom_bringer_lvl_pain:IsStealable()
	return true
end

function doom_bringer_lvl_pain:IsHiddenWhenStolen()
	return false
end

function doom_bringer_lvl_pain:GetIntrinsicModifierName()
	return "modifier_doom_bringer_lvl_pain_handler"
end

modifier_doom_bringer_lvl_pain_handler = class({})
LinkLuaModifier( "modifier_doom_bringer_lvl_pain_handler", "heroes/hero_doom/doom_bringer_lvl_pain.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_doom_bringer_lvl_pain_handler:OnCreated()
	self:OnRefresh()
end

function modifier_doom_bringer_lvl_pain_handler:OnRefresh()
	self.bonus_hero_damage = self:GetSpecialValueFor("bonus_hero_damage")
end

function modifier_doom_bringer_lvl_pain_handler:DeclareFunctions()
    local funcs = {
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
    }
    return funcs
end

function modifier_doom_bringer_lvl_pain_handler:GetModifierTotalDamageOutgoing_Percentage(params)
    if not params.target:IsConsideredHero() then
		return self.bonus_hero_damage
	end
end
