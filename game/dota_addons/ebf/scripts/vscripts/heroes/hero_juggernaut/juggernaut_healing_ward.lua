juggernaut_healing_ward = class({})

function juggernaut_healing_ward:Precache(context)
    PrecacheResource("particle", "particles/econ/items/venomancer/veno_2022_immortal_tail/veno_2022_immortal_poison_nova_shockwave_pulse.vpcf", context)
end

function juggernaut_healing_ward:OnSpellStart()
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    local duration = 25
    self:SpawnWard(point, duration)
    EmitSoundOn("Hero_Juggernaut.HealingWard.Cast", caster)
end

function juggernaut_healing_ward:SpawnWard(position, duration)
    local caster = self:GetCaster()
    local ward = caster:CreateSummon("npc_dota_juggernaut_healing_ward", position, duration)

    FindClearSpaceForUnit(ward, position, true)
    local mspd = self:GetSpecialValueFor("healing_ward_movespeed_tooltip")
    ward:SetBaseMoveSpeed(mspd)

    ward:AddNewModifier(caster, self, "modifier_juggernaut_healing_ward_handler", {duration})
    ward:AddNewModifier(caster, self, "modifier_juggernaut_healing_ward_ebf_aura", {duration})

    local negative_aura = self:GetSpecialValueFor("negative_aura")
    if negative_aura ~= 0 then
        ward:AddNewModifier(caster, self, "modifier_juggernaut_healing_ward_ebf_ronin_aura", {duration})
    end
    return ward
end


----------------------------------------------------------------------------------------------------------------------------------------
modifier_juggernaut_healing_ward_handler = class({})
LinkLuaModifier("modifier_juggernaut_healing_ward_handler", "heroes/hero_juggernaut/juggernaut_healing_ward", LUA_MODIFIER_MOTION_NONE)

function modifier_juggernaut_healing_ward_handler:IsHidden()
    return true
end
function modifier_juggernaut_healing_ward_handler:CheckState()
    return
    {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_PROVIDES_VISION] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true
    }
end

function modifier_juggernaut_healing_ward_handler:OnCreated()
    self.pulse_interval = self:GetSpecialValueFor("pulse_interval")
    self.parent = self:GetParent()
    local radius = self:GetSpecialValueFor("healing_ward_aura_radius")

    local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_juggernaut/juggernaut_healing_ward.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
    ParticleManager:SetParticleControl(nfx, 1, Vector(radius, 0, radius))
    ParticleManager:ReleaseParticleIndex(nfx)
    EmitSoundOn("Hero_Juggernaut.HealingWard.Loop", self:GetParent())

    if self.pulse_interval ~= 0 then
        self:StartIntervalThink(self.pulse_interval)
    end
end

function modifier_juggernaut_healing_ward_handler:OnIntervalThink()
    if IsServer() then
        local caster = self:GetCaster()
        local radius = self:GetSpecialValueFor("healing_ward_aura_radius")
        local sohei_duration = self:GetSpecialValueFor("bonus_aspd_duration")
        local allies = caster:FindFriendlyUnitsInRadius(self.parent:GetAbsOrigin(), radius)

        ParticleManager:CreateParticle("particles/econ/items/venomancer/veno_2022_immortal_tail/veno_2022_immortal_poison_nova_shockwave_pulse.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
        for _, units in ipairs(allies) do
            units:AddNewModifier(self.parent, self:GetAbility(), "modifier_juggernaut_healing_ward_ebf_sohei", {duration = sohei_duration})
        end
    end
end

function modifier_juggernaut_healing_ward_handler:OnDestroy()
    self:StartIntervalThink(-1)
    EmitSoundOn("Hero_Juggernaut.HealingWard.Stop", self:GetParent())
end

modifier_juggernaut_healing_ward_ebf_aura = class({})
LinkLuaModifier("modifier_juggernaut_healing_ward_ebf_aura", "heroes/hero_juggernaut/juggernaut_healing_ward", LUA_MODIFIER_MOTION_NONE)
function modifier_juggernaut_healing_ward_ebf_aura:IsHidden()
    return true
end

function modifier_juggernaut_healing_ward_ebf_aura:OnCreated()
    self:OnRefresh()
end

function modifier_juggernaut_healing_ward_ebf_aura:OnRefresh()
    self.radius = self:GetSpecialValueFor("healing_ward_aura_radius")
end

function modifier_juggernaut_healing_ward_ebf_aura:IsAura()
    return true
end

function modifier_juggernaut_healing_ward_ebf_aura:GetAuraRadius()
    return self.radius
end

function modifier_juggernaut_healing_ward_ebf_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_juggernaut_healing_ward_ebf_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_ALL
end

function modifier_juggernaut_healing_ward_ebf_aura:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS
end

function modifier_juggernaut_healing_ward_ebf_aura:GetModifierAura()
    return "modifier_juggernaut_healing_ward_ebf_heal"
end

modifier_juggernaut_healing_ward_ebf_heal = class({})
LinkLuaModifier("modifier_juggernaut_healing_ward_ebf_heal", "heroes/hero_juggernaut/juggernaut_healing_ward", LUA_MODIFIER_MOTION_NONE)

function modifier_juggernaut_healing_ward_ebf_heal:IsBuff()
    return true
end
function modifier_juggernaut_healing_ward_ebf_heal:GetTextureName()
    return "juggernaut_healing_ward"
end

function modifier_juggernaut_healing_ward_ebf_heal:OnCreated()
    self:OnRefresh()
end

function modifier_juggernaut_healing_ward_ebf_heal:OnRefresh()
    self.heal_pct = self:GetSpecialValueFor("healing_ward_heal_amount")
    self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
    self.bonus_mres = self:GetSpecialValueFor("bonus_mres")
    self:StartIntervalThink(0)
end

function modifier_juggernaut_healing_ward_ebf_heal:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local heal_pct = self:GetSpecialValueFor("healing_ward_heal_amount") / 100

    local maxHP = parent:GetMaxHealth()
    local preHP = parent:GetHealth()
    if preHP < maxHP and IsServer() then
        local heal_amt = (maxHP * heal_pct) / 30
        parent:Heal(heal_amt, ability)
    end
end

function modifier_juggernaut_healing_ward_ebf_heal:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
    }
end

function modifier_juggernaut_healing_ward_ebf_heal:GetModifierPhysicalArmorBonus()
    if self.bonus_mres ~= 0 then
        return self.bonus_armor
    end
end

function modifier_juggernaut_healing_ward_ebf_heal:GetModifierMagicalResistanceBonus()
    if self.bonus_mres ~= 0 then
        return self.bonus_mres
    end
end


----------------------------------------------------------------------------------------------------------------------------------------
modifier_juggernaut_healing_ward_ebf_sohei = class({})
LinkLuaModifier("modifier_juggernaut_healing_ward_ebf_sohei", "heroes/hero_juggernaut/juggernaut_healing_ward", LUA_MODIFIER_MOTION_NONE)

function modifier_juggernaut_healing_ward_ebf_sohei:IsPurgable()
    return true
end

function modifier_juggernaut_healing_ward_ebf_sohei:OnCreated()
    self.bonus_aspd = self:GetSpecialValueFor("bonus_aspd")
    self.bonus_outgoing = self:GetSpecialValueFor("bonus_outgoing")
end

function modifier_juggernaut_healing_ward_ebf_sohei:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
    }
end

function modifier_juggernaut_healing_ward_ebf_sohei:GetModifierAttackSpeedBonus_Constant()
    return self.bonus_aspd
end

function modifier_juggernaut_healing_ward_ebf_sohei:GetModifierTotalDamageOutgoing_Percentage()
    return self.bonus_outgoing
end

----------------------------------------------------------------------------------------------------------------------------------------
modifier_juggernaut_healing_ward_ebf_ronin_aura = class({})
LinkLuaModifier("modifier_juggernaut_healing_ward_ebf_ronin_aura", "heroes/hero_juggernaut/juggernaut_healing_ward", LUA_MODIFIER_MOTION_NONE)

function modifier_juggernaut_healing_ward_ebf_ronin_aura:IsHidden()
    return true
end

function modifier_juggernaut_healing_ward_ebf_ronin_aura:OnCreated()
    self:OnRefresh()
end

function modifier_juggernaut_healing_ward_ebf_ronin_aura:OnRefresh()
    self.radius = self:GetSpecialValueFor("healing_ward_aura_radius")
end

function modifier_juggernaut_healing_ward_ebf_ronin_aura:IsAura()
    return true
end

function modifier_juggernaut_healing_ward_ebf_ronin_aura:GetAuraRadius()
    return self.radius
end

function modifier_juggernaut_healing_ward_ebf_ronin_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_juggernaut_healing_ward_ebf_ronin_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_ALL
end

function modifier_juggernaut_healing_ward_ebf_ronin_aura:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS
end

function modifier_juggernaut_healing_ward_ebf_ronin_aura:GetModifierAura()
    return "modifier_juggernaut_healing_ward_ebf_ronin"
end

modifier_juggernaut_healing_ward_ebf_ronin = class({})
LinkLuaModifier("modifier_juggernaut_healing_ward_ebf_ronin", "heroes/hero_juggernaut/juggernaut_healing_ward", LUA_MODIFIER_MOTION_NONE)

function modifier_juggernaut_healing_ward_ebf_ronin:IsDebuff()
    return true
end

function modifier_juggernaut_healing_ward_ebf_ronin:GetTextureName()
    return "juggernaut_healing_ward"
end

function modifier_juggernaut_healing_ward_ebf_ronin:OnCreated()
    self:OnRefresh()
end

function modifier_juggernaut_healing_ward_ebf_ronin:OnRefresh()
    self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
    self.bonus_mres = self:GetSpecialValueFor("bonus_mres")
end

function modifier_juggernaut_healing_ward_ebf_ronin:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
    }
end

function modifier_juggernaut_healing_ward_ebf_ronin:GetModifierPhysicalArmorBonus()
    return -self.bonus_armor
end

function modifier_juggernaut_healing_ward_ebf_ronin:GetModifierMagicalResistanceBonus()
    return -self.bonus_mres
end