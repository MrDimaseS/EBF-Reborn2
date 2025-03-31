dragon_knight_dragon_tail = class({})

function dragon_knight_dragon_tail:GetCastRange(location, target)
    if self:GetCaster():HasModifier("modifier_dragon_knight_elder_dragon_form_buff") then
        return self:GetSpecialValueFor("dragon_cast_range")
    else
        return self:GetSpecialValueFor("cast_range")
    end
end
function dragon_knight_dragon_tail:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
function dragon_knight_dragon_tail:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    
    local aoe = self:GetSpecialValueFor("radius") or 1
    local modifier = caster:FindModifierByNameAndCaster("modifier_dragon_knight_elder_dragon_form_buff", caster)
    local units = caster:FindEnemyUnitsInRadius(target:GetOrigin(), aoe)
    for _, unit in ipairs(units) do
        if modifier then
            local particle = "particles/units/heroes/hero_dragon_knight/dragon_knight_dragon_tail_dragonform_proj.vpcf"
            ProjectileManager:CreateTrackingProjectile({
                Target = unit,
                Source = caster,
                Ability = self,
                iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2,
                EffectName = particle,
                iMoveSpeed = self:GetSpecialValueFor("projectile_speed"),
                bDodgeable = true
            })
        else
            if not unit:TriggerSpellAbsorb(self) then
                self:Hit(unit, false)
            end
        end
    end
end
function dragon_knight_dragon_tail:OnProjectileHit(target, location)
    if not target then return end

    self:Hit(target, true)
end
function dragon_knight_dragon_tail:Hit(target, dragon_form)
    if target:TriggerSpellAbsorb(self) then return end

    local caster = self:GetCaster()
    local damage = self:GetSpecialValueFor("damage")
    local stun_duration = self:GetSpecialValueFor("stun_duration")

    self:DealDamage(caster, target, damage, { damage_type = TernaryOperator(DAMAGE_TYPE_PHYSICAL, self:GetSpecialValueFor("physical_damage_type") ~= 0, DAMAGE_TYPE_MAGICAL) })
    target:AddNewModifier(caster, self, "modifier_dragon_knight_dragon_tail_stun", { duration = stun_duration })
    
    if self:GetSpecialValueFor("attack_speed") ~= 0 then
        target:AddNewModifier(caster, self, "modifier_dragon_knight_dragon_tail_debuff", { duration = self:GetSpecialValueFor("debuff_duration") })
    end

    -- particles
    local vector = target:GetOrigin() - caster:GetOrigin()
    local attach = TernaryOperator("attach_attack2", dragon_form, "attach_attack1")
    local particle = "particles/units/heroes/hero_dragon_knight/dragon_knight_dragon_tail.vpcf"
    local effect = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControl(effect, 3, vector)
    ParticleManager:SetParticleControlEnt(
        effect,
        2,
        caster,
        PATTACH_POINT_FOLLOW,
        attach,
        Vector(0, 0, 0),
        true
    )
    ParticleManager:SetParticleControlEnt(
        effect,
        4,
        target,
        PATTACH_POINT_FOLLOW,
        "attach_hitloc",
        Vector(0, 0, 0),
        true
    )
    ParticleManager:ReleaseParticleIndex(effect)

    -- sounds
    local sound = "Hero_DragonKnight.DragonTail.Target"
    EmitSoundOn(sound, target)
end

modifier_dragon_knight_dragon_tail_stun = class({})
LinkLuaModifier( "modifier_dragon_knight_dragon_tail_stun", "heroes/hero_dragon_knight/dragon_knight_dragon_tail", LUA_MODIFIER_MOTION_NONE )

function modifier_dragon_knight_dragon_tail_stun:IsHidden()
    return false
end
function modifier_dragon_knight_dragon_tail_stun:IsDebuff()
    return true
end
function modifier_dragon_knight_dragon_tail_stun:IsStunDebuff()
    return true
end
function modifier_dragon_knight_dragon_tail_stun:IsPurgable()
    return false
end
function modifier_dragon_knight_dragon_tail_stun:OnDestroy()
    if IsClient() then return end
    
    if self:GetSpecialValueFor("attack_damage_reduction") ~= 0 then
        self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_dragon_knight_dragon_tail_debuff", { duration = self:GetSpecialValueFor("debuff_duration") })
    end
end
function modifier_dragon_knight_dragon_tail_stun:CheckState()
    return {
        [MODIFIER_STATE_STUNNED] = true
    }
end
function modifier_dragon_knight_dragon_tail_stun:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION
    }
end
function modifier_dragon_knight_dragon_tail_stun:GetOverrideAnimation()
	return ACT_DOTA_DISABLED
end
function modifier_dragon_knight_dragon_tail_stun:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf"
end
function modifier_dragon_knight_dragon_tail_stun:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

modifier_dragon_knight_dragon_tail_debuff = class({})
LinkLuaModifier( "modifier_dragon_knight_dragon_tail_debuff", "heroes/hero_dragon_knight/dragon_knight_dragon_tail", LUA_MODIFIER_MOTION_NONE )

function modifier_dragon_knight_dragon_tail_debuff:IsHidden()
    return false
end
function modifier_dragon_knight_dragon_tail_debuff:IsDebuff()
    return true
end
function modifier_dragon_knight_dragon_tail_debuff:IsPurgable()
    return true
end
function modifier_dragon_knight_dragon_tail_debuff:OnCreated()
    self:OnRefresh()
end
function modifier_dragon_knight_dragon_tail_debuff:OnRefresh()
    self.attack_speed = self:GetSpecialValueFor("attack_speed")
    self.attack_damage_reduction = self:GetSpecialValueFor("attack_damage_reduction")
end
function modifier_dragon_knight_dragon_tail_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
        MODIFIER_EVENT_ON_ATTACK_START
    }
end
function modifier_dragon_knight_dragon_tail_debuff:GetModifierDamageOutgoing_Percentage()
    return -self.attack_damage_reduction
end
function modifier_dragon_knight_dragon_tail_debuff:OnAttackStart(event)
    if IsClient()
    or not event.attacker 
    or not event.target
    or event.target ~= self:GetParent()
    or event.no_attack_cooldown
    then return end

    event.attacker:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_dragon_knight_dragon_tail_caustic_blood", { duration = 1.0 })
end

modifier_dragon_knight_dragon_tail_caustic_blood = class({})
LinkLuaModifier( "modifier_dragon_knight_dragon_tail_caustic_blood", "heroes/hero_dragon_knight/dragon_knight_dragon_tail", LUA_MODIFIER_MOTION_NONE )

function modifier_dragon_knight_dragon_tail_caustic_blood:IsHidden()
    return false
end
function modifier_dragon_knight_dragon_tail_caustic_blood:IsDebuff()
    return false
end
function modifier_dragon_knight_dragon_tail_caustic_blood:IsPurgable()
    return true
end
function modifier_dragon_knight_dragon_tail_caustic_blood:OnCreated()
    self:OnRefresh()
end
function modifier_dragon_knight_dragon_tail_caustic_blood:OnRefresh()
    self.attack_speed = self:GetSpecialValueFor("attack_speed")
end
function modifier_dragon_knight_dragon_tail_caustic_blood:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
    }
end
function modifier_dragon_knight_dragon_tail_caustic_blood:GetModifierAttackSpeedBonus_Constant()
    return self.attack_speed
end