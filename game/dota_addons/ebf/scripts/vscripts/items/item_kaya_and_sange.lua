LinkLuaModifier( "modifier_item_aeon_disk_effect", "items/item_aeon_disk.lua" ,LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_aeon_disk_cooldown", "items/item_aeon_disk.lua" ,LUA_MODIFIER_MOTION_NONE )
item_kaya_and_sange_2 = class({})

function item_kaya_and_sange_2:GetIntrinsicModifierName()
	return "modifier_item_kaya_and_sange_2_passive"
end

item_kaya_and_sange_3 = class(item_kaya_and_sange_2)
item_kaya_and_sange_4 = class(item_kaya_and_sange_2)
item_kaya_and_sange_5 = class(item_kaya_and_sange_2)

function item_kaya_and_sange_5:IsRearmable()
	return false
end

modifier_item_kaya_and_sange_2_passive = class({})
LinkLuaModifier( "modifier_item_kaya_and_sange_2_passive", "items/item_kaya_and_sange.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_kaya_and_sange_2_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_kaya_and_sange_2_passive:OnRefresh()
	self.bonus_strength = self:GetSpecialValueFor("bonus_strength")
	self.bonus_intellect = self:GetSpecialValueFor("bonus_intellect")

	self.spell_amp = self:GetSpecialValueFor("spell_amp")
	self.restore_amp = self:GetSpecialValueFor("restore_amp")
	self.status_resistance = self:GetSpecialValueFor("status_resistance")
	
	self.bonus_mana = self:GetSpecialValueFor("bonus_mana")
	self.bonus_health = self:GetSpecialValueFor("bonus_health")
	self.health_per_str = self:GetSpecialValueFor("health_per_str")
	
	self.spell_lifesteal = self:GetSpecialValueFor("spell_lifesteal")
	self.health_threshold_pct = self:GetSpecialValueFor("health_threshold_pct")
	self.buff_duration = self:GetSpecialValueFor("buff_duration")
	
	self.endurance_duration = self:GetSpecialValueFor("endurance_duration")
	
	self.max_stacks = self:GetSpecialValueFor("max_stacks")
	self.total_duration = self:GetSpecialValueFor("buffer_duration") + self:GetSpecialValueFor("loss_timer")
	
	self:GetParent()._spellLifestealModifiersList = self:GetParent()._spellLifestealModifiersList or {}
	self:GetParent()._spellLifestealModifiersList[self] = true
end

function modifier_item_kaya_and_sange_2_passive:DeclareFunctions()
	return {
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
			MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_HEALTH_BONUS,
			MODIFIER_PROPERTY_MANA_BONUS,
			MODIFIER_PROPERTY_MIN_HEALTH,
			MODIFIER_EVENT_ON_TAKEDAMAGE,
			MODIFIER_EVENT_ON_ABILITY_FULLY_CAST
	}
end

function modifier_item_kaya_and_sange_2_passive:GetMinHealth()
	if self.health_threshold_pct and self.health_threshold_pct > 1 and self:GetAbility():IsCooldownReady() and not self:GetParent():IsIllusion() then
		return math.floor( self:GetParent():GetMaxHealth() * self.health_threshold_pct / 100 )
	end
end

function modifier_item_kaya_and_sange_2_passive:OnAbilityFullyCast(params)
	if params.unit == self:GetParent() and params.ability:GetCooldown(-1) > 0 then
		self:GetParent():AddNewModifier( self:GetParent(), self:GetAbility(), "modifier_item_kaya_and_sange_endurance", {duration = self.endurance_duration} )
	end
end

function modifier_item_kaya_and_sange_2_passive:OnTakeDamage(params)
	if params.unit == self:GetParent() and not params.unit:IsIllusion() then
		if self:GetAbility():IsCooldownReady() and not params.unit:HasModifier("modifier_item_aeon_disk_effect") then
			local ability = self:GetAbility()
			if self.health_threshold_pct and self.health_threshold_pct > 1 and params.unit:GetHealthPercent() <= self.health_threshold_pct then
				ability:SetCooldown(  )
				params.unit:AddNewModifier( params.unit, ability, "modifier_item_aeon_disk_effect", {duration = self.buff_duration} )
				
				EmitSoundOn( "DOTA_Item.ComboBreaker", params.unit )
				params.unit:Dispel(params.unit, true)
				
				local magicImmune = params.unit:AddNewModifier( params.unit, ability, "modifier_magic_immune", {duration = self.buff_duration} )
				local FX = ParticleManager:CreateParticle( "particles/items_fx/black_king_bar_avatar.vpcf", PATTACH_POINT_FOLLOW, params.unit )
				magicImmune:AddEffect( FX )
			end
		end
		if not params.unit:HasModifier("modifier_item_kaya_and_sange_barrier") and self.max_stacks > 0 then
			local modifier = params.unit:AddNewModifier( params.unit, self:GetAbility(), "modifier_item_kaya_and_sange_vengeance", {duration = self.total_duration} )
			if modifier then
				modifier:SetStackCount( math.min( modifier:GetStackCount() + 1, self.max_stacks ) )
				modifier:ForceRefresh()
			end
		end
	end
end

function modifier_item_kaya_and_sange_2_passive:GetModifierProperty_MagicalLifesteal(params)
	return self.spell_lifesteal
end

function modifier_item_kaya_and_sange_2_passive:GetModifierBonusStats_Strength()
	return self.bonus_strength
end

function modifier_item_kaya_and_sange_2_passive:GetModifierBonusStats_Intellect()
	return self.bonus_intellect
end

function modifier_item_kaya_and_sange_2_passive:GetModifierStatusResistanceStacking()
	return self.status_resistance
end

function modifier_item_kaya_and_sange_2_passive:GetModifierSpellAmplify_Percentage()
	return self.spell_amp
end

function modifier_item_kaya_and_sange_2_passive:GetModifierHealAmplify_PercentageSource()
	return self.restore_amp
end

function modifier_item_kaya_and_sange_2_passive:GetModifierHPRegenAmplify_Percentage()
	return self.restore_amp
end

function modifier_item_kaya_and_sange_2_passive:GetModifierMPRegenAmplify_Percentage()
	return self.restore_amp
end

function modifier_item_kaya_and_sange_2_passive:GetModifierLifestealRegenAmplify_Percentage()
	return self.restore_amp
end

function modifier_item_kaya_and_sange_2_passive:GetModifierHealthBonus()
	return self.bonus_health + self.health_per_str * self:GetParent():GetStrength()
end

function modifier_item_kaya_and_sange_2_passive:GetModifierManaBonus()
	return self.bonus_mana
end

function modifier_item_kaya_and_sange_2_passive:IsHidden()
	return true
end

function modifier_item_kaya_and_sange_2_passive:IsPurgable()
	return false
end

function modifier_item_kaya_and_sange_2_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

modifier_item_kaya_and_sange_vengeance = class({})
LinkLuaModifier( "modifier_item_kaya_and_sange_vengeance", "items/item_kaya_and_sange.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_kaya_and_sange_vengeance:OnCreated()
	self:OnRefresh()
end

function modifier_item_kaya_and_sange_vengeance:OnRefresh()
	self.spell_amp_stacks = self:GetSpecialValueFor("spell_amp_stacks")
	self.buffer_duration = self:GetSpecialValueFor("buffer_duration")
	self.loss_per_sec = self:GetSpecialValueFor("loss_timer") / self:GetStackCount()
	self.loss_float = 0
	
	if IsServer() then
		self:StartIntervalThink(self.buffer_duration)
	end
end

function modifier_item_kaya_and_sange_vengeance:OnIntervalThink()
	if self:GetStackCount() > 1 then
		self:DecrementStackCount( )
		self:StartIntervalThink(self.loss_per_sec)
	end
end

function modifier_item_kaya_and_sange_vengeance:DeclareFunctions()
	return {MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE}
end

function modifier_item_kaya_and_sange_vengeance:GetModifierSpellAmplify_Percentage()
	return self.spell_amp_stacks * self:GetStackCount()
end

modifier_item_kaya_and_sange_endurance = class({})
LinkLuaModifier( "modifier_item_kaya_and_sange_endurance", "items/item_kaya_and_sange.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_kaya_and_sange_endurance:OnCreated()
	self:OnRefresh()
end

function modifier_item_kaya_and_sange_endurance:OnRefresh()
	self.endurance_bonus = self:GetSpecialValueFor("endurance_bonus") / 100
	self.restore_amp = self:GetSpecialValueFor("restore_amp") * self.endurance_bonus
	self.status_resistance = self:GetSpecialValueFor("status_resistance") * self.endurance_bonus
end

function modifier_item_kaya_and_sange_endurance:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
			MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
			MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_TOOLTIP}
end

function modifier_item_kaya_and_sange_endurance:GetModifierStatusResistanceStacking()
	return self.status_resistance
end

function modifier_item_kaya_and_sange_endurance:GetModifierHealAmplify_PercentageSource()
	return self.restore_amp
end

function modifier_item_kaya_and_sange_endurance:GetModifierHPRegenAmplify_Percentage()
	return self.restore_amp
end

function modifier_item_kaya_and_sange_endurance:GetModifierMPRegenAmplify_Percentage()
	return self.restore_amp
end

function modifier_item_kaya_and_sange_endurance:GetModifierLifestealRegenAmplify_Percentage()
	return self.restore_amp
end

function modifier_item_kaya_and_sange_endurance:OnTooltip()
	return self.endurance_bonus * 100
end