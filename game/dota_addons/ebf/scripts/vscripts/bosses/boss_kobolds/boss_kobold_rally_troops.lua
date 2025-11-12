boss_kobold_rally_troops = class({})

function boss_kobold_rally_troops:OnSpellStart()
	local caster = self:GetCaster()
	EmitSoundOn( "Hero_LegionCommander.Duel.Cast", caster )
	EmitSoundOn( "Hero_LegionCommander.Duel.FP", caster )
	
	ParticleManager:FireParticle("particles/units/heroes/heroes_underlord/underlord_pitofmalice.vpcf", PATTACH_ABSORIGIN, caster )
end

function boss_kobold_rally_troops:OnChannelFinish( interrupted )
	local caster = self:GetCaster()
	
	StopSoundOn( "Hero_LegionCommander.Duel.FP", self:GetCaster() )
	if not interrupted then
		EmitSoundOn( "Hero_LegionCommander.Duel.Victory", self:GetCaster() )
		local serfs = self:GetSpecialValueFor("serfs_per_player")
		local radius = self:GetSpecialValueFor("radius")
		
		local minions = {}
		for _, enemy in ipairs( FindAllUnits({team = DOTA_UNIT_TARGET_TEAM_ENEMY}) ) do
			if enemy:GetUnitName() == "npc_dota_boss_kobold_serf" then
			end
		end
		local maxSerfs = (HeroList:GetActiveHeroCount() * serfs) * 3
		for _, hero in ipairs( HeroList:GetActiveHeroes() ) do
			for i = 1, serfs do
				if #minions >= maxSerfs then
					local unitToUpgrade = minions[RandomInt(1,#minions)]
					local bonusHP = unitToUpgrade.MaxEHP * RandomFloat( 0.8, 1.2 )
					local prevHP = unitToUpgrade:GetHealth()
					unitToUpgrade:SetCoreHealth( unitToUpgrade:GetMaxHealth() + bonusHP )
					unitToUpgrade:SetHealth( prevHP + bonusHP )
					unitToUpgrade:SetAverageBaseDamage( unitToUpgrade:GetAverageBaseDamage() + unitToUpgrade.AttackDamageValue, 10 )
					unitToUpgrade:SetModelScale( unitToUpgrade:GetModelScale() + 0.1 )
					ParticleManager:FireParticle("particles/econ/events/spring_2021/hero_levelup_spring_2021.vpcf", PATTACH_POINT_FOLLOW, unitToUpgrade )
					if not unitToUpgrade._wearingACrown then
						ParticleManager:ReleaseParticleIndex(  ParticleManager:CreateParticle( "particles/boss/minion_powerup_overhead.vpcf", PATTACH_OVERHEAD_FOLLOW, unitToUpgrade ) )
						unitToUpgrade._wearingACrown = true
					end
				else
					local spawnPosition = hero:GetAbsOrigin() + ActualRandomVector( radius )
					ParticleManager:FireParticle("particles/units/heroes/heroes_underlord/underlord_pit_cast.vpcf", PATTACH_WORLDORIGIN, nil, {[0] = spawnPosition} )
					Timers:CreateTimer( 0.5, function()
						local unit = CreateUnitByName( "npc_dota_boss_kobold_serf", spawnPosition, true, nil, nil, caster:GetTeam() )
					end)
				end
			end
		end
	end
end