item_aeon_disk = class({})

function item_aeon_disk:GetIntrinsicModifierName()
	return "modifier_item_aeon_disk_handler"
end

function item_aeon_disk:ShouldUseResources()
	return true
end

function item_aeon_disk:IsRearmable()
	return false
end

item_aeon_disk2 = class(item_aeon_disk)
item_aeon_disk3 = class(item_aeon_disk)
item_aeon_disk4 = class(item_aeon_disk)
item_aeon_disk5 = class(item_aeon_disk)

modifier_item_aeon_disk_handler = class({})
LinkLuaModifier( "modifier_item_aeon_disk_handler", "items/item_aeon_disk.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_aeon_disk_handler:OnCreated()
	self.bonus_all = self:GetSpecialValueFor("bonus_all")
	self.bonus_health = self:GetSpecialValueFor("bonus_health")
	self.bonus_mana = self:GetSpecialValueFor("bonus_mana")
	
	self.health_threshold_pct = self:GetSpecialValueFor("health_threshold_pct")
	self.buff_duration = self:GetSpecialValueFor("buff_duration")
end

function modifier_item_aeon_disk_handler:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_MANA_BONUS,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_MIN_HEALTH,
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}
end

function modifier_item_aeon_disk_handler:GetModifierBonusStats_Agility()
	return self.bonus_all
end

function modifier_item_aeon_disk_handler:GetModifierBonusStats_Strength()
	return self.bonus_all
end

function modifier_item_aeon_disk_handler:GetModifierBonusStats_Intellect()
	return self.bonus_all
end


function modifier_item_aeon_disk_handler:GetModifierManaBonus()
	return self.bonus_mana
end

function modifier_item_aeon_disk_handler:GetModifierHealthBonus()
	return self.bonus_mana
end

function modifier_item_aeon_disk_handler:GetMinHealth()
	if self:GetAbility():IsCooldownReady() and not self:GetParent():IsIllusion() and self:GetParent():IsAlive() then
		return math.floor( self:GetParent():GetMaxHealth() * self.health_threshold_pct / 100 )
	end
end

function modifier_item_aeon_disk_handler:OnTakeDamage(params)
	if params.unit == self:GetParent() and self:GetAbility():IsCooldownReady() and not params.unit:HasModifier("modifier_item_aeon_disk_effect") and not params.unit:IsIllusion() then
		local ability = self:GetAbility()
		if params.unit:GetHealthPercent() <= self.health_threshold_pct+0.1 then
			ability:SetCooldown(  )
			params.unit:AddNewModifier( params.unit, ability, "modifier_item_aeon_disk_effect", {duration = self.buff_duration} )
			EmitSoundOn( "DOTA_Item.ComboBreaker", params.unit )
			params.unit:Dispel(params.unit, true)
			if self:GetSpecialValueFor("magic_immune") == 1 then
				local magicImmune = params.unit:AddNewModifier( params.unit, ability, "modifier_magic_immune", {duration = self.buff_duration} )
				local FX = ParticleManager:CreateParticle( "particles/items_fx/black_king_bar_avatar.vpcf", PATTACH_POINT_FOLLOW, params.unit )
				magicImmune:AddEffect( FX )
			end
		end
	end
end

function modifier_item_aeon_disk_handler:IsHidden()
	return true
end

modifier_item_aeon_disk_effect = class({})
LinkLuaModifier( "modifier_item_aeon_disk_effect", "items/item_aeon_disk.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_aeon_disk_effect:OnCreated()
	self.dmg_outgoing = self:GetSpecialValueFor("outgoing_damage_reduction")
	self.status_resistance = self:GetSpecialValueFor("status_resistance")
	
	self.magic_immune = self:GetSpecialValueFor("magic_immune") == 1
	
	if IsServer() then
		local FX = ParticleManager:CreateParticle( "particles/items4_fx/combo_breaker_buff.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
		ParticleManager:SetParticleControlEnt(FX, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(FX, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
		self:AddEffect( FX )
	end
end

function modifier_item_aeon_disk_effect:CheckState()
	if self.magic_immune then
		return {[MODIFIER_STATE_DEBUFF_IMMUNE] = true}
	end
end

function modifier_item_aeon_disk_effect:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	}
end

function modifier_item_aeon_disk_effect:GetModifierStatusResistanceStacking()
	return self.status_resistance
end

function modifier_item_aeon_disk_effect:GetModifierTotalDamageOutgoing_Percentage()
	return self.dmg_outgoing
end

function modifier_item_aeon_disk_effect:GetModifierIncomingDamage_Percentage()
	return -100
end

function modifier_item_aeon_disk_effect:GetStatusEffectName()
	return "particles/status_fx/status_effect_combo_breaker.vpcf"
end

function modifier_item_aeon_disk_effect:StatusEffectPriority()
	return 20
end

modifier_item_aeon_disk_cooldown = class({})
LinkLuaModifier( "modifier_item_aeon_disk_cooldown", "items/item_aeon_disk.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_aeon_disk_cooldown:IsPurgable()
	return false
end

function modifier_item_aeon_disk_cooldown:IsDebuff()
	return true
end