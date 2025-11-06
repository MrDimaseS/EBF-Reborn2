lycan_thrill_of_the_hunt = class({})

function lycan_thrill_of_the_hunt:GetIntrinsicModifierName()
    return "modifier_lycan_thrill_of_the_hunt"
end

modifier_lycan_thrill_of_the_hunt = class({})
LinkLuaModifier("modifier_lycan_thrill_of_the_hunt", "heroes/hero_lycan/lycan_thrill_of_the_hunt", LUA_MODIFIER_MOTION_NONE)

function modifier_lycan_thrill_of_the_hunt:IsHidden()
    return true
end

function modifier_lycan_thrill_of_the_hunt:OnCreated()
    self:OnRefresh()
end

function modifier_lycan_thrill_of_the_hunt:OnRefresh()
    self.bonus_health = self:GetSpecialValueFor("bonus_health")
    self.bonus_base_dmg = self:GetSpecialValueFor("bonus_base_dmg")
    self.shapeshift_multiplier = self:GetSpecialValueFor("shapeshift_multiplier")
    self.aspd = self:GetSpecialValueFor("aspd")
    self:StartIntervalThink(0.1)
end

function modifier_lycan_thrill_of_the_hunt:OnIntervalThink()
    self:OnCreated()
end

function modifier_lycan_thrill_of_the_hunt:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
end

function modifier_lycan_thrill_of_the_hunt:GetModifierAttackSpeedBonus_Constant()
    return self.aspd
end

function modifier_lycan_thrill_of_the_hunt:GetModifierHealthBonus()
    if self:GetParent():HasModifier("modifier_lycan_shapeshift") and self.shapeshift_multiplier ~= 0 then
        return self.bonus_health * self.shapeshift_multiplier
    else
        return self.bonus_health
    end
end

function modifier_lycan_thrill_of_the_hunt:GetModifierBaseAttack_BonusDamage()
    if self:GetParent():HasModifier("modifier_lycan_shapeshift") and self.shapeshift_multiplier ~= 0 then
        return self.bonus_base_dmg * self.shapeshift_multiplier
    else
        return self.bonus_base_dmg
    end
end