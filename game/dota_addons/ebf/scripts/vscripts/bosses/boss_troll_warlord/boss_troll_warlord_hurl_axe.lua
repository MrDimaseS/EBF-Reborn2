boss_troll_warlord_hurl_axe = class({})

function boss_troll_warlord_hurl_axe:OnSpellStart()
	local caster = self:GetCaster()
	
	local range = self:GetSpecialValueFor("axe_range")
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), -1 ) ) do
		if enemy:IsConsideredHero() or CalculateDistance( enemy, caster ) <= range then
			self:HurlAxe( enemy )
		end
	end
end

function boss_troll_warlord_hurl_axe:HurlAxe( target )
	local caster = self:GetCaster()
	
	local direction = CalculateDirection( target, caster )
	local distance = self:GetSpecialValueFor("axe_range")
	local speed = self:GetSpecialValueFor("axe_speed")
	local width = self:GetSpecialValueFor("axe_width")
	ParticleManager:FireLinearWarningParticle( caster:GetAbsOrigin(), caster:GetAbsOrigin() + direction * distance, width)
	
	self:FireLinearProjectile("particles/units/heroes/hero_troll_warlord/troll_warlord_whirling_axe_ranged.vpcf", direction * speed, distance, width)
end

function boss_troll_warlord_hurl_axe:OnProjectileHit(target, position)
	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("axe_damage")
	local duration = self:GetSpecialValueFor("axe_slow_duration")
	if target then
		self:DealDamage( caster, target, damage )
		target:AddNewModifier( caster, self, "modifier_boss_troll_warlord_hurl_axe_debuff", {duration = duration} )
	end
end

modifier_boss_troll_warlord_hurl_axe_debuff = class({})
LinkLuaModifier("modifier_boss_troll_warlord_hurl_axe_debuff", "bosses/boss_troll_warlord/boss_troll_warlord_hurl_axe", LUA_MODIFIER_MOTION_NONE)

function modifier_boss_troll_warlord_hurl_axe_debuff:OnCreated()
	self:OnRefresh()
end

function modifier_boss_troll_warlord_hurl_axe_debuff:OnRefresh()
	self.slow = -self:GetSpecialValueFor("movement_speed")
end

function modifier_boss_troll_warlord_hurl_axe_debuff:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_boss_troll_warlord_hurl_axe_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end