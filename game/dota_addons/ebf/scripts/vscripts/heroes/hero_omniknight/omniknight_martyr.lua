omniknight_martyr = class({})

function omniknight_martyr:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    
    local base_strength = self:GetTalentSpecialValueFor("base_strength")
    local base_hpregen = self:GetTalentSpecialValueFor("base_hpregen")
    local strength_bonus = self:GetTalentSpecialValueFor("strength_bonus")
    local duration = self:GetTalentSpecialValueFor("duration")
    local magic_resist = self:GetTalentSpecialValueFor("magic_resist")

    target:AddNewModifier(caster, self, "modifier_omniknight_martyr_buff", {
        duration = duration, 
        base_strength = base_strength, 
        base_hpregen = base_hpregen, 
        strength_bonus = strength_bonus, 
        magic_resist = magic_resist
    })

	EmitSoundOn("Hero_Omniknight.Repel", target)
end

LinkLuaModifier("modifier_omniknight_martyr_buff", "heroes/hero_omniknight/omniknight_martyr.lua", LUA_MODIFIER_MOTION_NONE)

modifier_omniknight_martyr_buff = class({})

function modifier_omniknight_martyr_buff:OnCreated(kv)
    self.base_strength = kv.base_strength or 0
    self.base_hpregen = kv.base_hpregen or 0
    self.strength_bonus = kv.strength_bonus or 0
    self.magic_resist = kv.magic_resist or 0

    if IsServer() then
        self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_repel_buff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
        self:AddParticle(self.particle, false, false, -1, false, false)
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
    local magic_resist = self.magic_resist
    if self:GetCaster():HasShard() then
        magic_resist = magic_resist + (magic_resist * 0.6)
    end
    return magic_resist
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