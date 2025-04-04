dragon_knight_breathe_fire = class({})

function dragon_knight_breathe_fire:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local point = self:GetCursorPosition()

    if target then
        point = target:GetOrigin()
    end

    local particle = "particles/units/heroes/hero_dragon_knight/dragon_knight_breathe_fire.vpcf"
    local direction = point - caster:GetOrigin()
    ProjectileManager:CreateLinearProjectile({
        Source = caster,
        Ability = self,
        vSpawnOrigin = caster:GetAbsOrigin(),
        bDeleteOnHit = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetType = DOTA_UNIT_TARGET_HEROES_AND_CREEPS,
        EffectName = particle,
        fDistance = self:GetSpecialValueFor("range") + caster:GetCastRangeBonus(),
        fStartRadius = self:GetSpecialValueFor("start_radius"),
        fEndRadius = self:GetSpecialValueFor("end_radius"),
        vVelocity = direction:Normalized() * self:GetSpecialValueFor("speed")
    })
    
    -- sounds
    local sound = "Hero_DragonKnight.BreathFire"
    EmitSoundOn(sound, caster)
end
function dragon_knight_breathe_fire:OnProjectileHit(target, location)
    if not target then return end

    local caster = self:GetCaster()
    local damage = self:GetSpecialValueFor("damage")
    local duration = self:GetSpecialValueFor("duration")

    target:AddNewModifier(caster, self, "modifier_dragon_knight_breathe_fire_debuff", { duration = duration })
    self:DealDamage(caster, target, damage, { damage_type = TernaryOperator(DAMAGE_TYPE_PHYSICAL, self:GetSpecialValueFor("physical_damage_type") ~= 0, DAMAGE_TYPE_MAGICAL) })
end

modifier_dragon_knight_breathe_fire_debuff = class({})
LinkLuaModifier( "modifier_dragon_knight_breathe_fire_debuff", "heroes/hero_dragon_knight/dragon_knight_breathe_fire", LUA_MODIFIER_MOTION_NONE )

function modifier_dragon_knight_breathe_fire_debuff:IsHidden()
    return false
end
function modifier_dragon_knight_breathe_fire_debuff:IsDebuff()
    return true
end
function modifier_dragon_knight_breathe_fire_debuff:IsPurgable()
    return true
end
function modifier_dragon_knight_breathe_fire_debuff:OnCreated()
    self:OnRefresh()
    if IsClient() then return end
    if self.damage_per_second ~= 0 then
        self:StartIntervalThink(1.0)
    end
end
function modifier_dragon_knight_breathe_fire_debuff:OnRefresh()
    self.magic_resist_reduction = self:GetSpecialValueFor("magic_resist_reduction")
    self.damage_per_second = self:GetSpecialValueFor("damage_per_second")
    self.base_attack_time_increase = self:GetSpecialValueFor("base_attack_time_increase")
    self.previous_base_attack_time = self:GetParent():GetBaseAttackTime()
end
function modifier_dragon_knight_breathe_fire_debuff:OnDestroy()
    if IsClient() then return end
end
function modifier_dragon_knight_breathe_fire_debuff:OnIntervalThink()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local parent = self:GetParent()
    ability:DealDamage(caster, parent, self.damage_per_second, { damage_type = DAMAGE_TYPE_PHYSICAL })
end
function modifier_dragon_knight_breathe_fire_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
    }
end
function modifier_dragon_knight_breathe_fire_debuff:GetModifierMagicalResistanceBonus()
    return -self.magic_resist_reduction
end
function modifier_dragon_knight_breathe_fire_debuff:GetModifierBaseAttackTimeConstant()
	if self._preventLoops then return end
	self._preventLoops = true
	self.previous_base_attack_time = self:GetParent():GetBaseAttackTime()
	self._preventLoops = false
    return self.previous_base_attack_time*(1+self.base_attack_time_increase/100)
end