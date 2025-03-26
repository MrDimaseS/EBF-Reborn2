luna_lucent_beam = class({})

function luna_lucent_beam:OnSpellStart()
	if IsClient() then return end

	self:CastOn(self:GetCursorTarget(), 1.0)
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
	local additional_beam = self:GetSpecialValueFor("additional_beam") ~= 0
	local targets = { target }
	if additional_beam then
		local enemies = FindUnitsInRadius(
			caster:GetTeamNumber(),
			target:GetOrigin(),
			nil,
			500,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			FIND_CLOSEST,
			false
		)
		if #enemies > 1 then
			table.remove(enemies, 1)
			table.insert(targets, enemies[RandomInt(1, #enemies)])
		end
	end

	local buff_duration = 0.0
	if target:IsConsideredHero() then
		buff_duration = self:GetSpecialValueFor("buff_duration_hero")
	else
		buff_duration = self:GetSpecialValueFor("buff_duration_creep")
	end
	buff_duration = buff_duration * duration_multiplier

	local heal = self:GetSpecialValueFor("heal")

	for _, tgt in ipairs(targets) do

		if not tgt:TriggerSpellAbsorb( self ) then
			self:DealDamage(caster, tgt, damage)
			self:Stun(tgt, stun_duration)

			-- wrathbearer
			if buff_duration ~= 0 then
				local buff = caster:AddNewModifier(caster, self, "modifier_luna_lucent_beam_wrathbearer")
				buff:AddIndependentStack({ duration = buff_duration })
			end

			-- spiteshield
			if heal ~= 0 then
				if caster:GetHealthPercent() ~= 100 then
					caster:HealEvent(heal, self, caster)
				else
					local allies = FindUnitsInRadius(
						caster:GetTeamNumber(),
						caster:GetOrigin(),
						nil,
						self:GetCastRange(caster:GetOrigin(), tgt),
						DOTA_UNIT_TARGET_TEAM_FRIENDLY,
						DOTA_UNIT_TARGET_HERO,
						DOTA_UNIT_TARGET_FLAG_NONE,
						FIND_CLOSEST,
						false
					)
					for _, ally in ipairs(allies) do
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
		local effect = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, tgt)
		ParticleManager:SetParticleControl(effect, 0, tgt:GetOrigin())
		ParticleManager:SetParticleControlEnt(
			effect,
			1,
			tgt,
			PATTACH_ABSORIGIN_FOLLOW,
			"attach_hitloc",
			Vector(0, 0, 0),
			true
		)
		ParticleManager:SetParticleControlEnt(
			effect,
			5,
			tgt,
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
		EmitSoundOn(sound_target, tgt)
	end
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