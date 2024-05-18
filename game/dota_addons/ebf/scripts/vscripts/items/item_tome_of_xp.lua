-- Linking modifiers
LinkLuaModifier("modifier_generic_tome_of_xp", "modifiers/modifier_generic_tome_of_xp.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tome_of_xp_2", "modifiers/modifier_tome_of_xp_2.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tome_of_xp_3", "modifiers/modifier_tome_of_xp_3.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tome_of_xp_4", "modifiers/modifier_tome_of_xp_4.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tome_of_xp_5", "modifiers/modifier_tome_of_xp_5.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tome_of_xp_6", "modifiers/modifier_tome_of_xp_6.lua", LUA_MODIFIER_MOTION_NONE)

-- Base class
item_generic_tome_of_xp = class({})

function item_generic_tome_of_xp:OnSpellStart()
    local caster = self:GetCaster()
    local exp_amount = self:GetSpecialValueFor("bonus_experience")
    if caster then
        caster:AddExperience(exp_amount, DOTA_ModifyXP_Unspecified, false, true)
        if self:GetCurrentCharges() > 1 then
            self:SetCurrentCharges(self:GetCurrentCharges() - 1)
        else
            self:RemoveSelf() 
        end
    end
end

-- Specific item classes
item_tome_of_xp_2 = class(item_generic_tome_of_xp)
item_tome_of_xp_3 = class(item_generic_tome_of_xp)
item_tome_of_xp_4 = class(item_generic_tome_of_xp)
item_tome_of_xp_5 = class(item_generic_tome_of_xp)
item_tome_of_xp_6 = class(item_generic_tome_of_xp)
