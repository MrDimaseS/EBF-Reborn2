gyrocopter_sidegunner = class({})

function gyrocopter_sidegunner:IsStealable()
	return false
end

function gyrocopter_sidegunner:IsHiddenWhenStolen()
	return false
end

function gyrocopter_sidegunner:ShouldUseResources()
	return true
end

function gyrocopter_sidegunner:GetIntrinsicModifierName()
	return "modifier_gyrocopter_sidegunner_timer"
end

function gyrocopter_sidegunner:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_PASSIVE + DOTA_ABILITY_BEHAVIOR_NOT_LEARNABLE
end

modifier_gyrocopter_sidegunner_timer = class({})
LinkLuaModifier( "modifier_gyrocopter_sidegunner_timer", "heroes/hero_gyrocopter/gyrocopter_sidegunner.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_gyrocopter_sidegunner_timer:OnCreated()
	self:OnRefresh()
end

function modifier_gyrocopter_sidegunner_timer:OnRefresh()
	self.fire_rate = self:GetSpecialValueFor("fire_rate")
	self.explosion_damage = self:GetSpecialValueFor("explosion_damage")
	self.explosion_radius = self:GetSpecialValueFor("explosion_radius")
	self.fire_rate_reduction_on_attack = self:GetSpecialValueFor("fire_rate_reduction_on_attack")
	if IsServer() then
		self:StartIntervalThink( 0.1 )
	end
end

function modifier_gyrocopter_sidegunner_timer:OnIntervalThink()
	local parent = self:GetParent()
	if parent:PassivesDisabled() then
		return
	end
	local ability = self:GetAbility()
	if ability:IsCooldownReady() then
		local target = parent:FindRandomEnemyInRadius( parent:GetAbsOrigin(), parent:GetAttackRange() + parent:GetPaddedCollisionRadius() + 25)
		if IsEntitySafe( target ) and target then
			parent:PerformGenericAttack( target, false, {ability = ability, neverMiss = false} )
			ability:SetCooldown( self.fire_rate )
		end
		return
	end
end

function modifier_gyrocopter_sidegunner_timer:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED}
end

function modifier_gyrocopter_sidegunner_timer:OnAttackLanded(params)
	if params.attacker ~= self:GetParent() then return end
	local ability = self:GetAbility()
	
	if self.explosion_damage > 0 and params.attacker:GetAttackData( params.record ).abilityIndex == ability:entindex() then -- sidegunner effects
		ParticleManager:FireParticle( "particles/econ/items/wraith_king/wraith_king_ti6_bracer/wraith_king_ti6_hellfireblast_explosion.vpcf", PATTACH_POINT_FOLLOW, params.target, {[3] = "attach_hitloc"} )
		for _, enemy in ipairs( params.attacker:FindEnemyUnitsInRadius( params.target:GetAbsOrigin(), self.explosion_radius ) ) do
			ability:DealDamage( params.attacker, enemy, self.explosion_damage )
		end
	end
	if self.fire_rate_reduction_on_attack > 0 then
		ability:ModifyCooldown( -self.fire_rate_reduction_on_attack )
	end
end

function modifier_gyrocopter_sidegunner_timer:IsHidden()
	return true
end

function modifier_gyrocopter_sidegunner_timer:IsPurgable()
	return false
end

function modifier_gyrocopter_sidegunner_timer:IsPermanent()
	return true
end

function modifier_gyrocopter_sidegunner_timer:DestroyOnExpire()
	return false
end