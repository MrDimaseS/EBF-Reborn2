item_octarine_core = class({})

function item_octarine_core:GetIntrinsicModifierName()
	return "modifier_item_octarine_core_ebf"
end

item_hourglass_shard = class(item_octarine_core)
item_octarine_core2 = class(item_octarine_core)

function item_octarine_core2:IsRefreshable()
	return false
end

function item_octarine_core2:OnSpellStart()
	self:GetCaster():RefreshAllCooldowns( true )
	
	EmitSoundOn( "DOTA_Item.Refresher.Activate", self:GetCaster() )
	ParticleManager:FireParticle( "particles/items2_fx/refresher.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster() )
end

item_refresher = class(item_octarine_core2)
item_octarine_core3 = class(item_octarine_core2)
item_octarine_core4 = class(item_octarine_core2)
item_octarine_core5 = class(item_octarine_core2)
item_asura_core = class(item_octarine_core2)

modifier_item_octarine_core_ebf = class({})
LinkLuaModifier( "modifier_item_octarine_core_ebf", "items/item_octarine_core.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_octarine_core_ebf:OnCreated()
	self:OnRefresh()
end

function modifier_item_octarine_core_ebf:OnRefresh()
	self.bonus_health_regen = self:GetAbility():GetSpecialValueFor("bonus_health_regen")
	self.bonus_mana_regen = self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
	self.bonus_mana = self:GetAbility():GetSpecialValueFor("bonus_mana")
	self.bonus_health = self:GetAbility():GetSpecialValueFor("bonus_health")
	self.bonus_all = self:GetAbility():GetSpecialValueFor("bonus_all")
	self.cast_range_bonus = self:GetAbility():GetSpecialValueFor("cast_range_bonus")
	self.cdr = self:GetAbility():GetSpecialValueFor("bonus_cooldown")
	
	self.bonus_health_pr = self:GetSpecialValueFor("bonus_health_pr")
	self.bonus_mana_pr = self:GetSpecialValueFor("bonus_mana_pr")
	self.bonus_health_regen_pr = self:GetSpecialValueFor("bonus_health_regen_pr")
	self.bonus_mana_regen_pr = self:GetSpecialValueFor("bonus_mana_regen_pr")
	
	self:GetParent().cooldownModifiers = self:GetParent().cooldownModifiers or {}
	self:GetParent().cooldownModifiers[self] = true
	
	if self.bonus_health_pr > 0 and IsServer() then
		self:StartIntervalThink(0.25)
	end
end

function modifier_item_octarine_core_ebf:OnDestroy()
	self:GetParent().cooldownModifiers[self] = nil
end

function modifier_item_octarine_core_ebf:OnIntervalThink()
	local stack = GameRules._roundnumber
	if stack ~= self:GetStackCount() then
		self:SetStackCount( stack )
	end
end

function modifier_item_octarine_core_ebf:DeclareFunctions(params)
local funcs = { MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
				MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
				MODIFIER_PROPERTY_HEALTH_BONUS,
				MODIFIER_PROPERTY_MANA_BONUS}
    return funcs
end

function modifier_item_octarine_core_ebf:GetModifierConstantManaRegen()
	return self.bonus_mana_regen + self:GetStackCount() * self.bonus_mana_regen_pr
end

function modifier_item_octarine_core_ebf:GetModifierConstantHealthRegen()
	return self.bonus_health_regen + self:GetStackCount() * self.bonus_health_regen_pr
end

function modifier_item_octarine_core_ebf:GetModifierManaBonus()
	return self.bonus_mana + self:GetStackCount() * self.bonus_mana_pr
end

function modifier_item_octarine_core_ebf:GetModifierHealthBonus()
	return self.bonus_health + self:GetStackCount() * self.bonus_health_pr
end

function modifier_item_octarine_core_ebf:GetModifierCastSpeed()
	return self.cdr
end

function modifier_item_octarine_core_ebf:IsHidden()
	return true
end

function modifier_item_octarine_core_ebf:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end