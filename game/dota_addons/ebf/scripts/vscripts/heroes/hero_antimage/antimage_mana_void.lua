antimage_mana_void = class ({})

function antimage_mana_void:GetAOERadius()
	return self:GetSpecialValueFor("mana_void_aoe_radius")
end

function antimage_mana_void:OnAbilityPhaseStart()
	self:GetCaster():EmitSound("Hero_Antimage.ManaVoidCast")
	return true
end

function antimage_mana_void:OnAbilityPhaseInterrupted()
	self:GetCaster():StopSound("Hero_Antimage.ManaVoidCast")
end

function antimage_mana_void:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_4
end

function antimage_mana_void:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	if target:TriggerSpellAbsorb(self) then return end
	local damagePerMana = self:GetSpecialValueFor("mana_void_damage_per_mana")
	local stunDur = self:GetSpecialValueFor("mana_void_ministun")
	local radius = self:GetSpecialValueFor("mana_void_aoe_radius")
	
	local enemies = caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), radius )
	local manaDrain = self:GetSpecialValueFor("mana_drain") / 100
	if manaDrain >= 0 then
		for _, enemy in ipairs( enemies ) do
			enemy:SpendMana( target:GetMaxMana() * manaDrain, self )
		end
	end
	local damage = damagePerMana * ( target:GetMaxMana() - target:GetMana() )
	local casterDamage = self:GetSpecialValueFor("caster_curr_mana_for_calc") / 100
	if casterDamage > 0 then
		damage = damage + caster:GetMana() * casterDamage * damagePerMana
	end
	
	self:Stun( target, stunDur )
	
	for _, enemy in ipairs( enemies ) do
		self:DealDamage( caster, enemy, damage )
	end
	
	ParticleManager:FireParticle("particles/units/heroes/hero_antimage/antimage_manavoid.vpcf", PATTACH_POINT_FOLLOW, target, {[1] = Vector(radius,1,1)})
	target:EmitSound("Hero_Antimage.ManaVoid")
end