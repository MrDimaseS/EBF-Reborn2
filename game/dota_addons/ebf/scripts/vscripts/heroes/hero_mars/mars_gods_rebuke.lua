mars_gods_rebuke = class({})

function mars_gods_rebuke:IsStealable()
	return true
end

function mars_gods_rebuke:IsHiddenWhenStolen()
	return false
end

function mars_gods_rebuke:GetCastRange(vLocation, hTarget)
	return self:GetCaster():GetAttackRange() + self:GetSpecialValueFor("radius") - self:GetCaster():GetCastRangeBonus()
end

function mars_gods_rebuke:OnSpellStart()
	local caster = self:GetCaster()
	local pos = self:GetCursorPosition()

	EmitSoundOn("Hero_Mars.Shield.Cast", caster)
	self:Rebuke(caster, pos)
end

function mars_gods_rebuke:Rebuke(source, position)
	local caster = self:GetCaster()
	local origin = source or caster

	local direction = CalculateDirection(position, origin:GetAbsOrigin())

	local angle = self:GetSpecialValueFor("angle")	
	local distance = self:GetTrueCastRange()
	local knockback_duration = self:GetSpecialValueFor("knockback_duration")	
	local knockback_distance = self:GetSpecialValueFor("knockback_distance")

	local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_mars/mars_shield_bash.vpcf", PATTACH_POINT_FOLLOW, origin)
				ParticleManager:SetParticleControlForward(nfx, 0, direction)
				ParticleManager:SetParticleControl( nfx, 0, origin:GetAbsOrigin() )
				ParticleManager:SetParticleControl(nfx, 1, Vector(distance, distance, distance))
				ParticleManager:ReleaseParticleIndex(nfx)

	caster:AddNewModifier(caster, self, "modifier_mars_gods_rebuke_damage_handler", {Duration = 1})

	local enemies = caster:FindEnemyUnitsInCone(direction, origin:GetAbsOrigin(), distance, distance)
	local slow_duration = self:GetSpecialValueFor("slow_duration")
	
	EmitSoundOn("Hero_Mars.Shield.Crit", caster)
	for _,enemy in pairs(enemies) do
		local nfx2 = ParticleManager:CreateParticle("particles/units/heroes/hero_mars/mars_shield_bash_crit.vpcf", PATTACH_WORLDORIGIN, enemy)
					ParticleManager:SetParticleControl(nfx2, 0, enemy:GetAbsOrigin())
					ParticleManager:SetParticleControl(nfx2, 1, enemy:GetAbsOrigin())
					ParticleManager:SetParticleControlForward(nfx2, 1, CalculateDirection(enemy, origin))
					ParticleManager:ReleaseParticleIndex(nfx2)
		if not enemy:TriggerSpellAbsorb( self ) then
			enemy:ApplyKnockBack(origin:GetAbsOrigin(), knockback_duration, knockback_duration, knockback_distance, 0, caster, self, false)
			enemy:AddNewModifier( caster, self, "modifier_mars_gods_rebuke_slow", {duration = slow_duration} )
			caster:PerformAbilityAttack(enemy, true, self, 0, false, true)
		end
	end

	caster:RemoveModifierByName("modifier_mars_gods_rebuke_damage_handler")
end

modifier_mars_gods_rebuke_damage_handler = class({})
LinkLuaModifier( "modifier_mars_gods_rebuke_damage_handler", "heroes/hero_mars/mars_gods_rebuke.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_mars_gods_rebuke_damage_handler:OnCreated()
	self:OnRefresh()
end

function modifier_mars_gods_rebuke_damage_handler:OnRefresh()
	self.crit = self:GetSpecialValueFor("crit_mult")
	self.bonus_dmg = self:GetSpecialValueFor("bonus_damage_vs_heroes")
end

function modifier_mars_gods_rebuke_damage_handler:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE }
end

function modifier_mars_gods_rebuke_damage_handler:GetModifierPreAttack_CriticalStrike(params)
	return self.crit
end
function modifier_mars_gods_rebuke_damage_handler:GetModifierPreAttack_BonusDamage(params)
	if not params.target then return end
	if params.target:IsConsideredHero() then
		return self.bonus_dmg
	end
end

function modifier_mars_gods_rebuke_damage_handler:IsPurgable()
	return false
end

function modifier_mars_gods_rebuke_damage_handler:IsPurgeException()
	return false
end

function modifier_mars_gods_rebuke_damage_handler:IsHidden()
	return true
end