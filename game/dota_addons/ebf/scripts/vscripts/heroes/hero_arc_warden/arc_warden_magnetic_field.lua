arc_warden_magnetic_field = class({})

function arc_warden_magnetic_field:GetBehavior()
    if self:GetSpecialValueFor("attack_range") ~= 0 then
        return self.BaseClass.GetBehavior( self )
    else
        return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE
    end
end

function arc_warden_magnetic_field:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function arc_warden_magnetic_field:OnSpellStart()
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    local duration = self:GetSpecialValueFor("duration")

    if self:GetSpecialValueFor("attack_range") ~= 0 then
        CreateModifierThinker(caster, self, "modifier_arc_warden_magnetic_field_disunity", {duration = duration}, caster:GetAbsOrigin(), caster:GetTeam(), false)
    else
        CreateModifierThinker(caster, self, "modifier_arc_warden_magnetic_field_unity", {duration = duration}, point, caster:GetTeam(), false)
    end

    EmitSoundOn("Hero_ArcWarden.MagneticField.Cast", caster)
    ParticleManager:CreateParticle("particles/units/heroes/hero_arc_warden/arc_warden_magnetic_cast.vpcf", PATTACH_POINT, caster)
end

-----------------------------------------------------------------------------------------------------------------------------------------

modifier_arc_warden_magnetic_field_disunity = class({})
LinkLuaModifier( "modifier_arc_warden_magnetic_field_disunity", "heroes/hero_arc_warden/arc_warden_magnetic_field", LUA_MODIFIER_MOTION_NONE)

function modifier_arc_warden_magnetic_field_disunity:OnCreated()
    local parent = self:GetParent()
    self.radius = self:GetSpecialValueFor("radius")

    if IsServer() then
        local caster = self:GetCaster()
        local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_arc_warden/arc_warden_magnetic.vpcf", PATTACH_POINT, caster)
                ParticleManager:SetParticleControl(nfx, 0, parent:GetAbsOrigin())
                ParticleManager:SetParticleControl(nfx, 1, Vector(self.radius,self.radius,self.radius))
        self:AttachEffect(nfx)
    end
end

function modifier_arc_warden_magnetic_field_disunity:IsAura()
    return true
end

function modifier_arc_warden_magnetic_field_disunity:GetAuraRadius()
    return self.radius - 20
end

function modifier_arc_warden_magnetic_field_disunity:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_arc_warden_magnetic_field_disunity:GetAuraSearchType()
	return DOTA_UNIT_TARGET_ALL
end

function modifier_arc_warden_magnetic_field_disunity:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS
end

function modifier_arc_warden_magnetic_field_disunity:GetModifierAura()
	return "modifier_arc_warden_magnetic_field_buff"
end

modifier_arc_warden_magnetic_field_buff = class({})
LinkLuaModifier("modifier_arc_warden_magnetic_field_buff", "heroes/hero_arc_warden/arc_warden_magnetic_field", LUA_MODIFIER_MOTION_NONE)

function modifier_arc_warden_magnetic_field_buff:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_arc_warden_magnetic_field_buff:IsBuff()
    return true
end

function modifier_arc_warden_magnetic_field_buff:IsPurgable()
    return false
end

function modifier_arc_warden_magnetic_field_buff:OnCreated()
    self.bonus_aspd = self:GetSpecialValueFor("attack_speed_bonus")
    self.evasion = self:GetSpecialValueFor("evasion_chance")
    self.projectile_speed = self:GetSpecialValueFor("projectile_speed_bonus")
    self.attack_range = self:GetSpecialValueFor("attack_range")
    self.bonus_mres = self:GetSpecialValueFor("bonus_mres")
end

function modifier_arc_warden_magnetic_field_buff:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_EVASION_CONSTANT,
        MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
        MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
    }
end

function modifier_arc_warden_magnetic_field_buff:GetModifierAttackSpeedBonus_Constant()
    return self.bonus_aspd
end

function modifier_arc_warden_magnetic_field_buff:GetModifierEvasion_Constant()
    return self.evasion
end

function modifier_arc_warden_magnetic_field_buff:GetModifierProjectileSpeedBonus()
    return self.projectile_speed
end

function modifier_arc_warden_magnetic_field_buff:GetModifierAttackRangeBonus()
    return self.attack_range
end

function modifier_arc_warden_magnetic_field_buff:GetModifierMagicalResistanceBonus()
    return self.bonus_mres
end

-----------------------------------------------------------------------------------------------------------------------------------------

modifier_arc_warden_magnetic_field_unity = class({})
LinkLuaModifier("modifier_arc_warden_magnetic_field_unity", "heroes/hero_arc_warden/arc_warden_magnetic_field", LUA_MODIFIER_MOTION_NONE)

function modifier_arc_warden_magnetic_field_unity:OnCreated()
    local parent = self:GetParent()
    self.radius = self:GetSpecialValueFor("radius")

    if IsServer() then
        local caster = self:GetCaster()
        local nfx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_arc_warden/arc_warden_magnetic_tempest.vpcf", PATTACH_POINT, caster)
                ParticleManager:SetParticleControl(nfx1, 0, parent:GetAbsOrigin())
                ParticleManager:SetParticleControl(nfx1, 1, Vector(self.radius,self.radius,self.radius))
        self:AttachEffect(nfx1)
    end
end

function modifier_arc_warden_magnetic_field_unity:IsAura()
    return true
end

function modifier_arc_warden_magnetic_field_unity:GetAuraRadius()
    return self.radius
end

function modifier_arc_warden_magnetic_field_unity:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_arc_warden_magnetic_field_unity:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HEROES_AND_CREEPS
end

function modifier_arc_warden_magnetic_field_unity:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_arc_warden_magnetic_field_unity:GetModifierAura()
	return "modifier_arc_warden_magnetic_field_debuff"
end


modifier_arc_warden_magnetic_field_debuff = class({})
LinkLuaModifier("modifier_arc_warden_magnetic_field_debuff", "heroes/hero_arc_warden/arc_warden_magnetic_field", LUA_MODIFIER_MOTION_NONE)

function modifier_arc_warden_magnetic_field_debuff:IsDebuff()
    return true
end

function modifier_arc_warden_magnetic_field_debuff:IsPurgable()
    return false
end

function modifier_arc_warden_magnetic_field_debuff:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
    }
end

function modifier_arc_warden_magnetic_field_debuff:OnCreated()
    self.mres_reduction = self:GetSpecialValueFor("mres_reduction")
end

function modifier_arc_warden_magnetic_field_debuff:CheckState()
    return
    {
        [MODIFIER_STATE_ROOTED] = true
    }
end

function modifier_arc_warden_magnetic_field_debuff:GetModifierMagicalResistanceBonus()
    return -self.mres_reduction
end

function modifier_arc_warden_magnetic_field_debuff:GetEffectName()
    return "particles/items3_fx/gleipnir_root.vpcf"
end