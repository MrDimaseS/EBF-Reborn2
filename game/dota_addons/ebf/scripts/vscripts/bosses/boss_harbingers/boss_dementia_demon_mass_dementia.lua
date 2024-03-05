boss_dementia_demon_mass_dementia = class({})

function boss_dementia_demon_mass_dementia:OnSpellStart()
	local caster = self:GetCaster()
	
	local duration = self:GetSpecialValueFor("disruption_duration")
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self:GetTrueCastRange() ) ) do
		enemy:AddNewModifier( caster, self, "modifier_shadow_demon_disruption", {duration = duration} )
		Timers:CreateTimer( duration, function()
		CreateUnitByNameAsync( "npc_dota_minion_dementia_splinter", enemy:GetAbsOrigin() + ActualRandomVector( 128, 32 ), true, nil, nil, caster:GetTeamNumber(),
		function(entUnit)
			entUnit:MoveToTargetToAttack( enemy )
		end)
		end)
	end
end