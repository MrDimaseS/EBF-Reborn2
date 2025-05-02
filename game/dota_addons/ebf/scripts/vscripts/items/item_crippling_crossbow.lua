item_crippling_crossbow = class({})

function item_crippling_crossbow:GetIntrinsicModifierName()
	return "modifier_item_crippling_crossbow_passive"
end

function item_crippling_crossbow:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	self:FireTrackingProjectile("particles/items4_fx/hefty_crossbow.vpcf", target, self:GetSpecialValueFor("projectile_speed"))
	EmitSoundOn( "item_crippling_crossbow.cast", caster )
end

function item_crippling_crossbow:OnProjectileHit( target, position )
	local caster = self:GetCaster()
	if not target then return end
	target:AddNewModifier( caster, self, "modifier_item_crippling_crossbow", {duration = self:GetSpecialValueFor("duration") })
	self:DealDamage( caster, target, self:GetSpecialValueFor("damage") )
	EmitSoundOn( "item_crippling_crossbow.target", target )
end


modifier_item_crippling_crossbow_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_crippling_crossbow_passive", "items/item_crippling_crossbow.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_crippling_crossbow_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_crippling_crossbow_passive:OnRefresh()
	self.bonus_all = self:GetSpecialValueFor("bonus_all")
end

function modifier_item_crippling_crossbow_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS }
end

function modifier_item_crippling_crossbow_passive:GetModifierBonusStats_Strength()
	return self.bonus_all
end

function modifier_item_crippling_crossbow_passive:GetModifierBonusStats_Agility()
	return self.bonus_all
end

function modifier_item_crippling_crossbow_passive:GetModifierBonusStats_Intellect()
	return self.bonus_all
end