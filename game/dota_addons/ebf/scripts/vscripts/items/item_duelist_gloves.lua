item_duelist_gloves = class({})

function item_duelist_gloves:GetIntrinsicModifierName()
	return "modifier_item_duelist_gloves_passive"
end

modifier_item_duelist_gloves_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_duelist_gloves_passive", "items/item_duelist_gloves.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_duelist_gloves_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_duelist_gloves_passive:OnRefresh()
	self.bonus_attack_speed = self:GetSpecialValueFor("bonus_attack_speed")
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.radius = self:GetSpecialValueFor("radius")
	self.proximity_bonus = self:GetSpecialValueFor("proximity_bonus") / 100
	
	if IsServer() then
		self:StartIntervalThink( 0.2 )
	end
end

function modifier_item_duelist_gloves_passive:OnIntervalThink()
	local caster = self:GetCaster()
	self:SetStackCount( #caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self.radius, {type = DOTA_UNIT_TARGET_HERO } ) )
end

function modifier_item_duelist_gloves_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE }
end

function modifier_item_duelist_gloves_passive:GetModifierAttackSpeedBonus_Constant()
	if self:GetStackCount() > 0 then
		return self.bonus_attack_speed * (1 + (self:GetStackCount()-1) * self.proximity_bonus )
	end
end

function modifier_item_duelist_gloves_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_duelist_gloves_passive:IsHidden()
	return self:GetStackCount() <= 0
end