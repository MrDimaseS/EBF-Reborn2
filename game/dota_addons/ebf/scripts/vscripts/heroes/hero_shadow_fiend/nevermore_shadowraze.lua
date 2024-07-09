nevermore_shadowraze_ebf = class({})

function nevermore_shadowraze_ebf:GetAOERadius()
    return self:GetSpecialValueFor("range")
end
function nevermore_shadowraze_ebf:OnSpellStart()
    local caster = self:GetCaster();
    local range = self:GetSpecialValueFor("range")
    local offset = caster:GetForwardVector() * range;
    local position = caster:GetAbsOrigin() + offset;

    -- find all of the units within the radius of the position, and do things to them.
    local units = FindUnitsInRadius(
        caster:GetTeam(),
        position,
        nil,
        self:GetSpecialValueFor("radius"),
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HEROES_AND_CREEPS,
        DOTA_UNIT_TARGET_FLAG_NONE,
        FIND_ANY_ORDER,
        false
    )
    for _,unit in ipairs(units) do
        if self:GetSpecialValueFor("does_attack") then
            caster:PerformGenericAttack(unit, true, false, self:GetSpecialValueFor("damage"), 100)
            -- deal some damage so that necromastery knows we razed
            self:DealDamage(caster, unit, 10)
        else
            local slow = self:GetSpecialValueFor("attack_speed_reduction")
            if slow ~= 0 then
                local debuff = unit:FindModifierByName("modifier_nevermore_shadowraze_slow")
                if not debuff then
                    debuff = unit:AddNewModifier(caster, self, "modifier_nevermore_shadowraze_slow", { duration = self:GetSpecialValueFor("attack_speed_reduction_duration") })
                end
                debuff:SetDuration(self:GetSpecialValueFor("attack_speed_reduction_duration"), true)
            end

            local damage = self:GetSpecialValueFor("damage")
            local bonus = self:GetSpecialValueFor("spell_damage_per_stack")
            if bonus > 0 then
                local debuff = unit:FindModifierByName("modifier_nevermore_shadowraze_stack")
                if debuff then
                    damage = damage * (1 + debuff:OnTooltip() / 100)
                    debuff:IncrementStackCount()
                    debuff:SetDuration(self:GetSpecialValueFor("spell_damage_stack_duration"), true)
                else
                    debuff = unit:AddNewModifier(caster, self, "modifier_nevermore_shadowraze_stack", { duration = self:GetSpecialValueFor("spell_damage_stack_duration") })
                    debuff:IncrementStackCount()
                end
            end
            self:DealDamage(caster, unit, damage)
        end
    end

    -- create the particle and sound
    local particle = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_nevermore/nevermore_shadowraze.vpcf",
        PATTACH_ABSORIGIN,
        caster
    )
    ParticleManager:SetParticleControl(particle, 0, position)
    ParticleManager:ReleaseParticleIndex(particle)
	EmitSoundOnLocationWithCaster(position, "Hero_Nevermore.Shadowraze", caster)
end

nevermore_shadowraze1_ebf = class(nevermore_shadowraze_ebf)
nevermore_shadowraze2_ebf = class(nevermore_shadowraze_ebf)
nevermore_shadowraze3_ebf = class(nevermore_shadowraze_ebf)

modifier_nevermore_shadowraze_stack = class({})
LinkLuaModifier("modifier_nevermore_shadowraze_stack", "heroes/hero_shadow_fiend/nevermore_shadowraze.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_nevermore_shadowraze_stack:IsDebuff()
    return true
end
function modifier_nevermore_shadowraze_stack:IsPurgable()
    return true
end
function modifier_nevermore_shadowraze_stack:DeclareFunctions()
    return { MODIFIER_PROPERTY_TOOLTIP }
end
function modifier_nevermore_shadowraze_stack:OnTooltip()
    return self:GetSpecialValueFor("spell_damage_per_stack") * self:GetStackCount()
end
function modifier_nevermore_shadowraze_stack:GetEffectName()
    return "particles/units/heroes/hero_nevermore/nevermore_shadowraze_debuff.vpcf"
end

modifier_nevermore_shadowraze_slow = class({})
LinkLuaModifier("modifier_nevermore_shadowraze_slow", "heroes/hero_shadow_fiend/nevermore_shadowraze.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_nevermore_shadowraze_slow:IsDebuff()
    return true
end
function modifier_nevermore_shadowraze_slow:IsPurgable()
    return true
end
function modifier_nevermore_shadowraze_slow:OnCreated()
    self:OnRefresh()
end
function modifier_nevermore_shadowraze_slow:OnRefresh()
    self.attack_speed_reduction = self:GetSpecialValueFor("attack_speed_reduction")
end
function modifier_nevermore_shadowraze_slow:DeclareFunctions()
    return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end
function modifier_nevermore_shadowraze_slow:GetModifierAttackSpeedBonus_Constant()
    return self.attack_speed_reduction
end
function modifier_nevermore_shadowraze_slow:GetEffectName()
    return "particles/units/heroes/hero_nevermore/nevermore_shadowraze_debuff.vpcf"
end