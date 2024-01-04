item_fallen_sky = class({})

function item_fallen_sky:GetIntrinsicModifierName()
	return "modifier_fallen_sky_passive"
end

function item_fallen_sky:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	local damage = self:DealDamage( caster, target, self:GetSpecialValueFor("damage")  )
	caster:HealEvent( damage * self:GetSpecialValueFor("dagon_spell_lifesteal") / 100, self, caster )
	ParticleManager:FireRopeParticle("particles/items_fx/dagon.vpcf", PATTACH_POINT_FOLLOW, caster, target )
	EmitSoundOn("DOTA_Item.Dagon.Activate", caster )
	EmitSoundOn("DOTA_Item.Dagon5.Target", target )
end

item_fallen_sky_2 = class(item_fallen_sky)
item_fallen_sky_3 = class(item_fallen_sky)
item_fallen_sky_4 = class(item_fallen_sky)
item_fallen_sky_5 = class(item_fallen_sky)

modifier_fallen_sky_passive = class({})
LinkLuaModifier( "modifier_fallen_sky_passive", "items/item_dagon.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_fallen_sky_passive:OnCreated()
	self:OnRefresh()
end

function modifier_fallen_sky_passive:OnRefresh()
	self.bonus_other = self:GetSpecialValueFor("bonus_other")
	self.bonus_intellect = self:GetSpecialValueFor("bonus_intellect")
	self.bonus_mana_regen = self:GetSpecialValueFor("bonus_mana_regen")
	self.bonus_cooldown = self:GetSpecialValueFor("bonus_cooldown")
	self.spell_lifesteal = self:GetSpecialValueFor("passive_spell_lifesteal")
end

function modifier_fallen_sky_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
			MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
			}
end

function modifier_fallen_sky_passive:GetModifierBonusStats_Strength()
	return self.bonus_other
end

function modifier_fallen_sky_passive:GetModifierBonusStats_Agility()
	return self.bonus_other
end

function modifier_fallen_sky_passive:GetModifierBonusStats_Intellect()
	return self.bonus_intellect
end

function modifier_fallen_sky_passive:GetModifierConstantManaRegen()
	return self.bonus_mana_regen
end

function modifier_fallen_sky_passive:GetModifierPercentageCooldown()
	return self.bonus_cooldown
end

function modifier_fallen_sky_passive:IsHidden()
	return true
end

function modifier_fallen_sky_passive:IsPurgable()
	return false
end

function modifier_fallen_sky_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end