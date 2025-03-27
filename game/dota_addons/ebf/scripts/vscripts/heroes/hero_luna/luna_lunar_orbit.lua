luna_lunar_orbit = class({})

function luna_lunar_orbit:GetAOERadius()
	return self:GetSpecialValueFor("rotating_glaives_movement_radius")
end
function luna_lunar_orbit:OnSpellStart()
	if IsClient() then return end

	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_luna_lunar_orbit", { duration = self:GetSpecialValueFor("rotating_glaives_duration") })
end

modifier_luna_lunar_orbit = class({})
LinkLuaModifier( "modifier_luna_lunar_orbit", "heroes/hero_luna/luna_lunar_orbit.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_luna_lunar_orbit:IsHidden()
	return false
end
function modifier_luna_lunar_orbit:IsDebuff()
	return false
end
function modifier_luna_lunar_orbit:IsPurgable()
	return false
end
function modifier_luna_lunar_orbit:OnCreated()
	if IsClient() then return end
	self:OnRefresh()
end
function modifier_luna_lunar_orbit:OnRefresh()
	if IsClient() then return end
	self.count = self:GetSpecialValueFor("rotating_glaives")
	self.distance = self:GetSpecialValueFor("rotating_glaives_movement_radius")

	-- create thinkers around caster.
	-- they will be in charge of their own movement, but deleted by this modifier.
	if self.thinkers ~= nil then
		for i = 1, #self.thinkers do
			UTIL_Remove(self.thinkers[i])
		end
	end
	self.thinkers = {}
	local angle = 2 * math.pi / self.count
	for i = 1, self.count do
		local direction = Vector(math.cos(angle * i), math.sin(angle * i), 0)
		local point = direction * self.distance
		self.thinkers[i] = CreateModifierThinker(
			self:GetParent(),
			self:GetAbility(),
			"modifier_luna_lunar_orbit_glaive",
			{ angle = angle * i },
			self:GetParent():GetOrigin() + point,
			self:GetParent():GetTeamNumber(),
			false
		)
	end
end
function modifier_luna_lunar_orbit:OnDestroy()
	if IsClient() then return end
	for i = 1, #self.thinkers do
		UTIL_Remove(self.thinkers[i])
	end
end

modifier_luna_lunar_orbit_glaive = class({})
LinkLuaModifier( "modifier_luna_lunar_orbit_glaive", "heroes/hero_luna/luna_lunar_orbit.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_luna_lunar_orbit_glaive:OnCreated(params)
	self:OnRefresh(params)
end
function modifier_luna_lunar_orbit_glaive:OnRefresh(params)
	if IsClient() then return end
	self.caster = self:GetCaster()
	self.parent = self:GetParent()
	self.speed = self:GetSpecialValueFor("rotating_glaives_speed")
	self.angle = params.angle
	self.rotation_per_think = self.speed * math.pi / 180 / 33 / 2
	self.distance = self:GetSpecialValueFor("rotating_glaives_movement_radius")
	self.hit_radius = self:GetSpecialValueFor("rotating_glaives_hit_radius")
	self.damage_reduction_duration = self:GetSpecialValueFor("damage_reduction_duration")
	self.damage = self:GetSpecialValueFor("rotating_glaives_collision_damage")
	self.does_procs = self:GetSpecialValueFor("does_procs") == 1
	self.grace_period = (self.distance / self.speed) - 0.1
	
	self.hits = {}

	local particle = "particles/units/heroes/hero_luna/luna_moon_glaive_shield.vpcf"
	local effect = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, self.parent)
	ParticleManager:SetParticleControlEnt(
		effect,
		0,
		self.parent,
		PATTACH_ABSORIGIN_FOLLOW,
		"attach_hitloc",
		Vector(0, 0, 0),
		true
	)
	ParticleManager:SetParticleControl(effect, 1, Vector(0, self.hit_radius, self:GetSpecialValueFor("rotating_glaives_duration")))
	ParticleManager:SetParticleControlEnt(
		effect,
		2,
		self.caster,
		PATTACH_ABSORIGIN_FOLLOW,
		"attach_hitloc",
		Vector(0, 0, 0),
		true
	)
	ParticleManager:ReleaseParticleIndex(effect)
	
	self:StartIntervalThink(0)
end
function modifier_luna_lunar_orbit_glaive:OnIntervalThink()
	self.angle = self.angle + self.rotation_per_think
	local direction = Vector(math.cos(self.angle), math.sin(self.angle), 0)
	local point = self.caster:GetAbsOrigin() + direction * self.distance
	self.parent:SetAbsOrigin( point)
	
	for enemy, grace_period in pairs( self.hits ) do
		if grace_period > 0 then
			self.hits[enemy] = grace_period - FrameTime()
		end
	end
	
	for _, enemy in ipairs( self.caster:FindEnemyUnitsInRadius( point, self.hit_radius ) ) do
		self.hits[enemy] = self.hits[enemy] or 0
		if self.hits[enemy] < FrameTime() then
			self.hits[enemy] = self.grace_period
			self.caster:PerformGenericAttack(enemy, true, 
			{ 
				neverMiss = true, 
				suppressCleave = true,
				bonusDamagePct = self.damage,
				procAttackEffects = self.does_procs,
				ability = self:GetAbility() 
			})
			if self.damage_reduction_duration ~= 0 then
				enemy:AddNewModifier(self.caster, self:GetAbility(), "modifier_luna_lunar_orbit_spiteshield", { duration = self.damage_reduction_duration })
			end
		end
	end
end

modifier_luna_lunar_orbit_spiteshield = class({})
LinkLuaModifier( "modifier_luna_lunar_orbit_spiteshield", "heroes/hero_luna/luna_lunar_orbit.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_luna_lunar_orbit_spiteshield:OnCreated()
	self:OnRefresh()
end
function modifier_luna_lunar_orbit_spiteshield:OnRefresh()
	self.damage_reduction_percent = self:GetSpecialValueFor("damage_reduction_percent")
end
function modifier_luna_lunar_orbit_spiteshield:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
	}
end
function modifier_luna_lunar_orbit_spiteshield:GetModifierTotalDamageOutgoing_Percentage()
	return -self.damage_reduction_percent
end