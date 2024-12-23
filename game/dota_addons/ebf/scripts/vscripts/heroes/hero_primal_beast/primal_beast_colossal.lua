primal_beast_colossal = class({})

function primal_beast_colossal:GetIntrinsicModifierName()
	return "modifier_primal_beast_colossal_innate"
end

modifier_primal_beast_colossal_innate = class({})
LinkLuaModifier("modifier_primal_beast_colossal_innate", "heroes/hero_primal_beast/primal_beast_colossal", LUA_MODIFIER_MOTION_NONE)

function modifier_primal_beast_colossal_innate:OnCreated()
	self:OnRefresh()
end

function modifier_primal_beast_colossal_innate:OnRefresh()
	self.damage_per_second = self:GetSpecialValueFor("damage_per_second")
	if IsServer() then
		self:StartIntervalThink( 1 )
	end
end

function modifier_primal_beast_colossal_innate:OnIntervalThink()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local modelScale = caster:GetModelScale()
	local damage = self.damage_per_second * modelScale
	local radius = 125 * modelScale
	
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), radius ) ) do
		ability:DealDamage( caster, enemy, damage )
	end
end

function modifier_primal_beast_colossal_innate:CheckState()
	return { [MODIFIER_STATE_NO_UNIT_COLLISION] = true }
end

function modifier_primal_beast_colossal_innate:IsHidden()
	return true
end