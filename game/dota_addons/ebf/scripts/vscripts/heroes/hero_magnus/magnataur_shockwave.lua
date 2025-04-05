magnataur_shockwave = class({})

function magnataur_shockwave:OnAbilityPhaseStart()
    if IsClient() then return end

    -- particles
    local caster = self:GetCaster()
    local particle = "particles/units/heroes/hero_magnataur/magnataur_shockwave_cast.vpcf"
    local effect = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(
        effect,
        1,
        caster,
        PATTACH_POINT_FOLLOW,
        "attach_attack1",
        Vector(),
        true
    )
    self.effect = effect

    -- sounds
    local sound = "Hero_Magnataur.ShockWave.Cast"
    EmitSoundOn(sound, caster)
end
function magnataur_shockwave:OnAbilityPhaseInterrupted()
    if IsClient() then return end

    -- particles
    ParticleManager:DestroyParticle(self.effect, true)
    ParticleManager:ReleaseParticleIndex(self.effect)

    -- sounds
    local sound = "Hero_Magnataur.ShockWave.Cast"
    StopSoundOn(sound, self:GetCaster())
end
function magnataur_shockwave:OnSpellStart()
    if IsClient() then return end

    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local point = self:GetCursorPosition()

    if target then
        point = target:GetOrigin()
    end

    local radius = self:GetSpecialValueFor("shock_width")
    local direction = CalculateDirection(point, caster:GetAbsOrigin())
    local distance = self:GetCastRange(point, nil)
    local velocity = direction * self:GetSpecialValueFor("shock_speed")
    local particle = "particles/units/heroes/hero_magnataur/magnataur_shockwave.vpcf"
    ProjectileManager:CreateLinearProjectile({
        Source = caster,
        Ability = self,
        vSpawnOrigin = caster:GetAbsOrigin(),
        bDeleteOnHit = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HEROES_AND_CREEPS,
        EffectName = particle,
        fDistance = distance,
        fStartRadius = radius,
        fEndRadius = radius,
        vVelocity = velocity,
        ExtraData = { do_bounce = 1 }
    })

    -- particles
    ParticleManager:DestroyParticle(self.effect, false)
    ParticleManager:ReleaseParticleIndex(self.effect)

    -- sounds
    local cast_sound = "Hero_Magnataur.ShockWave.Cast"
    StopSoundOn(cast_sound, self:GetCaster())
    local particle_sound = "Hero_Magnataur.ShockWave.Particle"
    EmitSoundOn(particle_sound, caster)
end
function magnataur_shockwave:OnProjectileHit_ExtraData(target, location, data)
    local caster = self:GetCaster()
    if target then
        local damage = self:GetSpecialValueFor("shock_damage") * TernaryOperator(self:GetSpecialValueFor("return_damage") / 100, data.is_bounce, 1)
        local debuff_duration = self:GetSpecialValueFor("basic_slow_duration")
        local pull_duration = self:GetSpecialValueFor("pull_duration")
        local pull_distance = self:GetSpecialValueFor("pull_distance")
        local direction = CalculateDirection(location, target:GetAbsOrigin())
        
        self:DealDamage(caster, target, damage)
        local modifiers = target:ApplyKnockBack(target:GetAbsOrigin() - direction, pull_duration, pull_duration, pull_distance, 0, caster, self)
        target:AddNewModifier(caster, self, "modifier_magnataur_shockwave_ebf", { duration = debuff_duration })

        -- particles
        local particle = "particles/units/heroes/hero_magnataur/magnataur_shockwave_hit.vpcf"
        local effect = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, target)
        ParticleManager:ReleaseParticleIndex(effect)

        if modifiers.stun then
            modifiers.stun:AddParticle(
                effect,
                false,
                false,
                -1,
                false,
                false
            )
        end

        -- sounds
        local sound = "Hero_Magnataur.ShockWave.Target"
        EmitSoundOn(sound, target)
    elseif data.do_bounce ~= nil then
        local radius = self:GetSpecialValueFor("shock_width")
        local direction = CalculateDirection(caster:GetAbsOrigin(), location)
        local distance = self:GetCastRange(location, nil)
        local velocity = direction * self:GetSpecialValueFor("shock_speed")
        local particle = "particles/units/heroes/hero_magnataur/magnataur_shockwave.vpcf"
        ProjectileManager:CreateLinearProjectile({
            Source = caster,
            Ability = self,
            vSpawnOrigin = location,
            bDeleteOnHit = false,
            iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
            iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
            iUnitTargetType = DOTA_UNIT_TARGET_HEROES_AND_CREEPS,
            EffectName = particle,
            fDistance = distance,
            fStartRadius = radius,
            fEndRadius = radius,
            vVelocity = velocity,
            ExtraData = { is_bounce = 1 }
        })
    end
end

modifier_magnataur_shockwave_ebf = class({})
LinkLuaModifier( "modifier_magnataur_shockwave_ebf", "heroes/hero_magnus/magnataur_shockwave", LUA_MODIFIER_MOTION_NONE )

function modifier_magnataur_shockwave_ebf:IsHidden()
    return false
end
function modifier_magnataur_shockwave_ebf:IsDebuff()
    return true
end
function modifier_magnataur_shockwave_ebf:IsPurgable()
    return true
end
function modifier_magnataur_shockwave_ebf:OnCreated()
    self:OnRefresh()
end
function modifier_magnataur_shockwave_ebf:OnRefresh()
    self.movement_slow = self:GetSpecialValueFor("movement_slow")
    self.does_disarm = self:GetSpecialValueFor("does_disarm") ~= 0
end
function modifier_magnataur_shockwave_ebf:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end
function modifier_magnataur_shockwave_ebf:GetModifierMoveSpeedBonus_Percentage()
    return -self.movement_slow 
end
function modifier_magnataur_shockwave_ebf:CheckState()
	return {
        [MODIFIER_STATE_DISARMED] = self.does_disarm
    }
end
function modifier_magnataur_shockwave_ebf:GetEffectName()
	return "particles/units/heroes/hero_magnataur/magnataur_skewer_debuff.vpcf"
end
function modifier_magnataur_shockwave_ebf:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end