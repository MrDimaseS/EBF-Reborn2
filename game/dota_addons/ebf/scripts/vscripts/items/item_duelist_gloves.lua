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
	self.bonus_health = self:GetSpecialValueFor("bonus_health")
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
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_HEALTH_BONUS 
			}
end

function modifier_item_duelist_gloves_passive:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed * (1 + (self:GetStackCount()) * self.proximity_bonus )
end

function modifier_item_duelist_gloves_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage * (1 + (self:GetStackCount()) * self.proximity_bonus )
end

function modifier_item_duelist_gloves_passive:GetModifierHealthBonus()
	return self.bonus_health * (1 + (self:GetStackCount()) * self.proximity_bonus )
end

function modifier_item_duelist_gloves_passive:IsHidden()
	return self:GetStackCount() <= 0
end