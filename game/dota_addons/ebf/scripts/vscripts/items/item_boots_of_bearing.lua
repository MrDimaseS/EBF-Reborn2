item_boots_of_bearing = class({})

function item_boots_of_bearing:GetIntrinsicModifierName()
	return "modifier_item_boots_of_bearing_passive"
end

function item_boots_of_bearing:OnSpellStart()
	local caster = self:GetCaster()

	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("duration")
	for _, ally in ipairs( caster:FindFriendlyUnitsInRadius( caster:GetAbsOrigin(), radius ) ) do
		ally:RemoveModifierByName( "modifier_item_boots_of_bearing_endurance" )
		ally:AddNewModifier( caster, self, "modifier_item_boots_of_bearing_endurance", {duration = duration} )
	end
	EmitSoundOn( "DOTA_Item.DoE.Activate", caster )
end

item_boots_of_bearing_2 = class(item_boots_of_bearing)
item_boots_of_bearing_3 = class(item_boots_of_bearing)
item_boots_of_bearing_4 = class(item_boots_of_bearing)
item_boots_of_bearing_5 = class(item_boots_of_bearing)

modifier_item_boots_of_bearing_endurance = class({})
LinkLuaModifier( "modifier_item_boots_of_bearing_endurance", "items/item_boots_of_bearing.lua" ,LUA_MODIFIER_MOTION_NONE )
function modifier_item_boots_of_bearing_endurance:OnCreated()
	self:OnRefresh()
end

function modifier_item_boots_of_bearing_endurance:OnRefresh()
	self.bonus_attack_speed_pct = self:GetAbility():GetSpecialValueFor("bonus_attack_speed_pct")
	self.bonus_movement_speed_pct = self:GetAbility():GetSpecialValueFor("bonus_movement_speed_pct")
	self.restoration_amp = self:GetAbility():GetSpecialValueFor("restoration_amp")
	self.bonus_ms_duration = self:GetAbility():GetSpecialValueFor("bonus_ms_duration")
end

function modifier_item_boots_of_bearing_endurance:CheckState()
	if self:GetLastAppliedTime() + self.bonus_ms_duration < GameRules:GetGameTime() then return end
	return {[MODIFIER_STATE_UNSLOWABLE] = true,
			[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true }
end


function modifier_item_boots_of_bearing_endurance:DeclareFunctions()
	return {MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
			MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
			}
end

function modifier_item_boots_of_bearing_endurance:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed_pct
end

function modifier_item_boots_of_bearing_endurance:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_movement_speed_pct
end

function modifier_item_boots_of_bearing_endurance:GetModifierHPRegenAmplify_Percentage()
	return self.restoration_amp
end

function modifier_item_boots_of_bearing_endurance:GetModifierHealAmplify_PercentageSource()
	return self.restoration_amp
end

function modifier_item_boots_of_bearing_endurance:GetModifierLifestealRegenAmplify_Percentage()
	return self.restoration_amp
end

function modifier_item_boots_of_bearing_endurance:GetModifierSpellLifestealRegenAmplify_Percentage()
	return self.restoration_amp
end

function modifier_item_boots_of_bearing_endurance:GetModifierMPRegenAmplify_Percentage()
	return self.restoration_amp
end

function modifier_item_boots_of_bearing_endurance:GetEffectName()
	return "particles/items_fx/drum_of_endurance_buff.vpcf"
end

modifier_item_boots_of_bearing_passive = class({})
LinkLuaModifier( "modifier_item_boots_of_bearing_passive", "items/item_boots_of_bearing.lua" ,LUA_MODIFIER_MOTION_NONE )
function modifier_item_boots_of_bearing_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_boots_of_bearing_passive:OnRefresh()
	self.bonus_movement_speed = self:GetAbility():GetSpecialValueFor("bonus_movement_speed")
	self.bonus_str = self:GetAbility():GetSpecialValueFor("bonus_str")
	self.bonus_int = self:GetAbility():GetSpecialValueFor("bonus_int")
	self.bonus_health = self:GetAbility():GetSpecialValueFor("bonus_health")
	self.health_regen_pct = self:GetAbility():GetSpecialValueFor("health_regen_pct")
	
	self.aura_radius = self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_item_boots_of_bearing_passive:DeclareFunctions(params)
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
		MODIFIER_PROPERTY_HEALTH_BONUS,
    }
    return funcs
end

function modifier_item_boots_of_bearing_passive:GetModifierMoveSpeedBonus_Special_Boots()
	return self.bonus_movement_speed
end

function modifier_item_boots_of_bearing_passive:GetModifierHealthRegenPercentage()
	return self.health_regen_pct
end

function modifier_item_boots_of_bearing_passive:GetModifierHealthBonus()
	return self.bonus_health
end

function modifier_item_boots_of_bearing_passive:GetModifierBonusStats_Strength()
	return self.bonus_str
end

function modifier_item_boots_of_bearing_passive:GetModifierBonusStats_Intellect()
	return self.bonus_int
end

function modifier_item_boots_of_bearing_passive:IsAura()
	return true
end

function modifier_item_boots_of_bearing_passive:GetModifierAura()
	return "modifier_item_boots_of_bearing_aura"
end

function modifier_item_boots_of_bearing_passive:GetAuraRadius()
	return self.aura_radius
end

function modifier_item_boots_of_bearing_passive:GetAuraDuration()
	return 0.5
end

function modifier_item_boots_of_bearing_passive:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_boots_of_bearing_passive:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_item_boots_of_bearing_passive:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_item_boots_of_bearing_passive:IsHidden()
	return true
end