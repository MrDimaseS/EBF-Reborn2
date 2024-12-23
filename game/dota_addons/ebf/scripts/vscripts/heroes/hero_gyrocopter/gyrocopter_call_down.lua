gyrocopter_call_down = class({})

function gyrocopter_call_down:IsStealable()
	return true
end

function gyrocopter_call_down:IsHiddenWhenStolen()
	return false
end

function gyrocopter_call_down:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function gyrocopter_call_down:GetVectorTargetStartRadius()
	return self:GetSpecialValueFor("radius")
end

function gyrocopter_call_down:GetBehavior()
	if not self:GetCaster():HasModifier( "modifier_gyrocopter_flight_of_the_valkyrie_active" ) then
		return self.BaseClass.GetBehavior( self )
	else
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET
	end
end

function gyrocopter_call_down:GetVectorTargetRange()
	return (self:GetSpecialValueFor("total_strikes") - 1) * self:GetSpecialValueFor("strike_separation")
end

function gyrocopter_call_down:Spawn()
	self.rockets = self.rockets or {}
end

function gyrocopter_call_down:OnVectorCastStart( vPos, vDir )
	local caster = self:GetCaster()
	local position = self:GetCursorPosition()
	local direction = self:GetVectorDirection()
	
	if caster:HasModifier("modifier_gyrocopter_flight_of_the_valkyrie_active") then
		self:StartValkyrieCalldown()
	else
		self:StartCalldown( position, direction )
	end
end

function gyrocopter_call_down:OnSpellStart()
	self:StartValkyrieCalldown()
end

function gyrocopter_call_down:StartCalldown( position, direction )
	local caster = self:GetCaster()
	
	local radius = self:GetSpecialValueFor("radius")
	local strike_delay = self:GetSpecialValueFor("strike_delay")
	local total_strikes = self:GetSpecialValueFor("total_strikes")
	local strike_separation = self:GetSpecialValueFor("strike_separation")
	
	local uniqueCastID = DoUniqueString("call_down")
	self.rockets[uniqueCastID] = total_strikes
	Timers:CreateTimer(function()
		-- print("rocket check", self.rockets[uniqueCastID], uniqueCastID)
		self:CreateMissileStrike( position, radius )
		self.rockets[uniqueCastID] = self.rockets[uniqueCastID] - 1
		
		if self.rockets[uniqueCastID] > 0 then
			position = position + direction * strike_separation
			return strike_delay
		else
			self.valkyrieTimer = nil
		end
	end)
end

function gyrocopter_call_down:StartValkyrieCalldown()
	local caster = self:GetCaster()
	
	local radius = self:GetSpecialValueFor("radius")
	local strike_delay = self:GetSpecialValueFor("strike_delay")
	local total_strikes = self:GetSpecialValueFor("total_strikes")
	local strike_separation = self:GetSpecialValueFor("strike_separation")
	
	total_strikes = total_strikes + math.floor( caster:FindModifierByName("modifier_gyrocopter_flight_of_the_valkyrie_active"):GetRemainingTime() )
	if self.valkyrieTimer then
		self.rockets[self.valkyrieTimer] = math.min( self.rockets[self.valkyrieTimer] + total_strikes, 20 )
	else
		local uniqueCastID = DoUniqueString("call_down")
		self.valkyrieTimer = uniqueCastID
		self.rockets[uniqueCastID] = total_strikes
		Timers:CreateTimer(function()
			if not caster:HasModifier("modifier_gyrocopter_flight_of_the_valkyrie_active") then
				position = position + self._forwardsFacing * strike_separation
			else
				position = caster:GetAbsOrigin() - caster:GetForwardVector() * strike_separation
				self._forwardsFacing = caster:GetForwardVector()
			end
			self:CreateMissileStrike( position, radius )
			self.rockets[uniqueCastID] = self.rockets[uniqueCastID] - 1
			
			if self.rockets[uniqueCastID] > 0 then
				return strike_delay
			else
				self.valkyrieTimer = nil
			end
		end)
	end
end

function gyrocopter_call_down:CreateMissileStrike( target, flRadius, flDamage )
	local caster = self:GetCaster()
	
	local missileDelay = self:GetSpecialValueFor("missile_delay_tooltip")
	local radius = flRadius or self:GetSpecialValueFor("radius")
	local damage = flDamage or self:GetSpecialValueFor("damage")
	local slow_duration = self:GetSpecialValueFor("slow_duration")
	local attack_damage_bonus = self:GetSpecialValueFor("attack_damage_bonus")
	local tracking_missile_damage = self:GetSpecialValueFor("tracking_missile_damage") / 100 
	if attack_damage_bonus > 0 then
		damage = damage + caster:GetAverageTrueAttackDamage(nil) * attack_damage_bonus / 100
	end
	
	local position = target
	local targetedEntity = false
	if target.GetAbsOrigin then 
		position = target:GetAbsOrigin()
		targetedEntity = true		
	end
	
	local markerFX = ParticleManager:CreateParticle("particles/units/heroes/hero_gyrocopter/gyro_calldown_marker.vpcf", PATTACH_POINT, caster)
	if targetedEntity then
		ParticleManager:SetParticleControlEnt(markerFX, 0, target, PATTACH_ABSORIGIN_FOLLOW, "attach_feet", target:GetAbsOrigin(), true)
	else
		ParticleManager:SetParticleControl(markerFX, 0, position)
	end
	ParticleManager:SetParticleControl(markerFX, 1, Vector(radius, radius, -radius))
	
	if not targetedEntity then
		local explosionFX = ParticleManager:CreateParticle("particles/units/heroes/hero_gyrocopter/gyro_calldown_first.vpcf", PATTACH_WORLDORIGIN, caster)
		ParticleManager:SetParticleControl(explosionFX, 0, caster:GetAbsOrigin())
		ParticleManager:SetParticleControl(explosionFX, 1, position)
		ParticleManager:SetParticleControl(explosionFX, 5, Vector(radius, radius, -radius))
		ParticleManager:ReleaseParticleIndex(explosionFX)
	end

	EmitSoundOn("Hero_Gyrocopter.CallDown.Fire", caster)			
	Timers:CreateTimer(0.1, function()
		
		if targetedEntity and IsEntitySafe( target ) then
			position = target:GetAbsOrigin()
		end
		if missileDelay <= 0 then
			EmitSoundOnLocationWithCaster(position, "Hero_Gyrocopter.CallDown.Damage", caster)
			ParticleManager:ClearParticle( markerFX, true )
			for _,enemy in pairs(caster:FindEnemyUnitsInRadius(position, radius)) do
				enemy:AddNewModifier(caster, self, "modifier_gyrocopter_call_down_slow", {Duration = slow_duration})
				self:DealDamage(caster, enemy, damage)
				if tracking_missile_damage > 0 and not targetedEntity then
					self:CreateMissileStrike( enemy, radius * tracking_missile_damage, damage * tracking_missile_damage )
				end
			end
			if targetedEntity then
				local explosionFX = ParticleManager:CreateParticle("particles/units/heroes/hero_gyrocopter/gyro_calldown_explosion.vpcf", PATTACH_WORLDORIGIN, caster)
				ParticleManager:SetParticleControl(explosionFX, 3, position)
				ParticleManager:SetParticleControl(explosionFX, 5, Vector(radius, radius, -radius))
			end
		else
			missileDelay = missileDelay - 0.1
			return 0.1
		end
	end)
end