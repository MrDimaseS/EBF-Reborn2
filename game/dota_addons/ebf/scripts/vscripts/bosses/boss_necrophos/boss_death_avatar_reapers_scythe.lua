boss_death_avatar_reapers_scythe = class({})

function boss_death_avatar_reapers_scythe:OnSpellStart()
	local caster = self:GetCaster()
	
	
	
	local duration = self:GetSpecialValueFor("stun_duration")
	local damage_per_health = self:GetSpecialValueFor("damage_per_health")
	
		EmitSoundOn("Hero_Necrolyte.ReapersScythe.Cast", caster)
	for _, target in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), -1 ) ) do
		local sFX = ParticleManager:CreateParticle("particles/units/heroes/hero_necrolyte/necrolyte_scythe_start.vpcf", PATTACH_WORLDORIGIN, caster)
		ParticleManager:SetParticleControl(sFX, 1, target:GetAbsOrigin() )
		local modifier = self:Stun(target, duration)
		if modifier then
			local nFX = ParticleManager:CreateParticle("particles/units/heroes/hero_necrolyte/necrolyte_scythe.vpcf", PATTACH_POINT_FOLLOW, target)
			modifier:AddEffect(nFX)
		end
		
		Timers:CreateTimer(duration, function()
			if target:IsAlive() then
				self:DealDamage( caster, target, target:GetHealthDeficit() * damage_per_health )
			end
		end)
	end
end