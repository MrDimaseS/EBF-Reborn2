magnataur_reverse_polarity = class({})

function magnataur_reverse_polarity:GetBehavior()
    if self:GetSpecialValueFor("avenger") == 0 then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_AUTOCAST
    else
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET
    end
end
function magnataur_reverse_polarity:OnAbilityPhaseStart()
    local caster = self:GetCaster()
    local radius = self:GetSpecialValueFor("pull_radius")
    local cast_point = self:GetCastPoint()

    local rrp = self:GetSpecialValueFor("avenger") == 0 and self:GetAutoCastState()
    if rrp then
        radius = self:GetSpecialValueFor("push")
    end

    -- particles
    local particle = TernaryOperator("particles/units/heroes/hero_magnataur/magnataur_reverse_polarity_push.vpcf", rrp, "particles/units/heroes/hero_magnataur/magnataur_reverse_polarity.vpcf")
    self.effect = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(self.effect, 1, Vector(radius, radius, radius))
    ParticleManager:SetParticleControl(self.effect, 2, Vector(cast_point, 0, 0))
    ParticleManager:SetParticleControlEnt(
        self.effect,
        3,
        caster,
        PATTACH_ABSORIGIN_FOLLOW,
        "attach_hitloc",
        Vector(),
        true
    )

    -- sounds
    self.sound = "Hero_Magnataur.ReversePolarity.Anim"
    EmitSoundOn(self.sound, caster)
end
function magnataur_reverse_polarity:OnAbilityPhaseInterrupted()
    self:StopEffects(true)
end
function magnataur_reverse_polarity:OnSpellStart()
    self:StopEffects(false)

    local caster = self:GetCaster()
    local radius = self:GetSpecialValueFor("pull_radius")
    local damage = self:GetSpecialValueFor("polarity_damage")
    local duration = self:GetSpecialValueFor("hero_stun_duration")
    local offset = self:GetSpecialValueFor("forward_offset")

    local hero_stat_stacks = self:GetSpecialValueFor("hero_stat_stacks")
    local creep_stat_stacks = self:GetSpecialValueFor("creep_stat_stacks")
    local stat_buff_duration = self:GetSpecialValueFor("stat_buff_duration")
    local stat_modifier = nil
    
    local avenger = self:GetSpecialValueFor("avenger") ~= 0
    local guardian = not avenger
    local buff_duration = self:GetSpecialValueFor("buff_duration")
    local rrp = guardian and self:GetAutoCastState()
    if rrp then
        radius = self:GetSpecialValueFor("push")
    end
    local push_duration = self:GetSpecialValueFor("push_duration")
    local max_knockback = self:GetSpecialValueFor("max_knockback")
    print(push_duration)

    if stat_buff_duration ~= 0 then
        stat_modifier = caster:AddNewModifier(caster, self, "modifier_magnataur_reverse_polarity_stats", { duration = stat_buff_duration })
    end
    if avenger then
        caster:AddNewModifier(caster, self, "modifier_magnataur_reverse_polarity_buff", { duration = buff_duration })
    end

    local enemies = caster:FindEnemyUnitsInRadius(caster:GetAbsOrigin(), radius)
    for _, enemy in ipairs(enemies) do
        local old_location = enemy:GetOrigin()
        local position = caster:GetOrigin() + caster:GetForwardVector() * offset
        if rrp then
            local distance = math.min(radius, max_knockback - CalculateDistance(position, old_location))
            enemy:ApplyKnockBack(position, push_duration, push_duration, distance, 0, caster, self)
        else
            FindClearSpaceForUnit(enemy, position, true)
        end

        self:DealDamage(caster, enemy, damage)
        self:Stun(enemy, duration)

        if stat_buff_duration ~= 0 and stat_modifier then
            stat_modifier:SetStackCount(stat_modifier:GetStackCount() + TernaryOperator(hero_stat_stacks, enemy:IsConsideredHero(), creep_stat_stacks))
        end
        if guardian then
            enemy:AddNewModifier(caster, self, "modifier_magnataur_reverse_polarity_buff", { duration = buff_duration, invert = true })
        end

        -- particles
        local particle = "particles/units/heroes/hero_magnataur/magnataur_reverse_polarity_pull.vpcf"
        local effect = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, enemy)
        ParticleManager:SetParticleControl(effect, 1, old_location)
        ParticleManager:ReleaseParticleIndex(effect)

        -- sounds
        local sound = "Hero_Magnataur.ReversePolarity.Stun"
        EmitSoundOn(sound, enemy)
    end

    -- sounds
    local sound = "Hero_Magnataur.ReversePolarity.Cast"
    EmitSoundOn(sound, caster)
end
function magnataur_reverse_polarity:StopEffects(immediately)
    -- particles
    ParticleManager:DestroyParticle(self.effect, immediately)
    ParticleManager:ReleaseParticleIndex(self.effect)

    -- sounds
    StopSoundOn(self.sound, self:GetCaster())
end

modifier_magnataur_reverse_polarity_stats = class({})
LinkLuaModifier( "modifier_magnataur_reverse_polarity_stats", "heroes/hero_magnus/magnataur_reverse_polarity", LUA_MODIFIER_MOTION_NONE )

function modifier_magnataur_reverse_polarity_stats:IsHidden()
    return false
end
function modifier_magnataur_reverse_polarity_stats:IsDebuff()
    return false
end
function modifier_magnataur_reverse_polarity_stats:IsPurgable()
    return false
end
function modifier_magnataur_reverse_polarity_stats:DeclareFunctions()
    return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS
    }
end
function modifier_magnataur_reverse_polarity_stats:GetModifierBonusStats_Strength()
	return self:GetStackCount()
end
function modifier_magnataur_reverse_polarity_stats:GetModifierBonusStats_Intellect()
	return self:GetStackCount()
end
function modifier_magnataur_reverse_polarity_stats:GetModifierBonusStats_Agility()
	return self:GetStackCount()
end

modifier_magnataur_reverse_polarity_buff = class({})
LinkLuaModifier( "modifier_magnataur_reverse_polarity_buff", "heroes/hero_magnus/magnataur_reverse_polarity", LUA_MODIFIER_MOTION_NONE )

function modifier_magnataur_reverse_polarity_buff:IsHidden()
    return false
end
function modifier_magnataur_reverse_polarity_buff:IsDebuff()
    return false
end
function modifier_magnataur_reverse_polarity_buff:IsPurgable()
    return false
end
function modifier_magnataur_reverse_polarity_buff:OnCreated()
    self:OnRefresh()
end
function modifier_magnataur_reverse_polarity_buff:OnRefresh()
    self.invert = TernaryOperator(-1, self:GetParent():GetTeamNumber() ~= self:GetCaster():GetTeamNumber(), 1)
    self.armor = self:GetSpecialValueFor("armor")
    self.attack_speed = self:GetSpecialValueFor("attack_speed")
end
function modifier_magnataur_reverse_polarity_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
end
function modifier_magnataur_reverse_polarity_buff:GetModifierPhysicalArmorBonus()
    return self.armor * self.invert
end
function modifier_magnataur_reverse_polarity_buff:GetModifierAttackSpeedBonus_Constant()
    return self.attack_speed * self.invert
end