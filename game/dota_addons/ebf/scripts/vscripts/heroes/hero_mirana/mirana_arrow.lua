mirana_arrow = class({})

function mirana_arrow:IsStealable()
    return true
end

function mirana_arrow:IsHiddenWhenStolen()
    return false
end

function mirana_arrow:OnSpellStart()
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    local casterPos = caster:GetAbsOrigin()

    local arrow_speed = self:GetSpecialValueFor("arrow_speed")
    local arrow_angle = self:GetSpecialValueFor("arrow_angle")
    local arrow_width = self:GetSpecialValueFor("arrow_width")
    local total_arrows = self:GetSpecialValueFor("total_arrows")

    EmitSoundOn("Hero_Mirana.ArrowCast", caster)
	
	self.arrow_projectiles = self.arrow_projectiles or {}
    local origin = casterPos + CalculateDirection( point, casterPos ) * 150
	local initialOffset = (total_arrows % 2)
	for i = 1, total_arrows do
		local position = RotatePosition(casterPos, QAngle( 0, arrow_angle * math.ceil((i-1)/2) * (-1)^i, 0 ), origin )
		local direction = CalculateDirection(position, casterPos)
		local projectile = self:FireLinearProjectile("particles/units/heroes/hero_mirana/mirana_spell_arrow.vpcf", direction*arrow_speed, 9999, arrow_width)
		self.arrow_projectiles[projectile] = {origin = casterPos, radius = self:GetSpecialValueFor("starstorm_aoe"), units = {}}
	end
	if self:GetSpecialValueFor("crit_damage") > 0 then
		caster:AddNewModifier( caster, self, "modifier_mirana_arrow_full_moon", {} )
	end
	if self:GetSpecialValueFor("starstorm_aoe") > 0 then
		self._linkedStarFall = caster:FindAbilityByName("mirana_starfall")
	end
end

function mirana_arrow:OnProjectileThinkHandle(projectile)
	local caster = self:GetCaster()
	if not (self.arrow_projectiles[projectile] and self._linkedStarFall) then return end
	local position = ProjectileManager:GetLinearProjectileLocation( projectile )
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( position, self.arrow_projectiles[projectile].radius ) ) do
		if not self.arrow_projectiles[projectile].units[enemy:entindex()] then
			self._linkedStarFall:StarDrop( enemy )
			self.arrow_projectiles[projectile].units[enemy:entindex()] = true
		end
	end
end

function mirana_arrow:OnProjectileHitHandle(target, position, projectile)
    local caster = self:GetCaster()
    if target and self.arrow_projectiles[projectile] then
		if target:IsConsideredHero() or target:IsAncient() then
			local power_multiplier = (1 + (CalculateDistance( self.arrow_projectiles[projectile].origin, position ) / self:GetSpecialValueFor("bonus_damage_range")) * self:GetSpecialValueFor("arrow_bonus_damage") / 100 )
			local damage = self:GetSpecialValueFor("arrow_damage") * power_multiplier
			local stun_duration = self:GetSpecialValueFor("arrow_max_stun") * power_multiplier
			
			self:DealDamage(caster, target, damage, nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE)
			self:Stun(target, stun_duration, false)
		else
			target:AttemptKill( self, caster )
		end
        EmitSoundOn("Hero_Mirana.ArrowImpact", target)
		return true
    end
end
modifier_mirana_arrow_full_moon = class({})
LinkLuaModifier("modifier_mirana_arrow_full_moon", "heroes/hero_mirana/mirana_arrow", LUA_MODIFIER_MOTION_NONE)

function modifier_mirana_arrow_full_moon:OnCreated()
	self:OnRefresh()
end

function modifier_mirana_arrow_full_moon:OnRefresh()
	self.crit_damage = self:GetSpecialValueFor("crit_damage")
	self.hasBeenTriggered = false
end

function modifier_mirana_arrow_full_moon:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE }
end

function modifier_mirana_arrow_full_moon:GetModifierPreAttack_CriticalStrike( params )
	if self.hasBeenTriggered then return end
	self.hasBeenTriggered = true
	if IsServer() then
		self:SetDuration( 0.1, false )
	end
	return self.crit_damage
end