centaur_hoof_stomp = class({})

function centaur_hoof_stomp:GetCastRange(position, target)
    return self:GetSpecialValueFor("radius")
end
function centaur_hoof_stomp:OnSpellStart()
    local caster = self:GetCaster()
    local windup_time = self:GetSpecialValueFor("windup_time")

    caster:AddNewModifier(caster, self, "modifier_centaur_hoof_stomp_windup_ebf", { duration = windup_time })
end

modifier_centaur_hoof_stomp_windup_ebf = class({})
LinkLuaModifier( "modifier_centaur_hoof_stomp_windup_ebf", "heroes/hero_centaur/centaur_hoof_stomp", LUA_MODIFIER_MOTION_NONE )

function modifier_centaur_hoof_stomp_windup_ebf:IsHidden()
    return false
end
function modifier_centaur_hoof_stomp_windup_ebf:IsDebuff()
    return false
end
function modifier_centaur_hoof_stomp_windup_ebf:IsPurgable()
    return false
end
function modifier_centaur_hoof_stomp_windup_ebf:OnCreated()
    self:OnRefresh()
    if IsClient() then return end

    self:GetCaster():StartGesture(ACT_DOTA_CAST_ABILITY_1)
end
function modifier_centaur_hoof_stomp_windup_ebf:OnRefresh()
    self.disarm = self:GetSpecialValueFor("does_windup_disarm") ~= 0
    self.damage_resistance = self:GetSpecialValueFor("damage_resistance")
    self.cancelled = false
end
function modifier_centaur_hoof_stomp_windup_ebf:OnDestroy()
    if IsClient() then return end

    self:GetCaster():FadeGesture(ACT_DOTA_CAST_ABILITY_1)

    if not self.cancelled then
        local caster = self:GetCaster()
        local ability = self:GetAbility()
        local radius = self:GetSpecialValueFor("radius")
        local damage = self:GetSpecialValueFor("stomp_damage")
        local stun_duration = self:GetSpecialValueFor("stun_duration")

        local allied_attack_speed_radius = self:GetSpecialValueFor("allied_attack_speed_radius")
        local allied_attack_speed_duration = self:GetSpecialValueFor("allied_attack_speed_duration")

        local enemy_attack_speed_duration = self:GetSpecialValueFor("enemy_attack_speed_duration")

        local damage_resistance_duration = self:GetSpecialValueFor("damage_resistance_duration")

        local enemies = caster:FindEnemyUnitsInRadius(caster:GetAbsOrigin(), radius)
        for _, enemy in ipairs(enemies) do
            ability:DealDamage(caster, enemy, damage)
            ability:Stun(enemy, stun_duration)

            if enemy_attack_speed_duration ~= 0 then
                enemy:AddNewModifier(caster, ability, "modifier_centaur_hoof_stomp_thunderhoof", { duration = enemy_attack_speed_duration })
            end
        end

        if allied_attack_speed_duration ~= 0 then
            local allies = caster:FindFriendlyUnitsInRadius(caster:GetAbsOrigin(), allied_attack_speed_radius)
            for _, ally in ipairs(allies) do
                ally:AddNewModifier(caster, ability, "modifier_centaur_hoof_stomp_chieftain", { duration = allied_attack_speed_duration })
            end
        end

        if damage_resistance_duration ~= 0 then
            caster:AddNewModifier(caster, ability, "modifier_centaur_hoof_stomp_stepperazer", { duration = damage_resistance_duration })
        end

        -- particles
        local particle = "particles/units/heroes/hero_centaur/centaur_warstomp.vpcf"
        local effect = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN, caster)
        ParticleManager:SetParticleControl(effect, 1, Vector(radius, radius, radius))
        ParticleManager:SetParticleControl(effect, 2, caster:GetOrigin())
        ParticleManager:SetParticleControl(effect, 3, caster:GetOrigin())
        ParticleManager:SetParticleControl(effect, 4, caster:GetOrigin())
        ParticleManager:SetParticleControl(effect, 5, caster:GetOrigin())
        ParticleManager:ReleaseParticleIndex(effect)

        -- sounds
        local sound = "Hero_Centaur.HoofStomp"
        EmitSoundOn(sound, caster)
    else
        self:GetAbility():EndCooldown()
        self:GetAbility():RefundManaCost()
    end
end
function modifier_centaur_hoof_stomp_windup_ebf:CheckState()
    return {
        [MODIFIER_STATE_DISARMED] = self.disarm
    }
end
function modifier_centaur_hoof_stomp_windup_ebf:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
        MODIFIER_EVENT_ON_ORDER
    }
end
function modifier_centaur_hoof_stomp_windup_ebf:GetModifierIncomingDamage_Percentage()
    return -self.damage_resistance
end
function modifier_centaur_hoof_stomp_windup_ebf:OnOrder(params)
    if params.unit == self:GetCaster() then
        if params.order_type == DOTA_UNIT_ORDER_STOP or params.order_type == DOTA_UNIT_ORDER_HOLD_POSITION then
            self.cancelled = true
            self:Destroy()
        end
    end
end

modifier_centaur_hoof_stomp_chieftain = class({})
LinkLuaModifier( "modifier_centaur_hoof_stomp_chieftain", "heroes/hero_centaur/centaur_hoof_stomp", LUA_MODIFIER_MOTION_NONE )

function modifier_centaur_hoof_stomp_chieftain:IsHidden()
    return false
end
function modifier_centaur_hoof_stomp_chieftain:IsDebuff()
    return false
end
function modifier_centaur_hoof_stomp_chieftain:IsPurgable()
    return true
end
function modifier_centaur_hoof_stomp_chieftain:OnCreated()
    self:OnRefresh()
end
function modifier_centaur_hoof_stomp_chieftain:OnRefresh()
    self.attack_speed = self:GetSpecialValueFor("allied_attack_speed")
end
function modifier_centaur_hoof_stomp_chieftain:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
end
function modifier_centaur_hoof_stomp_chieftain:GetModifierAttackSpeedBonus_Constant()
    return self.attack_speed
end

modifier_centaur_hoof_stomp_thunderhoof = class({})
LinkLuaModifier( "modifier_centaur_hoof_stomp_thunderhoof", "heroes/hero_centaur/centaur_hoof_stomp", LUA_MODIFIER_MOTION_NONE )

function modifier_centaur_hoof_stomp_thunderhoof:IsHidden()
    return false
end
function modifier_centaur_hoof_stomp_thunderhoof:IsDebuff()
    return true
end
function modifier_centaur_hoof_stomp_thunderhoof:IsPurgable()
    return true
end
function modifier_centaur_hoof_stomp_thunderhoof:OnCreated()
    self:OnRefresh()
end
function modifier_centaur_hoof_stomp_thunderhoof:OnRefresh()
    self.attack_speed = self:GetSpecialValueFor("enemy_attack_speed")
end
function modifier_centaur_hoof_stomp_thunderhoof:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
end
function modifier_centaur_hoof_stomp_thunderhoof:GetModifierAttackSpeedBonus_Constant()
    return self.attack_speed
end

modifier_centaur_hoof_stomp_stepperazer = class({})
LinkLuaModifier( "modifier_centaur_hoof_stomp_stepperazer", "heroes/hero_centaur/centaur_hoof_stomp", LUA_MODIFIER_MOTION_NONE )

function modifier_centaur_hoof_stomp_stepperazer:IsHidden()
    return false
end
function modifier_centaur_hoof_stomp_stepperazer:IsDebuff()
    return false
end
function modifier_centaur_hoof_stomp_stepperazer:IsPurgable()
    return true
end
function modifier_centaur_hoof_stomp_stepperazer:OnCreated()
    self:OnRefresh()
end
function modifier_centaur_hoof_stomp_stepperazer:OnRefresh()
    self.damage_resistance = self:GetSpecialValueFor("damage_resistance")
end
function modifier_centaur_hoof_stomp_stepperazer:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
    }
end
function modifier_centaur_hoof_stomp_stepperazer:GetModifierIncomingDamage_Percentage()
    return -self.damage_resistance
end