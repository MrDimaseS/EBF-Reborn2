bristleback_viscous_nasal_goo = class({})

function bristleback_viscous_nasal_goo:GetIntrinsicModifierName()
    return "modifier_bristleback_viscous_nasal_goo_attacks"
end
function bristleback_viscous_nasal_goo:GetBehavior()
    if self:GetSpecialValueFor("radius") ~= 0 then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_AUTOCAST
    else
        return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING
    end
end
function bristleback_viscous_nasal_goo:OnSpellStart()
    self:DoGoo(self:GetCaster():GetOrigin(), self:GetCursorTarget())

    local warpath = self:GetCaster():FindAbilityByName("bristleback_warpath")
    if IsEntitySafe(warpath) and warpath:IsTrained() then
        warpath:AddStack()
    end
end
function bristleback_viscous_nasal_goo:DoGoo(position, target, override_radius)
    local caster = self:GetCaster()
    local radius = override_radius or self:GetSpecialValueFor("radius")
    
    if radius ~= 0 then
        local enemies = caster:FindEnemyUnitsInRadius(position, radius)
        for _, enemy in ipairs(enemies) do
            self:FireGoo(position, enemy)
        end
        caster:StartGesture(ACT_DOTA_CAST_ABILITY_1)
    else
        self:FireGoo(position, target)
    end

    -- sounds
	local sound = "Hero_Bristleback.ViscousGoo.Cast"
	EmitSoundOnLocationWithCaster(position, sound, caster)
end
function bristleback_viscous_nasal_goo:FireGoo(start_point, target)
    local goo_speed = self:GetSpecialValueFor("goo_speed")
    local particle = "particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_goo.vpcf"
    ProjectileManager:CreateTrackingProjectile({
        Target = target,
        Source = caster,
        Ability = self,
        EffectName = particle,
        iMoveSpeed = goo_speed,
        vSourceLoc = start_point
    })
end
function bristleback_viscous_nasal_goo:OnProjectileHit(target, position)
    if target == nil
    or not target:IsAlive()
    then return end

    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("goo_duration")
    local stack_limit = self:GetSpecialValueFor("max_stacks")

    local modifier = target:AddNewModifier(caster, self, "modifier_bristleback_viscous_nasal_goo_debuff", { duration = duration })
    if modifier:GetStackCount() < stack_limit then
        modifier:IncrementStackCount()
    end

    local warpath = caster:FindAbilityByName("bristleback_warpath")
    if IsEntitySafe(warpath) and warpath:IsTrained() then
        local damage_per_stack = warpath:GetSpecialValueFor("goo_damage_per_stack")
        local active_multiplier = warpath:GetSpecialValueFor("active_multiplier")
        if damage_per_stack ~= 0 and warpath:GetStackCount() > 0 then
            local damage = damage_per_stack * warpath:GetStackCount() * TernaryOperator(active_multiplier, warpath:IsActive(), 1.0)
            self:DealDamage(caster, target, damage, { damage_type = DAMAGE_TYPE_PHYSICAL })
        end
    end

    -- sounds
    local sound = "Hero_Bristleback.ViscousGoo.Target"
    EmitSoundOn(sound, target)
end

modifier_bristleback_viscous_nasal_goo_attacks = class({})
LinkLuaModifier( "modifier_bristleback_viscous_nasal_goo_attacks", "heroes/hero_bristleback/bristleback_viscous_nasal_goo", LUA_MODIFIER_MOTION_NONE )

function modifier_bristleback_viscous_nasal_goo_attacks:IsHidden()
    return self:GetSpecialValueFor("incoming_attacks_required") == 0
       and self:GetSpecialValueFor("outgoing_attacks_required") == 0
end
function modifier_bristleback_viscous_nasal_goo_attacks:OnCreated()
    self:OnRefresh()
    if IsClient() then return end

    self:StartIntervalThink(0)
end
function modifier_bristleback_viscous_nasal_goo_attacks:OnRefresh()
    self.incoming_attacks_required = self:GetSpecialValueFor("incoming_attacks_required")
    self.outgoing_attacks_required = self:GetSpecialValueFor("outgoing_attacks_required")
    self.incoming = self.incoming_attacks_required ~= 0
    self.outgoing = self.outgoing_attacks_required ~= 0
    self.attack_count = 0
end
function modifier_bristleback_viscous_nasal_goo_attacks:OnIntervalThink()
    local caster = self:GetCaster()
    if caster:IsSilenced()
    or caster:IsStunned()
    then return end

    local ability = self:GetAbility()
    if ability:GetAutoCastState() and ability:IsFullyCastable() then
        caster:CastAbilityNoTarget(ability, caster:GetPlayerOwnerID())
    end
end
function modifier_bristleback_viscous_nasal_goo_attacks:DeclareFunctions()
    return {
        MODIFIER_EVENT_ON_ATTACK_LANDED
    }
end
function modifier_bristleback_viscous_nasal_goo_attacks:OnAttackLanded(params)
    if (self.incoming_attacks_required == 0 and self.outgoing_attacks_required == 0)
    or (self.outgoing and params.attacker ~= self:GetParent())
    or (self.incoming and params.target ~= self:GetParent())
    then return end

    self.attack_count = self.attack_count + 1
    if self.incoming and self.attack_count >= self.incoming_attacks_required then
        self:GetAbility():DoGoo(self:GetParent():GetOrigin(), params.attacker)
        self.attack_count = 0
    elseif self.outgoing and self.attack_count >= self.outgoing_attacks_required then
        self:GetAbility():DoGoo(self:GetParent():GetOrigin(), params.target)
        self.attack_count = 0
    end
    self:SetStackCount(self.attack_count)
end

modifier_bristleback_viscous_nasal_goo_debuff = class({})
LinkLuaModifier( "modifier_bristleback_viscous_nasal_goo_debuff", "heroes/hero_bristleback/bristleback_viscous_nasal_goo", LUA_MODIFIER_MOTION_NONE )

function modifier_bristleback_viscous_nasal_goo_debuff:IsHidden()
    return false
end
function modifier_bristleback_viscous_nasal_goo_debuff:IsDebuff()
    return true
end
function modifier_bristleback_viscous_nasal_goo_debuff:IsPurgable()
    return false
end
function modifier_bristleback_viscous_nasal_goo_debuff:GetEffectName()
    return "particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_goo_debuff.vpcf"
end
function modifier_bristleback_viscous_nasal_goo_debuff:GetStatusEffectName()
    return "particles/status_fx/status_effect_goo.vpcf"
end
function modifier_bristleback_viscous_nasal_goo_debuff:OnCreated()
    self.base_armor = self:GetSpecialValueFor("base_armor")
    self.armor_per_stack = self:GetSpecialValueFor("armor_per_stack")
    self.base_move_slow = self:GetSpecialValueFor("base_move_slow")
    self.move_slow_per_stack = self:GetSpecialValueFor("move_slow_per_stack")
end
function modifier_bristleback_viscous_nasal_goo_debuff:OnRefresh()
    self.base_armor = self:GetSpecialValueFor("base_armor")
    self.armor_per_stack = self:GetSpecialValueFor("armor_per_stack")
    self.base_move_slow = self:GetSpecialValueFor("base_move_slow")
    self.move_slow_per_stack = self:GetSpecialValueFor("move_slow_per_stack")
end
function modifier_bristleback_viscous_nasal_goo_debuff:OnDestroy()
    if self.effect then
        ParticleManager:DestroyParticle(self.effect, true)
    end
end
function modifier_bristleback_viscous_nasal_goo_debuff:OnStackCountChanged(old)
    -- particles
    local particle = "particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_stack.vpcf"
    self.effect = self.effect or ParticleManager:CreateParticle(particle, PATTACH_OVERHEAD_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(self.effect, 1, Vector(0, self:GetStackCount(), 0))
end
function modifier_bristleback_viscous_nasal_goo_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }
end
function modifier_bristleback_viscous_nasal_goo_debuff:GetModifierPhysicalArmorBonus()
    return -(self.base_armor + self.armor_per_stack * (self:GetStackCount() - 1))
end
function modifier_bristleback_viscous_nasal_goo_debuff:GetModifierMoveSpeedBonus_Percentage()
    return -(self.base_move_slow + self.move_slow_per_stack * (self:GetStackCount() - 1))
end