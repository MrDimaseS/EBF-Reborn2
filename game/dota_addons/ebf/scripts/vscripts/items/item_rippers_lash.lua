item_rippers_lash = class({})

function item_rippers_lash:GetIntrinsicModifierName()
	return "modifier_item_rippers_lash_passive"
end

function item_rippers_lash:GetAOERadius()
	return self:GetSpecialValueFor("thorn_area")
end

function item_rippers_lash:OnSpellStart()
	local caster = self:GetCaster()
	local position = self:GetCursorPosition()
	
	local radius = self:GetAOERadius()
	local duration = self:GetSpecialValueFor("duration")
	
	ParticleManager:FireParticle("particles/items4_fx/thorn_whip.vpcf", PATTACH_ABSORIGIN, caster, {[0] = caster:GetAbsOrigin(), [1] = position, [2] = Vector(radius, 0, 0)})
	EmitSoundOn("item_rippers_lash.cast", caster )
	
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( position, radius ) ) do
		enemy:AddNewModifier( caster, self, "modifier_item_rippers_lash", {duration = duration})
	end
end

modifier_item_rippers_lash_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_rippers_lash_passive", "items/item_rippers_lash.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_rippers_lash_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_rippers_lash_passive:OnRefresh()
	self.bonus_attackspeed = self:GetSpecialValueFor("bonus_attackspeed")
	self.bonus_agility = self:GetSpecialValueFor("bonus_agility")
end

function modifier_item_rippers_lash_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,}
end

function modifier_item_rippers_lash_passive:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attackspeed
end

function modifier_item_rippers_lash_passive:GetModifierBonusStats_Agility()
	return self.bonus_agility
end