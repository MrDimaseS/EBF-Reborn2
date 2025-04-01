dragon_knight_inherited_vigor = class({})

function dragon_knight_inherited_vigor:GetIntrinsicModifierName()
    return "modifier_dragon_knight_inherited_vigor_passive"
end

modifier_dragon_knight_inherited_vigor_passive = class({})
LinkLuaModifier( "modifier_dragon_knight_inherited_vigor_passive", "heroes/hero_dragon_knight/dragon_knight_inherited_vigor", LUA_MODIFIER_MOTION_NONE )

function modifier_dragon_knight_inherited_vigor_passive:IsHidden()
    return true
end
function modifier_dragon_knight_inherited_vigor_passive:IsPurgable()
    return false
end
function modifier_dragon_knight_inherited_vigor_passive:OnCreated()
    self:SetHasCustomTransmitterData(true)
    self:OnRefresh()
    if IsClient() then return end

    self:StartIntervalThink(1.0)
end
function modifier_dragon_knight_inherited_vigor_passive:OnRefresh()
    self.base_health_regen = self:GetSpecialValueFor("base_health_regen")
    self.base_armor = self:GetSpecialValueFor("base_armor")
    self.dragon_form_multiplier = self:GetSpecialValueFor("regen_and_armor_multiplier_during_dragon_form")
    self.multiplier = 1.0

    self.spell_amp = self:GetSpecialValueFor("spell_amp")
    self.debuff_amp = self:GetSpecialValueFor("debuff_amp")
    self.healing_amp = self:GetSpecialValueFor("healing_amp")
end
function modifier_dragon_knight_inherited_vigor_passive:OnIntervalThink()
    self:SendBuffRefreshToClients()
end
function modifier_dragon_knight_inherited_vigor_passive:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_MAX_DEBUFF_DURATION,
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
        MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE
    }
end
function modifier_dragon_knight_inherited_vigor_passive:GetModifierConstantHealthRegen()
    return self.base_health_regen * self.multiplier
end
function modifier_dragon_knight_inherited_vigor_passive:GetModifierPhysicalArmorBonus()
    return self.base_armor * self.multiplier
end
function modifier_dragon_knight_inherited_vigor_passive:GetModifierSpellAmplify_Percentage()
    return self.spell_amp * self.multiplier
end
function modifier_dragon_knight_inherited_vigor_passive:GetModifierMaxDebuffDuration()
    return self.debuff_amp * self.multiplier
end
function modifier_dragon_knight_inherited_vigor_passive:GetModifierHealAmplify_PercentageTarget()
    return self.healing_amp * self.multiplier
end
function modifier_dragon_knight_inherited_vigor_passive:GetModifierHPRegenAmplify_Percentage()
    return self.healing_amp * self.multiplier
end
function modifier_dragon_knight_inherited_vigor_passive:GetModifierLifestealRegenAmplify_Percentage()
    return self.healing_amp * self.multiplier
end
function modifier_dragon_knight_inherited_vigor_passive:GetModifierSpellLifestealRegenAmplify_Percentage()
    return self.healing_amp * self.multiplier
end
function modifier_dragon_knight_inherited_vigor_passive:AddCustomTransmitterData()
    self.multiplier = TernaryOperator(self.dragon_form_multiplier, self:GetParent():HasModifier("modifier_dragon_knight_elder_dragon_form_buff"), 1.0)
    return {
        multiplier = tonumber(self.multiplier)
    }
end
function modifier_dragon_knight_inherited_vigor_passive:HandleCustomTransmitterData(data)
    self.multiplier = tonumber(data.multiplier)
end