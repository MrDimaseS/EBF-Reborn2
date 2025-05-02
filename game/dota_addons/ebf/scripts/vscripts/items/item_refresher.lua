item_refresher = class({})

function item_refresher:GetIntrinsicModifierName()
	return "modifier_item_refresher_passive"
end

function item_refresher:OnSpellStart()
	local caster = self:GetCaster()
	
	caster:RefreshAllCooldowns(true)
	ParticleManager:FireParticle("particles/items2_fx/refresher.vpcf", PATTACH_POINT_FOLLOW, caster )
	EmitSoundOn( "DOTA_Item.Refresher.Activate", caster )
end

modifier_item_refresher_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_refresher_passive", "items/item_refresher.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_refresher_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_refresher_passive:OnRefresh()
	self.bonus_health_regen = self:GetSpecialValueFor("bonus_health_regen")
	self.bonus_mana_regen = self:GetSpecialValueFor("bonus_mana_regen")
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	
	self.health_restore = self:GetSpecialValueFor("health_restore")
	self.mana_restore = self:GetSpecialValueFor("mana_restore")
end

function modifier_item_refresher_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_MANA_REGEN_CONSTANT ,
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_EVENT_ON_ABILITY_FULLY_CAST }
end

function modifier_item_refresher_passive:GetModifierConstantManaRegen()
	return self.bonus_mana_regen
end

function modifier_item_refresher_passive:GetModifierConstantHealthRegen()
	return self.bonus_health_regen
end

function modifier_item_refresher_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_refresher_passive:OnAbilityFullyCast( params )
	if params.unit ~= self:GetParent() then return end
	if params.ability:IsItem() then return end
	params.unit:HealEvent( self.health_restore, self:GetAbility(), params.unit )
	params.unit:GiveMana( self.mana_restore )
end