doom_bringer_doom = class({})

function doom_bringer_doom:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")
    local self_cast = self:GetSpecialValueFor("radius") ~= 0

    if self_cast then
        caster:AddNewModifier(caster, self, "modifier_doom_bringer_doom_aura", { duration = duration })
    else
        local target = self:GetCursorTarget()
        if target:TriggerSpellAbsorb(self) then return end
        target:AddNewModifier(caster, self, "modifier_doom_bringer_doom_ebf", { duration = duration })
    end
end

modifier_doom_bringer_doom_ebf = class({})
LinkLuaModifier( "modifier_doom_bringer_doom_ebf", "heroes/hero_doom/doom_bringer_doom", LUA_MODIFIER_MOTION_NONE )

function modifier_doom_bringer_doom_ebf:IsHidden()
    return false
end
function modifier_doom_bringer_doom_ebf:IsDebuff()
    return true
end
function modifier_doom_bringer_doom_ebf:IsPurgable()
    return false
end
function modifier_doom_bringer_doom_ebf:GetStatusEffectName()
    return "particles/status_fx/status_effect_doom.vpcf"
end
function modifier_doom_bringer_doom_ebf:GetStatusEffectPriority()
    return MODIFIER_PRIORITY_SUPER_ULTRA
end
function modifier_doom_bringer_doom_ebf:GetEffectName()
	return "particles/units/heroes/hero_doom_bringer/doom_bringer_doom.vpcf"
end
function modifier_doom_bringer_doom_ebf:OnCreated()
    self:OnRefresh()
    if IsClient() then return end

    self:StartIntervalThink(1.0)

    -- sounds
    local sound = "Hero_DoomBringer.Doom"
    EmitSoundOn(sound, self:GetParent())
end
function modifier_doom_bringer_doom_ebf:OnRefresh()
    self.damage = self:GetSpecialValueFor("damage")
    self.does_break = self:GetSpecialValueFor("does_break")
    self.does_mute = self:GetSpecialValueFor("does_mute")
    
    self.armor_loss = self:GetSpecialValueFor("armor_loss")
    self.magic_resist_loss = self:GetSpecialValueFor("magic_resist_loss")
end
function modifier_doom_bringer_doom_ebf:OnDestroy()
    if IsClient() then return end

    -- sounds
    local sound = "Hero_DoomBringer.Doom"
    StopSoundOn(sound, self:GetParent())
end
function modifier_doom_bringer_doom_ebf:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    if ability then
        ability:DealDamage(caster, parent, self.damage, { damage_type = DAMAGE_TYPE_PURE })
    else
        self:Destroy()
    end
end
function modifier_doom_bringer_doom_ebf:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
    }
end
function modifier_doom_bringer_doom_ebf:GetModifierPhysicalArmorBonus()
    return -self.armor_loss
end
function modifier_doom_bringer_doom_ebf:GetModifierMagicalResistanceBonus()
    return -self.magic_resist_loss
end
function modifier_doom_bringer_doom_ebf:CheckState()
    return {
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_MUTED] = self.does_mute,
		[MODIFIER_STATE_PASSIVES_DISABLED] = self.does_break
    }
end

modifier_doom_bringer_doom_aura = class({})
LinkLuaModifier( "modifier_doom_bringer_doom_aura", "heroes/hero_doom/doom_bringer_doom", LUA_MODIFIER_MOTION_NONE )

function modifier_doom_bringer_doom_aura:IsHidden()
    return false
end
function modifier_doom_bringer_doom_aura:IsDebuff()
    return false
end
function modifier_doom_bringer_doom_aura:IsPurgable()
    return false
end
function modifier_doom_bringer_doom_aura:IsAura()
	return true
end
function modifier_doom_bringer_doom_aura:GetModifierAura()
	return "modifier_doom_bringer_doom_aura_debuff"
end
function modifier_doom_bringer_doom_aura:GetAuraRadius()
	return self.radius
end
function modifier_doom_bringer_doom_aura:GetAuraDuration()
	return self.linger_duration
end
function modifier_doom_bringer_doom_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end
function modifier_doom_bringer_doom_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HEROES_AND_CREEPS
end
function modifier_doom_bringer_doom_aura:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NONE
end
function modifier_doom_bringer_doom_aura:GetEffectName()
    return "particles/units/heroes/hero_doom_bringer/doom_bringer_doom_aura.vpcf"
end
function modifier_doom_bringer_doom_aura:OnCreated()
    self:OnRefresh()
    if IsClient() then return end

    -- sounds
    local sound = "Hero_DoomBringer.Doom"
    EmitSoundOn(sound, self:GetParent())
end
function modifier_doom_bringer_doom_aura:OnRefresh()
    self.radius = self:GetSpecialValueFor("radius")
    self.linger_duration = self:GetSpecialValueFor("linger_duration")
end
function modifier_doom_bringer_doom_aura:OnDestroy()
    if IsClient() then return end

    -- sounds
    local sound = "Hero_DoomBringer.Doom"
    StopSoundOn(sound, self:GetParent())
end

modifier_doom_bringer_doom_aura_debuff = class({})
LinkLuaModifier( "modifier_doom_bringer_doom_aura_debuff", "heroes/hero_doom/doom_bringer_doom", LUA_MODIFIER_MOTION_NONE )

function modifier_doom_bringer_doom_aura_debuff:IsHidden()
    return false
end
function modifier_doom_bringer_doom_aura_debuff:IsDebuff()
    return true
end
function modifier_doom_bringer_doom_aura_debuff:IsPurgable()
    return false
end
function modifier_doom_bringer_doom_aura_debuff:GetStatusEffectName()
    return "particles/status_fx/status_effect_doom.vpcf"
end
function modifier_doom_bringer_doom_aura_debuff:GetStatusEffectPriority()
    return MODIFIER_PRIORITY_SUPER_ULTRA
end
function modifier_doom_bringer_doom_aura_debuff:OnCreated()
    self:OnRefresh()
    if IsClient() then return end

    self:StartIntervalThink(1.0)
end
function modifier_doom_bringer_doom_aura_debuff:OnRefresh()
    self.damage = self:GetSpecialValueFor("damage")
    self.does_break = self:GetSpecialValueFor("does_break")
    self.does_mute = self:GetSpecialValueFor("does_mute")
end
function modifier_doom_bringer_doom_aura_debuff:OnIntervalThink()
    local caster = self:GetCaster()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    if ability then
        ability:DealDamage(caster, parent, self.damage, { damage_type = DAMAGE_TYPE_PURE })
    else
        self:Destroy()
    end
end
function modifier_doom_bringer_doom_aura_debuff:CheckState()
    return {
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_MUTED] = self.does_mute,
		[MODIFIER_STATE_PASSIVES_DISABLED] = self.does_break
    }
end