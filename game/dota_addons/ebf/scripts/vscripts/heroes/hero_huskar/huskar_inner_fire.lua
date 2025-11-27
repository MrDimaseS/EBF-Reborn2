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
	
	local burn = caster:GetBurn()
	caster:RemoveBurn( burn )
	
	local bonusDamage = self:GetSpecialValueFor("bonus_burn_damage")
	if bonusDamage > 0 then
		damage = damage + bonusDamage * burn
	end
	local healPct = self:GetSpecialValueFor("damage_to_heal") / 100
	if healPct > 0 then
		local bonusHeal = self:GetSpecialValueFor("bonus_burn_heal")
		local heal = damage * healPct + bonusHeal * burn
		caster:HealEvent( heal, self, caster )
	end
	
	local enemies = caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), radius )
	for _, enemy in ipairs( enemies ) do
		self:DealDamage( caster, enemy, damage )
		enemy:ApplyKnockBack(caster:GetAbsOrigin(), kbDuration, kbDuration, math.max(50, kbDistance - CalculateDistance(enemy, caster)), 0, caster, self, false)
		
		enemy:AddNewModifier( caster, enemy, "modifier_huskar_inner_fire_disarm", {duration = duration})
	end
	
	ParticleManager:FireParticle("particles/units/heroes/hero_huskar/huskar_inner_fire.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	caster:EmitSound("Hero_Huskar.Inner_Fire.Cast")
end