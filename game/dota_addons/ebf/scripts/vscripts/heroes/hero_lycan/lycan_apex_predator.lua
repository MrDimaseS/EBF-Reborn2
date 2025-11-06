lycan_apex_predator = class({})

function lycan_apex_predator:GetIntrinsicModifierName()
    if self:GetSpecialValueFor("isolation_radius") ~= 0 then
        return "modifier_lycan_apex_predator_ebf_aura"
    else
        return "modifier_lycan_apex_predator_ebf"
    end
end

function lycan_apex_predator:GetBehavior()
    return DOTA_ABILITY_BEHAVIOR_PASSIVE
end

modifier_lycan_apex_predator_ebf = class({})
LinkLuaModifier("modifier_lycan_apex_predator_ebf", "heroes/hero_lycan/lycan_apex_predator", LUA_MODIFIER_MOTION_NONE)

function modifier_lycan_apex_predator_ebf:IsHidden()
    return false
end

function modifier_lycan_apex_predator_ebf:OnCreated()
    self:OnRefresh()
end

function modifier_lycan_apex_predator_ebf:OnRefresh()
    self.creep_dmg_bonus = self:GetSpecialValueFor("creep_dmg_bonus")
    self.isolated_hero = self.creep_dmg_bonus / 2
    self.isolation_radius = self:GetSpecialValueFor("isolation_radius")
    self.shapeshift_multiplier = self:GetSpecialValueFor("shapeshift_multiplier") / 100
end

function modifier_lycan_apex_predator_ebf:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_TOOLTIP
    }
end

function modifier_lycan_apex_predator_ebf:GetModifierTotalDamageOutgoing_Percentage(params)
    if params.attacker == self:GetParent() then
        if not params.target:IsConsideredHero() then
            if params.attacker:HasModifier("modifier_lycan_shapeshift") then
                return self.creep_dmg_bonus * self.shapeshift_multiplier
            else
                return self.creep_dmg_bonus
            end
        else
            if self.isolation_radius ~= 0 then
                local extra = params.attacker:FindEnemyUnitsInRadius(params.target:GetAbsOrigin(), self.isolation_radius, {type = DOTA_UNIT_TARGET_HERO})
                if #extra == 1 then
                    if params.attacker:HasModifier("modifier_lycan_shapeshift") then
                        return self.isolated_hero * self.shapeshift_multiplier
                    else
                        return self.isolated_hero
                    end
                else
                    return
                end
            else
                return
            end
        end
    end
end

function modifier_lycan_apex_predator_ebf:OnTooltip()
    return self.creep_dmg_bonus
end

modifier_lycan_apex_predator_ebf_aura = class({})
LinkLuaModifier("modifier_lycan_apex_predator_ebf_aura", "heroes/hero_lycan/lycan_apex_predator", LUA_MODIFIER_MOTION_NONE)

function modifier_lycan_apex_predator_ebf_aura:IsHidden()
    return true
end

function modifier_lycan_apex_predator_ebf_aura:OnCreated()
    self:OnRefresh()
end

function modifier_lycan_apex_predator_ebf_aura:OnRefresh()
    self.radius = self:GetSpecialValueFor("aura_radius") or 0
end

function modifier_lycan_apex_predator_ebf_aura:IsAura()
    return true
end

function modifier_lycan_apex_predator_ebf_aura:GetAuraRadius()
    return self.radius
end

function modifier_lycan_apex_predator_ebf_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_lycan_apex_predator_ebf_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_ALL
end

function modifier_lycan_apex_predator_ebf_aura:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS
end

function modifier_lycan_apex_predator_ebf_aura:GetModifierAura()
    return "modifier_lycan_apex_predator_ebf"
end