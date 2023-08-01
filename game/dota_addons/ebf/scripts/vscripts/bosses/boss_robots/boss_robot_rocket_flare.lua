boss_robot_rocket_flare = class({})

function boss_robot_rocket_flare:IsStealable()
	return true
end

function boss_robot_rocket_flare:IsHiddenWhenStolen()
	return false
end

function boss_robot_rocket_flare:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

if IsServer() then
	function boss_robot_rocket_flare:OnSpellStart()
		local targetPos = self:GetCursorPosition()
		self:FireFlashbang(targetPos)
	end
	
	function boss_robot_rocket_flare:FireFlashbang(position)
		local caster = self:GetCaster()
		self.projectiles = self.projectiles or {}
		
		local speed = self:GetSpecialValueFor("speed")
		
		local projectile = self:FireLinearProjectile("", CalculateDirection( position, self:GetCaster() ) * speed, CalculateDistance( position, self:GetCaster() ), 0 )
		EmitSoundOn("Hero_Rattletrap.Rocket_Flare.Fire", self:GetCaster())
		
		local nFX = ParticleManager:CreateParticle("particles/units/heroes/hero_rattletrap/rattletrap_rocket_flare.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl( nFX, 0, caster:GetAbsOrigin() )
		ParticleManager:SetParticleControl( nFX, 1, position )
		ParticleManager:SetParticleControl( nFX, 2, Vector( speed, 0, 0 ) )
		
		self.projectiles[projectile] = nFX
	end

	function boss_robot_rocket_flare:OnProjectileHitHandle(target, position, projectile)
		local caster = self:GetCaster()
		if caster:IsNull() then
			return
		end
		if not target then
			local radius = self:GetTalentSpecialValueFor("radius")
			local enemies = FindUnitsInRadius(caster:GetTeamNumber(), position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
			EmitSoundOn("Hero_Rattletrap.Rocket_Flare.Explode", self:GetCaster())
			
			for _, enemy in pairs(enemies) do
				ApplyDamage({victim = enemy, attacker = caster, damage = self:GetTalentSpecialValueFor("damage"), damage_type = self:GetAbilityDamageType(), ability = self})
			end
			ParticleManager:ClearParticle( self.projectiles[projectile] )
			self.projectiles[projectile] = nil
		end
	end
end