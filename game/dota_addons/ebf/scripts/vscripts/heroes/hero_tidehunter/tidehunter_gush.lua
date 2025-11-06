tidehunter_gush = class({})
--add projectiles

function tidehunter_gush:GetBehavior()
    if self:GetSpecialValueFor("aoe") == 0 then
        return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_AUTOCAST
    else
        return DOTA_ABILITY_BEHAVIOR_POINT
    end
end

function tidehunter_gush:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local point = self:GetCursorPosition()

    if self:GetSpecialValueFor("aoe") == 0 then
        self:Spit(caster, target)
    else
        self:SuperSpit(caster, point)
    end
end

function tidehunter_gush:Spit(caster, target)
    local speed = self:GetSpecialValueFor("projectile_speed")
    self:FireTrackingProjectile("particles/units/heroes/hero_tidehunter/tidehunter_gush.vpcf", target, speed)
    EmitSoundOn("Ability.GushCast", caster)
end

function tidehunter_gush:SuperSpit(caster, point)
    local speed = self:GetSpecialValueFor("scepter_speed")
    local aoe = self:GetSpecialValueFor("aoe")
    local distance = self:GetTrueCastRange() + self:GetSpecialValueFor("scepter_max_distance")

    local dir = CalculateDirection(point, caster)
    dir.z = 0
    local proj_dir = dir:Normalized()

    local info =
    {
        EffectName = "particles/units/heroes/hero_tidehunter/tidehunter_gush_upgrade.vpcf",
        Ability = self,
        vSpawnOrigin = caster:GetAbsOrigin() + dir,
        fStartRadius = aoe / 2,
        fEndRadius = aoe / 2,
        vVelocity = proj_dir * speed,
        fDistance = distance,
        Source = caster,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    }

    ProjectileManager:CreateLinearProjectile(info)
    EmitSoundOn("Ability.GushCast", caster)
    EmitSoundOnLocationWithCaster(point, "Hero_Tidehunter.Gush.AghsProjectile", caster)
end

function tidehunter_gush:OnProjectileHit(hTarget)
    if hTarget ~= nil and not hTarget:IsMagicImmune() and not hTarget:IsInvulnerable() then
        local caster = self:GetCaster()
        local duration = self:GetSpecialValueFor("AbilityDuration")
        local damage = self:GetSpecialValueFor("gush_damage")

        hTarget:AddNewModifier(caster, self, "modifier_tidehunter_gush", {duration = duration})
        EmitSoundOn("Ability.GushImpact", hTarget)
        self:DealDamage(caster, hTarget, damage)

        local pull_radius = self:GetSpecialValueFor("pull_radius")
        local pull_range = self:GetSpecialValueFor("pull_range")
        local pull_direction = CalculateDirection(caster, hTarget)
        local pull_duration = self:GetSpecialValueFor("pull_duration")
        if not self:GetAutoCastState() then
            hTarget:ApplyKnockBack(hTarget:GetAbsOrigin() + -pull_direction, 0, pull_duration, pull_range, 0, caster, self)
            for _, unit in ipairs (caster:FindEnemyUnitsInRadius(hTarget:GetAbsOrigin(), pull_radius)) do
                unit:ApplyKnockBack(unit:GetAbsOrigin() + -pull_direction, 0, pull_duration, pull_range, 0, caster, self)
            end
        end
    end
    return false
end