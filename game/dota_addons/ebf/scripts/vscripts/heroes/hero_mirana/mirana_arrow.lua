mirana_arrow = class({})

function mirana_arrow:OnSpellStart()
	local caster = self:GetCaster()
	local direction = CalculateDirection( self:GetCursorPosition(), caster )
	
	self.projectiles = self.projectiles or {}
	
	local speed = self:GetSpecialValueFor("arrow_speed")
	local width = self:GetSpecialValueFor("arrow_width")
	local distance = self:GetSpecialValueFor("arrow_range")
	local angle = self:GetSpecialValueFor("arrow_angle")
	local arrows = self:GetSpecialValueFor("total_arrows")
	
	local maxRange = self:GetSpecialValueFor("arrow_max_stunrange")
	
	for i = 1, arrows do
		local arrowDir = RotateVector2D( direction, ToRadians( angle * math.ceil((i-1)/2) * (-1)^i ) )
		local projectile = self:FireLinearProjectile("particles/units/heroes/hero_mirana/mirana_spell_arrow.vpcf", arrowDir * speed, distance, width)
		local projectileData = {}
		projectileData.damage = self:GetAbilityDamage()
		projectileData.maxDmg = projectileData.damage + self:GetSpecialValueFor("arrow_bonus_damage")
		projectileData.dmgGrowth = ( ( projectileData.maxDmg - projectileData.damage ) / (maxRange / speed) ) * FrameTime()
		projectileData.stun = self:GetSpecialValueFor("arrow_min_stun")
		projectileData.maxStun = self:GetSpecialValueFor("arrow_max_stun")
		projectileData.stunGrowth = ( ( projectileData.maxStun - projectileData.stun ) / (maxRange / speed) ) * FrameTime()
		
		if caster:HasScepter() then
			local starfall = caster:FindAbilityByName("mirana_starfall")
			projectileData.scepterTargets = {}
			projectileData.scepterRadius = self:GetSpecialValueFor("scepter_radius")
			projectileData.scepterDamage = starfall:GetSpecialValueFor("damage") * self:GetSpecialValueFor("scepter_starstorm_target_pct") / 100
		end
		
		self.projectiles[projectile] = projectileData
	end
end

function mirana_arrow:OnProjectileThinkHandle( projectile )
	if self.projectiles[projectile] then
		local caster = self:GetCaster()
		if self.projectiles[projectile].stun < self.projectiles[projectile].maxStun then
			self.projectiles[projectile].stun = math.min( self.projectiles[projectile].maxStun, self.projectiles[projectile].stun + self.projectiles[projectile].stunGrowth )
		end
		if self.projectiles[projectile].damage < self.projectiles[projectile].maxDmg then
			self.projectiles[projectile].damage = math.min( self.projectiles[projectile].maxDmg, self.projectiles[projectile].damage + self.projectiles[projectile].dmgGrowth )
		end
		if self.projectiles[projectile].scepterTargets then
			for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( ProjectileManager:GetLinearProjectileLocation( projectile ), self.projectiles[projectile].scepterRadius ) ) do
				if not self.projectiles[projectile].scepterTargets[enemy] then
					self.projectiles[projectile].scepterTargets[enemy] = true
					ParticleManager:FireParticle("particles/units/heroes/hero_mirana/mirana_loadout.vpcf", PATTACH_POINT_FOLLOW, enemy, {[0]=enemy:GetAbsOrigin()})
					Timers:CreateTimer(0.57, function() --particle delay
						EmitSoundOn("Ability.StarfallImpact", enemy)
						self:DealDamage( caster, enemy, self.projectiles[projectile].scepterDamage )
					end)
				end
			end
		end
	end
end

function mirana_arrow:OnProjectileHitHandle( target, position, projectile )
	if self.projectiles[projectile] then
		if target then
			local caster = self:GetCaster()
			
			if target:IsConsideredHero() or target:IsAncient() then
				self:DealDamage( caster, target, self.projectiles[projectile].damage )
				self:Stun( target, self.projectiles[projectile].stun )
			else
				self:DealDamage( caster, target, self.projectiles[projectile].damage + target:GetMaxHealth(), {damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS} )
			end
			return true
		else
			self.projectiles[projectile] = nil
		end
	end
end