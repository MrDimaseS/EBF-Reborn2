magnataur_empower = class({})

function magnataur_empower:GetBehavior()
    if self:GetSpecialValueFor("aoe_on_cast") ~= 0 then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_AOE
    else
        return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
    end
end
function magnataur_empower:GetAOERadius()
	return self:GetSpecialValueFor("aoe_on_cast")
end
function magnataur_empower:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("empower_duration")
    local aoe_on_cast = self:GetSpecialValueFor("aoe_on_cast")

    if aoe_on_cast == 0 then
        local target = self:GetCursorTarget()
        if target == caster then
            duration = -1
        end
        target:AddNewModifier(caster, self, "modifier_magnataur_empower_ebf", { duration = duration })

        -- sounds
        local target_sound = "Hero_Magnataur.Empower.Target"
        EmitSoundOn(target_sound, target)
    else
        local allies = caster:FindFriendlyUnitsInRadius(caster:GetOrigin(), aoe_on_cast)
        for _, ally in ipairs(allies) do
            ally:AddNewModifier(caster, self, "modifier_magnataur_empower_ebf", { duration = duration})

            -- sounds
            local target_sound = "Hero_Magnataur.Empower.Target"
            EmitSoundOn(target_sound, target)
        end
    end

    -- sounds
    local caster_sound = "Hero_Magnataur.Empower.Cast"
    EmitSoundOn(caster_sound, caster)
end

modifier_magnataur_empower_ebf = class({})
LinkLuaModifier( "modifier_magnataur_empower_ebf", "heroes/hero_magnus/magnataur_empower", LUA_MODIFIER_MOTION_NONE )

function modifier_magnataur_empower_ebf:IsHidden()
    return false
end
function modifier_magnataur_empower_ebf:IsDebuff()
    return false
end
function modifier_magnataur_empower_ebf:IsPurgable()
    return true
end
function modifier_magnataur_empower_ebf:GetEffectName()
	return "particles/units/heroes/hero_magnataur/magnataur_empower.vpcf"
end
function modifier_magnataur_empower_ebf:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
function modifier_magnataur_empower_ebf:OnCreated()
    self:OnRefresh()
end
function modifier_magnataur_empower_ebf:OnRefresh()
    self.bonus_damage_pct = self:GetSpecialValueFor("bonus_damage_pct")
    self.cleave_damage_pct = self:GetSpecialValueFor("cleave_damage_pct") / 100
    self.cleave_ending_width = self:GetSpecialValueFor("cleave_ending_width")
    self.cleave_distance = self:GetSpecialValueFor("cleave_distance")

    self.stack_duration = self:GetSpecialValueFor("stack_duration")
    self.max_stacks = self:GetSpecialValueFor("max_stacks")
    self.bonus_per_stack = self:GetSpecialValueFor("bonus_per_stack") / 100
end
function modifier_magnataur_empower_ebf:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end
function modifier_magnataur_empower_ebf:GetModifierDamageOutgoing_Percentage()
    return self.bonus_damage_pct * (1 + self.bonus_per_stack * self:GetStackCount())
end
function modifier_magnataur_empower_ebf:OnAttackLanded(params)
	if params.attacker == self:GetParent() then
        if params.attacker == self:GetCaster() and self.stack_duration ~= 0 then
            if self:GetStackCount() < self.max_stacks then
                self:AddIndependentStack(self.stack_duration)
            end
            self:RefreshAllIndependentStacks()
        end
        if not params.attacker:IsIllusion() and not params.attacker:IsCleaveSuppressed() then
            local ability = self:GetAbility()
            local units = 0
            local direction = CalculateDirection(params.target, params.attacker)
            local splash = params.attacker:FindEnemyUnitsInCone(direction, params.target:GetAbsOrigin(), self.cleave_ending_width, self.cleave_distance)
            local splashFX = ParticleManager:CreateParticle("particles/units/heroes/hero_magnataur/magnataur_empower_cleave_effect.vpcf", PATTACH_POINT, params.attacker)
            ParticleManager:SetParticleControl(splashFX, 0, params.attacker:GetAbsOrigin())
            ParticleManager:SetParticleControlTransformForward(splashFX, 0, params.attacker:GetAbsOrigin(), direction)
            
            local splashDamage = params.original_damage * (self.cleave_damage_pct + self.bonus_per_stack * self:GetStackCount())
            for _, unit in ipairs(splash) do
                if unit ~= params.target then
                    units = units + 1
                    ParticleManager:SetParticleControl(splashFX, units, unit:GetAbsOrigin())
                    ability:DealDamage(params.attacker, unit, splashDamage, { damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL })
                end
            end
            ParticleManager:ReleaseParticleIndex(splashFX)
        end
    end
end