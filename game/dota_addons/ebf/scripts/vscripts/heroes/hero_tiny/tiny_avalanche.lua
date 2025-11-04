--Thanks Dota Imba
tiny_avalanche_bh = class({})

function tiny_avalanche_bh:IsStealable()
    return true
end

function tiny_avalanche_bh:IsHiddenWhenStolen()
    return false
end

function tiny_avalanche_bh:GetBehavior()
	if self:GetSpecialValueFor("no_target") == 1 then
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET
	else
		return DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_POINT
	end
end

function tiny_avalanche_bh:GetCastRange( position, target )
	if self:GetSpecialValueFor("no_target") == 1 then
		return self:GetSpecialValueFor("radius")
	else
		return self.BaseClass.GetCastRange( self, position, target )
	end
end

function tiny_avalanche_bh:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function tiny_avalanche_bh:OnSpellStart()
    local caster = self:GetCaster()

	if self:GetSpecialValueFor("no_target") == 1 then
		self:CreateAvalanche( caster:GetAbsOrigin(), caster:GetForwardVector(), self:GetSpecialValueFor("radius") )
	else
		local position = self:GetCursorPosition()
		local distance = CalculateDistance( position, caster )
		local direction = CalculateDirection( position, caster )
		local velocity = direction * self:GetSpecialValueFor("projectile_speed")
		
		self._projectiles = self._projectiles or {}
		local projectile = self:FireLinearProjectile("particles/units/heroes/hero_tiny/tiny_avalanche_projectile.vpcf", velocity, distance, width, data)
		self._projectiles[projectile] = {lastPosition = caster:GetAbsOrigin() - direction * self:GetSpecialValueFor("radius"), 
										 radius = self:GetSpecialValueFor("radius"),
										 direction = direction } -- offset by a radius for the calculation
	end
    
end

function tiny_avalanche:CreateAvalanche( position, direction, radius )
    local caster = self:GetCaster()
	
	local avalanche = ParticleManager:CreateParticle("particles/units/heroes/hero_tiny/tiny_avalanche.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(avalanche, 0, position + direction)
    ParticleManager:SetParticleControlOrientation(avalanche, 0, direction, direction, caster:GetUpVector())
    ParticleManager:SetParticleControl(avalanche, 1, Vector(radius, 1, radius/2))
	ParticleManager:ReleaseParticleIndex(avalanche)
	
	local duration = self:GetSpecialValueFor("stun_duration")
    local interval = self:GetSpecialValueFor("tick_interval")
    local tick_count = self:GetSpecialValueFor("tick_count")
    local toss_multiplier = self:GetSpecialValueFor("toss_multiplier")
    local damage = self:GetSpecialValueFor("avalanche_damage") / tick_count
	
	Timers:CreateTimer(function()
        GridNav:DestroyTreesAroundPoint(position, radius, false)
        local enemies_tick = caster:FindEnemyUnitsInRadius(position, radius)
        for _,enemy in pairs(enemies_tick) do
			local unitDamage = damage
			if enemy:HasModifier("modifier_tiny_toss_bh") and not self.repeat_increase then
				unitDamage = unitDamage * toss_multiplier
			end
			self:DealDamage(caster, enemy, unitDamage)
			self:Stun(enemy, duration, false)
        end
        if tick_count > 0 then
			tick_count = tick_count - 1
            return interval
        end
    end)
	
	EmitSoundOnLocationWithCaster(position, "Ability.Avalanche", caster)
end

function tiny_avalanche_bh:OnProjectileThinkHandle(target, position, projectile)
    local caster = self:GetCaster()
	local projectileData = self._projectiles[projectile]
	if not projectileData then return end
	if CalculateDistance( position, projectileData.lastPosition ) > projectileData.radius then
		self:CreateAvalanche( position, projectileData.direction, projectileData.radius )
		projectileData.lastPosition = position
	end
end