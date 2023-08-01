nyx_assassin_burrow = class({})

function nyx_assassin_burrow:IsStealable()
	return false
end

function nyx_assassin_burrow:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	
	if caster:HasModifier("modifier_in_water") then
		EmitSoundOn("Hero_NyxAssassin.Burrow.In.River", caster)
		self.startFX = ParticleManager:FireParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_burrow_water.vpcf", PATTACH_POINT, caster)
	else
		EmitSoundOn("Hero_NyxAssassin.Burrow.In", caster)
		self.startFX = ParticleManager:CreateParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_burrow.vpcf", PATTACH_POINT, caster)
	end
end

function nyx_assassin_burrow:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
	
	if caster:HasModifier("modifier_in_water") then
		StopSoundOn("Hero_NyxAssassin.Burrow.Out.River", caster)
	else
		StopSoundOn("Hero_NyxAssassin.Burrow.Out", caster)
	end
	ParticleManager:ClearParticle( self.startFX )
end

function nyx_assassin_burrow:OnSpellStart()
	local caster = self:GetCaster()
	
	caster:AddNewModifier(caster, self, "modifier_nyx_assassin_burrowed", {})
	caster:SwapAbilities( "nyx_assassin_burrow", "nyx_assassin_unburrow", false, true )
end

nyx_assassin_unburrow = class({})

function nyx_assassin_unburrow:IsStealable()
	return false
end

function nyx_assassin_unburrow:OnSpellStart()
	local caster = self:GetCaster()
	
	caster:RemoveModifierByName("modifier_nyx_assassin_burrowed")
	caster:SwapAbilities( "nyx_assassin_burrow", "nyx_assassin_unburrow", true, false )
	caster:StartGesture( ACT_DOTA_CAST_BURROW_END )
end

modifier_nyx_assassin_burrowed = class({})
LinkLuaModifier( "modifier_nyx_assassin_burrowed", "heroes/hero_nyx_assassin/nyx_assassin_burrow.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_nyx_assassin_burrowed:OnCreated()
	self.health_regen_rate = self:GetSpecialValueFor("health_regen_rate")
	self.mana_regen_rate = self:GetSpecialValueFor("mana_regen_rate")
	self.magic_resist = self:GetSpecialValueFor("magic_resist")
	self.bonus_attack_range = self:GetSpecialValueFor("bonus_attack_range")
	
	self.impale_cooldown_reduction = self:GetSpecialValueFor("impale_cooldown_reduction") / 100
	self.impale_bonus_cast_range = self:GetSpecialValueFor("impale_bonus_cast_range")
	self.mana_burn_bonus_cast_range = self:GetSpecialValueFor("mana_burn_bonus_cast_range")
	self.carapace_armor_multiplier = self:GetSpecialValueFor("carapace_armor_multiplier")
end

function modifier_nyx_assassin_burrowed:CheckState()
	return {[MODIFIER_STATE_ROOTED] = true}
end

function modifier_nyx_assassin_burrowed:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MODEL_CHANGE,
		MODIFIER_PROPERTY_IGNORE_CAST_ANGLE,
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
		MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL, 
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE
	}
	return funcs
end

function modifier_nyx_assassin_burrowed:GetModifierModelChange()
	return "models/heroes/nerubian_assassin/mound.vmdl"
end

function modifier_nyx_assassin_burrowed:GetModifierIgnoreCastAngle()
	return 1
end

function modifier_nyx_assassin_burrowed:GetModifierHealthRegenPercentage()
	return self.health_regen_rate
end

function modifier_nyx_assassin_burrowed:GetModifierTotalPercentageManaRegen()
	return self.mana_regen_rate
end

function modifier_nyx_assassin_burrowed:GetModifierMagicalResistanceBonus()
	return self.magic_resist
end

function modifier_nyx_assassin_burrowed:GetModifierAttackRangeBonus()
	return self.bonus_attack_range
end

function modifier_nyx_assassin_burrowed:GetModifierOverrideAbilitySpecial(params)
	if params.ability:GetAbilityName() == "nyx_assassin_impale" then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if specialValue == "AbilityCastRange" or specialValue == "length" then
			return 1
		end
		if specialValue == "AbilityCooldown" then
			return 1
		end
	end
	if params.ability:GetAbilityName() == "nyx_assassin_mana_burn" then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if specialValue == "AbilityCastRange" then
			return 1
		end
	end
	if params.ability:GetAbilityName() == "nyx_assassin_spiked_carapace" then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if specialValue == "bonus_armor" then
			return 1
		end
	end
end

function modifier_nyx_assassin_burrowed:GetModifierOverrideAbilitySpecialValue(params)
	if params.ability:GetAbilityName() == "nyx_assassin_impale" then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if specialValue == "AbilityCastRange" or specialValue == "length" then
			local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( specialValue, params.ability_special_level )
			return flBaseValue + self.impale_bonus_cast_range
		end
		if specialValue == "AbilityCooldown" then
			local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( specialValue, params.ability_special_level )
			return flBaseValue * self.impale_cooldown_reduction
		end
	end
	if params.ability:GetAbilityName() == "nyx_assassin_mana_burn" then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if specialValue == "AbilityCastRange" then
			local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( specialValue, params.ability_special_level )
			return flBaseValue + self.mana_burn_bonus_cast_range
		end
	end
	if params.ability:GetAbilityName() == "nyx_assassin_spiked_carapace" then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if specialValue == "bonus_armor" then
			local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( specialValue, params.ability_special_level )
			return flBaseValue * self.carapace_armor_multiplier
		end
	end
end

function modifier_nyx_assassin_burrowed:OnRemoved()
	if IsServer() then
		local caster = self:GetCaster()
		if caster:HasModifier("modifier_in_water") then
			EmitSoundOn("Hero_NyxAssassin.Burrow.Out.River", caster)
			ParticleManager:FireParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_burrow_exit_water.vpcf", PATTACH_POINT, caster, {})
		else
			EmitSoundOn("Hero_NyxAssassin.Burrow.Out", caster)
			ParticleManager:FireParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_burrow_exit.vpcf", PATTACH_POINT, caster, {})
		end
	end
end

function modifier_nyx_assassin_burrowed:GetEffectName()
	return "particles/units/heroes/hero_nyx_assassin/nyx_assassin_burrow_inground.vpcf"
end

function modifier_nyx_assassin_burrowed:IsPurgable()
	return false
end

function modifier_nyx_assassin_burrowed:IsPurgeException()
	return false
end