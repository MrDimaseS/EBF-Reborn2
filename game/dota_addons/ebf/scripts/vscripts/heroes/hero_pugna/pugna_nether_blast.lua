pugna_nether_blast = class({})

function pugna_nether_blast:IsHiddenWhenStolen()
	return false
end

function pugna_nether_blast:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function pugna_nether_blast:OnSpellStart()
	local caster = self:GetCaster()
	local position = self:GetCursorPosition()
	
	local delay = self:GetSpecialValueFor("delay")
	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("blast_damage")
	
	EmitSoundOnLocationWithCaster(position, "Hero_Pugna.NetherBlastPreCast", caster)
	if delay > 0 then
		ParticleManager:FireParticle("particles/units/heroes/hero_pugna/pugna_netherblast_pre.vpcf", PATTACH_WORLDORIGIN, nil, {[0] = position, [1] = Vector(radius,1,1)})
	end
	
	local lifeDrain = caster:FindAbilityByName("pugna_life_drain")
	local triggerForHero = true
	local lifeDrainTargets
	if lifeDrain:IsTrained() and lifeDrain:IsCooldownReady() and not caster:PassivesDisabled() then
		lifeDrainTargets = {}
	end
	Timers:CreateTimer(delay, function()
		ParticleManager:FireParticle("particles/units/heroes/hero_pugna/pugna_netherblast.vpcf", PATTACH_WORLDORIGIN, nil, {[0] = position, [1] = Vector(radius,1,1)})
		EmitSoundOnLocationWithCaster(position, "Hero_Pugna.NetherBlast", caster)
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( position, radius ) ) do
			if not enemy:TriggerSpellAbsorb( self ) then
				self:DealDamage( caster, enemy, damage )
				if lifeDrainTargets then
					table.insert( lifeDrainTargets, enemy )
				end
			end
		end
		if lifeDrainTargets and #lifeDrainTargets > 0 then
			for _, unit in ipairs( lifeDrainTargets ) do
				if not unit:IsConsideredHero() or triggerForHero then
					lifeDrain:ApplyLifeDrain(unit)
					if triggerForHero and unit:IsConsideredHero() then
						triggerForHero = false
					end
				end
			end
			lifeDrain:SetCooldown()
		end
	end)
	
end