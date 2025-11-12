boss_ogre_destroyer_smash = class({})

function boss_ogre_destroyer_smash:Precache(context)
	PrecacheResource("particle", "particles/neutral_fx/ogre_bruiser_smash.vpcf", context)
	PrecacheResource("particle", "particles/neutral_fx/ogre_bruiser_smash_decal_dark.vpcf", context)
	PrecacheResource("particle", "particles/neutral_fx/ogre_bruiser_smash_distortion.vpcf", context)
	PrecacheResource("particle", "particles/neutral_fx/ogre_bruiser_smash_ground_burst.vpcf", context)
	PrecacheResource("particle", "particles/neutral_fx/ogre_bruiser_smash_ground_impact.vpcf", context)
	PrecacheResource("particle", "particles/neutral_fx/ogre_bruiser_smash_ground_impact_flat.vpcf", context)
	PrecacheResource("particle", "particles/neutral_fx/ogre_bruiser_smash_ground_impact_ring.vpcf", context)
	PrecacheResource("particle", "particles/neutral_fx/ogre_bruiser_smash_i.vpcf", context)
	PrecacheResource("particle", "particles/neutral_fx/ogre_bruiser_smash_proj_cracks_decal.vpcf", context)
	PrecacheResource("particle", "particles/neutral_fx/ogre_bruiser_smash_proj_scorch_decal.vpcf", context)
	PrecacheResource("particle", "particles/neutral_fx/ogre_bruiser_smash_rocks.vpcf", context)
	PrecacheResource("particle", "particles/neutral_fx/ogre_bruiser_smash_shockwave.vpcf", context)
	PrecacheResource("particle", "particles/neutral_fx/ogre_bruiser_smash_telegraph_debris.vpcf", context)
	PrecacheResource("particle", "particles/neutral_fx/ogre_bruiser_smash_telegraph_dirt_spear.vpcf", context)
	PrecacheResource("particle", "particles/neutral_fx/ogre_bruiser_smash_telegraph_dust.vpcf", context)
	PrecacheResource("particle", "particles/neutral_fx/ogre_bruiser_smash_telegraph_rocks.vpcf", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_creeps.vsndevts", context)
end

function boss_ogre_destroyer_smash:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("damage")
	local stun_duration = self:GetSpecialValueFor("hero_stun_duration")

	EmitSoundOn("n_creep_OgreBruiser.Smash.Charge", caster)

	local particle_list = {
		"particles/neutral_fx/ogre_bruiser_smash.vpcf",
		"particles/neutral_fx/ogre_bruiser_smash_decal_dark.vpcf",
		"particles/neutral_fx/ogre_bruiser_smash_distortion.vpcf",
		"particles/neutral_fx/ogre_bruiser_smash_ground_burst.vpcf",
		"particles/neutral_fx/ogre_bruiser_smash_ground_impact.vpcf",
		"particles/neutral_fx/ogre_bruiser_smash_ground_impact_flat.vpcf",
		"particles/neutral_fx/ogre_bruiser_smash_ground_impact_ring.vpcf",
		"particles/neutral_fx/ogre_bruiser_smash_i.vpcf",
		"particles/neutral_fx/ogre_bruiser_smash_proj_cracks_decal.vpcf",
		"particles/neutral_fx/ogre_bruiser_smash_proj_scorch_decal.vpcf",
		"particles/neutral_fx/ogre_bruiser_smash_rocks.vpcf",
		"particles/neutral_fx/ogre_bruiser_smash_shockwave.vpcf",
		"particles/neutral_fx/ogre_bruiser_smash_telegraph_debris.vpcf",
		"particles/neutral_fx/ogre_bruiser_smash_telegraph_dirt_spear.vpcf",
		"particles/neutral_fx/ogre_bruiser_smash_telegraph_dust.vpcf",
		"particles/neutral_fx/ogre_bruiser_smash_telegraph_rocks.vpcf"
	}

	for _, particle_path in pairs(particle_list) do
		local particle = ParticleManager:CreateParticle(particle_path, PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(particle, 0, point)
		ParticleManager:SetParticleControl(particle, 1, Vector(radius, 0, 0))
		ParticleManager:ReleaseParticleIndex(particle)
	end

	EmitSoundOn("n_creep_OgreBruiser.Smash.Stun", caster)

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		point,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)

	for _, enemy in pairs(enemies) do
		ApplyDamage({
			victim = enemy,
			attacker = caster,
			damage = damage,
			damage_type = self:GetAbilityDamageType(),
			ability = self
		})
		enemy:AddNewModifier(caster, self, "modifier_stunned", {duration = stun_duration})
	end
end