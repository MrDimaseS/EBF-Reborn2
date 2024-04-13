nevermore_requiem = class({})

function nevermore_requiem:OnAbilityPhaseStart()
	EmitSoundOn("Hero_Nevermore.RequiemOfSoulsCast", self:GetCaster())
	self.warmupFX = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_wings.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControlEnt(self.warmupFX, 5, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_attack1", self:GetCaster():GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(self.warmupFX, 6, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_attack2", self:GetCaster():GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(self.warmupFX, 7, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetCaster():GetAbsOrigin(), true)
	self:GetCaster():AddNewModifier(self:GetCaster(), hAbility, "modifier_phased", {})
	return true
end

function nevermore_requiem:OnAbilityPhaseInterrupted()
	StopSoundOn("Hero_Nevermore.RequiemOfSoulsCast", self:GetCaster())
	ParticleManager:ClearParticle( self.warmupFX )
	self:GetCaster():RemoveModifierByName("modifier_phased")
end


function nevermore_requiem:OnOwnerDied()
	self:OnAbilityPhaseInterrupted()
	self:ReleaseSouls( true )
end

function nevermore_requiem:OnSpellStart()
	local caster = self:GetCaster()
	self:ReleaseSouls()
end

function nevermore_requiem:ReleaseSouls(bDeath)
	local caster = self:GetCaster()

	local startPos = caster:GetAbsOrigin()
	local direction = caster:GetForwardVector()

	local souls = 0
	local modifier = caster:FindModifierByName("modifier_nevermore_necromastery_passive")
	if modifier then
		souls = modifier:GetStackCount()
	end
	
	local projectiles = souls / self:GetSpecialValueFor("requiem_soul_conversion")
	if bDeath then projectiles = math.floor( projectiles * self:GetSpecialValueFor("soul_death_release") ) end
	
	ParticleManager:FireParticle("particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_a.vpcf", PATTACH_ABSORIGIN, caster, {[1]=Vector(projectiles, 0, 0),[2]=caster:GetAbsOrigin()})
	ParticleManager:FireParticle("particles/units/heroes/hero_nevermore/nevermore_requiemofsouls.vpcf", PATTACH_ABSORIGIN, caster, {[1]=Vector(projectiles, 0, 0)})

	local angle = math.min( 360/projectiles, 360/25 )
	EmitSoundOn("Hero_Nevermore.RequiemOfSouls", caster)
	self.requiemProj = self.requiemProj or {}
	for i=0, projectiles do
		local initialOffset = (projectiles % 2) * angle / 2
		local newDir = RotateVector2D(direction, ToRadians( initialOffset + angle * math.floor(i / 2) * (-1)^i ) )
		local projectile = self:FireRequiemSoul( newDir )
		self.requiemProj[projectile] = {}
		self.requiemProj[projectile].damage = 0
		if caster:HasScepter() then
			self.requiemProj[projectile].bounce = true
		end
	end
end

function nevermore_requiem:FireRequiemSoul( direction, origin )
	local caster = self:GetCaster()
	
	local distance = self:GetSpecialValueFor("requiem_radius")
	local width_start = self:GetSpecialValueFor("requiem_line_width_start")
	local width_end = self:GetSpecialValueFor("requiem_line_width_end")
	local speed = self:GetSpecialValueFor("requiem_line_speed")
	
	local particle_lines_fx = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_line.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(particle_lines_fx, 0, origin or caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle_lines_fx, 1, direction*speed)
	ParticleManager:SetParticleControl(particle_lines_fx, 2, Vector(0, distance/speed, 0))
	ParticleManager:ReleaseParticleIndex(particle_lines_fx)

	local projectile = self:FireLinearProjectile("", direction*speed, distance, width_start, {width_end=width_end}, false, true, width_end)
	return projectile
end

function nevermore_requiem:OnProjectileHitHandle(hTarget, vLocation, projectile)
	local caster = self:GetCaster()
	
	local requiem_slow_duration = self:GetSpecialValueFor("requiem_slow_duration")
	local requiem_slow_duration_max = self:GetSpecialValueFor("requiem_slow_duration_max")
	local damage = self:GetSpecialValueFor("damage")
	if hTarget then
		EmitSoundOn("Hero_Nevermore.RequiemOfSouls.Damage", hTarget)
		local modifier = hTarget:FindModifierByName("modifier_nevermore_requiem_fear")
		if modifier then
			requiem_slow_duration = math.min( modifier:GetRemainingTime() + requiem_slow_duration, requiem_slow_duration_max )
		end
		if self.requiemProj[projectile].bounce == false then -- rebound
			damage = damage * self:GetSpecialValueFor("requiem_damage_pct_scepter") / 100
		end
		hTarget:AddNewModifier(caster, self, "modifier_nevermore_requiem_fear", {Duration = requiem_slow_duration})
		hTarget:AddNewModifier(caster, self, "modifier_nevermore_requiem_slow", {Duration = requiem_slow_duration})
		local damageDealt = self:DealDamage(caster, hTarget, damage)
		self.requiemProj[projectile].damage = self.requiemProj[projectile].damage + damageDealt
	elseif self.requiemProj[projectile] ~= nil then
		if self.requiemProj[projectile].bounce then -- outward reflect
			local newProj = self:FireRequiemSoul( -ProjectileManager:GetLinearProjectileVelocity( projectile ):Normalized(), vLocation )
			self.requiemProj[newProj] = table.copy(self.requiemProj[projectile])
			self.requiemProj[newProj].bounce = false
		elseif caster:IsAlive() then
			caster:HealEvent( self.requiemProj[projectile].damage, self, caster )
		end
		self.requiemProj[projectile] = nil
	end
end