boss_zombie_soul_rip = class({})

function boss_zombie_soul_rip:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	local radius = self:GetSpecialValueFor("radius")
	local units = self:GetSpecialValueFor("max_units")
	local max_units = self:GetSpecialValueFor("max_units")
	local damage_per_unit = self:GetSpecialValueFor("damage_per_unit")
	
	local enemies = caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), radius )
	for _, enemy in ipairs( enemies ) do
		self:DealDamage( caster, enemy, damage_per_unit )
				ParticleManager:FireRopeParticle("particles/units/heroes/hero_undying/undying_soul_rip_damage.vpcf", PATTACH_ABSORIGIN_FOLLOW, target, enemy)
	end
	max_units = math.max( 0, max_units - #enemies )
	if max_units > 0 then
		local allies = caster:FindFriendlyUnitsInRadius( caster:GetAbsOrigin(), radius )
		for _, ally in ipairs( enemies ) do
			if max_units > 0 then
				self:DealDamage( caster, ally, damage_per_unit )
				ParticleManager:FireRopeParticle("particles/units/heroes/hero_undying/undying_soul_rip_damage.vpcf", PATTACH_ABSORIGIN_FOLLOW, target, ally)
				max_units = max_units - 1
			else
				break
			end
		end
	end
	
	self:DealDamage( caster, target, damage_per_unit * (units - max_units) )
	EmitSoundOn("Hero_Undying.SoulRip.Enemy", target)
end