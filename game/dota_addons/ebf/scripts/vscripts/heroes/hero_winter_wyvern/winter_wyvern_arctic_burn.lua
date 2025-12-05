winter_wyvern_arctic_burn  = class({})

function winter_wyvern_arctic_burn:GetBehavior()
    if self:GetSpecialValueFor("mana_per_second") ~= 0 then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_TOGGLE
    else
        return self.BaseClass.GetBehavior(self)
    end
end

function winter_wyvern_arctic_burn:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")
    local heal_radius = self:GetSpecialValueFor("heal_radius")

    caster:AddNewModifier(caster, self, "modifier_winter_wyvern_arctic_burn_flight", {duration = duration})
    caster:AddNewModifier(caster, self, "modifier_winter_wyvern_arctic_burn_ebf_attack", {duration = duration})
    if heal_radius ~= 0 then
        caster:AddNewModifier(caster, self, "modifier_winter_wyvern_arctic_burn_ebf_heal_aura", {duration = duration})
    end
    EmitSoundOn("Hero_Winter_Wyvern.ArcticBurn.Cast", caster)
end

function winter_wyvern_arctic_burn:OnToggle()
    local caster = self:GetCaster()
    
    if self:GetToggleState() then
        caster:AddNewModifier(caster, self, "modifier_winter_wyvern_arctic_burn_flight", {duration = -1})
        caster:AddNewModifier(caster, self, "modifier_winter_wyvern_arctic_burn_ebf_handler", {duration = -1})
        caster:AddNewModifier(caster, self, "modifier_winter_wyvern_arctic_burn_ebf_attack", {duration = -1})
        EmitSoundOn("Hero_Winter_Wyvern.ArcticBurn.Cast", caster)
        caster:SpendMana(self:GetSpecialValueFor("AbilityManaCost"), self)
    else
        caster:RemoveModifierByName("modifier_winter_wyvern_arctic_burn_flight")
        caster:RemoveModifierByName("modifier_winter_wyvern_arctic_burn_ebf_handler")
        caster:RemoveModifierByName("modifier_winter_wyvern_arctic_burn_ebf_attack")
        caster:SpendMana(self:GetSpecialValueFor("AbilityManaCost"), self)
    end
end

modifier_winter_wyvern_arctic_burn_ebf_handler = class({})
LinkLuaModifier("modifier_winter_wyvern_arctic_burn_ebf_handler", "heroes/hero_winter_wyvern/winter_wyvern_arctic_burn", LUA_MODIFIER_MOTION_NONE)

function modifier_winter_wyvern_arctic_burn_ebf_handler:IsHidden()
    return true
end

function modifier_winter_wyvern_arctic_burn_ebf_handler:OnCreated()
    self.mana_per_second = self:GetSpecialValueFor("mana_per_second")
    self:StartIntervalThink(1)
end

function modifier_winter_wyvern_arctic_burn_ebf_handler:OnIntervalThink()
    if IsServer() then
        self:GetParent():SpendMana(self.mana_per_second, self:GetAbility())
    end
end

function modifier_winter_wyvern_arctic_burn_ebf_handler:OnDestroy()
    self:StartIntervalThink(-1)
end


modifier_winter_wyvern_arctic_burn_ebf_attack = class({})
LinkLuaModifier("modifier_winter_wyvern_arctic_burn_ebf_attack", "heroes/hero_winter_wyvern/winter_wyvern_arctic_burn", LUA_MODIFIER_MOTION_NONE)

function modifier_winter_wyvern_arctic_burn_ebf_attack:IsHidden()
    return true
end

function modifier_winter_wyvern_arctic_burn_ebf_attack:OnCreated()
    self:OnRefresh()
end

function modifier_winter_wyvern_arctic_burn_ebf_attack:OnRefresh()
    self.damage_duration = self:GetSpecialValueFor("damage_duration")
    self.no_limit = self:GetSpecialValueFor("no_limit")
end

function modifier_winter_wyvern_arctic_burn_ebf_attack:DeclareFunctions()
    return
    {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
        MODIFIER_EVENT_ON_ATTACK
    }
end

function modifier_winter_wyvern_arctic_burn_ebf_attack:OnAttack()
    local caster = self:GetCaster()
    EmitSoundOn("Hero_Winter_Wyvern.ArcticBurn.attack", caster)
end

function modifier_winter_wyvern_arctic_burn_ebf_attack:OnAttackLanded(params)
    local parent = self:GetParent()
    EmitSoundOn("Hero_Winter_Wyvern.ArcticBurn.projectileImpact", parent)
    if params.attacker == parent then
        if params.target:HasModifier("modifier_winter_wyvern_arctic_burn_ebf_debuff") then
            if self.no_limit ~= 0 then
                params.target:FindModifierByName("modifier_winter_wyvern_arctic_burn_ebf_debuff"):SetDuration(self.damage_duration, true)
            else
                return
            end
        else
            params.target:AddNewModifier(parent, self:GetAbility(), "modifier_winter_wyvern_arctic_burn_ebf_debuff", {duration = self.damage_duration})
        end
    end
end


modifier_winter_wyvern_arctic_burn_ebf_debuff = class({})
LinkLuaModifier("modifier_winter_wyvern_arctic_burn_ebf_debuff", "heroes/hero_winter_wyvern/winter_wyvern_arctic_burn", LUA_MODIFIER_MOTION_NONE)

function modifier_winter_wyvern_arctic_burn_ebf_debuff:IsDebuff()
    return true
end

function modifier_winter_wyvern_arctic_burn_ebf_debuff:OnCreated()
    self:OnRefresh()
end

function modifier_winter_wyvern_arctic_burn_ebf_debuff:OnRefresh()
    self.base_damage = self:GetSpecialValueFor("base_damage")
    self.percent_damage = self:GetSpecialValueFor("percent_damage") / 100
    self.move_slow = self:GetSpecialValueFor("move_slow")
    self.attack_slow = self:GetSpecialValueFor("attack_slow")
    self.damage_interval = self:GetSpecialValueFor("damage_interval")
    self:StartIntervalThink(self.damage_interval)
end

function modifier_winter_wyvern_arctic_burn_ebf_debuff:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
end

function modifier_winter_wyvern_arctic_burn_ebf_debuff:GetModifierMoveSpeedBonus_Percentage()
    return -self.move_slow
end

function modifier_winter_wyvern_arctic_burn_ebf_debuff:GetModifierAttackSpeedBonus_Constant()
    if self.attack_slow ~= 0 then
        return -self.attack_slow
    end
end

function modifier_winter_wyvern_arctic_burn_ebf_debuff:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()
    local currentHP = parent:GetHealth()
    local damage = currentHP * self.percent_damage

    if IsServer() then
        self:GetAbility():DealDamage( caster, parent, self.base_damage * (1+caster:GetSpellAmplification( false )) + damage * parent:GetMaxHealthDamageResistance(), {damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION } )
    end
end

function modifier_winter_wyvern_arctic_burn_ebf_debuff:OnDestroy()
    self:StartIntervalThink(-1)
end

function modifier_winter_wyvern_arctic_burn_ebf_debuff:GetEffectName()
    return "particles/units/heroes/hero_winter_wyvern/wyvern_arctic_burn_slow.vpcf"
end

modifier_winter_wyvern_arctic_burn_ebf_heal_aura = class({})
LinkLuaModifier("modifier_winter_wyvern_arctic_burn_ebf_heal_aura", "heroes/hero_winter_wyvern/winter_wyvern_arctic_burn", LUA_MODIFIER_MOTION_NONE)

function modifier_winter_wyvern_arctic_burn_ebf_heal_aura:IsHidden()
    return true
end

function modifier_winter_wyvern_arctic_burn_ebf_heal_aura:OnCreated()
    self:OnRefresh()
end

function modifier_winter_wyvern_arctic_burn_ebf_heal_aura:OnRefresh()
    self.heal_pct = self:GetSpecialValueFor("heal_pct") / 100
    self.heal_radius = self:GetSpecialValueFor("heal_radius")
    self.heal_interval = self:GetSpecialValueFor("heal_interval")
    self:StartIntervalThink(self.heal_interval)
end

function modifier_winter_wyvern_arctic_burn_ebf_heal_aura:OnIntervalThink()
    local parent = self:GetParent()

    if IsServer() then
        for _, allies in ipairs(parent:FindFriendlyUnitsInRadius(parent:GetAbsOrigin(), self.heal_radius)) do
            local missingHP = allies:GetHealthDeficit()
            local healAmount = missingHP * self.heal_pct * self.heal_interval
            allies:HealEvent(healAmount, self:GetAbility(), self:GetCaster())
        end
    end
    ParticleManager:CreateParticle("particles/units/heroes/hero_winter_wyvern/wyvern_arctic_burn_start_swirl.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
end

function modifier_winter_wyvern_arctic_burn_ebf_heal_aura:OnDestroy()
    self:StartIntervalThink(-1)
end