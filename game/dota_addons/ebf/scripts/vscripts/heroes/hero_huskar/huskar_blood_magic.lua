huskar_blood_magic = class({})

function huskar_blood_magic:GetIntrinsicModifierName()
	return "modifier_huskar_blood_magic_passive"
end

modifier_huskar_blood_magic_passive = class({})
LinkLuaModifier("modifier_huskar_blood_magic_passive", "heroes/hero_huskar/huskar_blood_magic", LUA_MODIFIER_MOTION_NONE)

function modifier_huskar_blood_magic_passive:OnCreated()
	self:OnRefresh()
end

function modifier_huskar_blood_magic_passive:OnRefresh()
	self.rage_to_burn = self:GetSpecialValueFor("rage_to_burn") / 100
	self.burn_resist = -self:GetSpecialValueFor("burn_resist")
	self.burn_spell_amp = self:GetSpecialValueFor("burn_spell_amp")
	self.burn_restore_amp = self:GetSpecialValueFor("burn_restore_amp")
end

function modifier_huskar_blood_magic_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
			MODIFIER_PROPERTY_MANACOST_REDUCTION_CONSTANT,
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_EVENT_ON_ABILITY_EXECUTED}
end

function modifier_huskar_blood_magic_passive:OnAbilityExecuted( params )
	local parent = self:GetParent()
	if params.unit ~= parent then return end
	self._lastRememberedParentMana = params.unit:GetRage()
end

function modifier_huskar_blood_magic_passive:GetModifierManacostReduction_Constant( params )
	local manaCost = params.ability:GetSpecialValueFor("AbilityManaCost")
	if manaCost == 0 then return end
	local lastManaValue = params.unit:GetMana()
	local burn = false
	if self._lastRememberedParentMana then
		lastManaValue = self._lastRememberedParentMana
		self._lastRememberedParentMana = nil
		burn = true
	end
	local costDiff = manaCost - lastManaValue
	if costDiff <= 0 then return end
	if burn then
		params.unit:AddBurn( params.unit, math.ceil( costDiff * self.rage_to_burn ) )
	end
	return costDiff
end

function modifier_huskar_blood_magic_passive:GetModifierIncomingDamage_Percentage( params )
	if params.inflictor and params.inflictor._isBurnDamage then
		return self.burn_resist
	end
end

function modifier_huskar_blood_magic_passive:GetModifierSpellAmplify_Percentage()
	return self.burn_spell_amp * self:GetParent():GetBurn()
end

function modifier_huskar_blood_magic_passive:GetModifierPropertyRestorationAmplification()
	return self.burn_restore_amp * self:GetParent():GetBurn()
end

function modifier_huskar_blood_magic_passive:IsHidden()
	return true
end

function modifier_huskar_blood_magic_passive:IsPurgable()
	return false
end