item_paladin_sword = class({})

function item_paladin_sword:GetIntrinsicModifierName()
	return "modifier_item_paladin_sword_passive"
end

modifier_item_paladin_sword_passive = class({})
LinkLuaModifier( "modifier_item_paladin_sword_passive", "items/item_paladin_sword.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_paladin_sword_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_paladin_sword_passive:OnRefresh()
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.bonus_amp = self:GetSpecialValueFor("bonus_amp")
	self.bonus_health_regen = self:GetSpecialValueFor("bonus_health_regen")
	if IsServer() then
		self:StartIntervalThink( 0.33 )
	end
end

function modifier_item_paladin_sword_passive:OnIntervalThink()
	self:SetStackCount( math.floor( self:GetParent():GetHealthRegen() ) )
end

function modifier_item_paladin_sword_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT}
end

function modifier_item_paladin_sword_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage * self:GetStackCount()
end

function modifier_item_paladin_sword_passive:GetModifierPropertyRestorationAmplification()
	return self.bonus_amp
end

function modifier_item_paladin_sword_passive:GetModifierConstantHealthRegen()
	return self.bonus_health_regen
end

function modifier_item_paladin_sword_passive:IsHidden()
	return true
end

function modifier_item_paladin_sword_passive:IsPurgable()
	return false
end

function modifier_item_paladin_sword_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end