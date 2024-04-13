mirana_starfall = class({})

function mirana_starfall:IsStealable()
    return true
end

function mirana_starfall:IsHiddenWhenStolen()
    return false
end

function mirana_starfall:OnSpellStart()
    local caster = self:GetCaster()
	
	EmitSoundOn("Ability.Starfall", caster)
	
    local damage = self:GetSpecialValueFor("damage")
	local radius = caster:GetAttackRange() + self:GetSpecialValueFor("starfall_radius")
	self.castAbility = true
	for _,enemy in pairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), radius ) ) do
		self:StarDrop( enemy, damage )
	end
	self.castAbility = false
end

function mirana_starfall:StarDrop(target, flDamage, bLesser)
	local caster = self:GetCaster()
	local damage = flDamage or self:GetSpecialValueFor("damage")
	local abilityCast = self.castAbility
	ParticleManager:FireParticle("particles/units/heroes/hero_mirana/mirana_starfall_attack.vpcf", PATTACH_POINT_FOLLOW, target, {[0]=target:GetAbsOrigin()})
	Timers:CreateTimer(0.5, function() --particle delay
		EmitSoundOn("Ability.StarfallImpact", target)
		self:DealDamage(caster, target, damage, {damage_flags = TernaryOperator( DOTA_DAMAGE_FLAG_PROPERTY_FIRE, not abilityCast, DOTA_DAMAGE_FLAG_NONE )})
		if not bLesser then target:AddNewModifier( caster, self, "modifier_mirana_starfall_debuff", {duration = self:GetSpecialValueFor("debuff_duration")}) end
	end)
end

modifier_mirana_starfall_debuff = class({})
LinkLuaModifier("modifier_mirana_starfall_debuff", "heroes/hero_mirana/mirana_starfall", LUA_MODIFIER_MOTION_NONE)

function modifier_mirana_starfall_debuff:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_mirana_starfall_debuff:OnTakeDamage( params )
	if params.attacker == self:GetCaster() and params.unit == self:GetParent() and not HasBit( params.damage_flags, DOTA_DAMAGE_FLAG_PROPERTY_FIRE ) then
		local ability = self:GetAbility()
		local damage = self:GetSpecialValueFor("damage")
		local triggerDamage = params.inflictor and self:GetCaster():HasAbility( params.inflictor:GetAbilityName() )
		ability:StarDrop( params.unit, damage * TernaryOperator( 1, triggerDamage, self:GetSpecialValueFor("secondary_starfall_damage_percent") / 100 ), not triggerDamage )
		self:Destroy()
	end
end

modifier_mirana_starfall_starfall_immunity = class({})
LinkLuaModifier("modifier_mirana_starfall_starfall_immunity", "heroes/hero_mirana/mirana_starfall", LUA_MODIFIER_MOTION_NONE)