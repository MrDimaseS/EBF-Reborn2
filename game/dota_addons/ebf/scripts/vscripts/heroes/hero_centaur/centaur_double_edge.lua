centaur_double_edge = class({})

function centaur_double_edge:IsStealable()
	return true
end

function centaur_double_edge:IsHiddenWhenStolen()
	return false
end

function centaur_double_edge:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	local edgeDamage = self:GetSpecialValueFor( "edge_damage" )
	local bonusDamage = caster:GetStrength() * self:GetSpecialValueFor( "strength_damage" ) / 100
	local selfDamage = self:GetSpecialValueFor("self_damage") / 100
	local maxSelfDamage = self:GetSpecialValueFor("max_self_damage") / 100
	local unitCap = math.floor( maxSelfDamage / selfDamage + 0.5 )
	local radius = self:GetSpecialValueFor("radius")
	
	
	EmitSoundOn( "Hero_Centaur.DoubleEdge", caster )
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_centaur/centaur_double_edge.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin()) -- Origin
	ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin()) -- Destination
	ParticleManager:SetParticleControl(particle, 5, target:GetAbsOrigin()) -- Hit Glow
	
	local units = caster:FindEnemyUnitsInRadius(target:GetAbsOrigin(), radius)
	for _, enemy in ipairs(units) do
		if not enemy:TriggerSpellAbsorb( self ) then
			self:DealDamage( caster, enemy, edgeDamage, {damage_type = DAMAGE_TYPE_MAGICAL} )
			if caster:HasShard() then
				if enemy:IsConsideredHero() then
					local buff = caster:AddNewModifier( caster, self, "modifier_centaur_doubleedge_buff", {duration = self:GetSpecialValueFor("shard_str_duration")} )
					if buff:GetStackCount() < self:GetSpecialValueFor("shard_max_stacks") then
						buff:IncrementStackCount()
					end
				end
				target:AddNewModifier( caster, self, "modifier_centaur_doubleedge_slow", {duration = self:GetSpecialValueFor("shard_movement_slow_duration")} )
			end
		end
	end
	self:DealDamage( caster, caster, edgeDamage * selfDamage * math.min(#units, unitCap), {damage_type = DAMAGE_TYPE_MAGICAL, damage_flags = DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION})
end