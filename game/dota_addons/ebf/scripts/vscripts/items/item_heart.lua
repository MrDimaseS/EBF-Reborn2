item_heart = class({})

function item_heart:GetIntrinsicModifierName()
	return "modifier_item_heart_passive"
end

function item_heart:OnSpellStart()
	local caster = self:GetCaster()
	
	caster:AddNewModifier( caster, self, "modifier_item_heart_active", {duration = self:GetSpecialValueFor("duration")} )
	EmitSoundOn( "DOTA_Item.HealingSalve.Activate", caster )
end

item_heart_2 = class(item_heart)
item_heart_3 = class(item_heart)
item_heart_4 = class(item_heart)
item_heart_5 = class(item_heart)
item_asura_heart = class(item_heart)


modifier_item_heart_active = class({})
LinkLuaModifier( "modifier_item_heart_active", "items/item_heart.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_heart_active:OnCreated()
	self:OnRefresh()
end

function modifier_item_heart_active:OnRefresh()
	self.power_multiplier = self:GetSpecialValueFor("power_multiplier")-1
	self.bonus_hp_regen_per_str = self:GetSpecialValueFor("bonus_hp_regen_per_str")
	self.bonus_hp_per_str = self:GetSpecialValueFor("bonus_hp_per_str")
	self.magic_resist = self:GetSpecialValueFor("magic_resist")
	self.magic_immune = self:GetSpecialValueFor("magic_immune") == 1
	if IsServer() and self.magic_immune then
		local magicFX = ParticleManager:CreateParticle("particles/items_fx/black_king_bar_avatar.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
		self:AddEffect( magicFX )
		
		self:StartIntervalThink(0)
	end
end

function modifier_item_heart_active:OnIntervalThink()
	self:GetParent():HealEvent( self.bonus_hp_per_str * self:GetParent():GetStrength(), self:GetAbility(), self:GetParent() )
	self:StartIntervalThink(-1)
end

function modifier_item_heart_active:CheckState()
	if self.magic_immune then
		return {[MODIFIER_STATE_DEBUFF_IMMUNE] = true}
	end
end

function modifier_item_heart_active:DeclareFunctions()
	return {MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
			MODIFIER_PROPERTY_TOOLTIP,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }
end

function modifier_item_heart_active:GetModifierMagicalResistanceBonus()
	return self.magic_resist
end

function modifier_item_heart_active:GetModifierExtraHealthBonus()
	return self.bonus_hp_per_str * self:GetParent():GetStrength()
end

function modifier_item_heart_active:GetModifierConstantHealthRegen()
	return self.bonus_hp_regen_per_str * self:GetParent():GetStrength()
end

function modifier_item_heart_active:OnTooltip()
	return 1+self.power_multiplier
end

function modifier_item_heart_active:GetEffectName()
	return "particles/items_fx/item_heart_active.vpcf"
end

modifier_item_heart_passive = class({})
LinkLuaModifier( "modifier_item_heart_passive", "items/item_heart.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_heart_passive:OnCreated()
	self.bonus_strength = self:GetSpecialValueFor("bonus_strength")
	self.bonus_hp_per_str = self:GetSpecialValueFor("bonus_hp_per_str")
	self.bonus_hp_regen_per_str = self:GetSpecialValueFor("bonus_hp_regen_per_str")
	
	self.bonus_strength_PR = self:GetSpecialValueFor("bonus_strength_PR")
	
	if self.bonus_strength_PR > 0 and IsServer() then
		self:StartIntervalThink(0.25)
	end
end

function modifier_item_heart_passive:OnIntervalThink()
	local stack = GameRules._roundnumber
	if stack ~= self:GetStackCount() then
		self:SetStackCount( stack )
	end
end

function modifier_item_heart_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS }
end

function modifier_item_heart_passive:GetModifierExtraHealthBonus()
	return self.bonus_hp_per_str * self:GetParent():GetStrength()
end

function modifier_item_heart_passive:GetModifierConstantHealthRegen()
	return self.bonus_hp_regen_per_str * self:GetParent():GetStrength()
end

function modifier_item_heart_passive:GetModifierBonusStats_Strength()
	return self.bonus_strength + self:GetStackCount() * self.bonus_strength_PR
end

function modifier_item_heart_passive:IsHidden()
	return true
end

function modifier_item_heart_passive:IsPurgable()
	return false
end

function modifier_item_heart_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end