boss_death_avatar_plague_ward = class({})

function boss_death_avatar_plague_ward:OnSpellStart()
	local caster = self:GetCaster()
	
	local duration = self:GetSpecialValueFor("duration")
	if not caster:IsAlive() then 
		return
	end
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self:GetTrueCastRange() ) ) do
		for i = 1, self:GetSpecialValueFor("wards_spawned") do
			CreateUnitByNameAsync( "npc_dota_minion_death_bringer", enemy:GetAbsOrigin() + ActualRandomVector( 128, 32 ), true, nil, nil, caster:GetTeamNumber(),
			function(entUnit)
				entUnit:MoveToTargetToAttack( enemy )
				ParticleManager:FireParticle( "particles/units/heroes/hero_venomancer/venomancer_ward_cast.vpcf", PATTACH_POINT_FOLLOW, entUnit )
			end)
		end
	end
end