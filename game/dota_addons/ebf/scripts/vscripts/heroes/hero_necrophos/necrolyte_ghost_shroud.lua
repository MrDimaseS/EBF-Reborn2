necrolyte_ghost_shroud = class({})

function necrolyte_ghost_shroud:OnSpellStart()
	local caster = self:GetCaster()
	
	if caster:HasModifier("modifier_necrolyte_ghost_shroud_ethereal") then
		caster:RemoveModifierByName("modifier_necrolyte_ghost_shroud_ethereal")
	else
		caster:AddNewModifier( caster, self, "modifier_necrolyte_ghost_shroud_ethereal", {duration = self:GetSpecialValueFor("duration")})
		caster:EmitSound("Hero_Necrolyte.SpiritForm.Cast")
		self:SetCooldown(0.2)
	end
end
modifier_necrolyte_ghost_shroud_ethereal = class({})
LinkLuaModifier( "modifier_necrolyte_ghost_shroud_ethereal", "heroes/hero_necrophos/necrolyte_ghost_shroud", LUA_MODIFIER_MOTION_NONE )

function modifier_necrolyte_ghost_shroud_ethereal:OnCreated()
	self.heal_amp = self:GetSpecialValueFor("heal_bonus")
	self.radius = self:GetSpecialValueFor("slow_aoe")
	self.minus_mr = self:GetSpecialValueFor("bonus_damage")
	self.movement_transfer = self:GetSpecialValueFor("movement_transfer")
end

function modifier_necrolyte_ghost_shroud_ethereal:OnRemoved()
	if IsServer() then
		self:GetAbility():SetCooldown()
		ProjectileManager:ProjectileDodge( self:GetCaster() )
	end
end

function modifier_necrolyte_ghost_shroud_ethereal:DeclareFunctions()
	return {MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL, 
			MODIFIER_PROPERTY_EVASION_CONSTANT,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET}
end

function modifier_necrolyte_ghost_shroud_ethereal:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_necrolyte_ghost_shroud_ethereal:GetModifierEvasion_Constant()
	return 100
end

function modifier_necrolyte_ghost_shroud_ethereal:GetModifierMagicalResistanceBonus()
	return self.minus_mr
end

function modifier_necrolyte_ghost_shroud_ethereal:GetModifierHealAmplify_PercentageTarget()
	return self.heal_amp
end

function modifier_necrolyte_ghost_shroud_ethereal:GetModifierHPRegenAmplify_Percentage()
	return self.heal_amp
end

function modifier_necrolyte_ghost_shroud_ethereal:GetModifierMPRegenAmplify_Percentage()
	return self.heal_amp
end

function modifier_necrolyte_ghost_shroud_ethereal_slow:GetModifierMoveSpeedBonus_Percentage()
	return self.movement_transfer
end

function modifier_necrolyte_ghost_shroud_ethereal:IsAura()
	return true
end

function modifier_necrolyte_ghost_shroud_ethereal:GetModifierAura()
	return "modifier_necrolyte_ghost_shroud_ethereal_slow"
end

function modifier_necrolyte_ghost_shroud_ethereal:GetAuraRadius()
	return self.radius
end

function modifier_necrolyte_ghost_shroud_ethereal:GetAuraDuration()
	return 0.5
end

function modifier_necrolyte_ghost_shroud_ethereal:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_necrolyte_ghost_shroud_ethereal:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_necrolyte_ghost_shroud_ethereal:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_necrolyte_ghost_shroud_ethereal:GetEffectName()
	return "particles/units/heroes/hero_necrolyte/necrolyte_spirit.vpcf"
end

function modifier_necrolyte_ghost_shroud_ethereal:GetStatusEffectName()
	return "particles/status_fx/status_effect_necrolyte_spirit.vpcf"
end

function modifier_necrolyte_ghost_shroud_ethereal:StatusEffectPriority()
	return 15
end

modifier_necrolyte_ghost_shroud_ethereal_slow = class({})
LinkLuaModifier( "modifier_necrolyte_ghost_shroud_ethereal_slow", "heroes/hero_necrophos/necrolyte_ghost_shroud", LUA_MODIFIER_MOTION_NONE )

function modifier_necrolyte_ghost_shroud_ethereal_slow:OnCreated()
	self.slow = self:GetSpecialValueFor("movement_speed")
end

function modifier_necrolyte_ghost_shroud_ethereal_slow:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_necrolyte_ghost_shroud_ethereal_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self.slow
end

function modifier_necrolyte_ghost_shroud_ethereal_slow:GetEffectName()
	return "particles/units/heroes/hero_necrolyte/necrolyte_spirit_debuff.vpcf"
end