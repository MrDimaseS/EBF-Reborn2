sniper_assassinate = class({})

function sniper_assassinate:GetAOERadius()
	return self:GetSpecialValueFor("aoe_radius")
end

function sniper_assassinate:Spawn()
	self.projectileTable = self.projectileTable or {}
end

function sniper_assassinate:GetCastPoint()
	return self:GetSpecialValueFor("AbilityCastPoint")
end

function sniper_assassinate:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	EmitSoundOn("Ability.AssassinateLoad", self:GetCaster())

	target:AddNewModifier( caster, self, "modifier_sniper_assassinate", {} )
	if self:GetAOERadius() > 0 then
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), self:GetAOERadius() ) ) do
			if enemy ~= target then
				enemy:AddNewModifier( caster, self, "modifier_sniper_assassinate", {} )
			end
		end
	end
	return true
end

function sniper_assassinate:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), -1 ) ) do
		enemy:RemoveModifierByName("modifier_sniper_assassinate")
	end
end

function sniper_assassinate:OnSpellStart()
	local caster = self:GetCaster()

	EmitSoundOn("Ability.Assassinate", self:GetCaster())
	EmitSoundOn("Hero_Sniper.AssassinateProjectile", self:GetCaster())
	
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), -1 ) ) do
		if enemy:HasModifier("modifier_sniper_assassinate") then
			self:LaunchAssassinate( enemy )
		end
	end
end

function sniper_assassinate:LaunchAssassinate( target, power, source )
	self.projectileTable = self.projectileTable or {}
	local projectile = self:FireTrackingProjectile("particles/units/heroes/hero_sniper/sniper_assassinate.vpcf", target, self:GetSpecialValueFor("projectile_speed"), {source = source or self:GetCaster()}, TernaryOperator( DOTA_PROJECTILE_ATTACHMENT_ATTACK_1, source ~= nil, DOTA_PROJECTILE_ATTACHMENT_HITLOCATION ), false, true, 100)
	self.projectileTable[projectile] = {impact_power = power or 1}
	return projectile
end

function sniper_assassinate:OnProjectileHitHandle(target, vLocation, projectile)
	local caster = self:GetCaster()
	if target and not target:TriggerSpellAbsorb( self ) then
		local impact_power = self.projectileTable[projectile].impact_power
		EmitSoundOn("Hero_Sniper.AssassinateDamage", caster)
		self:Stun(target, self:GetSpecialValueFor("ministun_duration") * impact_power )
		caster:PerformGenericAttack(target, true, {ability = self})
		
		if not target:IsAlive() then
			if target:IsConsideredHero() then
				caster:RefreshAllCooldowns( false )
			else
				local newTarget
				for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), self:GetTrueCastRange() ) ) do
					if enemy ~= target and not enemy:IsConsideredHero() then
						newTarget = enemy
						break
					end
				end
				if not newTarget then
					for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), self:GetTrueCastRange() ) ) do
						if enemy ~= target then
							newTarget = enemy
							break
						end
					end
				end
				if newTarget then
					self:LaunchAssassinate( newTarget, impact_power * self:GetSpecialValueFor("bounce_power") / 100, target )
				end
			end
		end
		target:RemoveModifierByName("modifier_sniper_assassinate")
		self.projectileTable[projectile] = nil
	end
end