winter_wyvern_cold_embrace = class({})

function winter_wyvern_cold_embrace:GetAbilityTargetTeam()
    if self:GetSpecialValueFor("damage") ~= 0 then
        return DOTA_UNIT_TARGET_TEAM_BOTH
    else
        return DOTA_UNIT_TARGET_TEAM_FRIENDLY
    end
end

function winter_wyvern_cold_embrace:CastFilterResultTarget(target)
    if self:GetSpecialValueFor("stuns") == 0 then
        if target:HasModifier("modifier_winter_wyvern_cold_embrace_ebf") then
            return UF_FAIL_CUSTOM
        end
    end
    return UF_SUCCESS
end

function winter_wyvern_cold_embrace:GetCustomCastErrorTarget(target)
    return "Already in a Cold Embrace"
end

function winter_wyvern_cold_embrace:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()

    local duration = self:GetSpecialValueFor("duration")
    local modifier = target:FindModifierByName("modifier_winter_wyvern_cold_embrace_ebf")
    if not modifier then
        if target:GetTeam() == caster:GetTeam() then
            target:AddNewModifier(caster, self, "modifier_winter_wyvern_cold_embrace_ebf", {duration = duration})
        else
            target:AddNewModifier(caster, self, "modifier_winter_wyvern_cold_embrace_ebf", {duration = duration / 2})
        end
    else
        if self:GetSpecialValueFor("stuns") == 1 then
            modifier:SetDuration(modifier:GetRemainingTime() + duration, true)
        end
    end
    EmitSoundOn("Hero_Winter_Wyvern.ColdEmbrace.Cast", caster)
end


modifier_winter_wyvern_cold_embrace_ebf = class({})
LinkLuaModifier("modifier_winter_wyvern_cold_embrace_ebf", "heroes/hero_winter_wyvern/winter_wyvern_cold_embrace", LUA_MODIFIER_MOTION_NONE)

function modifier_winter_wyvern_cold_embrace_ebf:IsPurgable()
    return false
end

function modifier_winter_wyvern_cold_embrace_ebf:IsBuff()
    return true
end

function modifier_winter_wyvern_cold_embrace_ebf:OnCreated()
    self:OnRefresh()
    EmitSoundOn("Hero_Winter_Wyvern.ColdEmbrace", self:GetParent())
end

function modifier_winter_wyvern_cold_embrace_ebf:OnRefresh()
    if self:GetSpecialValueFor("stuns") ~= 0 then
        self.stuns = false
    else
        self.stuns = true
    end

    if self:GetSpecialValueFor("damage") ~= 0 then
        self.damage = false
    else
        self.damage = true
    end

    self.heal_additive = self:GetSpecialValueFor("heal_additive")
    self.heal_percentage = self:GetSpecialValueFor("heal_percentage") / 100
    self.heal_interval = self:GetSpecialValueFor("heal_interval")
    self.damage_bb = self:GetSpecialValueFor("damage")

    self:StartIntervalThink(self.heal_interval)
end

function modifier_winter_wyvern_cold_embrace_ebf:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    if IsServer() then
        if parent:GetTeam() == caster:GetTeam() then
            local maxHP = parent:GetMaxHealth() * self.heal_percentage
            local healAmt = self.heal_additive + maxHP
            parent:HealEvent(healAmt, ability, caster)
        else
            ability:DealDamage(caster, parent, self.damage_bb)
        end
    end
end

function modifier_winter_wyvern_cold_embrace_ebf:CheckState()
    return
    {
        [MODIFIER_STATE_STUNNED] = self.stuns,
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
        [MODIFIER_STATE_FROZEN] = self.stuns,
        [MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE] = self.stuns,
        [MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL] = self.damage
    }
end

function modifier_winter_wyvern_cold_embrace_ebf:GetEffectName()
    return "particles/units/heroes/hero_winter_wyvern/wyvern_cold_embrace_buff.vpcf"
end
