sniper_concussive_grenade = class({})

function sniper_concussive_grenade:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function sniper_concussive_grenade:OnSpellStart()	
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()
	
	local projectileSpeed = self:GetSpecialValueFor("projectile_speed")
	
	self.projectiles = {}
	local projectile = self:FireLinearProjectile( "particles/units/heroes/hero_sniper/sniper_concussive_grenade_linear.vpcf", projectileSpeed * CalculateDirection( target, caster ), CalculateDistance( target, caster ) )
	EmitSoundOn( "Hero_Sniper.ConcussiveGrenade.Cast", caster)
end

function sniper_concussive_grenade:OnProjectileHitHandle( target, position, projectile )
	if not target then
		local caster = self:GetCaster()
		
		local radius = self:GetSpecialValueFor("radius")
		local damage = self:GetSpecialValueFor("damage")
		local knockbackDistance = self:GetSpecialValueFor("knockback_distance")
		local knockbackHeight = self:GetSpecialValueFor("knockback_height")
		local knockbackDuration = self:GetSpecialValueFor("knockback_duration")
		local debuffDuration = self:GetSpecialValueFor("debuff_duration")
		
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( position, radius ) ) do
			EmitSoundOn( "Hero_Sniper.ConcussiveGrenade.Target", enemy)
			enemy:ApplyKnockBack(position, knockbackDuration, knockbackDuration, knockbackDistance, knockbackHeight, caster, self)
			enemy:AddNewModifier( caster, self, "modifier_sniper_concussive_grenade_slow", {duration = debuffDuration} )
			self:DealDamage( caster, enemy, damage )
		end
		if CalculateDistance( caster, position ) < radius then
			EmitSoundOn( "Hero_Sniper.ConcussiveGrenade.Target", caster)
			caster:ApplyKnockBack(position, 0, knockbackDuration, knockbackDistance, knockbackHeight, caster, self)
		end
	end
end