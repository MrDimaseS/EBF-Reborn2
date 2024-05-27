zuus_static_field = class({})

function zuus_static_field:GetIntrinsicModifierName()
	return "modifier_zuus_static_field_passive"
end

function zuus_static_field:ShouldUseResources()
	return true
end

LinkLuaModifier("modifier_zuus_static_field_passive", "heroes/hero_zeus/zuus_static_field", LUA_MODIFIER_MOTION_NONE)
modifier_zuus_static_field_passive = class({})

function modifier_zuus_static_field_passive:OnCreated()
	self:OnRefresh()
end

function modifier_zuus_static_field_passive:OnRefresh()
	self.damage_health_pct_spell = self:GetSpecialValueFor("damage_health_pct_spell") / 100
	self.damage_health_pct_attack = self:GetSpecialValueFor("damage_health_pct_attack") / 100
	self.creep_health_pct_spell = self:GetSpecialValueFor("creep_health_pct_spell") / 100
	self.creep_health_pct_attack = self:GetSpecialValueFor("creep_health_pct_attack") / 100
	
	self.damage_threshold_max = self:GetSpecialValueFor("damage_threshold_max") / 100
	self.damage_threshold_min = self:GetSpecialValueFor("damage_threshold_min") / 100
	self.distance_threshold_max = self:GetSpecialValueFor("distance_threshold_max")
	self.distance_threshold_min = self:GetSpecialValueFor("distance_threshold_min")
end

function modifier_zuus_static_field_passive:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_zuus_static_field_passive:OnTakeDamage(params)
	if params.attacker == self:GetParent() and params.inflictor ~= self:GetAbility() then
		local ability = self:GetAbility()
		local damageMultiplier = 1
		if self.damage_threshold_min > 0 then
			local minimumDamage = self.damage_threshold_max
			local bonusDamage = self.damage_threshold_min - self.damage_threshold_max
			local damageThreshold = self.distance_threshold_max - self.distance_threshold_min
			local distance = CalculateDistance( params.attacker, params.unit ) - self.distance_threshold_min
			damageMultiplier = minimumDamage + bonusDamage * math.min( math.max( 0, (damageThreshold-distance)/damageThreshold ), 1 )
		end
		if params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
			local damage = TernaryOperator( self.damage_health_pct_attack, params.unit:IsConsideredHero(), self.creep_health_pct_attack )
			ability:DealDamage( params.attacker, params.unit, params.unit:GetHealth() * damage * damageMultiplier )
			
			ParticleManager:FireParticle("particles/units/heroes/hero_zuus/zuus_static_field.vpcf", PATTACH_POINT_FOLLOW, params.unit )
		elseif params.inflictor and params.attacker:HasAbility( params.inflictor:GetAbilityName() ) then
			local damage = TernaryOperator( self.damage_health_pct_spell, params.unit:IsConsideredHero(), self.creep_health_pct_spell )
			ability:DealDamage( params.attacker, params.unit, params.unit:GetHealth() * damage * damageMultiplier )
			
			EmitSoundOn( "Hero_Zuus.StaticField", params.unit )
			ParticleManager:FireParticle("particles/units/heroes/hero_zuus/zuus_static_field.vpcf", PATTACH_POINT_FOLLOW, params.unit )
		end
	end
end

function modifier_zuus_static_field_passive:IsHidden()
	return true
end

function modifier_zuus_static_field_passive:IsPurgable()
	return false
end