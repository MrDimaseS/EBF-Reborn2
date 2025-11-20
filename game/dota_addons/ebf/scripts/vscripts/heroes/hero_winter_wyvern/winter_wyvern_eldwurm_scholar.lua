winter_wyvern_eldwurm_scholar = class({})

function winter_wyvern_eldwurm_scholar:GetIntrinsicModifierName()
    return "modifier_winter_wyvern_eldwurm_scholar_ebf"
end

modifier_winter_wyvern_eldwurm_scholar_ebf = class({})
LinkLuaModifier("modifier_winter_wyvern_eldwurm_scholar_ebf", "heroes/hero_winter_wyvern/winter_wyvern_eldwurm_scholar", LUA_MODIFIER_MOTION_NONE)

function modifier_winter_wyvern_eldwurm_scholar_ebf:IsHidden()
    return true
end

function modifier_winter_wyvern_eldwurm_scholar_ebf:OnCreated()
    self:OnRefresh()
end

function modifier_winter_wyvern_eldwurm_scholar_ebf:OnRefresh()
    self.spell_amp = self:GetSpecialValueFor("spell_amp")
    self.per_int = self:GetSpecialValueFor("per_int")
    self.heal_amp = self:GetSpecialValueFor("heal_amp")
    self.debuff_duration = self:GetSpecialValueFor("debuff_duration")
end

function modifier_winter_wyvern_eldwurm_scholar_ebf:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_MAX_DEBUFF_DURATION,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE
    }
end

function modifier_winter_wyvern_eldwurm_scholar_ebf:GetModifierMaxDebuffDuration()
    if self.debuff_duration ~= 0 then
        return self.debuff_duration * math.floor(self:GetParent():GetIntellect(false) / self.per_int)
    end
end

function modifier_winter_wyvern_eldwurm_scholar_ebf:GetModifierSpellAmplify_Percentage()
    return self.spell_amp * math.floor(self:GetParent():GetIntellect(false) / self.per_int)
end

function modifier_winter_wyvern_eldwurm_scholar_ebf:GetModifierHealAmplify_PercentageSource()
    if self.heal_amp ~= 0 then
        return self.heal_amp * math.floor(self:GetParent():GetIntellect(false) / self.per_int)
    end
end