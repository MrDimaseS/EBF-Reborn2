huskar_inner_fire = class({})

function huskar_inner_fire:IsStealable()
	return true
end

function huskar_inner_fire:IsHiddenWhenStolen()
	return false
end

function huskar_inner_fire:OnSpellStart()
	local caster = self:GetCaster()
	
	local damage = self:GetSpecialValueFor("damage")
	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("disarm_duration")
	local kbDistance = self:GetSpecialValueFor("knockback_distance")
	local kbDuration = self:GetSpecialValueFor("knockback_duration")
	
	local talent1 = caster:HasTalent("special_bonus_unique_huskar_inner_fire_1")
	local tDuration = caster:FindTalentValue("special_bonus_unique_huskar_inner_fire_1", "duration")
	
	local delay
	local stacks = 0
	local enemies = caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), radius )
	for _, enemy in ipairs( enemies ) do
		if not enemy:TriggerSpellAbsorb(self) then
			self:DealDamage( caster, enemy, damage )
			enemy:ApplyKnockBack(caster:GetAbsOrigin(), kbDuration, kbDuration, math.max(50, kbDistance - CalculateDistance(enemy, caster)), 0, caster, self, false)
			
			enemy:Silence(target, duration)
		end
	end
	-- if stacks > 0 then
		-- caster:AddNewModifier( caster, self, "modifier_huskar_inner_fire_damage", {duration = duration}):SetStackCount(#enemies)
	-- end
	ParticleManager:FireParticle("particles/units/heroes/hero_huskar/huskar_inner_fire.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	caster:EmitSound("Hero_Huskar.Inner_Fire.Cast")
end

modifier_huskar_inner_fire_talent = class({})
LinkLuaModifier("modifier_huskar_inner_fire_talent", "heroes/hero_huskar/huskar_inner_fire", LUA_MODIFIER_MOTION_NONE)

function modifier_huskar_inner_fire_talent:OnCreated()
	self.as = self:GetCaster():FindTalentValue("special_bonus_unique_huskar_inner_fire_1")
end

function modifier_huskar_inner_fire_talent:OnRefresh()
	self.as = self:GetCaster():FindTalentValue("special_bonus_unique_huskar_inner_fire_1")
end

function modifier_huskar_inner_fire_talent:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end

function modifier_huskar_inner_fire_talent:GetModifierAttackSpeedBonus_Constant()
	return self.as
end

modifier_huskar_inner_fire_damage = class({})
LinkLuaModifier("modifier_huskar_inner_fire_damage", "heroes/hero_huskar/huskar_inner_fire", LUA_MODIFIER_MOTION_NONE)
function modifier_huskar_inner_fire_damage:OnCreated(kv)
	self.damage = self:GetSpecialValueFor("bonus_damage")
end

function modifier_huskar_inner_fire_damage:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    }

    return funcs
end

function modifier_huskar_inner_fire_damage:GetModifierPreAttack_BonusDamage( params )
    return self.damage * self:GetStackCount()
end

function modifier_huskar_inner_fire_damage:IsHidden()
    return true
end