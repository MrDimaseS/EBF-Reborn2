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
	local projectile = self:TossShuriken(target, caster)
end

function bounty_hunter_shuriken_toss:TossShuriken(target, source)
	local caster = self:GetCaster()
	local hSource = source or caster
	local projectile = self:FireTrackingProjectile( "particles/units/heroes/hero_bounty_hunter/bounty_hunter_suriken_toss.vpcf", target, self:GetSpecialValueFor("speed"), {source = hSource, origin = hSource:GetAbsOrigin()}, TernaryOperator( DOTA_PROJECTILE_ATTACHMENT_ATTACK_1, caster == source, DOTA_PROJECTILE_ATTACHMENT_HITLOCATION) )
	self.projectiles[projectile] = {targets = {}}
	return projectile
end

function bounty_hunter_shuriken_toss:OnProjectileHitHandle( target, position, projectile )
	if target then
		local caster = self:GetCaster()
		if target:TriggerSpellAbsorb( self ) then return end
		EmitSoundOn("Hero_BountyHunter.Shuriken.Impact", caster)
		
		self.projectiles[projectile].targets[target:entindex()] = true
		
		local damage = self:GetSpecialValueFor("bonus_damage")
		if self.projectiles[projectile].lesser then
			damage = damage * self:GetSpecialValueFor("shurikens_split_dmg") / 100
		end
		local debuffBonus = self:GetSpecialValueFor("debuff_bonus_damage") / 100
		if debuffBonus > 0 then
			local damageBonus = 1
			if target:IsSilenced() then
				damageBonus = damageBonus + debuffBonus
			end
			if target:IsDisarmed() then
				damageBonus = damageBonus + debuffBonus
			end
			if target:PassivesDisabled() then
				damageBonus = damageBonus + debuffBonus
			end
			damage = damage * damageBonus
		end
		self:DealDamage( caster, target, damage )
		target:AddNewModifier( caster, self, "modifier_bounty_hunter_shuriken_toss_maim", {duration = self:GetSpecialValueFor("slow_duration")})
		
		if self.projectiles[projectile].lesser then
			return
		end
		
		local radius = self:GetSpecialValueFor("bounce_aoe")
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), radius ) ) do
			if not self.projectiles[projectile].targets[enemy:entindex()] and enemy:HasModifier("modifier_bounty_hunter_track") then
				local newProj = self:TossShuriken(enemy, damage)
				self.projectiles[newProj] = table.copy( self.projectiles[projectile] )
				break
			end
		end
		
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), self:GetTrueCastRange() ) ) do
			if enemy ~= target then
				local newProj = self:TossShuriken(enemy, damage)
				self.projectiles[newProj].lesser = true
				break
			end
		end
		self.projectiles[projectile] = nil
	end
end


modifier_bounty_hunter_shuriken_toss_maim = class({})
LinkLuaModifier("modifier_bounty_hunter_shuriken_toss_maim", "heroes/hero_bounty_hunter/bounty_hunter_jinada", LUA_MODIFIER_MOTION_NONE)

function modifier_bounty_hunter_shuriken_toss_maim:OnCreated()
	self.slow = self:GetSpecialValueFor("slow")
	self.attack_slow = self:GetSpecialValueFor("attack_slow")
	self.improved_shuriken_debuff = self:GetSpecialValueFor("improved_shuriken_debuff")
end

function modifier_bounty_hunter_shuriken_toss_maim:DeclareFunctions()	
	if self.improved_shuriken_debuff then
		return {[MODIFIER_STATE_ROOTED] = true,
				[MODIFIER_STATE_DISARMED] = true}
	end
end

function modifier_bounty_hunter_shuriken_toss_maim:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_bounty_hunter_shuriken_toss_maim:GetModifierMoveSpeedBonus_Percentage()
	return -self.slow
end

function modifier_bounty_hunter_shuriken_toss_maim:GetModifierAttackSpeedBonus_Constant()
	return -self.attack_slow
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