juggernaut_blade_fury = class({})

function juggernaut_blade_fury:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")

    local disarm = self:GetSpecialValueFor("disarm")
    caster:Dispel(caster, nil)
    caster:AddNewModifier(caster, self, "modifier_juggernaut_blade_fury_ebf_caster", {duration = duration})
    caster:AddNewModifier(caster, self, "modifier_juggernaut_blade_fury_ebf_handler", {duration = duration})
    if disarm ~= 0 then
        caster:AddNewModifier(caster, self, "modifier_juggernaut_blade_fury_ronin", {duration = duration})
    end
end

modifier_juggernaut_blade_fury_ebf_caster = class({})
LinkLuaModifier("modifier_juggernaut_blade_fury_ebf_caster", "heroes/hero_juggernaut/juggernaut_blade_fury", LUA_MODIFIER_MOTION_NONE)

function modifier_juggernaut_blade_fury_ebf_caster:IsHidden()
    return true
end

function modifier_juggernaut_blade_fury_ebf_caster:CheckState()
    return
    {
        [MODIFIER_STATE_DISARMED] = self.is_disarmed,
        [MODIFIER_STATE_DEBUFF_IMMUNE] = true,
        [MODIFIER_STATE_INVULNERABLE] = self.invuln,
        [MODIFIER_STATE_NO_HEALTH_BAR] = self.invuln
    }
end
function modifier_juggernaut_blade_fury_ebf_caster:OnCreated()
    local caster = self:GetCaster()
    self.omni_slash = caster:FindAbilityByName("juggernaut_omni_slash")
    self.swift_slash = caster:FindAbilityByName("juggernaut_swift_slash")
    EmitSoundOn("Hero_Juggernaut.BladeFuryStart", self:GetParent())

    if IsServer() then
        if caster:HasAbility("juggernaut_swift_slash") then
            self.omni_slash:SetActivated(false)
            self.swift_slash:SetActivated(false)
        else
            self.omni_slash:SetActivated(false)
        end
    end

    local disarm = self:GetSpecialValueFor("disarm")
    if disarm ~= 0 then
        self.is_disarmed = true
    else
        self.is_disarmed = false
    end

    local invuln = self:GetSpecialValueFor("invulnerability")
    if invuln ~= 0 then
        self.invuln = true
    else
        self.invuln = false
    end
end
function modifier_juggernaut_blade_fury_ebf_caster:OnDestroy()
    local parent = self:GetParent()
    if IsServer() then
        if parent:HasAbility("juggernaut_swift_slash") then
            self.omni_slash:SetActivated(true)
            self.swift_slash:SetActivated(true)
        else
            self.omni_slash:SetActivated(true)
        end
    end
    StopSoundOn("Hero_Juggernaut.BladeFuryStart", self:GetParent())
end

modifier_juggernaut_blade_fury_ebf_handler = class({})
LinkLuaModifier("modifier_juggernaut_blade_fury_ebf_handler", "heroes/hero_juggernaut/juggernaut_blade_fury", LUA_MODIFIER_MOTION_NONE)

function modifier_juggernaut_blade_fury_ebf_handler:OnCreated()
    self.radius = self:GetSpecialValueFor("radius")
    self.damage = self:GetSpecialValueFor("blade_fury_damage")

    if IsServer() then
        local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_juggernaut/juggernaut_blade_fury.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
        ParticleManager:SetParticleControl(nfx, 5, (Vector(self.radius + 100,0,0)))
        self:AddEffect(nfx)
        self:StartIntervalThink(0.2)
    end
end

function modifier_juggernaut_blade_fury_ebf_handler:OnIntervalThink()
    local caster = self:GetParent()
    local mods = self:GetSpecialValueFor("applies_modifiers")
    for _, units in ipairs(caster:FindEnemyUnitsInRadius(caster:GetAbsOrigin(), self.radius)) do
        self:GetAbility():DealDamage(caster, units, self.damage)
        if mods ~= 0 then
            caster:PerformAttack(units, false, true, true, false, false, true, true)
        end
        EmitSoundOn("Hero_Juggernaut.BladeFury.Impact", units)
    end
end

function modifier_juggernaut_blade_fury_ebf_handler:OnDestroy()
    self:StartIntervalThink(-1)
end

function modifier_juggernaut_blade_fury_ebf_handler:IsBuff()
    return true
end

function modifier_juggernaut_blade_fury_ebf_handler:IsPurgable()
    return false
end

function modifier_juggernaut_blade_fury_ebf_handler:GetTextureName()
    return "juggernaut_blade_fury"
end

modifier_juggernaut_blade_fury_ronin = class({})
LinkLuaModifier("modifier_juggernaut_blade_fury_ronin", "heroes/hero_juggernaut/juggernaut_blade_fury", LUA_MODIFIER_MOTION_NONE)

function modifier_juggernaut_blade_fury_ronin:IsHidden()
    return true
end

function modifier_juggernaut_blade_fury_ronin:OnCreated()
    self.radius = self:GetSpecialValueFor("radius")
end

function modifier_juggernaut_blade_fury_ronin:IsAura()
    return true
end

function modifier_juggernaut_blade_fury_ronin:GetAuraRadius()
    return self.radius
end

function modifier_juggernaut_blade_fury_ronin:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_juggernaut_blade_fury_ronin:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HEROES_AND_CREEPS
end

function modifier_juggernaut_blade_fury_ronin:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_juggernaut_blade_fury_ronin:GetModifierAura()
	return "modifier_juggernaut_blade_fury_ronin_aura"
end

modifier_juggernaut_blade_fury_ronin_aura = class({})
LinkLuaModifier("modifier_juggernaut_blade_fury_ronin_aura", "heroes/hero_juggernaut/juggernaut_blade_fury", LUA_MODIFIER_MOTION_NONE)

function modifier_juggernaut_blade_fury_ronin_aura:IsDebuff()
    return true
end

function modifier_juggernaut_blade_fury_ronin_aura:IsPurgable()
    return false
end

function modifier_juggernaut_blade_fury_ronin_aura:OnCreated()
    self.mspd_slow = self:GetSpecialValueFor("mspd_slow")
    self.aspd_slow = self:GetSpecialValueFor("aspd_slow")
end

function modifier_juggernaut_blade_fury_ronin_aura:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
end

function modifier_juggernaut_blade_fury_ronin_aura:GetModifierMoveSpeedBonus_Percentage()
    return -self.mspd_slow
end

function modifier_juggernaut_blade_fury_ronin_aura:GetModifierAttackSpeedBonus_Constant()
    return -self.aspd_slow
end