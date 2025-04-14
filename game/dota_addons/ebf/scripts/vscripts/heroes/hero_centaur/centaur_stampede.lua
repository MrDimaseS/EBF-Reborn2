centaur_stampede = class({})

function centaur_stampede:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")

    local units = caster:FindAllUnitsInRadius(caster:GetAbsOrigin(), 99999)
    for _, unit in ipairs(units) do
        if unit:IsSameTeam(caster) then
            unit:AddNewModifier(caster, self, "modifier_centaur_stampede_buff", { duration = duration })
        elseif unit:HasModifier("modifier_centaur_stampede_immune") then
            unit:RemoveModifierByName("modifier_centaur_stampede_immune")
        end
    end

    -- gestures
    caster:StartGesture(ACT_DOTA_CENTAUR_STAMPEDE)

    -- sounds
    local sound = "Hero_Centaur.Stampede.Cast"
    EmitSoundOn(sound, caster)
end

modifier_centaur_stampede_buff = class({})
LinkLuaModifier( "modifier_centaur_stampede_buff", "heroes/hero_centaur/centaur_stampede", LUA_MODIFIER_MOTION_NONE )

function modifier_centaur_stampede_buff:IsHidden()
    return false
end
function modifier_centaur_stampede_buff:IsDebuff()
    return false
end
function modifier_centaur_stampede_buff:IsPurgable()
    return false
end
function modifier_centaur_stampede_buff:GetEffectName()
    return "particles/units/heroes/hero_centaur/centaur_stampede_overhead.vpcf"
end
function modifier_centaur_stampede_buff:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end
function modifier_centaur_stampede_buff:OnCreated()
    self:OnRefresh()
    if IsClient() then return end

    self:StartIntervalThink(0.1)

    -- particles
    local particle = "particles/units/heroes/hero_centaur/centaur_stampede.vpcf"
    local effect = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, self.parent)
    ParticleManager:SetParticleControl(effect, 0, self.parent:GetAbsOrigin())
    self:AddParticle(effect, false, false, -1, false, false)
end
function modifier_centaur_stampede_buff:OnRefresh()
    self.parent = self:GetParent()
    self.radius = self:GetSpecialValueFor("radius")
    self.damage = self:GetSpecialValueFor("base_damage")
    self.slow_duration = self:GetSpecialValueFor("slow_duration")
    self.damage_reduction = self:GetSpecialValueFor("damage_reduction")
    self.has_flying_movement = self:GetSpecialValueFor("has_flying_movement") ~= 0
end
function modifier_centaur_stampede_buff:OnIntervalThink()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    local enemies = self.parent:FindEnemyUnitsInRadius(self.parent:GetAbsOrigin(), self.radius)
    for _, enemy in ipairs(enemies) do
        if not enemy:HasModifier("modifier_centaur_stampede_immune") then
            enemy:AddNewModifier(caster, ability, "modifier_centaur_stampede_immune", { duration = self:GetRemainingTime() })
            enemy:AddNewModifier(caster, ability, "modifier_centaur_stampede_debuff", { duration = self.slow_duration })
            ability:DealDamage(caster, enemy, self.damage)
        end
    end
end
function modifier_centaur_stampede_buff:CheckState()
    return {
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_ALLOW_PATHING_THROUGH_CLIFFS] = self.has_flying_movement
    }
end
function modifier_centaur_stampede_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE_MIN,
        MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
    }
end
function modifier_centaur_stampede_buff:GetModifierMoveSpeed_AbsoluteMin()
    return 550
end
function modifier_centaur_stampede_buff:GetModifierIncomingDamage_Percentage()
    return -self.damage_reduction
end

modifier_centaur_stampede_debuff = class({})
LinkLuaModifier( "modifier_centaur_stampede_debuff", "heroes/hero_centaur/centaur_stampede", LUA_MODIFIER_MOTION_NONE )

function modifier_centaur_stampede_debuff:IsHidden()
    return false
end
function modifier_centaur_stampede_debuff:IsDebuff()
    return true
end
function modifier_centaur_stampede_debuff:IsPurgable()
    return true
end
function modifier_centaur_stampede_debuff:OnCreated()
    self:OnRefresh()
end
function modifier_centaur_stampede_debuff:OnRefresh()
    self.slow_movement_speed = self:GetSpecialValueFor("slow_movement_speed")
    self.does_disarm_and_silence = self:GetSpecialValueFor("does_disarm_and_silence") ~= 0
end
function modifier_centaur_stampede_debuff:CheckState()
    return {
        [MODIFIER_STATE_DISARMED] = self.does_disarm_and_silence,
        [MODIFIER_STATE_SILENCED] = self.does_disarm_and_silence
    }
end
function modifier_centaur_stampede_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end
function modifier_centaur_stampede_debuff:GetModifierMoveSpeedBonus_Percentage()
    return -self.slow_movement_speed
end

modifier_centaur_stampede_immune = class({})
LinkLuaModifier( "modifier_centaur_stampede_immune", "heroes/hero_centaur/centaur_stampede", LUA_MODIFIER_MOTION_NONE )

function modifier_centaur_stampede_immune:IsHidden()
    return true
end
function modifier_centaur_stampede_immune:IsPurgable()
    return false
end