item_vindicators_axe = class({})

function item_vindicators_axe:GetIntrinsicModifierName()
	return "modifier_item_vindicators_axe_passive"
end

modifier_item_vindicators_axe_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_vindicators_axe_passive", "items/item_vindicators_axe.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_vindicators_axe_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_vindicators_axe_passive:OnRefresh()
	self.bonus_attack_speed = self:GetSpecialValueFor("bonus_attack_speed")
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.radius = self:GetSpecialValueFor("radius")
	
	if IsServer() then
		self:StartIntervalThink( 0.2 )
	end
end

function modifier_item_vindicators_axe_passive:OnIntervalThink()
	local caster = self:GetCaster()
	self:SetStackCount( #caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self.radius, {type = DOTA_UNIT_TARGET_HERO } ) )
end

function modifier_item_vindicators_axe_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE }
end

function modifier_item_vindicators_axe_passive:GetModifierAttackSpeedBonus_Constant()
	if self:GetStackCount() > 0 then
		return self.bonus_attack_speed
	end
end

function modifier_item_vindicators_axe_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end