luna_eclipse = class({})

function luna_eclipse:GetAOERadius()
	if self:GetSpecialValueFor("cast_range") == 0 then
		return self:GetSpecialValueFor("radius")
	else
		self:GetSpecialValueFor("cast_range")
	end
end
function luna_eclipse:GetBehavior()
	if self:GetSpecialValueFor("cast_range") == 0 then
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET
	else
		return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_OPTIONAL_POINT + DOTA_ABILITY_BEHAVIOR_AOE
	end
end
function luna_eclipse:GetCastRange(position, target)
	return self:GetSpecialValueFor("cast_range")
end
function luna_eclipse:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local point = self:GetCursorPosition()
	local spiteshield = self:GetSpecialValueFor("miss_chance") ~= 0
	local wrathbearer = self:GetSpecialValueFor("cast_range") ~= 0

	local duration = self:GetSpecialValueFor("beams") * self:GetSpecialValueFor("interval") + 0.1
	local unit = nil
	if wrathbearer and target then
		target:AddNewModifier(caster, self, "modifier_luna_eclipse_ebf", { duration = duration })
		unit = target
	elseif wrathbearer and point then
		unit = CreateModifierThinker(
			caster,
			self,
			"modifier_luna_eclipse_ebf",
			{ duration = self:GetDuration() },
			point,
			caster:GetTeamNumber(),
			false
		)
		AddFOWViewer(caster:GetTeamNumber(), point, self:GetSpecialValueFor("radius") + 75, duration, true)
	else
		caster:AddNewModifier(caster, self, "modifier_luna_eclipse_ebf", { duration = duration })
		unit = caster
	end

	if spiteshield then
		unit:AddNewModifier(caster, self, "modifier_luna_eclipse_ebf_spiteshield", { duration = duration + 0.1 })
	end

	GameRules:BeginTemporaryNight(self:GetSpecialValueFor("night_duration"))
end

modifier_luna_eclipse_ebf = class({})
LinkLuaModifier( "modifier_luna_eclipse_ebf", "heroes/hero_luna/luna_eclipse.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_luna_eclipse_ebf:IsHidden()
	return false
end
function modifier_luna_eclipse_ebf:IsDebuff()
	return false
end
function modifier_luna_eclipse_ebf:IsPurgable()
	return false
end
function modifier_luna_eclipse_ebf:OnCreated()
	if not IsServer() then return end

	self.beams = self:GetSpecialValueFor("beams")
	self.radius = self:GetSpecialValueFor("radius")
	self.hero_targets = self:GetSpecialValueFor("hero_targets")
	self.interval = self:GetSpecialValueFor("interval")
	self.duration = self:GetAbility():GetDuration()
	self.effect_duration_reduction_percent = self:GetSpecialValueFor("effect_duration_reduction_percent")
	self.effect_duration_reduction_percent = self.effect_duration_reduction_percent / 100

	self.parent = self:GetParent();
	self.caster = self:GetCaster();
	self.lucent_beam = self.caster:FindAbilityByName("luna_lucent_beam")

	self.counter = 0
	self:StartIntervalThink(self.interval)
	self:OnIntervalThink()

	-- particles
	local particle = "particles/units/heroes/hero_luna/luna_eclipse.vpcf"
	local effect = nil
	if self.point then
		effect = ParticleManager:CreateParticle(particle, PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(effect, 0, self.point)
	else
		effect = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	end
	ParticleManager:SetParticleControl(effect, 1, Vector(self.radius, 0, 0))
	self:AddParticle(effect, false, false, -1, false, false)

	-- sounds
	local sound = "Hero_Luna.Eclipse.Cast"
	if self.point then
		EmitSoundOnLocationWithCaster(self.point, sound, self:GetParent())
	else
		EmitSoundOn(sound, self:GetParent())
	end
end
function modifier_luna_eclipse_ebf:OnIntervalThink()
	local point = self.parent:GetOrigin()
	local enemies = FindUnitsInRadius(
		self.caster:GetTeamNumber(),
		point,
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HEROES_AND_CREEPS,
		DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS,
		FIND_ANY_ORDER,
		false
	)

	table.shuffle(enemies)
	local heroes_hit = 0
	for i = 1, #enemies do
		if enemies[i]:IsConsideredHero() then
			if heroes_hit < self.hero_targets and self.lucent_beam and self.lucent_beam:GetLevel() ~= 0 then
				self.lucent_beam:CastOn(enemies[i], 1.0 - self.effect_duration_reduction_percent)
				heroes_hit = heroes_hit + 1
			end
		else
			if self.lucent_beam and self.lucent_beam:GetLevel() ~= 0 then
				self.lucent_beam:CastOn(enemies[i], 1.0 - self.effect_duration_reduction_percent)
			end
		end
	end

	self.counter = self.counter + 1
	if self.counter >= self.beams then
		self:StartIntervalThink(-1)
		self:Destroy()
	end
end

modifier_luna_eclipse_ebf_spiteshield = class({})
LinkLuaModifier( "modifier_luna_eclipse_ebf_spiteshield", "heroes/hero_luna/luna_eclipse.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_luna_eclipse_ebf_spiteshield:OnCreated()
	self:OnRefresh()
end
function modifier_luna_eclipse_ebf_spiteshield:OnRefresh()
	self.radius = self:GetSpecialValueFor("radius")
end
function modifier_luna_eclipse_ebf_spiteshield:IsAura()
	return true
end
function modifier_luna_eclipse_ebf_spiteshield:GetModifierAura()
	return "modifier_luna_eclipse_ebf_spiteshield_aura"
end
function modifier_luna_eclipse_ebf_spiteshield:GetAuraRadius()
	return self.radius
end
function modifier_luna_eclipse_ebf_spiteshield:GetAuraDuration()
	return 0.5
end
function modifier_luna_eclipse_ebf_spiteshield:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end
function modifier_luna_eclipse_ebf_spiteshield:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HEROES_AND_CREEPS
end
function modifier_luna_eclipse_ebf_spiteshield:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NONE
end
function modifier_luna_eclipse_ebf_spiteshield:IsHidden()
	return true
end

modifier_luna_eclipse_ebf_spiteshield_aura = class({})
LinkLuaModifier( "modifier_luna_eclipse_ebf_spiteshield_aura", "heroes/hero_luna/luna_eclipse.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_luna_eclipse_ebf_spiteshield_aura:IsHidden()
	return false
end
function modifier_luna_eclipse_ebf_spiteshield_aura:IsDebuff()
	return true
end
function modifier_luna_eclipse_ebf_spiteshield_aura:IsPurgable()
	return true
end
function modifier_luna_eclipse_ebf_spiteshield_aura:OnCreated()
	self:OnRefresh()
end
function modifier_luna_eclipse_ebf_spiteshield_aura:OnRefresh()
	self.miss_chance = self:GetSpecialValueFor("miss_chance")
end
function modifier_luna_eclipse_ebf_spiteshield_aura:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MISS_PERCENTAGE
	}
end
function modifier_luna_eclipse_ebf_spiteshield_aura:GetModifierMiss_Percentage()
	return self:GetSpecialValueFor("miss_chance")
end