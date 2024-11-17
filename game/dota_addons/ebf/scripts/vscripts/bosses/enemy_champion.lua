enemy_champion = class({})

function enemy_champion:GetIntrinsicModifierName()
	return "modifier_enemy_champion_passive"
end

modifier_enemy_champion_passive = class({})
LinkLuaModifier("modifier_enemy_champion_passive", "bosses/enemy_champion", 0)

function modifier_enemy_champion_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE}
end

function modifier_enemy_champion_passive:GetModifierIncomingDamage_Percentage( params )
	if IsClient() then return end
	-- if params.inflictor and params.inflictor._abilityNeedsToProcessMaxHP then
		-- local multiplier = MAX_HP_DAMAGE[params.inflictor:GetAbilityName()][params.inflictor._abilityNeedsToProcessMaxHP]
		-- local intendedDamage = params.inflictor:GetSpecialValueFor(params.inflictor._abilityNeedsToProcessMaxHP) / math.abs(multiplier)
		-- if multiplier > 0 then
			-- intendedDamage = intendedDamage * self:GetParent():GetMaxHealth()
		-- else
			-- intendedDamage = intendedDamage * self:GetParent():GetHealth()
		-- end
		-- local reducedValue = intendedDamage / HeroList:GetActiveHeroCount()
		-- local flatDamage = params.original_damage - intendedDamage
		-- local intendedReduction = 1 - 1/HeroList:GetActiveHeroCount()
		-- local reductionModifier = 1-(flatDamage / params.original_damage)
		-- local reduction = 1 - intendedReduction * reductionModifier
		-- params.inflictor._abilityNeedsToProcessMaxHP = nil
		-- print( (1-reduction)*100, flatDamage, intendedReduction*100, reduction, reductionModifier )
		-- return -(1-reduction)*100
	-- end
end

function modifier_enemy_champion_passive:IsHidden()
	return true
end

function modifier_enemy_champion_passive:IsPurgable()
	return false
end