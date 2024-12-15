gyrocopter_flak_cannon = class({})

function gyrocopter_flak_cannon:IsStealable()
	return true
end

function gyrocopter_flak_cannon:IsHiddenWhenStolen()
	return false
end

function gyrocopter_flak_cannon:OnSpellStart()
	local caster = self:GetCaster()
	
	self.disableLoop = false
	caster:AddNewModifier( caster, self, "modifier_gyrocopter_flak_cannon_active", {duration = self:GetSpecialValueFor("AbilityDuration")} )
	EmitSoundOn("Hero_Gyrocopter.FlackCannon.Activate", caster)
end

function gyrocopter_flak_cannon:OnProjectileHit(target, position)
	local caster = self:GetCaster()
	if target then
		local bonusDamage = self:GetSpecialValueFor("bonus_damage")
		self.disableLoop = true
		caster:PerformGenericAttack( target, true, {procAttackEffects = false, ability = self} )
		self.disableLoop = false
		
	end
end

modifier_gyrocopter_flak_cannon_active = class({})
LinkLuaModifier( "modifier_gyrocopter_flak_cannon_active", "heroes/hero_gyrocopter/gyrocopter_flak_cannon.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_gyrocopter_flak_cannon_active:OnCreated()
	self:OnRefresh()
end

function modifier_gyrocopter_flak_cannon_active:OnRefresh()
	self.radius = self:GetSpecialValueFor("radius")
	self.projectile_speed = self:GetSpecialValueFor("projectile_speed")
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
end
function modifier_gyrocopter_flak_cannon_active:DeclareFunctions()
	funcs = {MODIFIER_EVENT_ON_ATTACK, MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE }
	return funcs
end

function modifier_gyrocopter_flak_cannon_active:OnAttack(params)
	if params.attacker ~= self:GetParent() then return end
	if params.attacker:GetAttackData( params.record ).abilityIndex then
		local attackAbility = EntIndexToHScript( params.attacker:GetAttackData( params.record ).abilityIndex )
		if IsEntitySafe( attackAbility ) and attackAbility:GetAbilityName() ~= "gyrocopter_sidegunner" then
			return
		end
	end
	if self:GetAbility().disableLoop then return end
	EmitSoundOn("Hero_Gyrocopter.FlackCannon", params.attacker)
	local ability = self:GetAbility()
	for _,enemy in pairs(params.attacker:FindEnemyUnitsInRadius(params.attacker:GetAbsOrigin(), self.radius)) do
		if enemy ~= params.target then
			local attachment = TernaryOperator( DOTA_PROJECTILE_ATTACHMENT_ATTACK_1, RollPercentage(50), DOTA_PROJECTILE_ATTACHMENT_ATTACK_2 )
			ability:FireTrackingProjectile(params.attacker:GetRangedProjectileName(), enemy, self.projectile_speed, {}, attachment)
		end
	end
end

function modifier_gyrocopter_flak_cannon_active:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end