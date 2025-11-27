huskar_burning_spear = class({})

function huskar_burning_spear:IsStealable()
	return false
end

function huskar_burning_spear:IsHiddenWhenStolen()
	return false
end

function huskar_burning_spear:GetIntrinsicModifierName()
	return "modifier_huskar_burning_spear_autocast"
end

function huskar_burning_spear:GetCastPoint()
	return 0
end

function huskar_burning_spear:OnSpellStart()
end


function huskar_burning_spear:GetCastRange(location, target)
	return self:GetCaster():GetAttackRange()
end

function huskar_burning_spear:LaunchSpear(target, bAttack)
	local caster = self:GetCaster()
	EmitSoundOn("Hero_Huskar.Burning_Spear.Cast", caster)
	caster:AddBurn( caster, self:GetSpecialValueFor("burn_damage") )
	local projTable = {
		EffectName = "particles/empty_projectile.vcpf",
		Ability = self,
		Target = target,
		Source = caster,
		bDodgeable = true,
		bProvidesVision = false,
		vSpawnOrigin = caster:GetAbsOrigin(),
		iMoveSpeed = caster:GetProjectileSpeed(),
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
	}
	ProjectileManager:CreateTrackingProjectile( projTable )
end


function huskar_burning_spear:OnProjectileHit(target, position)
	if target then
		local caster = self:GetCaster()
		EmitSoundOn("Hero_Huskar.Burning_Spear", caster)
		if target:IsAlive() then target:AddBurn( caster, self:GetSpecialValueFor("burn_damage") ) end
	end
end

modifier_huskar_burning_spear_autocast = class({})
LinkLuaModifier("modifier_huskar_burning_spear_autocast", "heroes/hero_huskar/huskar_burning_spear", LUA_MODIFIER_MOTION_NONE)

function modifier_huskar_burning_spear_autocast:OnCreated()
	self:OnRefresh()
end

function modifier_huskar_burning_spear_autocast:OnCreated()
	self.retribution_cd = self:GetSpecialValueFor("retribution_cd")
	self._lastRetributionTrigger = 0
end

function modifier_huskar_burning_spear_autocast:IsHidden()
	return true
end

function modifier_huskar_burning_spear_autocast:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK, 
			MODIFIER_EVENT_ON_ORDER,
			MODIFIER_PROPERTY_PROJECTILE_NAME }
end

function modifier_huskar_burning_spear_autocast:OnOrder(params)
	if params.unit == self:GetParent() then
		if params.ability == self:GetAbility() and params.order_type == DOTA_UNIT_ORDER_CAST_TARGET then
			self.autocast = true
		else
			self.autocast = false
		end
	end
end

function modifier_huskar_burning_spear_autocast:OnAttack(params)
	if params.attacker == self:GetParent() and params.target and (( self:GetAbility():GetAutoCastState() and self:GetAbility():IsFullyCastable() ) or self.autocast) then
		self:GetAbility():LaunchSpear(params.target)
		self.autocast = false
	end
	local parent = self:GetParent()
	if self.retribution_cd > 0 and params.target == parent and parent:GetBurn() > 0 then
		local ability = self:GetAbility()
		local damage = self:GetSpecialValueFor("retribution_damage") * caster:GetBurn()
		if self._lastRetributionTrigger + self.retribution_cd <= GameRules:GetGameTime() then
			ParticleManager:FireParticle("particles/fire_ball_explosion.vpcf", PATTACH_POINT_FOLLOW, caster )
			self._lastRetributionTrigger = GameRules:GetGameTime()
			for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( params.target:GetAbsOrigin(), self:GetSpecialValueFor("retribution_radius") ) ) do
				ability:DealDamage( caster, enemy, damage, {damage_type = DAMAGE_TYPE_MAGICAL} )
			end
		end
		
	end
end
	
function modifier_huskar_burning_spear_autocast:GetModifierProjectileName(params)
	if IsServer() and (self:GetAbility():IsFullyCastable() and self:GetAbility():GetAutoCastState()) or self.autocast then
		return "particles/units/heroes/hero_huskar/huskar_burning_spear.vpcf"
	end
end