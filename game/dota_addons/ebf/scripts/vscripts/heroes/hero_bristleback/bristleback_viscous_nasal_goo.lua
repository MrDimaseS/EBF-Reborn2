bristleback_viscous_nasal_goo = class({})

function bristleback_viscous_nasal_goo:GetIntrinsicModifierName()
    return "modifier_bristleback_viscous_nasal_goo_autocast"
end
function bristleback_viscous_nasal_goo:GetBehavior()
    if self:GetSpecialValueFor("radius") ~= 0 then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_AUTOCAST
    else
        return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING + DOTA_ABILITY_BEHAVIOR_AUTOCAST
    end
end
function bristleback_viscous_nasal_goo:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	if self:GetSpecialValueFor("radius") > 0 then target = nil end
	if not target then
		caster:StartGesture(ACT_DOTA_CAST_ABILITY_1)
	end
	self:DoGoo( target )
end
function bristleback_viscous_nasal_goo:DoGoo( target, source )
    local caster = self:GetCaster()
    local origin = source or caster
	
    local radius = self:GetSpecialValueFor("radius")
    local goo_speed = self:GetSpecialValueFor("goo_speed")
	
	if target then
		self:FireTrackingProjectile("particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_goo.vpcf", target, goo_speed )
	else
		local enemies = caster:FindEnemyUnitsInRadius( origin:GetAbsOrigin(), radius)
        for _, enemy in ipairs(enemies) do
            self:FireTrackingProjectile("particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_goo.vpcf", enemy, goo_speed, {source = origin} )
        end
	end
	
    -- sounds
	EmitSoundOnLocationWithCaster(origin:GetAbsOrigin(), "Hero_Bristleback.ViscousGoo.Cast", caster)
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
    local stacks = modifier:GetStackCount() - 1
	
	local slip_chance = self:GetSpecialValueFor("slip_chance")
	if slip_chance > 0 and self:RollPRNG( slip_chance ) then
		local slip_base_duration = self:GetSpecialValueFor("slip_base_duration")
		local slip_stack_duration = self:GetSpecialValueFor("slip_stack_duration")
		local slip_duration = slip_base_duration + slip_stack_duration * stacks
		
		self:Disarm(target, slip_duration)
	end
	
    local baseDamage = self:GetSpecialValueFor("base_damage")
    local stackDamage = self:GetSpecialValueFor("damage_per_stack")
    local damage = self:GetSpecialValueFor("base_damage") + stackDamage * stacks
	self:DealDamage( caster, target, damage )

	
    EmitSoundOn("Hero_Bristleback.ViscousGoo.Target", target)
end

modifier_bristleback_viscous_nasal_goo_autocast = class(persistentModifier)
LinkLuaModifier( "modifier_bristleback_viscous_nasal_goo_autocast", "heroes/hero_bristleback/bristleback_viscous_nasal_goo", LUA_MODIFIER_MOTION_NONE )

function modifier_bristleback_viscous_nasal_goo_autocast:OnCreated()
    if IsClient() then return end

    self:StartIntervalThink(0)
end

function modifier_bristleback_viscous_nasal_goo_autocast:OnIntervalThink()
    local caster = self:GetCaster()
    if caster:IsSilenced() or caster:IsStunned() then return end

    local ability = self:GetAbility()
	local target = caster:GetAggroTarget()
	if not ( IsEntitySafe( target ) and IsEntitySafe( ability ) ) then return end
    if ability:GetAutoCastState() and ability:IsFullyCastable() then
		caster:SetCursorCastTarget( target )
        ability:CastAbility()
    end
end

function modifier_bristleback_viscous_nasal_goo_autocast:IsHidden()
	return true
end

modifier_bristleback_viscous_nasal_goo_debuff = class({})
LinkLuaModifier( "modifier_bristleback_viscous_nasal_goo_debuff", "heroes/hero_bristleback/bristleback_viscous_nasal_goo", LUA_MODIFIER_MOTION_NONE )

function modifier_bristleback_viscous_nasal_goo_debuff:OnCreated()
	local quills = self:GetCaster():FindAbilityByName("bristleback_quill_spray")
	self.bonus_goo_power = quills:GetSpecialValueFor("bonus_goo_power") / 100
	self:OnRefresh()
end
function modifier_bristleback_viscous_nasal_goo_debuff:OnRefresh()
    self.base_armor = self:GetSpecialValueFor("base_armor")
    self.armor_per_stack = self:GetSpecialValueFor("armor_per_stack")
    self.base_move_slow = self:GetSpecialValueFor("base_move_slow")
    self.move_slow_per_stack = self:GetSpecialValueFor("move_slow_per_stack")
    self.base_attack_damage_reduction = self:GetSpecialValueFor("base_attack_damage_reduction")
    self.stack_attack_damage_reduction = self:GetSpecialValueFor("stack_attack_damage_reduction")
end
function modifier_bristleback_viscous_nasal_goo_debuff:OnDestroy()
    if IsClient() then return end
    if self.effect then ParticleManager:DestroyParticle(self.effect, true) end
end
function modifier_bristleback_viscous_nasal_goo_debuff:OnStackCountChanged(old)
    if IsClient() then return end
    self.effect = self.effect or ParticleManager:CreateParticle("particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_stack.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(self.effect, 1, Vector(0, self:GetStackCount(), 0))
end
function modifier_bristleback_viscous_nasal_goo_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE
    }
end
function modifier_bristleback_viscous_nasal_goo_debuff:GetModifierPhysicalArmorBonus()
    return -(self.base_armor + self.armor_per_stack * (self:GetStackCount() - 1)) * (1 + self.bonus_goo_power * self:GetParent():GetModifierStackCount( "modifier_bristleback_quill_spray_boogerman", self:GetCaster() ) )
end
function modifier_bristleback_viscous_nasal_goo_debuff:GetModifierMoveSpeedBonus_Percentage()
    return -(self.base_move_slow + self.move_slow_per_stack * (self:GetStackCount() - 1)) * (1 + self.bonus_goo_power * self:GetParent():GetModifierStackCount( "modifier_bristleback_quill_spray_boogerman", self:GetCaster() ) )
end
function modifier_bristleback_viscous_nasal_goo_debuff:GetModifierBaseDamageOutgoing_Percentage()
    return -(self.base_attack_damage_reduction + self.stack_attack_damage_reduction * (self:GetStackCount() - 1)) * (1 + self.bonus_goo_power * self:GetParent():GetModifierStackCount( "modifier_bristleback_quill_spray_boogerman", self:GetCaster() ) )
end
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