magnataur_skewer = class({})

function magnataur_skewer:OnSpellStart()
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    local range = self:GetSpecialValueFor("range")
    local distance = CalculateDistance(point, caster:GetOrigin())
    if distance > range then
        distance = range
    end
    local speed = self:GetSpecialValueFor("skewer_speed")
    local duration = distance / speed

    caster:AddNewModifier(caster, self, "modifier_magnataur_skewer_ebf", { skewer_duration = duration })
end

modifier_magnataur_skewer_ebf = class({})
LinkLuaModifier( "modifier_magnataur_skewer_ebf", "heroes/hero_magnus/magnataur_skewer", LUA_MODIFIER_MOTION_NONE )

function modifier_magnataur_skewer_ebf:IsHidden()
    return false
end
function modifier_magnataur_skewer_ebf:IsDebuff()
    return false
end
function modifier_magnataur_skewer_ebf:IsPurgable()
    return false
end
function modifier_magnataur_skewer_ebf:OnCreated(params)
    if IsClient() then return end

    self.caster = self:GetCaster()
    self.ability = self:GetAbility()
    self.radius = self:GetSpecialValueFor("skewer_radius")
    self.speed = self:GetSpecialValueFor("skewer_speed")
    self.duration = params.skewer_duration
    self.distance = 0
    self.hits = {}

    self.skewer_damage = self:GetSpecialValueFor("skewer_damage")
    self.damage_distance_pct = self:GetSpecialValueFor("damage_distance_pct") / 100
    self.slow_duration = self:GetSpecialValueFor("slow_duration")

    self:StartMotionController()

    -- particles
    local particle = "particles/units/heroes/hero_magnataur/magnataur_skewer.vpcf"
    local effect = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, self.caster)
    ParticleManager:SetParticleControlEnt(
        effect,
        1,
        self.caster,
        PATTACH_POINT_FOLLOW,
        "attach_horn",
        Vector(),
        true
    )
    ParticleManager:SetParticleControlForward(effect, 1, self.caster:GetForwardVector())
    self:AddParticle(effect, false, false, -1, false, false)

    -- sounds
    local sound = "Hero_Magnataur.Skewer.Cast"
    EmitSoundOn(sound, self.caster)
end
function modifier_magnataur_skewer_ebf:OnDestroy()
    if IsClient() then return end
    
    self.caster:StartGesture(ACT_DOTA_MAGNUS_SKEWER_END)
end
function modifier_magnataur_skewer_ebf:DoControlledMotion()
    local enemies = self.caster:FindEnemyUnitsInRadius(self.caster:GetAbsOrigin(), self.radius)
    for _, enemy in ipairs(enemies) do
        if not self.hits[enemy] then
            self.caster:PerformGenericAttack(enemy, true, {
                neverMiss = true,
                ability = self.ability,
                bonusDamage = self.skewer_damage + self.distance * self.damage_distance_pct,
                suppressCleave = true
            })
            enemy:AddNewModifier(self.caster, self.ability, "modifier_magnataur_skewer_debuff", { duration = self.slow_duration })
            self.hits[enemy] = true

            -- sounds
            local sound = "Hero_Magnataur.Skewer.Target"
            EmitSoundOn(sound, enemy)
        end
    end

    if self.duration <= 0 then
        GridNav:DestroyTreesAroundPoint(self.caster:GetAbsOrigin(), self.radius, false)
        FindClearSpaceForUnit(self.caster, self.caster:GetAbsOrigin(), true)
        self:Destroy()
    else
        self.duration = self.duration - FrameTime()
        self.distance = self.distance + self.speed * FrameTime()
        self.caster:SetAbsOrigin(GetGroundPosition(self.caster:GetAbsOrigin() + self.caster:GetForwardVector() * self.speed * FrameTime(), self.caster))
    end
end
function modifier_magnataur_skewer_ebf:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
        MODIFIER_EVENT_ON_ORDER
    }
end
function modifier_magnataur_skewer_ebf:CheckState()
	return {
        [MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS] = true
    }
end
function modifier_magnataur_skewer_ebf:GetOverrideAnimation()
	return ACT_DOTA_MAGNUS_SKEWER_START
end
function modifier_magnataur_skewer_ebf:OnOrder(params)
    if params.unit == self.caster then
        if params.order_type == DOTA_UNIT_ORDER_STOP or params.order_type == DOTA_UNIT_ORDER_HOLD_POSITION then
            GridNav:DestroyTreesAroundPoint(self.caster:GetAbsOrigin(), self.radius, false)
            FindClearSpaceForUnit(self.caster, self.caster:GetAbsOrigin(), true)
            self.duration = 0
            self:Destroy()
        end
    end
end

modifier_magnataur_skewer_debuff = class({})
LinkLuaModifier( "modifier_magnataur_skewer_debuff", "heroes/hero_magnus/magnataur_skewer", LUA_MODIFIER_MOTION_NONE )

function modifier_magnataur_skewer_debuff:IsHidden()
    return false
end
function modifier_magnataur_skewer_debuff:IsDebuff()
    return true
end
function modifier_magnataur_skewer_debuff:IsPurgable()
    return true
end
function modifier_magnataur_skewer_debuff:GetEffectName()
    return "particles/units/heroes/hero_magnataur/magnataur_skewer_debuff.vpcf"
end
function modifier_magnataur_skewer_debuff:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
function modifier_magnataur_skewer_debuff:OnCreated()
    self:OnRefresh()
end
function modifier_magnataur_skewer_debuff:OnRefresh()
    self.slow_pct = self:GetSpecialValueFor("slow_pct")
end
function modifier_magnataur_skewer_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end
function modifier_magnataur_skewer_debuff:GetModifierMoveSpeedBonus_Percentage()
    return -self.slow_pct
end