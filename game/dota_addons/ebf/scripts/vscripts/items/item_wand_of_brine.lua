item_wand_of_brine = class({})

function item_wand_of_brine:GetIntrinsicModifierName()
	return "modifier_item_wand_of_brine_passive"
end

function item_wand_of_brine:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	target:RemoveModifierByName("modifier_item_wand_of_brine_active")
	local buffDuration	 = self:GetSpecialValueFor("buff_duration")
	target:AddNewModifier( caster, self, "modifier_item_wand_of_brine_active", {duration = buffDuration} )
	
	EmitSoundOn("Hero_Ancient_Apparition.IceBlast.Tracker", caster )
	EmitSoundOn("Hero_Tidehunter.DeadInTheWater.Destroy", target )
end

modifier_item_wand_of_brine_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_wand_of_brine_passive", "items/item_wand_of_brine.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_wand_of_brine_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_wand_of_brine_passive:OnRefresh()
	self.bonus_primary = self:GetSpecialValueFor("bonus_primary")
end

function modifier_item_wand_of_brine_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS }
end

function modifier_item_wand_of_brine_passive:GetModifierBonusStats_Strength()
	if self:GetParent():GetPrimaryAttribute() == DOTA_ATTRIBUTE_ALL then
		return self.bonus_primary / 3
	elseif self:GetParent():GetPrimaryAttribute() == DOTA_ATTRIBUTE_STRENGTH then
		return self.bonus_primary
	end
end

function modifier_item_wand_of_brine_passive:GetModifierBonusStats_Agility()
	if self:GetParent():GetPrimaryAttribute() == DOTA_ATTRIBUTE_ALL then
		return self.bonus_primary / 3
	elseif self:GetParent():GetPrimaryAttribute() == DOTA_ATTRIBUTE_AGILITY then
		return self.bonus_primary
	end
end

function modifier_item_wand_of_brine_passive:GetModifierBonusStats_Intellect()
	if self:GetParent():GetPrimaryAttribute() == DOTA_ATTRIBUTE_ALL then
		return self.bonus_primary / 3
	elseif self:GetParent():GetPrimaryAttribute() == DOTA_ATTRIBUTE_INTELLECT then
		return self.bonus_primary
	end
end

modifier_item_wand_of_brine_active = class({})
LinkLuaModifier( "modifier_item_wand_of_brine_active", "items/item_wand_of_brine.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_wand_of_brine_active:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink( self.tick )
	end
end

function modifier_item_wand_of_brine_active:OnRefresh()
	self.heal_per_second = self:GetSpecialValueFor("heal_per_second")
	self.tick = 0.5
end

function modifier_item_wand_of_brine_active:OnIntervalThink()
	self:GetParent():HealEvent( self.heal_per_second * self.tick, self:GetAbility(), self:GetCaster() )
end

function modifier_item_wand_of_brine_active:CheckState()
	return {[MODIFIER_STATE_STUNNED] = true,
			[MODIFIER_STATE_INVULNERABLE] = true,
			[MODIFIER_STATE_OUT_OF_GAME] = true,}
end

function modifier_item_wand_of_brine_active:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE}
end

function modifier_item_wand_of_brine_active:GetModifierIncomingDamage_Percentage( params )
	if params.damage_category ~= DOTA_DAMAGE_CATEGORY_SPELL then return end
	if self.bonus_damage <= 0 then return end
	local bonusDamage = math.min( params.damage, self.bonus_damage )
	local dmgPct = (params.damage + bonusDamage) / params.damage
	self.bonus_damage = math.max( 0, self.bonus_damage - params.damage )
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, params.target, bonusDamage, self:GetCaster():GetPlayerOwner())
	if self.bonus_damage <= 0 then
		self:Destroy()
	end
	return dmgPct * 100 - 100
end

function modifier_item_wand_of_brine_active:GetEffectName()
	return "particles/items_fx/wand_of_the_brine_buff.vpcf"
end

function modifier_item_wand_of_brine_active:GetStatusEffectName()
	return "particles/status_fx/status_effect_charge_of_darkness.vpcf"
end

function modifier_item_wand_of_brine_active:StatusEffectPriority()
	return 10
end