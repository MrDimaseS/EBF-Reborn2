boss_golem_rock_throw = class({})

function boss_golem_rock_throw:GetAOERadius()
	return self:GetSpecialValueFor("search_radius")
end

function boss_golem_rock_throw:OnSpellStart()
	local caster = self:GetCaster()
	local position = self:GetCursorPosition()
	
	local golemsSpawned = self:GetSpecialValueFor("golems_spawned") + self:GetSpecialValueFor("bonus_golems_per_player") * math.min( 5, HeroList:GetActiveHeroCount() )
	
	local golemTossed
	for _, golem in ipairs( caster:FindFriendlyUnitsInRadius( caster:GetAbsOrigin(), caster:GetAttackRange() ) ) do
		if golem ~= caster and golem:GetUnitName() == "npc_dota_boss_granite_golem" then
			golemTossed = golem
			break
		end
	end
	if not golemTossed then golemsSpawned = golemsSpawned - 1 end
	
	local radius = self:GetAOERadius()
	local baseGolemPosition = position
	local impact_radius = self:GetSpecialValueFor("impact_radius")
	local rings = radius / self:GetSpecialValueFor("impact_radius")
	local golemsPerRing = math.floor( golemsSpawned / rings )
	local looseGolems = golemsPerRing * rings - golemsSpawned
	
	local ogDir = caster:GetForwardVector()
	
	if golemTossed then
		self:ThrowGolem( golemTossed, position )
	else
		local mudGolem = CreateUnitByName( "npc_dota_boss_mud_golem", caster:GetAbsOrigin() + RandomVector( 50 ), true, nil, nil, caster:GetTeam() )
		self:ThrowGolem( mudGolem, position )
	end
	for i = 1, rings do
		for j = 1, golemsPerRing do
			local mudGolem = CreateUnitByName( "npc_dota_boss_mud_golem", caster:GetAbsOrigin() + RandomVector( 50 ), true, nil, nil, caster:GetTeam() )
			local tossPosition = position + RandomVector( i * impact_radius ) + ActualRandomVector( impact_radius )
			self:ThrowGolem( mudGolem, tossPosition )
		end
	end
end

function boss_golem_rock_throw:ThrowGolem( golem, tossPosition )
	local caster = self:GetCaster()
	
	local distance = CalculateDistance( tossPosition, golem )
	local height = 150 + (640/(distance+self:GetAOERadius()))*150
	
	local radius = self:GetSpecialValueFor("impact_radius")
	local bonusRadius = self:GetSpecialValueFor("golem_bonus_radius")
	local damage = self:GetSpecialValueFor("damage")
	local bonusDamage = self:GetSpecialValueFor("golem_bonus_damage")
	local duration = self:GetSpecialValueFor("duration")
	local toss_duration = math.max( 0.8, distance / self:GetSpecialValueFor("speed") )
	
	local totalDamage = damage + TernaryOperator( bonusDamage, golem:GetUnitName() == "npc_dota_boss_granite_golem", 0 )
	local totalRadius = radius + TernaryOperator( bonusRadius, golem:GetUnitName() == "npc_dota_boss_granite_golem", 0 )
	
	ParticleManager:FireWarningParticle(tossPosition, radius)
	
	EmitSoundOn("Hero_Tiny.Toss.Target", golem)
	golem:ApplyKnockBack(tossPosition, toss_duration, toss_duration, -distance, height, caster, self)
	golem._stillProcessingCreation = true
	Timers:CreateTimer( toss_duration, function()
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( golem:GetAbsOrigin(), totalRadius ) ) do
			if not enemy:FindModifierByNameAndCaster( "modifier_boss_rock_throw_immunity", caster ) then
				enemy:AddNewModifier( caster, self, "modifier_boss_rock_throw_immunity", {duration = 0.25} )
				self:DealDamage( caster, enemy, totalDamage, {damage_type = DAMAGE_TYPE_MAGICAL} )
				self:Stun( enemy, duration )
			end
		end
		ParticleManager:FireParticle("particles/units/heroes/hero_tiny/tiny_toss_impact.vpcf", PATTACH_POINT_FOLLOW, golem )
		
		for _, unit in ipairs( caster:FindFriendlyUnitsInRadius( golem:GetAbsOrigin(), 64 + golem:GetPaddedCollisionRadius() * 2 ) ) do
			if unit ~= golem and unit:GetUnitName() == golem:GetUnitName() and not unit._stillProcessingCreation then
				local newHP = unit:GetHealth() + golem:GetHealth()
				unit:SetCoreHealth( unit:GetMaxHealth() + golem:GetMaxHealth() )
				unit:SetHealth( newHP )
				unit:SetAverageBaseDamage( unit:GetAverageBaseDamage() + golem:GetAverageBaseDamage(), 10 )
				
				golem:ForceKill( false )
				return
			end
		end
		golem._stillProcessingCreation = false
	end)
end

modifier_boss_rock_throw_immunity = class({})
LinkLuaModifier( "modifier_boss_rock_throw_immunity", "bosses/boss_golems/boss_golem_rock_throw", LUA_MODIFIER_MOTION_NONE)

function modifier_boss_rock_throw_immunity:IsHidden()
	return true
end

function modifier_boss_rock_throw_immunity:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE 
end