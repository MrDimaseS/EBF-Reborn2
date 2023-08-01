item_uber_dagon = class({})

function item_uber_dagon:GetIntrinsicModifierName()
	return "modifier_uber_dagon_passive"
end

function item_uber_dagon:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	local damage = self:DealDamage( caster, target, self:GetSpecialValueFor("damage")  )
	caster:HealEvent( damage * self:GetSpecialValueFor("dagon_spell_lifesteal") / 100, self, caster )
	ParticleManager:FireRopeParticle("particles/items_fx/dagon.vpcf", PATTACH_POINT_FOLLOW, caster, target )
	EmitSoundOn("DOTA_Item.Dagon.Activate", caster )
	EmitSoundOn("DOTA_Item.Dagon5.Target", target )
end

item_uber_dagon_2 = class(item_uber_dagon)
item_uber_dagon_3 = class(item_uber_dagon)
item_uber_dagon_4 = class(item_uber_dagon)
item_uber_dagon_5 = class(item_uber_dagon)
item_dagon_5 = class(item_uber_dagon)

modifier_uber_dagon_passive = class({})
LinkLuaModifier( "modifier_uber_dagon_passive", "items/item_dagon.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_uber_dagon_passive:OnCreated()
	self:OnRefresh()
end

function modifier_uber_dagon_passive:OnRefresh()
	self.bonus_other = self:GetSpecialValueFor("bonus_other")
	self.bonus_intellect = self:GetSpecialValueFor("bonus_intellect")
	self.bonus_mana_regen = self:GetSpecialValueFor("bonus_mana_regen")
	self.bonus_cooldown = self:GetSpecialValueFor("bonus_cooldown")
	self.spell_lifesteal = self:GetSpecialValueFor("passive_spell_lifesteal")
	
	self:GetParent().cooldownModifiers = self:GetParent().cooldownModifiers or {}
	self:GetParent().cooldownModifiers[self] = true
end

function modifier_uber_dagon_passive:OnDestroy()
	self:GetParent().cooldownModifiers[self] = nil
end

function modifier_uber_dagon_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
			MODIFIER_EVENT_ON_TAKEDAMAGE 
			}
end

function modifier_uber_dagon_passive:OnTakeDamage( params )
	if self.spell_lifesteal > 0 and params.attacker == self:GetParent() and params.damage_category == DOTA_DAMAGE_CATEGORY_SPELL and params.inflictor and not ( HasBit( params.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL ) or HasBit( params.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS ) or HasBit( params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION )) then
		local spell_lifesteal = self.spell_lifesteal
		
		if not params.unit:IsConsideredHero() then
			spell_lifesteal =  spell_lifesteal / 5
		end
		
		local EHPMult = self:GetParent().EHP_MULT or 1
		local lifesteal = params.damage * spell_lifesteal / 100 * math.max( 1, EHPMult )
		
		self.lifeToGive = (self.lifeToGive or 0) + lifesteal
		if self.lifeToGive > 1 then
			local preHP = params.attacker:GetHealth()
			params.attacker:HealWithParams( lifesteal, params.inflictor, false, true, self, true )
			self.lifeToGive = self.lifeToGive - math.floor(self.lifeToGive)
			local postHP = params.attacker:GetHealth()
		
			if postHP - preHP ~= 0 then
				ParticleManager:FireParticle( "particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_POINT_FOLLOW, params.attacker )
			end
		end
	end
end

function modifier_uber_dagon_passive:GetModifierBonusStats_Strength()
	return self.bonus_other
end

function modifier_uber_dagon_passive:GetModifierBonusStats_Agility()
	return self.bonus_other
end

function modifier_uber_dagon_passive:GetModifierBonusStats_Intellect()
	return self.bonus_intellect
end

function modifier_uber_dagon_passive:GetModifierConstantManaRegen()
	return self.bonus_mana_regen
end

function modifier_uber_dagon_passive:GetModifierCastSpeed()
	return self.bonus_cooldown
end

function modifier_uber_dagon_passive:IsHidden()
	return true
end

function modifier_uber_dagon_passive:IsPurgable()
	return false
end

function modifier_uber_dagon_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end