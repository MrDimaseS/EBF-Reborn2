boss_demonic_cultist_rain_of_chaos = class({})

function boss_demonic_cultist_rain_of_chaos:GetAOERadius()
	return self:GetSpecialValueFor("aoe")
end

function boss_demonic_cultist_rain_of_chaos:OnSpellStart()
	local caster = self:GetCaster()
	local position = self:GetCursorPosition()
	
	local radius = self:GetSpecialValueFor("aoe")
	local duration = self:GetSpecialValueFor("stun_duration")
	local golems = self:GetSpecialValueFor("golem_count")
	local stun_delay = self:GetSpecialValueFor("stun_delay")
	
	EmitSoundOn("Hero_Warlock.RainOfChaos", caster)
	local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_warlock/warlock_rain_of_chaos_start.vpcf", PATTACH_POINT, caster)
				ParticleManager:SetParticleControl(nfx, 0, position)
				ParticleManager:SetParticleControl(nfx, 1, position)
				ParticleManager:SetParticleControl(nfx, 2, Vector( radius, radius, radius ) )
				ParticleManager:ReleaseParticleIndex(nfx)

	Timers:CreateTimer(stun_delay, function()
		local nfx2 = ParticleManager:CreateParticle("particles/units/heroes/hero_warlock/warlock_rain_of_chaos.vpcf", PATTACH_POINT, caster)
					 ParticleManager:SetParticleControl(nfx2, 0, position)
					 ParticleManager:SetParticleControl(nfx2, 1, Vector(2,2,2))
					 ParticleManager:SetParticleControl(nfx2, 2, position)
					 ParticleManager:SetParticleControl(nfx2, 5, position)
					 ParticleManager:ReleaseParticleIndex(nfx2)

		local enemies = caster:FindEnemyUnitsInRadius(position, radius)
		for _,enemy in pairs(enemies) do
			self:Stun(enemy, duration, false)
		end

		for i = 1, golems do
			CreateUnitByName( "npc_dota_boss_demonic_golem", position + RandomVector( radius/2 ), true, nil, nil, self:GetCaster():GetTeam() )
		end
	end)
end