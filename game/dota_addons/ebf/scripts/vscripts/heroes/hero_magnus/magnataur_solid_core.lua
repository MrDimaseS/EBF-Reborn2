magnataur_solid_core = class({})

function magnataur_solid_core:GetIntrinsicModifierName()
    return "modifier_magnataur_solid_core_passive"
end

modifier_magnataur_solid_core_passive = class({})
LinkLuaModifier( "modifier_magnataur_solid_core_passive", "heroes/hero_magnus/magnataur_solid_core", LUA_MODIFIER_MOTION_NONE )

function modifier_magnataur_solid_core_passive:IsHidden()
    return true
end
function modifier_magnataur_solid_core_passive:OnCreated()
    self:OnRefresh()
end
function modifier_magnataur_solid_core_passive:OnRefresh()
    self.parent = self:GetParent()
    self.slow_resistance = self:GetSpecialValueFor("slow_resistance")
    self.status_resistance = self:GetSpecialValueFor("status_resistance")

    self.damage_per_armor = self:GetSpecialValueFor("damage_per_armor")
    self.base_armor = self:GetSpecialValueFor("base_armor")
    self.armor_per_level = self:GetSpecialValueFor("armor_per_level")
    self.status_resistance_per_level = self:GetSpecialValueFor("status_resistance_per_level")
end
function modifier_magnataur_solid_core_passive:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_SLOW_RESISTANCE_STACKING,
        MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    }
end
function modifier_magnataur_solid_core_passive:GetModifierSlowResistance_Stacking()
    return self.slow_resistance
end
function modifier_magnataur_solid_core_passive:GetModifierStatusResistanceStacking()
    return self.status_resistance + self.status_resistance_per_level * self.parent:GetLevel()
end
function modifier_magnataur_solid_core_passive:GetModifierDamageOutgoing_Percentage()
    return self.damage_per_armor * self.parent:GetPhysicalArmorValue(false)
end
function modifier_magnataur_solid_core_passive:GetModifierPhysicalArmorBonus()
    return self.base_armor + self.armor_per_level * self.parent:GetLevel()
end