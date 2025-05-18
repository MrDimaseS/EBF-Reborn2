item_paintball = class({})

function item_paintball:GetIntrinsicModifierName()
	return "modifier_item_paintball_passive"
end

function item_paintball:GetAOERadius()
	return self:GetSpecialValueFor("aoe")
end

function item_paintball:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()
	
	local dummy = caster:CreateDummy(target)
	self:FireTrackingProjectile("particles/items2_fx/paintball.vpcf", dummy, 900)
	EmitSoundOn( "Item.Paintball.Cast", caster )
end

function item_paintball:OnProjectileHit( target, position )
	local caster = self:GetCaster()
	if not target then return end
	
	local duration = self:GetSpecialValueFor("duration")
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), self:GetAOERadius() ) ) do
		enemy:AddNewModifier( caster, self, "modifier_item_paintball_debuff", {duration = duration })
	end
	EmitSoundOn( "Item.Paintball.Target", target )
	
	UTIL_Remove( target )
end

modifier_item_paintball_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_paintball_passive", "items/item_paintball.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_paintball_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_paintball_passive:OnRefresh()
	self.movespeed = self:GetSpecialValueFor("movespeed")
	self.bonus_all = self:GetSpecialValueFor("bonus_all")
end

function modifier_item_paintball_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,				
			MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT }
end

function modifier_item_paintball_passive:GetModifierMoveSpeedBonus_Constant()
	return self.movespeed
end

function modifier_item_paintball_passive:GetModifierBonusStats_Strength()
	return self.bonus_all
end

function modifier_item_paintball_passive:GetModifierBonusStats_Agility()
	return self.bonus_all
end

function modifier_item_paintball_passive:GetModifierBonusStats_Intellect()
	return self.bonus_all
end