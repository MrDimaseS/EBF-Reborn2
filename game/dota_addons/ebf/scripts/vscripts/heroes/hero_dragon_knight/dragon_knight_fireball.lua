dragon_knight_fireball_ebf = class({})

function dragon_knight_fireball_ebf:GetCastRange(location, target)
    if self:GetCaster():HasModifier("modifier_dragon_knight_elder_dragon_form_buff") then
        return self:GetSpecialValueFor("dragon_form_cast_range")
    else
        return self:GetSpecialValueFor("melee_cast_range")
    end
end
function dragon_knight_fireball_ebf:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
function dragon_knight_fireball_ebf:OnSpellStart()
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    local duration = self:GetSpecialValueFor("duration")

    if IsClient() then return end

    CreateModifierThinker(caster, self, "modifier_dragon_knight_fireball_thinker", { duration = duration }, point, caster:GetTeamNumber(), false)

    -- particles
    local direction = CalculateDirection(point, caster:GetAbsOrigin())
    local particle = "particles/units/heroes/hero_dragon_knight/dragon_knight_shard_fireball_cast.vpcf"
    local effect = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControl(effect, 1, caster:GetAbsOrigin())
    ParticleManager:SetParticleControlTransformForward(effect, 1, caster:GetAbsOrigin(), direction)
    ParticleManager:ReleaseParticleIndex(effect)

    -- sounds
    local sound = "Hero_DragonKnight.Fireball.Cast"
    EmitSoundOn(sound, caster)
end

modifier_dragon_knight_fireball_thinker = class({})
LinkLuaModifier( "modifier_dragon_knight_fireball_thinker", "heroes/hero_dragon_knight/dragon_knight_fireball", LUA_MODIFIER_MOTION_NONE )

function modifier_dragon_knight_fireball_thinker:IsHidden()
    return true
end
function modifier_dragon_knight_fireball_thinker:IsPurgable()
    return false
end
function modifier_dragon_knight_fireball_thinker:IsAura()
    return true
end
function modifier_dragon_knight_fireball_thinker:GetModifierAura()
    return "modifier_dragon_knight_fireball_aura"
end
function modifier_dragon_knight_fireball_thinker:GetAuraRadius()
    return self.radius
end
function modifier_dragon_knight_fireball_thinker:GetAuraDuration()
    return self.linger_duration
end
function modifier_dragon_knight_fireball_thinker:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end
function modifier_dragon_knight_fireball_thinker:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HEROES_AND_CREEPS
end
function modifier_dragon_knight_fireball_thinker:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_NONE
end
function modifier_dragon_knight_fireball_thinker:OnCreated()
    self:OnRefresh()
end
function modifier_dragon_knight_fireball_thinker:OnRefresh()
    self.radius = self:GetSpecialValueFor("radius")
    self.duration = self:GetSpecialValueFor("duration")
    self.linger_duration = self:GetSpecialValueFor("linger_duration")
    if IsClient() then return end

    for _, unit in ipairs(self:GetCaster():FindEnemyUnitsInRadius(self:GetCaster():GetAbsOrigin(), self.radius)) do
        if unit:HasModifier("modifier_dragon_knight_fireball_aura") then
            unit:RemoveModifierByName("modifier_dragon_knight_fireball_aura")
        end
    end

    -- particles
    local particle = "particles/units/heroes/hero_dragon_knight/dragon_knight_shard_fireball.vpcf"
    local effect = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN, self:GetParent())
    ParticleManager:SetParticleControl(effect, 0, self:GetParent():GetOrigin())
    ParticleManager:SetParticleControl(effect, 1, self:GetParent():GetOrigin())
    ParticleManager:SetParticleControl(effect, 2, Vector(1 + self.duration, 0, 0))
    self:AddEffect(effect)

    -- sounds
    local sound = "Hero_DragonKnight.Fireball.Target"
    EmitSoundOn(sound, self:GetParent())
end

modifier_dragon_knight_fireball_aura = class({})
LinkLuaModifier( "modifier_dragon_knight_fireball_aura", "heroes/hero_dragon_knight/dragon_knight_fireball", LUA_MODIFIER_MOTION_NONE )

function modifier_dragon_knight_fireball_aura:IsHidden()
    return false
end
function modifier_dragon_knight_fireball_aura:IsDebuff()
    return true
end
function modifier_dragon_knight_fireball_aura:IsPurgable()
    return true
end
function modifier_dragon_knight_fireball_aura:OnCreated()
    self:SetHasCustomTransmitterData(true)
    self:OnRefresh()
    self.duration = 0
    if IsClient() then return end

    self:StartIntervalThink(self.burn_interval)
end
function modifier_dragon_knight_fireball_aura:OnRefresh()
    self.damage = self:GetSpecialValueFor("damage")
    self.physical_damage_type = self:GetSpecialValueFor("physical_damage_type")
    self.magic_resist_reduction = self:GetSpecialValueFor("magic_resist_reduction")
    self.damage_per_second = self:GetSpecialValueFor("damage_per_second")
    self.armor_per_second = self:GetSpecialValueFor("armor_per_second")
    self.base_attack_time_increase = self:GetSpecialValueFor("base_attack_time_increase")
    self.freeze_delay = self:GetSpecialValueFor("freeze_delay")
    self.freeze_duration = self:GetSpecialValueFor("freeze_duration")
    self.burn_interval = self:GetSpecialValueFor("burn_interval")
end
function modifier_dragon_knight_fireball_aura:OnIntervalThink()
    self.duration = self.duration + self.burn_interval
    
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    ability:DealDamage(caster, parent, self.damage / (1.0 / self.burn_interval), { damage_type = TernaryOperator(DAMAGE_TYPE_PHYSICAL, self.physical_damage_type, DAMAGE_TYPE_MAGICAL) })

    if self.damage_per_second ~= 0 then
        ability:DealDamage(caster, parent, self.damage_per_second / (1.0 / self.burn_interval), { damage_type = DAMAGE_TYPE_PHYSICAL })
    end
    if self.freeze_delay ~= 0 and self.duration >= self.freeze_delay then
        self.duration = -self.freeze_duration
        parent:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_dragon_knight_fireball_cerulean_blood", { duration = self.freeze_duration })
    end
    
    self:SendBuffRefreshToClients()
end
function modifier_dragon_knight_fireball_aura:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_BASE_ATTACK_TIME_PERCENTAGE,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    }
end
function modifier_dragon_knight_fireball_aura:GetModifierMagicalResistanceBonus()
    return -self.magic_resist_reduction
end
function modifier_dragon_knight_fireball_aura:GetModifierBaseAttackTimePercentage()
    return -self.base_attack_time_increase
end
function modifier_dragon_knight_fireball_aura:GetModifierPhysicalArmorBonus()
    return -self.armor_per_second * self.duration
end
function modifier_dragon_knight_fireball_aura:AddCustomTransmitterData()
    return {
        duration = tonumber(self.duration)
    }
end
function modifier_dragon_knight_fireball_aura:HandleCustomTransmitterData(data)
    self.duration = tonumber(data.duration)
end

modifier_dragon_knight_fireball_cerulean_blood = class({})
LinkLuaModifier( "modifier_dragon_knight_fireball_cerulean_blood", "heroes/hero_dragon_knight/dragon_knight_fireball", LUA_MODIFIER_MOTION_NONE )

function modifier_dragon_knight_fireball_cerulean_blood:IsHidden()
    return false
end
function modifier_dragon_knight_fireball_cerulean_blood:IsDebuff()
    return true
end
function modifier_dragon_knight_fireball_cerulean_blood:IsStunDebuff()
    return true
end
function modifier_dragon_knight_fireball_cerulean_blood:IsPurgable()
    return true
end
function modifier_dragon_knight_fireball_cerulean_blood:GetEffectName()
    return "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf"
end
function modifier_dragon_knight_fireball_cerulean_blood:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
function modifier_dragon_knight_fireball_cerulean_blood:OnCreated()
    if IsClient() then return end

    -- sounds
    local sound = "hero_Crystal.frostbite"
    EmitSoundOn(sound, self:GetParent())
end
function modifier_dragon_knight_fireball_cerulean_blood:OnDestroy()
    if IsClient() then return end

    -- sounds
    local sound = "hero_Crystal.frostbite"
    StopSoundOn(sound, self:GetParent())
end
function modifier_dragon_knight_fireball_cerulean_blood:CheckState()
    return {
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_FROZEN] = true,
        [MODIFIER_STATE_INVISIBLE] = false
    }
end