nyx_assassin_mana_burn = class({})

function nyx_assassin_mana_burn:IsStealable()
	return true
end

function nyx_assassin_mana_burn:GetAOERadius( )
	return self:GetSpecialValueFor("aoe")
end

function nyx_assassin_mana_burn:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	local aoe = self:GetSpecialValueFor("aoe")
	local max_mana_burn = self:GetSpecialValueFor("max_mana_burn") / 100
	local float_multiplier = self:GetSpecialValueFor("float_multiplier")
	local full_drain_slow_duration = self:GetSpecialValueFor("full_drain_slow_duration")

	EmitSoundOn("Hero_NyxAssassin.ManaBurn.Cast", caster)
	ParticleManager:FireParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_mana_burn_start.vpcf", PATTACH_POINT_FOLLOW, caster, {[0]="attach_mouth"})
	
	
	if aoe > 0 then
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), aoe ) ) do
			self:ManaBurn( enemy )
		end
	else
		self:ManaBurn( target )
	end
end

function nyx_assassin_mana_burn:ManaBurn( target )
	local caster = self:GetCaster()
	
	local max_mana_burn = self:GetSpecialValueFor("max_mana_burn") / 100
	local float_multiplier = self:GetSpecialValueFor("float_multiplier")
	local full_drain_slow_duration = self:GetSpecialValueFor("full_drain_slow_duration")
	local damageType = DAMAGE_TYPE_MAGICAL
	
	local manaBurn =  target:GetMaxMana() * max_mana_burn
	target:ReduceMana( manaBurn )
	if target:GetMana() <= 0 then
		damageType = DAMAGE_TYPE_PURE
		target:AddNewModifier( caster, self, "modifier_nyx_assassin_mana_burn_slow", {duration = full_drain_slow_duration} )
	end
	self:DealDamage(caster, target, manaBurn * float_multiplier, {damage_type = damageType}, OVERHEAD_ALERT_MANA_LOSS)
	
	EmitSoundOn("Hero_NyxAssassin.ManaBurn.Target", target)
	local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_mana_burn.vpcf", PATTACH_POINT, caster)
				ParticleManager:SetParticleControlEnt(nfx, 0, target, PATTACH_POINT, "attach_hitloc", target:GetAbsOrigin(), true)
				ParticleManager:ReleaseParticleIndex(nfx)
end

modifier_nyx_assassin_mana_burn_slow = class({})
LinkLuaModifier( "modifier_nyx_assassin_mana_burn_slow", "heroes/hero_nyx_assassin/nyx_assassin_mana_burn.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_nyx_assassin_mana_burn_slow:OnCreated()
	self.slow = self:GetSpecialValueFor("full_drain_slow")
end

function modifier_nyx_assassin_mana_burn_slow:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end

function modifier_nyx_assassin_mana_burn_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self.slow
end

function modifier_nyx_assassin_mana_burn_slow:GetModifierAttackSpeedBonus_Constant()
	return -self.slow
end

function modifier_nyx_assassin_mana_burn_slow:GetEffectName()
	return "particles/units/heroes/hero_antimage/antimage_manabreak_slow.vpcf"
end