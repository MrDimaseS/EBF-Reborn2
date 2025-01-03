phantom_assassin_stifling_dagger = class({})

function phantom_assassin_stifling_dagger:GetAOERadius()
	return self:GetSpecialValueFor("aoe_radius")
end

function phantom_assassin_stifling_dagger:OnSpellStart( bActivated )
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	self.projectiles = self.projectiles or {}
	
	local speed = self:GetSpecialValueFor("dagger_speed")
	self:FireTrackingProjectile( "particles/units/heroes/hero_phantom_assassin/phantom_assassin_stifling_dagger.vpcf", target, speed )
	local radius = self:GetSpecialValueFor("aoe_radius")
	if radius > 0 then
		local bonusUnitFound = false
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), radius ) ) do
			if target ~= enemy then
				self:FireTrackingProjectile( "particles/units/heroes/hero_phantom_assassin/phantom_assassin_stifling_dagger.vpcf", enemy, speed )
				bonusUnitFound = true
			end
		end
		if not bonusUnitFound then
			local delay = self:GetSpecialValueFor("double_strike_delay")
			local damageFactor = self:GetSpecialValueFor("double_strike_damage") / 100
			Timers:CreateTimer( delay, function()
				local projectile = self:FireTrackingProjectile( "particles/units/heroes/hero_phantom_assassin/phantom_assassin_stifling_dagger.vpcf", target, speed )
				self.projectiles[projectile] = {damageFactor = damageFactor}
			end)
		end
	end
	local tripleStrike = self:GetSpecialValueFor("triple_strike") == 1
	if tripleStrike and not bActivated then
		local strikes = 2
		local enemyTargets = caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self:GetTrueCastRange() )
		if #enemyTargets > 0 then
			Timers:CreateTimer( 0.1, function()
				strikes = strikes - 1
				enemy = enemyTargets[RandomInt(1, #enemyTargets)]
				if enemy then
					table.remove( enemyTargets, 1 )
					caster:SetCursorCastTarget( enemy )
					self:OnSpellStart( true )
					if strikes > 0 then
						return 0.1
					else
						return
					end
				end
			end)
		end
	end
end

function phantom_assassin_stifling_dagger:OnProjectileHitHandle( target, position, projectile )
	if target then
		local caster = self:GetCaster()
		
		local attackFactor = self:GetSpecialValueFor("attack_factor")
		local bonusAttackFactor = self:GetSpecialValueFor("bonus_attack_factor")
		local damage = self:GetSpecialValueFor("base_damage")
		local duration = self:GetSpecialValueFor("duration")
		local stunDuration = self:GetSpecialValueFor("stun_duration")
		local rootDuration = self:GetSpecialValueFor("root_duration")
		
		if bonusAttackFactor > 0 then
			local buff = caster:FindModifierByName("modifier_phantom_assassin_immaterial_handler")
			if buff then
				attackFactor = attackFactor + bonusAttackFactor * buff:GetStackCount()
			end
		end
		
		projectileData = self.projectiles[projectile]
		if projectileData then
			if projectileData.damageFactor then
				attackFactor = (100 - attackFactor)*projectileData.damageFactor - 100
				damage = damage * projectileData.damageFactor
			end
		end
		
		caster:PerformGenericAttack(target, true, {bonusDamagePct = attackFactor, bonusDamage = damage, ability = self} )
		target:AddNewModifier( caster, self, "modifier_phantom_assassin_stiflingdagger", {duration = duration} )
		
		if stunDuration > 0 then
			self:Stun(target, stunDuration)
		end
		if rootDuration > 0 then
			target:AddNewModifier( caster, self, "modifier_rooted", {duration = rootDuration} )
		end
	end
end

modifier_phantom_assassin_stifling_dagger_cd = class({})
LinkLuaModifier( "modifier_phantom_assassin_stifling_dagger_cd", "heroes/hero_phantom_assassin/phantom_assassin_stifling_dagger", LUA_MODIFIER_MOTION_NONE )

function modifier_phantom_assassin_stifling_dagger_cd:IsDebuff()
	return true
end

function modifier_phantom_assassin_stifling_dagger_cd:IsPurgable()
	return false
end