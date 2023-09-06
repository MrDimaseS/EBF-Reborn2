tinker_heat_seeking_missile = class({})

function tinker_heat_seeking_missile:OnSpellStart()
	local caster = self:GetCaster()

    local particleName = "particles/units/heroes/hero_tinker/tinker_missile.vpcf"
    local projectileSpeed = self:GetTalentSpecialValueFor( "speed")
    local radius = self:GetTalentSpecialValueFor( "radius")
    local rockets = self:GetTalentSpecialValueFor( "targets")
	
    local heroType = {}
	local creepType = {}
    local enemies = caster:FindEnemyUnitsInRadius(caster:GetAbsOrigin(), radius, {order = FIND_CLOSEST}) 

	EmitSoundOn("Hero_Tinker.Heat-Seeking_Missile", caster)
	for _,enemy in pairs( enemies ) do
		if enemy:IsConsideredHero() then
			table.insert( heroType, enemy )
		else
			table.insert( creepType, enemy )
		end
	end
	
	for _, hero in ipairs( heroType ) do
		self:FireTrackingProjectile(particleName, hero, projectileSpeed, {}, DOTA_PROJECTILE_ATTACHMENT_ATTACK_3, false, true, 100)
		rockets = rockets - 1
		if rockets <= 0 then
			return
		end
	end
	for _, creep in ipairs( creepType ) do
		self:FireTrackingProjectile(particleName, creep, projectileSpeed, {}, DOTA_PROJECTILE_ATTACHMENT_ATTACK_3, false, true, 100)
		rockets = rockets - 1
		if rockets <= 0 then
			return
		end
	end
end

function tinker_heat_seeking_missile:OnProjectileHit(hTarget, vLocation)
	local caster = self:GetCaster()

	if hTarget ~= nil and not hTarget:TriggerSpellAbsorb( self ) then
		EmitSoundOn("Hero_Tinker.Heat-Seeking_Missile.Impact", hTarget)
		ParticleManager:FireParticle("particles/units/heroes/hero_tinker/tinker_missle_explosion.vpcf", PATTACH_POINT, hTarget, {})

		self:DealDamage(caster, hTarget, self:GetSpecialValueFor("damage"))
		
		local ministun = self:GetSpecialValueFor("ministun_duration")
		if ministun > 0 then
			self:Stun(hTarget, ministun)
		end
	end
end