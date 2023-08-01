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
	self.restoration_amp = self:GetSpecialValueFor("restoration_amp")
	self.magic_resist = self:GetSpecialValueFor("magic_resist")
	self.magic_immune = self:GetSpecialValueFor("magic_immune") == 1
	if IsServer() and self.magic_immune then
		local magicFX = ParticleManager:CreateParticle("particles/items_fx/black_king_bar_avatar.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
		self:AddEffect( magicFX )
	end
end

function modifier_item_heart_active:CheckState()
	if self.magic_immune then
		return {[MODIFIER_STATE_DEBUFF_IMMUNE] = true}
	end
end

function modifier_item_heart_active:DeclareFunctions()
	return {MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
			MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }
end

function modifier_item_heart_active:GetModifierMagicalResistanceBonus()
	return self.magic_resist
end

function modifier_item_heart_active:GetModifierHPRegenAmplify_Percentage()
	return self.restoration_amp
end

function modifier_item_heart_active:GetModifierHealAmplify_PercentageSource()
	return self.restoration_amp
end

function modifier_item_heart_active:GetModifierLifestealRegenAmplify_Percentage()
	return self.restoration_amp
end

function modifier_item_heart_active:GetModifierSpellLifestealRegenAmplify_Percentage()
	return self.restoration_amp
end

function modifier_item_heart_active:GetModifierMPRegenAmplify_Percentage()
	return self.restoration_amp
end

function modifier_item_heart_active:GetEffectName()
	return "particles/items_fx/item_heart_active.vpcf"
end

modifier_item_heart_passive = class({})
LinkLuaModifier( "modifier_item_heart_passive", "items/item_heart.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_heart_passive:OnCreated()
	self.bonus_strength = self:GetSpecialValueFor("bonus_strength")
	self.bonus_health = self:GetSpecialValueFor("bonus_health")
	self.health_regen_pct = self:GetSpecialValueFor("health_regen_pct")
	
	self.bonus_strength_PR = self:GetSpecialValueFor("bonus_strength_PR")
	self.bonus_health_PR = self:GetSpecialValueFor("bonus_health_PR")
	
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
	return {MODIFIER_PROPERTY_HEALTH_BONUS,
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE_UNIQUE  }
end

function modifier_item_heart_passive:GetModifierHealthBonus()
	return self.bonus_health + self:GetStackCount() * self.bonus_health_PR
end

function modifier_item_heart_passive:GetModifierBonusStats_Strength()
	return self.bonus_strength + self:GetStackCount() * self.bonus_strength_PR
end

function modifier_item_heart_passive:GetModifierHealthRegenPercentageUnique()
	return self.health_regen_pct
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