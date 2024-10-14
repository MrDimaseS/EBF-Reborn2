omniknight_purification = class({})

function omniknight_purification:GetAOERadius()
	return self:GetSpecialValueFor("search_radius")
end

function omniknight_purification:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	local damage = self:GetSpecialValueFor("damage")
	local heal = self:GetSpecialValueFor("heal")
	local radius = self:GetSpecialValueFor("radius")
	
	target:HealEvent( heal, self, caster )
	target:Dispel( caster, true )
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), radius ) ) do
		self:DealDamage( caster, enemy, damage )
		ParticleManager:FireParticle("particles/units/heroes/hero_omniknight/omniknight_purification_hit.vpcf", PATTACH_POINT_FOLLOW, enemy )
	end
	
	EmitSoundOnLocationWithCaster(target:GetAbsOrigin(), "Hero_Omniknight.Purification", caster)
	ParticleManager:FireParticle("particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_POINT_FOLLOW, target, {[1] = Vector( radius, radius, radius )})
end