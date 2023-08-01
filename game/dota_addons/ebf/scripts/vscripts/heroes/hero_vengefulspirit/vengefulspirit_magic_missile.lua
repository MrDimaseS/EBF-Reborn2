vengefulspirit_magic_missile = class({})

function vengefulspirit_magic_missile:IsStealable()
	return true
end

function vengefulspirit_magic_missile:IsHiddenWhenStolen()
	return false
end

function vengefulspirit_magic_missile:GetCooldown(iLvl)
    local cooldown = self.BaseClass.GetCooldown(self, iLvl)
    return cooldown
end

function vengefulspirit_magic_missile:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function vengefulspirit_magic_missile:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	EmitSoundOn("Hero_VengefulSpirit.MagicMissile", caster)

	self.projectiles = self.projectiles or {}
	local projectile = self:FireTrackingProjectile("particles/units/heroes/hero_vengeful/vengeful_magic_missle.vpcf", target, self:GetSpecialValueFor("magic_missile_speed"), {}, DOTA_PROJECTILE_ATTACHMENT_ATTACK_2, false, true, 100)
	
	self.projectiles[projectile] = {bounces = TernaryOperator( 1, caster:HasShard(), 0 )}
	
	local enemies = caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), self:GetSpecialValueFor("radius") )
	for _,enemy in pairs(enemies) do
		if enemy ~= target then
			local bounceProj = self:FireTrackingProjectile("particles/units/heroes/hero_vengeful/vengeful_magic_missle.vpcf", enemy, self:GetSpecialValueFor("magic_missile_speed"), {}, DOTA_PROJECTILE_ATTACHMENT_ATTACK_2, false, true, 100)

			self.projectiles[bounceProj] = {bounces = TernaryOperator( 1, caster:HasShard(), 0 )}
		end
	end
end

function vengefulspirit_magic_missile:OnProjectileHitHandle(target, position, projectile)
	if target ~= nil then
		local caster = self:GetCaster()
		
		if target:TriggerSpellAbsorb( self ) then return end
		
		EmitSoundOn("Hero_VengefulSpirit.MagicMissileImpact", target)
		self:Stun(target, self:GetSpecialValueFor("magic_missile_stun"), false)
		self:DealDamage(caster, target, self:GetSpecialValueFor("magic_missile_damage") )
		
		if self.projectiles[projectile].bounces > 0 then
			local enemies = caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), self:GetEffectiveCastRange( position, target ) )
			for _,enemy in pairs(enemies) do
				if enemy ~= target then
					local bounceProj = self:FireTrackingProjectile("particles/units/heroes/hero_vengeful/vengeful_magic_missle.vpcf", enemy, self:GetSpecialValueFor("magic_missile_speed"), {source = target}, DOTA_PROJECTILE_ATTACHMENT_ATTACK_2, false, true, 100)
	
					self.projectiles[bounceProj] = {bounces = 0}
					
					return
				end
			end
			
		end
	end
end