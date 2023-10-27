necrolyte_sadist = class({})

function necrolyte_sadist:OnSpellStart()
	local caster = self:GetCaster()
	
	if caster:HasModifier("modifier_necrolyte_sadist_ethereal") then
		caster:RemoveModifierByName("modifier_necrolyte_sadist_ethereal")
	else
		caster:AddNewModifier( caster, self, "modifier_necrolyte_sadist_ethereal", {duration = self:GetTalentSpecialValueFor("duration")})
		caster:EmitSound("Hero_Necrolyte.SpiritForm.Cast")
		self:SetCooldown(0.2)
	end
end
modifier_necrolyte_sadist_ethereal = class({})
LinkLuaModifier( "modifier_necrolyte_sadist_ethereal", "heroes/hero_necrophos/necrolyte_sadist", LUA_MODIFIER_MOTION_NONE )

function modifier_necrolyte_sadist_ethereal:OnCreated()
	self.heal_amp = self:GetTalentSpecialValueFor("heal_bonus")
	self.radius = self:GetTalentSpecialValueFor("slow_aoe")
	self.minus_mr = self:GetTalentSpecialValueFor("bonus_damage")
end

function modifier_necrolyte_sadist_ethereal:OnRemoved()
	if IsServer() then
		self:GetAbility():SetCooldown()
		ProjectileManager:ProjectileDodge( self:GetCaster() )
	end
end

function modifier_necrolyte_sadist_ethereal:DeclareFunctions()
	return {MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL, 
			MODIFIER_PROPERTY_EVASION_CONSTANT,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET}
end

function modifier_necrolyte_sadist_ethereal:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_necrolyte_sadist_ethereal:GetModifierEvasion_Constant()
	return 100
end

function modifier_necrolyte_sadist_ethereal:GetModifierMagicalResistanceBonus()
	return self.minus_mr
end

function modifier_necrolyte_sadist_ethereal:GetModifierHealAmplify_PercentageTarget()
	return self.heal_amp
end

function modifier_necrolyte_sadist_ethereal:GetModifierHPRegenAmplify_Percentage()
	return self.heal_amp
end

function modifier_necrolyte_sadist_ethereal:GetModifierMPRegenAmplify_Percentage()
	return self.heal_amp
end

function modifier_necrolyte_sadist_ethereal:IsAura()
	return true
end

function modifier_necrolyte_sadist_ethereal:GetModifierAura()
	return "modifier_necrolyte_sadist_ethereal_slow"
end

function modifier_necrolyte_sadist_ethereal:GetAuraRadius()
	return self.radius
end

function modifier_necrolyte_sadist_ethereal:GetAuraDuration()
	return 0.5
end

function modifier_necrolyte_sadist_ethereal:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_necrolyte_sadist_ethereal:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_necrolyte_sadist_ethereal:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_necrolyte_sadist_ethereal:GetEffectName()
	return "particles/units/heroes/hero_necrolyte/necrolyte_spirit.vpcf"
end

function modifier_necrolyte_sadist_ethereal:GetStatusEffectName()
	return "particles/status_fx/status_effect_necrolyte_spirit.vpcf"
end

function modifier_necrolyte_sadist_ethereal:StatusEffectPriority()
	return 15
end

modifier_necrolyte_sadist_ethereal_slow = class({})
LinkLuaModifier( "modifier_necrolyte_sadist_ethereal_slow", "heroes/hero_necrophos/necrolyte_sadist", LUA_MODIFIER_MOTION_NONE )

function modifier_necrolyte_sadist_ethereal_slow:OnCreated()
	self.slow = self:GetTalentSpecialValueFor("movement_speed")
end

function modifier_necrolyte_sadist_ethereal_slow:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_necrolyte_sadist_ethereal_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self.slow
end

function modifier_necrolyte_sadist_ethereal_slow:GetEffectName()
	return "particles/units/heroes/hero_necrolyte/necrolyte_spirit_debuff.vpcf"
end