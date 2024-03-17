sniper_assassinate = class({})

function sniper_assassinate:GetAOERadius()
	if self:GetCaster():HasScepter() then return self:GetSpecialValueFor("scepter_radius") end
end

function sniper_assassinate:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	EmitSoundOn("Ability.AssassinateLoad", self:GetCaster())

	target:AddNewModifier( caster, self, "modifier_sniper_assassinate", {} )
	if caster:HasScepter() then
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
	
	self.projectileTable = self.projectileTable or {}
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), -1 ) ) do
		if enemy:HasModifier("modifier_sniper_assassinate") then
			local projectile = self:FireTrackingProjectile("particles/units/heroes/hero_sniper/sniper_assassinate.vpcf", enemy, self:GetSpecialValueFor("projectile_speed"), {}, DOTA_PROJECTILE_ATTACHMENT_ATTACK_1, false, true, 100)
			self.projectileTable[projectile] = {impact_power = 1}
		end
	end
end

function sniper_assassinate:OnProjectileHitHandle(target, vLocation, projectile)
	local caster = self:GetCaster()
	if target and not target:TriggerSpellAbsorb( self ) then
		EmitSoundOn("Hero_Sniper.AssassinateDamage", caster)
		self:Stun(target, self:GetSpecialValueFor("ministun_duration") )
		caster:PerformGenericAttack(target, true, nil, nil, true)
		local impact_power = self.projectileTable[projectile].impact_power
		self:DealDamage( caster, target, self:GetSpecialValueFor("impact_damage") * impact_power )
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
					local projectile = self:FireTrackingProjectile( "particles/units/heroes/hero_sniper/sniper_assassinate.vpcf", newTarget, self:GetSpecialValueFor("projectile_speed"), {source = target}, DOTA_PROJECTILE_ATTACHMENT_ATTACK_1, false, true, 100 )
					self.projectileTable[projectile] = {impact_power = impact_power * self:GetSpecialValueFor("bounce_power") / 100}
				end
			end
		end
		target:RemoveModifierByName("modifier_sniper_assassinate")
		self.projectileTable[projectile] = nil
	end
end