modifier_generic_level_scaling_for_summons = class({})

function modifier_generic_level_scaling_for_summons:DeclareFunctions()
  local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
		MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE
  }
  return funcs
end

function modifier_generic_level_scaling_for_summons:GetModifierOverrideAbilitySpecial(params)
	if self._lockForProcessing then return end
	if params.ability._processValuesForScaling == nil then
		params.ability._processValuesForScaling = {}
	end
	local special_value = params.ability_special_value:gsub("%#", "")
	local abilityValues = GetAbilityKeyValuesByName(params.ability:GetAbilityName()).AbilityValues
	if params.ability._processValuesForScaling[special_value] == nil and abilityValues then
		params.ability._processValuesForScaling[special_value] = {}
		params.ability._processValuesForScaling[special_value].affected_by_aoe_increase = false
		params.ability._processValuesForScaling[special_value].affected_by_lvl_increase = false
		if type(GetAbilityKeyValuesByName(params.ability:GetAbilityName()).AbilityValues[special_value]) == "table" then -- check for adjustments
			if toboolean(GetAbilityKeyValuesByName(params.ability:GetAbilityName()).AbilityValues[special_value].affected_by_aoe_increase) then
				params.ability._processValuesForScaling[special_value].affected_by_aoe_increase = true
			end
			if toboolean(GetAbilityKeyValuesByName(params.ability:GetAbilityName()).AbilityValues[special_value].CalculateSpellDamageTooltip)
			or toboolean(GetAbilityKeyValuesByName(params.ability:GetAbilityName()).AbilityValues[special_value].CalculateSpellHealTooltip)
			or toboolean(GetAbilityKeyValuesByName(params.ability:GetAbilityName()).AbilityValues[special_value].CalculateAttackDamageTooltip)
			or toboolean(GetAbilityKeyValuesByName(params.ability:GetAbilityName()).AbilityValues[special_value].CalculateAttributeTooltip) then
				params.ability._processValuesForScaling[special_value].affected_by_lvl_increase = true
			end
			if GetAbilityKeyValuesByName(params.ability:GetAbilityName()).AbilityValues[special_value].ForceCalculateLevelBonus then
				params.ability._processValuesForScaling[special_value].affected_by_lvl_increase = toboolean(GetAbilityKeyValuesByName(params.ability:GetAbilityName()).AbilityValues[special_value].ForceCalculateLevelBonus)
			end
		elseif special_value == "AbilityDamage" then
			params.ability._processValuesForScaling[special_value].affected_by_lvl_increase = true
		end
	end
	if params.ability._processValuesForScaling[special_value]
	and (params.ability._processValuesForScaling[special_value].affected_by_aoe_increase
	or params.ability._processValuesForScaling[special_value].affected_by_lvl_increase) then
		return 1
	end
end

function modifier_generic_level_scaling_for_summons:GetModifierOverrideAbilitySpecialValue(params)
	self._lockForProcessing = true
	local special_value = params.ability_special_value:gsub("%#", "")
	local flBaseValue = params.ability:GetLevelSpecialValueFor( special_value, params.ability_special_level )
	self._lockForProcessing = false
	if flBaseValue <= 0 then
		return
	end
	if params.ability._processValuesForScaling[special_value].affected_by_lvl_increase then
		local flNewValue = flBaseValue * ( 1 + (self:GetCaster():GetLevel() - 1) * 0.2 )
		return flNewValue
	end
end