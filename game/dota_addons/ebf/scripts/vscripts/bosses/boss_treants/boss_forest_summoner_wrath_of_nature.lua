boss_forest_summoner_wrath_of_nature = class({})

function boss_forest_summoner_wrath_of_nature:IsStealable()
	return true
end

function boss_forest_summoner_wrath_of_nature:IsHiddenWhenStolen()
	return false
end

function boss_forest_summoner_wrath_of_nature:OnSpellStart()
	local caster = self:GetCaster()
	local point = caster:GetAbsOrigin()

	local previousEnemy = caster

	local damage = self:GetTalentSpecialValueFor("damage")
	local bonusDamagePerHit = damage * self:GetTalentSpecialValueFor("damage_percent_add") / 100
	local bounces = self:GetTalentSpecialValueFor("max_targets")
	local jump_delay = self:GetTalentSpecialValueFor("jump_delay")
	
	local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_furion/furion_wrath_of_nature_cast.vpcf", PATTACH_POINT_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(nfx, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(nfx, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)

	EmitSoundOn("Hero_boss_forest_summoner.WrathOfNature_Cast.Self", caster)
	
	local hitTable = {}
	Timers:CreateTimer(0,function()
		local enemies = self:GetCaster():FindEnemyUnitsInRadius(previousEnemy:GetAbsOrigin(), FIND_UNITS_EVERYWHERE, {order = FIND_CLOSEST})
		for _,enemy in pairs(enemies) do
			if not hitTable[enemy:entindex()] then -- only hit every target once
				--Spare ourselves sound complaints
				--EmitSoundOn("Hero_boss_forest_summoner.WrathOfNature_Damage.Creep", enemy)
				hitTable[enemy:entindex()] = true
				local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_furion/furion_wrath_of_nature.vpcf", PATTACH_POINT_FOLLOW, caster)
				ParticleManager:SetParticleControlEnt(particle, 0, previousEnemy, PATTACH_POINT_FOLLOW, "attach_hitloc", previousEnemy:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(particle, 1, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(particle, 2, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(particle, 3, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(particle, 4, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
				ParticleManager:ReleaseParticleIndex(particle)
				
				
				self:DealDamage(caster, enemy, damage, {}, 0)
				local treant = caster:CreateSummon( "npc_dota_boss_treant", enemy:GetAbsOrigin(), self:GetSpecialValueFor("kill_damage_duration"))
				FindClearSpaceForUnit(treant, enemy:GetAbsOrigin() + RandomVector(128), true)
				

				previousEnemy = enemy
				bounces = bounces-1

				return jump_delay
			end -- no valid targets found
		end
	end)
end