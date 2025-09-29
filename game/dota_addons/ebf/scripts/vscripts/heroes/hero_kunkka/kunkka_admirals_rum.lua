kunkka_admirals_rum = class({})

function kunkka_admirals_rum:CastFilterResultTarget(target)
    local caster = self:GetCaster()
    if self:GetSpecialValueFor("damage_increase") ~= 0 then
        if target ~= caster and target:GetTeamNumber() == caster:GetTeamNumber() then
            return UF_FAIL_FRIENDLY
        end
        return UnitFilter(target, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, self:GetCaster():GetTeamNumber() )
    end
end

function kunkka_admirals_rum:GetBehavior()
    if self:GetSpecialValueFor("total_attack_bonus") ~= 0 then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
    else
        if self:GetSpecialValueFor("aoe") ~= 0 then
            return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_AOE --+ DOTA_ABILITY_BEHAVIOR_IMMEDIATE
        else
            return self.BaseClass.GetBehavior( self )
        end
    end
end

function kunkka_admirals_rum:GetAOERadius()
    return self:GetSpecialValueFor("aoe")
end

function kunkka_admirals_rum:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    local aoe = self:GetSpecialValueFor("aoe")
    if  aoe ~= 0 then
        if target ~= caster then
            local enemies = caster:FindEnemyUnitsInRadius(target:GetAbsOrigin(), aoe )
            for _, unit in ipairs(enemies) do
                self:Drink(unit, caster)
            end
        else
            self:Drink(caster, caster)
        end
    else
        self:Drink(target, caster)
    end
end

function kunkka_admirals_rum:Drink(target, caster, bDur)
    local mariner = self:GetSpecialValueFor("damage_increase")
    local admiral = self:GetSpecialValueFor("dispel")
    local privateer = self:GetSpecialValueFor("total_attack_bonus")

    local duration = self:GetSpecialValueFor("buff_duration") or bDur

    if mariner ~= 0 then
        if target ~= caster then
            target:AddNewModifier(caster, self, "modifier_kunkka_admirals_rum_mariner", {duration = duration})
        else
            caster:AddNewModifier(caster, self, "modifier_kunkka_admirals_rum_self", {duration = duration})
            caster:AddNewModifier(caster, self, "modifier_kunkka_admirals_rum_hangover", {duration = duration + 10})
        end
    end
    if admiral ~= 0 then
        target:AddNewModifier(caster, self, "modifier_kunkka_admirals_rum_self", {duration = duration})
        target:AddNewModifier(caster, self, "modifier_kunkka_admirals_rum_hangover", {duration = duration + 10})
        target:Purge(false, true, false, false, false)
    end
    if privateer ~= 0 then
        caster:AddNewModifier(caster, self, "modifier_kunkka_admirals_rum_self", {duration = duration})
        caster:AddNewModifier(caster, self, "modifier_kunkka_admirals_rum_privateer", {duration = duration})
        caster:AddNewModifier(caster, self, "modifier_kunkka_admirals_rum_hangover", {duration = duration + 10})
    end
end

modifier_kunkka_admirals_rum_self = class({})
LinkLuaModifier("modifier_kunkka_admirals_rum_self", "heroes/hero_kunkka/kunkka_admirals_rum", LUA_MODIFIER_MOTION_NONE)

function modifier_kunkka_admirals_rum_self:IsBuff()
    return true
end

function modifier_kunkka_admirals_rum_self:OnCreated()
    self:OnRefresh()
end

function modifier_kunkka_admirals_rum_self:OnRefresh()
    self.dmg_res = self:GetSpecialValueFor("damage_reduction")
    self.mspd_bonus = self:GetSpecialValueFor("mspd_bonus")
    self.armor_bonus = self:GetSpecialValueFor("armor_bonus")
end

function modifier_kunkka_admirals_rum_self:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    }
end

function modifier_kunkka_admirals_rum_self:GetModifierIncomingDamage_Percentage()
    return -self.dmg_res
end

function modifier_kunkka_admirals_rum_self:GetModifierMoveSpeedBonus_Percentage()
    if self.mspd_bonus ~= 0 then
        return self.mspd_bonus
    end
end

function modifier_kunkka_admirals_rum_self:GetModifierPhysicalArmorBonus()
    if self.armor_bonus ~= 0 then
        return self.armor_bonus
    end
end

function modifier_kunkka_admirals_rum_self:GetEffectName()
    return "particles/units/heroes/hero_kunkka/kunkka_admirals_rum.vpcf"
end

modifier_kunkka_admirals_rum_mariner = class({})
LinkLuaModifier("modifier_kunkka_admirals_rum_mariner", "heroes/hero_kunkka/kunkka_admirals_rum", LUA_MODIFIER_MOTION_NONE)

function modifier_kunkka_admirals_rum_mariner:IsDebuff()
    return true
end

function modifier_kunkka_admirals_rum_mariner:IsPurgable()
    return true
end

function modifier_kunkka_admirals_rum_mariner:OnCreated()
    self:OnRefresh()
end

function modifier_kunkka_admirals_rum_mariner:OnRefresh()
    self.dmg_increase = self:GetSpecialValueFor("damage_increase")
    self.heal_percentage = self:GetSpecialValueFor("heal_percentage") / 100
    self.stat_res_reduction = self:GetSpecialValueFor("stat_res_reduction")
end

function modifier_kunkka_admirals_rum_mariner:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_kunkka_admirals_rum_mariner:OnTakeDamage(params)
    if IsServer() then
        local extra_dmg = params.damage * self.dmg_increase
        self:GetAbility():DealDamage(params.attacker, params.target, extra_dmg)
        params.attacker:HealEvent(extra_dmg * self.heal_percentage, self, self:GetCaster())
    end
end

function modifier_kunkka_admirals_rum_mariner:GetModifierStatusResistanceStacking()
    return -self.stat_res_reduction
end

function modifier_kunkka_admirals_rum_mariner:GetModifierIncomingDamage_Percentage()
    return self.dmg_increase
end

function modifier_kunkka_admirals_rum_mariner:GetEffectName()
    return "particles/units/heroes/hero_kunkka/kunkka_admirals_rum.vpcf"
end

modifier_kunkka_admirals_rum_privateer = class({})
LinkLuaModifier("modifier_kunkka_admirals_rum_privateer", "heroes/hero_kunkka/kunkka_admirals_rum", LUA_MODIFIER_MOTION_NONE)

function modifier_kunkka_admirals_rum_privateer:IsPurgable()
    return true
end

function modifier_kunkka_admirals_rum_privateer:IsBuff()
    return true
end

function modifier_kunkka_admirals_rum_privateer:OnCreated()
    self:OnRefresh()
end

function modifier_kunkka_admirals_rum_privateer:OnRefresh()
    self.dmg_amp = self:GetSpecialValueFor("total_attack_bonus")
    self.base_damage_bonus = self:GetSpecialValueFor("base_damage_bonus")
end

function modifier_kunkka_admirals_rum_privateer:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE
    }
end

function modifier_kunkka_admirals_rum_privateer:GetModifierTotalDamageOutgoing_Percentage()
    return self.dmg_amp
end

function modifier_kunkka_admirals_rum_privateer:GetModifierBaseAttack_BonusDamage()
    if self.base_damage_bonus ~= 0 then
        return self.base_damage_bonus
    end
end

modifier_kunkka_admirals_rum_hangover = class({})
LinkLuaModifier("modifier_kunkka_admirals_rum_hangover", "heroes/hero_kunkka/kunkka_admirals_rum", LUA_MODIFIER_MOTION_NONE)

function modifier_kunkka_admirals_rum_hangover:IsHidden()
    if self:GetParent():HasModifier("modifier_kunkka_admirals_rum_self") then
        return true
    else
        return false
    end
end

function modifier_kunkka_admirals_rum_hangover:IsPurgable()
    if self:GetParent():HasModifier("modifier_kunkka_admirals_rum_self") then
        return false
    else
        return true
    end
end

function modifier_kunkka_admirals_rum_hangover:IsDebuff()
    return true
end

function modifier_kunkka_admirals_rum_hangover:DeclareFunctions()
    return
    {
        MODIFIER_EVENT_ON_TAKEDAMAGE
    }
end

function modifier_kunkka_admirals_rum_hangover:OnCreated()
    self.damage_taken = 0
    self.absorbing = true
    if IsServer() then
        Timers:CreateTimer(self:GetSpecialValueFor("hangover_duration"), function()
            self:StartIntervalThink(1)
            self.absorbing = false
        end)
    end
end

function modifier_kunkka_admirals_rum_hangover:OnTakeDamage(params)
    if params.unit == self:GetParent() and self.absorbing == true then
        self.damage_taken = self.damage_taken + params.damage
        print(self.damage_taken)
    end
end

function modifier_kunkka_admirals_rum_hangover:OnIntervalThink()
    local parent = self:GetParent()
    local currentHp = parent:GetHealth()
    local postHp = currentHp - self.damage_taken
    if postHp <= 0 then
        parent:SetHealth(1)
    else
        parent:SetHealth(postHp)
    end
end
