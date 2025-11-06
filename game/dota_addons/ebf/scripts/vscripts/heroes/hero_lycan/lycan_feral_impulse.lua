lycan_feral_impulse = class({})

function lycan_feral_impulse:GetIntrinsicModifierName()
    if self:GetSpecialValueFor("aura_radius") == 0 then
        return "modifier_lycan_feral_impulse_ebf"
    else
        return "modifier_lycan_feral_impulse_ebf_aura"
    end
end

modifier_lycan_feral_impulse_ebf = class({})
LinkLuaModifier("modifier_lycan_feral_impulse_ebf", "heroes/hero_lycan/lycan_feral_impulse", LUA_MODIFIER_MOTION_NONE)

function modifier_lycan_feral_impulse_ebf:OnCreated()
    self:OnRefresh()
end

function modifier_lycan_feral_impulse_ebf:OnRefresh()
    self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
    self.bonus_hp_regen = self:GetSpecialValueFor("bonus_hp_regen")

    self.bonus_per_missing_health = self:GetSpecialValueFor("bonus_per_missing_health")
    self.missing_health_pct = self:GetSpecialValueFor("missing_health_pct")
    self.shapeshift_multiplier = self:GetSpecialValueFor("shapeshift_multiplier")

    self.hero_bonus = self:GetSpecialValueFor("hero_bonus") / 100
    self.ally_creep_bonus = self:GetSpecialValueFor("ally_creep_bonus") / 100

    self.aura_radius = self:GetSpecialValueFor("aura_radius")
    self:StartIntervalThink(0.1)
end

function modifier_lycan_feral_impulse_ebf:OnIntervalThink()
    --there's probably a way to simplify this
    if self.aura_radius == 0 then
        local maxHP = self:GetParent():GetMaxHealth()
        local currentHP = self:GetParent():GetHealth()
        local missingHealth = math.floor(((maxHP - currentHP) / maxHP) * 100)
        local missingHealthPCT = math.floor(missingHealth / self.missing_health_pct)
        self:SetStackCount(missingHealthPCT)
    end
end

function modifier_lycan_feral_impulse_ebf:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    }
end

function modifier_lycan_feral_impulse_ebf:GetModifierDamageOutgoing_Percentage()
    if self:GetParent():GetPlayerOwnerID() == self:GetCaster():GetPlayerOwnerID() then
        if self:GetParent():HasModifier("modifier_lycan_shapeshift") and self.shapeshift_multiplier ~= 0 then
            return self.bonus_damage * ((1+self.bonus_per_missing_health * self:GetStackCount()/100) or 1) * self.shapeshift_multiplier
        else
            return self.bonus_damage * ((1+self.bonus_per_missing_health * self:GetStackCount()/100) or 1)
        end
    else
        if self:GetParent():IsConsideredHero() then
            return self.bonus_damage * ((1+self.bonus_per_missing_health * self:GetStackCount()/100) or 1) * self.hero_bonus
        end
    end
end

function modifier_lycan_feral_impulse_ebf:GetModifierConstantHealthRegen()
    if self:GetParent():GetPlayerOwnerID() == self:GetCaster():GetPlayerOwnerID() then
        if self:GetParent():HasModifier("modifier_lycan_shapeshift") and self.shapeshift_multiplier ~= 0 then
            return self.bonus_hp_regen  * ((1+self.bonus_per_missing_health * self:GetStackCount()/100) or 1) * self.shapeshift_multiplier
        else
            return self.bonus_hp_regen  * ((1+self.bonus_per_missing_health * self:GetStackCount()/100) or 1)
        end
    else
        if self:GetParent():IsConsideredHero() then
            return self.bonus_hp_regen  * ((1+self.bonus_per_missing_health * self:GetStackCount()/100) or 1) * self.hero_bonus
        end
    end
end

modifier_lycan_feral_impulse_ebf_aura = class({})
LinkLuaModifier("modifier_lycan_feral_impulse_ebf_aura", "heroes/hero_lycan/lycan_feral_impulse", LUA_MODIFIER_MOTION_NONE)


function modifier_lycan_feral_impulse_ebf_aura:IsHidden()
    return true
end

function modifier_lycan_feral_impulse_ebf_aura:OnCreated()
    self:OnRefresh()
end

function modifier_lycan_feral_impulse_ebf_aura:OnRefresh()
    self.radius = self:GetSpecialValueFor("aura_radius") or 0
end

function modifier_lycan_feral_impulse_ebf_aura:IsAura()
    return true
end

function modifier_lycan_feral_impulse_ebf_aura:GetAuraRadius()
    return self.radius
end

function modifier_lycan_feral_impulse_ebf_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_lycan_feral_impulse_ebf_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_ALL
end

function modifier_lycan_feral_impulse_ebf_aura:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS
end

function modifier_lycan_feral_impulse_ebf_aura:GetModifierAura()
    return "modifier_lycan_feral_impulse_ebf"
end