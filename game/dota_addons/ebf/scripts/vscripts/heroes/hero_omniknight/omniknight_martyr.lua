omniknight_martyr = class({})

function omniknight_martyr:OnSpellStart()
    local caster = self:GetCaster()
    local target_point = self:GetCursorPosition()
    
    local duration = self:GetSpecialValueFor("duration")
    local radius = self:GetSpecialValueFor("radius")

    local allies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        target_point,
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_FRIENDLY,
        DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )

    for _, ally in pairs(allies) do
        ally:AddNewModifier(caster, self, "modifier_omniknight_martyr_buff", {duration = duration})
    end

    EmitSoundOnLocationWithCaster(target_point, "Hero_Omniknight.Repel", caster)
end

LinkLuaModifier("modifier_omniknight_martyr_buff", "heroes/hero_omniknight/omniknight_martyr.lua", LUA_MODIFIER_MOTION_NONE)

modifier_omniknight_martyr_buff = class({})

function modifier_omniknight_martyr_buff:OnCreated(kv)
    self.base_strength = self:GetSpecialValueFor("base_strength")
    self.base_hpregen = self:GetSpecialValueFor("base_hpregen")
    self.strength_bonus = self:GetSpecialValueFor("strength_bonus")
    self.magic_resist = self:GetSpecialValueFor("magic_resist")

    if IsServer() then
        local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_repel_buff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
        self:AddEffect(particle)
    end
end

function modifier_omniknight_martyr_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
    }
end

function modifier_omniknight_martyr_buff:GetModifierBonusStats_Strength()
    return self.base_strength + self.strength_bonus
end

function modifier_omniknight_martyr_buff:GetModifierConstantHealthRegen()
    return self.base_hpregen
end

function modifier_omniknight_martyr_buff:GetModifierMagicalResistanceBonus()
    return self.magic_resist
end

function modifier_omniknight_martyr_buff:OnTooltip()
    return self:GetModifierMagicalResistanceBonus()
end

function modifier_omniknight_martyr_buff:OnTooltip2()
    return self.base_strength + self.strength_bonus
end

function modifier_omniknight_martyr_buff:OnTooltip3()
    return self.base_hpregen
end

function modifier_omniknight_martyr_buff:IsHidden()
    return false
end

function modifier_omniknight_martyr_buff:IsPurgable()
    return true
end

function modifier_omniknight_martyr_buff:GetEffectName()
    return "particles/units/heroes/hero_omniknight/omniknight_repel_buff.vpcf"
end

function modifier_omniknight_martyr_buff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_omniknight_martyr_buff:OnDestroy()
    if IsServer() and self.particle then
        ParticleManager:DestroyParticle(self.particle, false)
        ParticleManager:ReleaseParticleIndex(self.particle)
    end
end