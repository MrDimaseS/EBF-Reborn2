bounty_hunter_shuriken_toss = class({})

function bounty_hunter_shuriken_toss:IsStealable()
	return true
end

function bounty_hunter_shuriken_toss:IsHiddenWhenStolen()
	return false
end

function bounty_hunter_shuriken_toss:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	EmitSoundOn("Hero_BountyHunter.Shuriken", caster)

	self.projectiles = self.projectiles or {}
	local projectile = self:TossShuriken(target, self:GetTalentSpecialValueFor("damage"), caster, self.shadow_walk)
	self.projectiles[projectile] = {}
end

function bounty_hunter_shuriken_toss:TossShuriken(target, damage, source)
	local caster = self:GetCaster()
	local hSource = source or caster
	local projectile = self:FireTrackingProjectile( "particles/units/heroes/hero_bounty_hunter/bounty_hunter_suriken_toss.vpcf", target, self:GetSpecialValueFor("speed"), {source = hSource, origin = hSource:GetAbsOrigin()}, TernaryOperator( DOTA_PROJECTILE_ATTACHMENT_ATTACK_1, caster == source, DOTA_PROJECTILE_ATTACHMENT_HITLOCATION) )
	return projectile
end

function bounty_hunter_shuriken_toss:OnProjectileHitHandle( target, position, projectile )
	if target then
		local caster = self:GetCaster()
		if target:TriggerSpellAbsorb( self ) then return end
		EmitSoundOn("Hero_BountyHunter.Shuriken.Impact", caster)

		if caster:HasScepter() then
			local jinada = caster:FindAbilityByName("bounty_hunter_jinada")
			jinada:TriggerJinada(target, true)
		end
		
		self.projectiles[projectile][target:entindex()] = true
		
		local damage = self:GetSpecialValueFor("bonus_damage")
		local track = caster:FindAbilityByName("bounty_hunter_track")
		if target:HasModifier("modifier_bounty_hunter_track") and track and track:GetLevel() > 0 then
			damage = damage * track:GetSpecialValueFor("toss_crit_multiplier") / 100
			self:DealDamage( caster, target, damage, {}, OVERHEAD_ALERT_CRITICAL )
		else
			self:DealDamage( caster, target, damage )
		end
		target:AddNewModifier( caster, self, "modifier_bounty_hunter_shuriken_toss_maim", {duration = self:GetSpecialValueFor("slow_duration")})
		
		local radius = self:GetTalentSpecialValueFor("bounce_aoe")
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), radius, {flag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES} ) ) do
			if not self.projectiles[projectile][enemy:entindex()] and enemy:HasModifier("modifier_bounty_hunter_track") then
				local newProj = self:TossShuriken(enemy, damage, target)
				self.projectiles[newProj] = table.copy( self.projectiles[projectile] )
				break
			end
		end
		self.projectiles[projectile] = nil
	end
end


modifier_bounty_hunter_shuriken_toss_maim = class({})
LinkLuaModifier("modifier_bounty_hunter_shuriken_toss_maim", "heroes/hero_bounty_hunter/bounty_hunter_jinada", LUA_MODIFIER_MOTION_NONE)

function modifier_bounty_hunter_shuriken_toss_maim:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_bounty_hunter_shuriken_toss_maim:GetModifierMoveSpeedBonus_Percentage()
	return self:GetSpecialValueFor("slow")
end

function modifier_bounty_hunter_shuriken_toss_maim:GetModifierAttackSpeedBonus_Constant()
	return self:GetSpecialValueFor("attack_slow")
end

function modifier_bounty_hunter_shuriken_toss_maim:GetEffectName()
	return "particles/units/heroes/hero_bounty_hunter/bounty_hunter_jinda_slow.vpcf"
end

function modifier_bounty_hunter_shuriken_toss_maim:GetStatusEffectName()
	return "particles/units/heroes/hero_bounty_hunter/status_effect_bounty_hunter_jinda_slow.vpcf"
end

function modifier_bounty_hunter_shuriken_toss_maim:StatusEffectPriority()
	return 10
end

function modifier_bounty_hunter_shuriken_toss_maim:IsDebuff()
	return true
end