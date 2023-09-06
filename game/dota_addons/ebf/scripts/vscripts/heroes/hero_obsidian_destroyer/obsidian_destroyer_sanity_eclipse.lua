obsidian_destroyer_sanity_eclipse = class({})

function obsidian_destroyer_sanity_eclipse:GetAOERadius()
	return self:GetTalentSpecialValueFor("radius")
end

function obsidian_destroyer_sanity_eclipse:OnSpellStart()
	local caster = self:GetCaster()
	local vTarget = self:GetCursorPosition()
	
	
	local base_damage = self:GetTalentSpecialValueFor("base_damage")
	local radius = self:GetTalentSpecialValueFor("radius")
	local summon_multiplier = self:GetTalentSpecialValueFor("summon_multiplier")
	local enemies = caster:FindEnemyUnitsInRadius( vTarget, radius, { flag = DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD + DOTA_UNIT_TARGET_FLAG_INVULNERABLE } )
	for _,enemy in pairs(enemies) do
		local intDamage = self:GetTalentSpecialValueFor("damage_multiplier") * ( caster:GetMana() - enemy:GetMana() )
		local damage = base_damage + math.max(0, intDamage)
		if not enemy:IsConsideredHero() then damage = damage * summon_multiplier end
		self:DealDamage( caster, enemy, damage, {damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY } )
		EmitSoundOn("Hero_ObsidianDestroyer.SanityEclipse", enemy)
	end
	
	
	EmitSoundOn("Hero_ObsidianDestroyer.SanityEclipse.Cast", caster)
	local eclipse = ParticleManager:CreateParticle("particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_sanity_eclipse_area.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(eclipse, 0, vTarget)
	ParticleManager:SetParticleControl(eclipse, 1, Vector(radius, 0, 0))
	ParticleManager:SetParticleControl(eclipse, 2, Vector(radius, 0, 0))
	ParticleManager:SetParticleControl(eclipse, 3, Vector(radius, 0, 0))
	ParticleManager:ReleaseParticleIndex(eclipse)
end