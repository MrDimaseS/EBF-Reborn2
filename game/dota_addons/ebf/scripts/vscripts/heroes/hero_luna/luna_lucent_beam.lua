luna_lucent_beam = class({})

function luna_lucent_beam:OnSpellStart()
	if IsClient() then return end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	self:CastOn(target, 1.0)
	
	local additional_beam = self:GetSpecialValueFor("additional_beam")
	if additional_beam > 0 then
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), self:GetTrueCastRange() / 2 ) ) do
			if enemy ~= target then
				self:CastOn(target, 1.0)
				additional_beam = additional_beam - 1
			end
			if additional_beam <= 0 then
				return
			end
		end
	end
end
function luna_lucent_beam:OnAbilityPhaseStart()
	if IsClient() then return end

	-- particles
	local particle = "particles/units/heroes/hero_luna/luna_lucent_beam_precast.vpcf"

	local effect = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControlEnt(
		effect,
		0,
		self:GetCaster(),
		PATTACH_POINT_FOLLOW,
		"attach_attack1",
		Vector(0, 0, 0),
		true
	)
end
function luna_lucent_beam:CastOn(target, duration_multiplier)
	if not target then return end

	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")
	
	local stun_duration = self:GetSpecialValueFor("stun_duration") * duration_multiplier
	local buff_duration = TernaryOperator( self:GetSpecialValueFor("buff_duration_hero"), target:IsConsideredHero(), self:GetSpecialValueFor("buff_duration_creep") )
	buff_duration = buff_duration * duration_multiplier

	local heal = self:GetSpecialValueFor("heal")

	if not target:TriggerSpellAbsorb( self ) then
		self:DealDamage(caster, target, damage)

		if stun_duration > 0 then
			self:Stun(target, stun_duration)
		end
		-- wrathbearer
		if buff_duration > 0 then
			local buff = caster:AddNewModifier(caster, self, "modifier_luna_lucent_beam_wrathbearer")
			buff:AddIndependentStack({ duration = buff_duration })
		end

		-- spiteshield
		if heal ~= 0 then
			if caster:GetHealthPercent() ~= 100 then
				caster:HealEvent(heal, self, caster)
			else
				for _, ally in ipairs( caster:FindFriendlyUnitsInRadius( caster:GetAbsOrigin(), self:GetTrueCastRange(), {order = FIND_CLOSEST} ) ) do
					if ally:GetHealthPercent() ~= 100 then
						ally:HealEvent(heal, self, caster)
						break
					end
				end
			end
		end
	end

	-- particles
	local particle = "particles/units/heroes/hero_luna/luna_lucent_beam.vpcf"
	local effect = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(effect, 0, target:GetOrigin())
	ParticleManager:SetParticleControlEnt(
		effect,
		1,
		target,
		PATTACH_ABSORIGIN_FOLLOW,
		"attach_hitloc",
		Vector(0, 0, 0),
		true
	)
	ParticleManager:SetParticleControlEnt(
		effect,
		5,
		target,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(0, 0, 0),
		true
	)
	ParticleManager:SetParticleControlEnt(
		effect,
		6,
		caster,
		PATTACH_POINT_FOLLOW,
		"attach_attack1",
		Vector(0, 0, 0),
		true
	)
	ParticleManager:ReleaseParticleIndex(effect)

	-- sounds
	local sound_caster = "Hero_Luna.LucentBeam.Cast"
	local sound_target = "Hero_Luna.LucentBeam.Target"
	EmitSoundOn(sound_caster, caster)
	EmitSoundOn(sound_target, target)
end

modifier_luna_lucent_beam_wrathbearer = class({})
LinkLuaModifier( "modifier_luna_lucent_beam_wrathbearer", "heroes/hero_luna/luna_lucent_beam.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_luna_lucent_beam_wrathbearer:OnStackCountChanged(previous)
	if self:GetStackCount() == 0 then
		self:Destroy()
	end
end
function modifier_luna_lucent_beam_wrathbearer:OnCreated()
	self:OnRefresh()
end
function modifier_luna_lucent_beam_wrathbearer:OnRefresh()
	self.attack_speed = self:GetSpecialValueFor("attack_speed")
	self.movement_speed = self:GetSpecialValueFor("movement_speed")
end
function modifier_luna_lucent_beam_wrathbearer:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
end
function modifier_luna_lucent_beam_wrathbearer:GetModifierAttackSpeedBonus_Constant()
	return self.attack_speed * self:GetStackCount()
end
function modifier_luna_lucent_beam_wrathbearer:GetModifierMoveSpeedBonus_Percentage()
	return self.movement_speed * self:GetStackCount()
end