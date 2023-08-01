abaddon_death_coil = class({})

function abaddon_death_coil:IsStealable()
	return true
end

function abaddon_death_coil:IsHiddenWhenStolen()
	return false
end

function abaddon_death_coil:GetBehavior()
	if self:GetAOERadius() <= 0 then
		return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
	else
		return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_AOE
	end
end

function abaddon_death_coil:GetAOERadius()
	return self:GetSpecialValueFor( "effect_radius" )
end

function abaddon_death_coil:CastFilterResultTarget(target)
	if target == self:GetCaster() then
		return UF_FAIL_CUSTOM
	else
		return UnitFilter(target, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, target:GetTeamNumber())
	end
end

function abaddon_death_coil:GetCustomCastErrorTarget(target)
	return "Cannot target self"
end

function abaddon_death_coil:OnSpellStart()
	-- Variables
	local target = self:GetCursorTarget()
	local caster = self:GetCaster()

	-- Play the ability sound
	caster:EmitSound("Hero_Abaddon.DeathCoil.Cast")

	local projectile_speed = self:GetSpecialValueFor( "projectile_speed" )
	local self_damage = self:GetSpecialValueFor( "target_damage" ) * TernaryOperator( self:GetSpecialValueFor( "self_damage_ult" ), caster:HasModifier("modifier_abaddon_borrowed_time_active"), self:GetSpecialValueFor( "self_damage" ) ) / 100
	local effect_radius = self:GetSpecialValueFor( "effect_radius" )

	self:CreateMistCoil(target, caster)
	if effect_radius > 0 then
		for _, unit in ipairs( caster:FindAllUnitsInRadius( target:GetAbsOrigin(), effect_radius ) ) do
			if unit ~= target then
				self:CreateMistCoil(unit, caster)
			end
		end
	end
	self:DealDamage( caster, caster, self_damage, {damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NON_LETHAL })
end

function abaddon_death_coil:CreateMistCoil(target, source)
	self:FireTrackingProjectile("particles/units/heroes/hero_abaddon/abaddon_death_coil.vpcf", target, self:GetSpecialValueFor( "missile_speed" ), {source = source or self:GetCaster()})
end

function abaddon_death_coil:OnProjectileHit(target, position)
	local caster = self:GetCaster()
	if target then
		target:EmitSound("Hero_Abaddon.DeathCoil.Target")
		
		local damage = self:GetSpecialValueFor( "target_damage")
		local heal = self:GetSpecialValueFor( "heal_amount" )

		-- If the target and caster are on a different team, do Damage. Heal otherwise
		if not target:IsSameTeam( caster ) then
			if not target:TriggerSpellAbsorb(self) then
				self:DealDamage( caster, target, damage, {damage_type = DAMAGE_TYPE_MAGICAL} )
			else
				return
			end
		else
			target:HealEvent(heal, self, caster)
		end
	end
end