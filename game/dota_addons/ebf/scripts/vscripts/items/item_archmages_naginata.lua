item_archmages_naginata = class({})

function item_archmages_naginata:GetIntrinsicModifierName()
	return "modifier_item_archmages_naginata_passive"
end

modifier_item_archmages_naginata_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_archmages_naginata_passive", "items/item_archmages_naginata.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_archmages_naginata_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_archmages_naginata_passive:OnRefresh()
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.bonus_int = self:GetSpecialValueFor("bonus_int")
	self.bonus_mana_regen = self:GetSpecialValueFor("bonus_mana_regen")
	
	self.cdr_chance = self:GetSpecialValueFor("cdr_chance")
	self.cdr_on_proc = self:GetSpecialValueFor("cdr_on_proc") / 100
end

function modifier_item_archmages_naginata_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,				
			MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
			MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_item_archmages_naginata_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_archmages_naginata_passive:GetModifierBonusStats_Intellect()
	return self.bonus_int
end

function modifier_item_archmages_naginata_passive:GetModifierConstantManaRegen()
	return self.bonus_mana_regen
end

function modifier_item_archmages_naginata_passive:OnAttackLanded( params )
	local parent = self:GetParent()
	if params.attacker ~= parent then return end
	if self:RollPRNG( self.cdr_chance ) then
		EmitSoundOn( "Tower.Water.Attack", parent )
		ParticleManager:FireParticle( "particles/units/heroes/heroes_underlord/underlord_pit_cast_beam.vpcf", PATTACH_POINT_FOLLOW, parent )
		for i = 0, parent:GetAbilityCount()-1 do
			local ability = parent:GetAbilityByIndex(i)
			if ability and ability:GetCooldownTimeRemaining() > 0 then
				ability:ModifyCooldown( -ability:GetCooldownTimeRemaining() * self.cdr_on_proc )
			end
		end
	end
end